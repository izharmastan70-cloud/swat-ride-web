import '../models/agent_action_definition.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_read_only_payload.dart';
import '../models/agent_role.dart';
import '../models/agent_tool_request.dart';
import '../models/agent_tool_result.dart';
import 'agent_action_registry.dart';
import 'agent_permission_engine.dart';
import 'agent_read_only_connector.dart';
import 'agent_read_only_connector_registry.dart';
import 'agent_read_only_sanitizer.dart';
import 'agent_runtime_gate.dart';

// =========================================================
// AI AGENT — READ-ONLY EXECUTOR
// =========================================================
//
// Phase 7 first executable controlled-function path.
// It can execute READ-ONLY actions only.
// No approval token can turn a write action into a read action.
// No business module connector exists yet.

class AgentReadOnlyExecutor {
  final AgentPermissionEngine permissionEngine;
  final AgentRuntimeGate runtimeGate;
  final AgentReadOnlyConnectorRegistry connectorRegistry;
  final AgentReadOnlySanitizer sanitizer;

  AgentReadOnlyExecutor({
    AgentPermissionEngine? permissionEngine,
    AgentRuntimeGate? runtimeGate,
    AgentReadOnlyConnectorRegistry? connectorRegistry,
    AgentReadOnlySanitizer? sanitizer,
  })  : permissionEngine =
            permissionEngine ?? const AgentPermissionEngine(),
        runtimeGate = runtimeGate ?? const AgentRuntimeGate(),
        connectorRegistry =
            connectorRegistry ?? AgentReadOnlyConnectorRegistry(),
        sanitizer = sanitizer ?? const AgentReadOnlySanitizer();

  Future<AgentToolResult> execute({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentToolRequest request,
  }) async {
    try {
      request.validate();
    } catch (error) {
      return _result(
        request,
        AgentToolResultStatus.denied,
        'Invalid read-only request: $error',
      );
    }

    if (request.roleId != role.roleId) {
      return _result(
        request,
        AgentToolResultStatus.denied,
        'Request role does not match supplied role.',
      );
    }

    final AgentActionDefinition? action =
        AgentActionRegistry.get(request.actionId);

    if (action == null) {
      return _result(
        request,
        AgentToolResultStatus.denied,
        'Unknown action. Default-deny.',
      );
    }

    if (!action.readOnly) {
      return _result(
        request,
        AgentToolResultStatus.denied,
        'Phase 7 executor accepts read-only actions only.',
      );
    }

    final AgentPermissionDecision permission =
        permissionEngine.evaluate(
      role: role,
      actionId: request.actionId,
    );

    final AgentPermissionDecision gated = runtimeGate.apply(
      settings: settings,
      role: role,
      permissionDecision: permission,
    );

    if (gated.isDenied) {
      return _result(
        request,
        AgentToolResultStatus.denied,
        gated.reason,
      );
    }

    if (gated.needsApproval) {
      return _result(
        request,
        AgentToolResultStatus.approvalRequired,
        'This read-only action is configured to require approval.',
      );
    }

    final AgentReadOnlyConnector? connector =
        connectorRegistry.connectorFor(
      module: action.module,
      actionId: action.actionId,
    );

    if (connector == null) {
      return _result(
        request,
        AgentToolResultStatus.unavailable,
        'No approved read-only connector is attached for this action.',
      );
    }

    try {
      final AgentReadOnlyPayload payload =
          await connector.executeReadOnly(request);

      return AgentToolResult(
        status: AgentToolResultStatus.success,
        requestId: request.requestId,
        roleId: request.roleId,
        actionId: request.actionId,
        toolId: request.toolId,
        message: 'Read-only action completed.',
        data: sanitizer.sanitizeMap(payload.data),
      );
    } catch (error) {
      return _result(
        request,
        AgentToolResultStatus.failed,
        'Read-only connector failed safely: $error',
      );
    }
  }

  AgentToolResult _result(
    AgentToolRequest request,
    String status,
    String message,
  ) {
    return AgentToolResult(
      status: status,
      requestId: request.requestId,
      roleId: request.roleId,
      actionId: request.actionId,
      toolId: request.toolId,
      message: message,
    );
  }
}

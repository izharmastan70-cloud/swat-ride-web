import '../models/agent_master_settings.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import '../models/agent_tool_definition.dart';
import '../models/agent_tool_request.dart';
import '../models/agent_tool_result.dart';
import 'agent_controlled_tool_registry.dart';
import 'agent_permission_engine.dart';
import 'agent_runtime_gate.dart';

// =========================================================
// AI AGENT — CONTROLLED TOOL EXECUTOR
// =========================================================
//
// Phase 6 is deliberately NON-EXECUTING.
//
// This service proves the full gate order:
// Tool Registry -> role/tool match -> Permission Engine ->
// Master Runtime Gate -> approval requirement -> connector readiness.
//
// Since no SWAT RIDE module connector is attached yet, every request
// that passes safety checks ends as UNAVAILABLE, never as a business
// write. This keeps Phase 6 safe and standalone.

class AgentControlledToolExecutor {
  final AgentPermissionEngine permissionEngine;
  final AgentRuntimeGate runtimeGate;

  const AgentControlledToolExecutor({
    this.permissionEngine = const AgentPermissionEngine(),
    this.runtimeGate = const AgentRuntimeGate(),
  });

  AgentToolResult preflight({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentToolRequest request,
  }) {
    try {
      request.validate();
    } catch (error) {
      return _result(
        request: request,
        status: AgentToolResultStatus.denied,
        message: 'Invalid tool request: $error',
      );
    }

    final AgentToolDefinition? tool =
        AgentControlledToolRegistry.get(request.toolId);

    if (tool == null) {
      return _result(
        request: request,
        status: AgentToolResultStatus.denied,
        message: 'Unknown tool. Controlled Tool Registry is default-deny.',
      );
    }

    if (request.roleId != role.roleId) {
      return _result(
        request: request,
        status: AgentToolResultStatus.denied,
        message: 'Request role does not match supplied AgentRole.',
      );
    }

    if (request.actionId != tool.actionId) {
      return _result(
        request: request,
        status: AgentToolResultStatus.denied,
        message: 'Requested action does not match tool action.',
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
        request: request,
        status: AgentToolResultStatus.denied,
        message: gated.reason,
      );
    }

    if (gated.needsApproval) {
      return _result(
        request: request,
        status: AgentToolResultStatus.approvalRequired,
        message:
            'Explicit one-action approval is required before connector execution.',
      );
    }

    if (!tool.enabled || !tool.connectorReady) {
      return _result(
        request: request,
        status: AgentToolResultStatus.unavailable,
        message:
            'Safety gates passed, but this SWAT RIDE connector is not attached yet.',
      );
    }

    // Defensive fail-closed. Phase 6 contains no executable handlers.
    return _result(
      request: request,
      status: AgentToolResultStatus.unavailable,
      message:
          'No executable handler exists in Phase 6. Connector phase required.',
    );
  }

  AgentToolResult _result({
    required AgentToolRequest request,
    required String status,
    required String message,
  }) {
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

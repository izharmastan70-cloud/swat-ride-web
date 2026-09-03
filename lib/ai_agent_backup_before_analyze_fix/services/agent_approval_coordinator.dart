import '../models/agent_action_definition.dart';
import '../models/agent_approval_request.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import 'agent_action_registry.dart';
import 'agent_approval_service.dart';
import 'agent_permission_engine.dart';

// =========================================================
// AI AGENT — APPROVAL COORDINATOR
// =========================================================
//
// Bridges Phase 2 Permission Engine and Phase 3 Approval Engine.
// Still does NOT execute SWAT RIDE business tools.

class AgentApprovalCoordinator {
  final AgentPermissionEngine permissionEngine;
  final AgentApprovalService approvalService;

  const AgentApprovalCoordinator({
    required this.permissionEngine,
    required this.approvalService,
  });

  Future<AgentApprovalFlowResult> requestPermission({
    required AgentRole role,
    required String actionId,
    required String requestedBy,
    required Map<String, dynamic> actionScope,
    Duration approvalValidity = const Duration(minutes: 15),
  }) async {
    final AgentPermissionDecision decision = permissionEngine.evaluate(
      role: role,
      actionId: actionId,
    );

    if (decision.isDenied) {
      return AgentApprovalFlowResult(
        decision: decision,
        approvalRequest: null,
      );
    }

    if (decision.isAllowed) {
      return AgentApprovalFlowResult(
        decision: decision,
        approvalRequest: null,
      );
    }

    final AgentActionDefinition? action = AgentActionRegistry.get(actionId);

    if (action == null) {
      return AgentApprovalFlowResult(
        decision: AgentPermissionDecision.deny(
          roleId: role.roleId,
          actionId: actionId,
          reason: 'Unknown action.',
        ),
        approvalRequest: null,
      );
    }

    final AgentApprovalRequest approval =
        await approvalService.createRequest(
      roleId: role.roleId,
      actionId: actionId,
      module: action.module,
      reason: decision.reason,
      risk: action.risk,
      requestedBy: requestedBy,
      actionScope: actionScope,
      validity: approvalValidity,
    );

    return AgentApprovalFlowResult(
      decision: decision,
      approvalRequest: approval,
    );
  }
}

class AgentApprovalFlowResult {
  final AgentPermissionDecision decision;
  final AgentApprovalRequest? approvalRequest;

  const AgentApprovalFlowResult({
    required this.decision,
    required this.approvalRequest,
  });

  bool get canExecuteImmediately => decision.isAllowed;

  bool get isDenied => decision.isDenied;

  bool get isWaitingForApproval =>
      decision.needsApproval && approvalRequest != null;
}

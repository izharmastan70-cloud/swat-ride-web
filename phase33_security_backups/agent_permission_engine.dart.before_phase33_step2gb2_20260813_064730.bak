import '../constants/agent_enums.dart';
import '../models/agent_action_definition.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import 'agent_action_registry.dart';

// =========================================================
// AI AGENT — PERMISSION ENGINE
// =========================================================
//
// PURE decision engine: no Firestore writes, no tool execution.
// DEFAULT-DENY.
// Approval Engine (Phase 3) will consume REQUIRE_APPROVAL decisions.

class AgentPermissionEngine {
  const AgentPermissionEngine();

  AgentPermissionDecision evaluate({
    required AgentRole role,
    required String actionId,
  }) {
    if (role.isFailClosed) {
      return AgentPermissionDecision.deny(
        roleId: role.roleId,
        actionId: actionId,
        reason: 'Role is fail-closed/corrupted.',
      );
    }

    if (!role.isValid) {
      return AgentPermissionDecision.deny(
        roleId: role.roleId,
        actionId: actionId,
        reason: 'Role configuration is invalid.',
      );
    }

    if (!role.isOperational) {
      return AgentPermissionDecision.deny(
        roleId: role.roleId,
        actionId: actionId,
        reason: 'Role is disabled or mode is OFF.',
      );
    }

    final AgentActionDefinition? action = AgentActionRegistry.get(actionId);

    if (action == null) {
      return AgentPermissionDecision.deny(
        roleId: role.roleId,
        actionId: actionId,
        reason: 'Unknown action. Permission Engine is default-deny.',
        effectiveMode: role.mode,
      );
    }

    if (action.permanentlyForbiddenForAi) {
      return AgentPermissionDecision.deny(
        roleId: role.roleId,
        actionId: actionId,
        reason: 'Action is permanently forbidden for AI.',
        effectiveMode: role.mode,
      );
    }

    // Module isolation: a role cannot silently operate another module.
    // Shared "core" actions are the only exception.
    if (action.module != 'core' && action.module != role.module) {
      // crash_agent may hand off to Code Agent through its own crash action;
      // it never directly evaluates code.* actions.
      return AgentPermissionDecision.deny(
        roleId: role.roleId,
        actionId: actionId,
        reason: 'Action module does not match role module.',
        effectiveMode: role.mode,
      );
    }

    if (role.forbiddenActions.contains(actionId)) {
      return AgentPermissionDecision.deny(
        roleId: role.roleId,
        actionId: actionId,
        reason: 'Action is explicitly forbidden for this role.',
        effectiveMode: role.mode,
      );
    }

    // DEFAULT-DENY: explicit allow entry is mandatory.
    if (!role.allowedActions.contains(actionId)) {
      return AgentPermissionDecision.deny(
        roleId: role.roleId,
        actionId: actionId,
        reason: 'Action is not explicitly present in allowedActions.',
        effectiveMode: role.mode,
      );
    }

    final bool requiresApproval =
        action.alwaysRequiresApproval ||
        role.approvalRequiredActions.contains(actionId) ||
        role.mode == AgentMode.askFirst;

    if (requiresApproval) {
      return AgentPermissionDecision.requireApproval(
        roleId: role.roleId,
        actionId: actionId,
        reason: action.alwaysRequiresApproval
            ? 'Action risk policy always requires approval.'
            : role.approvalRequiredActions.contains(actionId)
                ? 'Role policy requires approval for this action.'
                : 'Role mode is ASK_FIRST.',
        effectiveMode: role.mode,
      );
    }

    switch (role.mode) {
      case AgentMode.monitorOnly:
        if (!action.readOnly) {
          return AgentPermissionDecision.deny(
            roleId: role.roleId,
            actionId: actionId,
            reason: 'MONITOR_ONLY cannot execute write actions.',
            effectiveMode: role.mode,
          );
        }
        return AgentPermissionDecision.allow(
          roleId: role.roleId,
          actionId: actionId,
          reason: 'Read-only action allowed in MONITOR_ONLY.',
          effectiveMode: role.mode,
        );

      case AgentMode.suggestOnly:
        if (!action.readOnly && actionId != 'core.create_suggestion') {
          return AgentPermissionDecision.deny(
            roleId: role.roleId,
            actionId: actionId,
            reason: 'SUGGEST_ONLY cannot execute business write actions.',
            effectiveMode: role.mode,
          );
        }
        return AgentPermissionDecision.allow(
          roleId: role.roleId,
          actionId: actionId,
          reason: 'Action allowed in SUGGEST_ONLY without execution.',
          effectiveMode: role.mode,
        );

      case AgentMode.auto:
        return AgentPermissionDecision.allow(
          roleId: role.roleId,
          actionId: actionId,
          reason: 'Explicitly allowed action permitted in AUTO mode.',
          effectiveMode: role.mode,
        );

      case AgentMode.askFirst:
        // Already handled above, kept for defensive completeness.
        return AgentPermissionDecision.requireApproval(
          roleId: role.roleId,
          actionId: actionId,
          reason: 'ASK_FIRST requires approval.',
          effectiveMode: role.mode,
        );

      case AgentMode.off:
      default:
        return AgentPermissionDecision.deny(
          roleId: role.roleId,
          actionId: actionId,
          reason: 'OFF/unknown mode is denied.',
          effectiveMode: AgentMode.off,
        );
    }
  }
}

import '../constants/agent_enums.dart';
import '../constants/agent_production_rollout_runtime_guard_constants.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_production_rollout_runtime_guard.dart';
import '../models/agent_role.dart';
import 'agent_permission_engine.dart';
import 'agent_runtime_gate.dart';

class AgentProductionRolloutRuntimeMonitorOnlyOverlay {
  const AgentProductionRolloutRuntimeMonitorOnlyOverlay({
    this.permissionEngine = const AgentPermissionEngine(),
    this.runtimeGate = const AgentRuntimeGate(),
  });

  final AgentPermissionEngine permissionEngine;
  final AgentRuntimeGate runtimeGate;

  AgentPermissionDecision evaluate({
    required AgentProductionRolloutRuntimeGuard guard,
    required AgentMasterSettings settings,
    required AgentRole role,
    required String actionId,
  }) {
    try {
      guard.validate();
    } on FormatException {
      return _deny(
        role: role,
        actionId: actionId,
        reason: 'Production MONITOR_ONLY guard is invalid.',
      );
    }

    if (!guard.enabled) {
      return _deny(
        role: role,
        actionId: actionId,
        reason: 'Production rollout guard is disabled.',
      );
    }

    if (role.mode == AgentMode.off) {
      return _deny(
        role: role,
        actionId: actionId,
        reason: 'OFF role cannot be elevated by production overlay.',
      );
    }

    if (role.mode == AgentMode.askFirst) {
      return _deny(
        role: role,
        actionId: actionId,
        reason:
            'ASK_FIRST/high-risk role remains approval-bound and cannot execute during MONITOR_ONLY rollout.',
      );
    }

    if (AgentProductionRolloutExternalModule.blockedDuringInitialMonitorOnly
        .contains(role.module)) {
      return _deny(
        role: role,
        actionId: actionId,
        reason:
            'External channel is disabled during initial MONITOR_ONLY rollout.',
      );
    }

    final AgentRole monitorRole = role.copyWith(mode: AgentMode.monitorOnly);

    final AgentPermissionDecision permission = permissionEngine.evaluate(
      role: monitorRole,
      actionId: actionId,
    );

    if (permission.needsApproval) {
      return _deny(
        role: monitorRole,
        actionId: actionId,
        reason:
            'MONITOR_ONLY production overlay blocks approval-required execution.',
      );
    }

    final AgentPermissionDecision runtimeDecision = runtimeGate.apply(
      settings: settings,
      role: monitorRole,
      permissionDecision: permission,
    );

    if (runtimeDecision.isAllowed &&
        runtimeDecision.effectiveMode != AgentMode.monitorOnly) {
      return _deny(
        role: monitorRole,
        actionId: actionId,
        reason:
            'Production overlay refused a non-MONITOR_ONLY effective decision.',
      );
    }

    return runtimeDecision;
  }

  AgentPermissionDecision _deny({
    required AgentRole role,
    required String actionId,
    required String reason,
  }) {
    return AgentPermissionDecision.deny(
      roleId: role.roleId,
      actionId: actionId,
      reason: reason,
      effectiveMode: AgentMode.monitorOnly,
    );
  }

  bool get privilegeCeilingOnly => true;
  bool get rewritesPersistedRole => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get writesFirestore => false;
  bool get routesAutoTraffic => false;
  bool get executesBusinessWrite => false;
  bool get enablesExternalChannel => false;
}

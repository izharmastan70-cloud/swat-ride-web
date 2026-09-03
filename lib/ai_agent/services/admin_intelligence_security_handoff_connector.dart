import '../models/admin_intelligence_execution_handoff.dart';
import '../models/admin_intelligence_security_authorization.dart';
import '../models/agent_action_definition.dart';
import '../models/agent_approval_request.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import 'agent_action_registry.dart';
import 'agent_permission_engine.dart';
import 'agent_runtime_gate.dart';

/// Pure fail-closed connector between Phase 38 execution handoff and the
/// existing Permission Engine + Runtime Gate.
///
/// It verifies an approval snapshot when one is required, but deliberately
/// does NOT consume it. Approval consumption remains a one-time mutation at
/// the later execution boundary.
///
/// No Firestore access.
/// No audit write.
/// No provider execution.
/// No budget mutation.
class AdminIntelligenceSecurityHandoffConnector {
  const AdminIntelligenceSecurityHandoffConnector({
    this.permissionEngine = const AgentPermissionEngine(),
    this.runtimeGate = const AgentRuntimeGate(),
  });

  final AgentPermissionEngine permissionEngine;
  final AgentRuntimeGate runtimeGate;

  AdminIntelligenceSecurityAuthorization evaluate({
    required DateTime now,
    required AgentMasterSettings settings,
    required AgentRole role,
    required String actionId,
    required AdminIntelligenceExecutionHandoff handoff,
    AgentApprovalRequest? approvalSnapshot,
  }) {
    final String normalizedActionId = actionId.trim();

    final AgentActionDefinition? action = AgentActionRegistry.get(
      normalizedActionId,
    );

    final AgentPermissionDecision permissionDecision = permissionEngine
        .evaluate(role: role, actionId: normalizedActionId);

    final AgentPermissionDecision runtimeDecision = runtimeGate.apply(
      settings: settings,
      role: role,
      permissionDecision: permissionDecision,
    );

    final Map<String, dynamic> approvalScope = buildApprovalScope(
      handoff: handoff,
    );

    final bool actionKnown = action != null;

    final bool handoffValid = _isHandoffValid(now: now, handoff: handoff);

    if (!actionKnown) {
      return AdminIntelligenceSecurityAuthorization(
        permissionDecision: permissionDecision,
        runtimeDecision: runtimeDecision,
        actionKnown: false,
        handoffValid: handoffValid,
        approvalRequired: false,
        approvalSnapshotValid: false,
        approvalConsumptionRequired: false,
        authorizationReady: false,
        reason: 'admin_intelligence_action_unknown_fail_closed',
        approvalScope: approvalScope,
      );
    }

    if (!handoffValid) {
      return AdminIntelligenceSecurityAuthorization(
        permissionDecision: permissionDecision,
        runtimeDecision: runtimeDecision,
        actionKnown: true,
        handoffValid: false,
        approvalRequired: runtimeDecision.needsApproval,
        approvalSnapshotValid: false,
        approvalConsumptionRequired: false,
        authorizationReady: false,
        reason: 'admin_intelligence_handoff_invalid_or_expired',
        approvalScope: approvalScope,
      );
    }

    if (runtimeDecision.isDenied) {
      return AdminIntelligenceSecurityAuthorization(
        permissionDecision: permissionDecision,
        runtimeDecision: runtimeDecision,
        actionKnown: true,
        handoffValid: true,
        approvalRequired: false,
        approvalSnapshotValid: false,
        approvalConsumptionRequired: false,
        authorizationReady: false,
        reason: runtimeDecision.reason,
        approvalScope: approvalScope,
      );
    }

    if (runtimeDecision.needsApproval) {
      final bool approvalValid = _approvalSnapshotMatches(
        approval: approvalSnapshot,
        role: role,
        action: action,
        actionId: normalizedActionId,
        expectedScope: approvalScope,
      );

      if (!approvalValid) {
        return AdminIntelligenceSecurityAuthorization(
          permissionDecision: permissionDecision,
          runtimeDecision: runtimeDecision,
          actionKnown: true,
          handoffValid: true,
          approvalRequired: true,
          approvalSnapshotValid: false,
          approvalConsumptionRequired: false,
          authorizationReady: false,
          reason: 'admin_intelligence_exact_approval_required',
          approvalScope: approvalScope,
        );
      }

      return AdminIntelligenceSecurityAuthorization(
        permissionDecision: permissionDecision,
        runtimeDecision: runtimeDecision,
        actionKnown: true,
        handoffValid: true,
        approvalRequired: true,
        approvalSnapshotValid: true,
        approvalConsumptionRequired: true,
        authorizationReady: false,
        reason: 'admin_intelligence_approval_verified_consume_before_execution',
        approvalScope: approvalScope,
      );
    }

    if (!runtimeDecision.isAllowed) {
      return AdminIntelligenceSecurityAuthorization(
        permissionDecision: permissionDecision,
        runtimeDecision: runtimeDecision,
        actionKnown: true,
        handoffValid: true,
        approvalRequired: false,
        approvalSnapshotValid: false,
        approvalConsumptionRequired: false,
        authorizationReady: false,
        reason: 'admin_intelligence_unexpected_permission_state_fail_closed',
        approvalScope: approvalScope,
      );
    }

    return AdminIntelligenceSecurityAuthorization(
      permissionDecision: permissionDecision,
      runtimeDecision: runtimeDecision,
      actionKnown: true,
      handoffValid: true,
      approvalRequired: false,
      approvalSnapshotValid: false,
      approvalConsumptionRequired: false,
      authorizationReady: true,
      reason: 'admin_intelligence_security_handoff_ready',
      approvalScope: approvalScope,
    );
  }

  Map<String, dynamic> buildApprovalScope({
    required AdminIntelligenceExecutionHandoff handoff,
  }) {
    final Map<String, dynamic> scope = <String, dynamic>{
      'handoffId': handoff.handoffId,
      'taskId': handoff.taskId,
      'providerId': handoff.providerId,
      'routingLane': handoff.routingLane,
      'requiredCapability': handoff.requiredCapability,
      'estimatedCostRs': handoff.estimatedCostRs,
      'paidReasoning': handoff.paidReasoning,
      'expiresAt': handoff.expiresAt.toIso8601String(),
    };
    if (handoff.projectContext != null) {
      scope['projectContext'] = handoff.projectContext!.toAuthorizationScope();
    }
    return scope;
  }

  bool _isHandoffValid({
    required DateTime now,
    required AdminIntelligenceExecutionHandoff handoff,
  }) {
    if (handoff.handoffId.trim().isEmpty ||
        handoff.taskId.trim().isEmpty ||
        handoff.providerId.trim().isEmpty ||
        handoff.routingLane.trim().isEmpty ||
        handoff.requiredCapability.trim().isEmpty) {
      return false;
    }

    if (handoff.estimatedCostRs < 0) {
      return false;
    }

    if (!handoff.readOnlyPreparation ||
        !handoff.routingPlanReady ||
        handoff.blockedReason != null) {
      return false;
    }

    if (handoff.paidReasoning &&
        (!handoff.ownerApprovalSatisfied ||
            !handoff.budgetAllowed ||
            !handoff.providerCapacityAllowed)) {
      return false;
    }

    if (!now.isBefore(handoff.expiresAt)) {
      return false;
    }

    return true;
  }

  bool _approvalSnapshotMatches({
    required AgentApprovalRequest? approval,
    required AgentRole role,
    required AgentActionDefinition action,
    required String actionId,
    required Map<String, dynamic> expectedScope,
  }) {
    if (approval == null) {
      return false;
    }

    approval.validate();

    if (!approval.isApproved ||
        approval.isExpiredNow ||
        approval.isConsumed ||
        approval.consumedAt != null) {
      return false;
    }

    if (approval.roleId != role.roleId ||
        approval.actionId != actionId ||
        approval.module != action.module) {
      return false;
    }

    return _deepMapEquals(approval.actionScope, expectedScope);
  }

  bool _deepMapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) {
      return false;
    }

    for (final String key in a.keys) {
      if (!b.containsKey(key)) {
        return false;
      }

      if (!_deepEquals(a[key], b[key])) {
        return false;
      }
    }

    return true;
  }

  bool _deepEquals(dynamic a, dynamic b) {
    if (a is Map && b is Map) {
      final Map<String, dynamic> mapA = a.map(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );

      final Map<String, dynamic> mapB = b.map(
        (dynamic key, dynamic value) =>
            MapEntry<String, dynamic>(key.toString(), value),
      );

      return _deepMapEquals(mapA, mapB);
    }

    if (a is Iterable && b is Iterable) {
      final List<dynamic> listA = a.toList(growable: false);

      final List<dynamic> listB = b.toList(growable: false);

      if (listA.length != listB.length) {
        return false;
      }

      for (int index = 0; index < listA.length; index++) {
        if (!_deepEquals(listA[index], listB[index])) {
          return false;
        }
      }

      return true;
    }

    return a == b;
  }
}

import '../constants/agent_cross_agent_supervisor_conflict_constants.dart';

class AgentCrossAgentSupervisorWorkClaim {
  const AgentCrossAgentSupervisorWorkClaim({
    required this.claimId,
    required this.taskId,
    required this.agentId,
    required this.agentRoleId,
    required this.moduleId,
    required this.actionId,
    required this.targetResourceRef,
    required this.workFingerprint,
    required this.idempotencyKey,
    required this.intendedOutcome,
    required this.lifecycleStatus,
    required this.roleEligible,
    required this.moduleEligible,
    required this.scopeEligible,
    required this.authoritativeSecuritySatisfied,
  });

  final String claimId;
  final String taskId;
  final String agentId;
  final String agentRoleId;
  final String moduleId;
  final String actionId;
  final String targetResourceRef;
  final String workFingerprint;
  final String idempotencyKey;
  final String intendedOutcome;
  final String lifecycleStatus;

  /// These are authoritative/prevalidated metadata supplied to
  /// Supervisor. Step 1C does not calculate Permission/Approval.
  final bool roleEligible;
  final bool moduleEligible;
  final bool scopeEligible;
  final bool authoritativeSecuritySatisfied;

  bool get active =>
      lifecycleStatus == AgentCrossAgentWorkLifecycleStatus.active;

  bool get containsRawUserMessage => false;
  bool get containsRawConversation => false;
  bool get containsRawPrivatePayload => false;
  bool get containsRawApprovalToken => false;
  bool get containsRawPermissionToken => false;

  bool get supervisorComputedRoleAuthority => false;
  bool get supervisorComputedScopeAuthority => false;
  bool get supervisorComputedSecurityAuthority => false;

  bool get executesBusinessAction => false;
  bool get mutatesTask => false;
  bool get persistsClaim => false;

  void validateStructure() {
    final List<String> values = <String>[
      claimId,
      taskId,
      agentId,
      agentRoleId,
      moduleId,
      actionId,
      targetResourceRef,
      workFingerprint,
      idempotencyKey,
      intendedOutcome,
    ];

    final bool invalid = values.any((String value) {
      final String trimmed = value.trim();

      return trimmed.isEmpty ||
          trimmed.length >
              AgentCrossAgentSupervisorConflictLimits.opaqueIdMaxLength ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
    });

    if (invalid ||
        !AgentCrossAgentWorkLifecycleStatus.values.contains(lifecycleStatus)) {
      throw const FormatException('Invalid Cross-Agent Supervisor work claim.');
    }
  }
}

import '../constants/agent_cross_agent_supervisor_contract_constants.dart';

class AgentCrossAgentSupervisorSecuritySnapshot {
  const AgentCrossAgentSupervisorSecuritySnapshot({
    required this.permissionDecisionRef,
    required this.approvalDecisionRef,
    required this.runtimeGateDecisionRef,
    required this.guardianSecurityDecisionRef,
    required this.ownerSuperAdminControlRef,
    required this.masterAiControlRef,
    required this.emergencyStopDecisionRef,
    required this.costBudgetDecisionRef,
    required this.mandatoryAuditDecisionRef,
    required this.permissionSatisfied,
    required this.approvalSatisfied,
    required this.runtimeGateSatisfied,
    required this.guardianSecuritySatisfied,
    required this.ownerSuperAdminControlSatisfied,
    required this.masterAiControlSatisfied,
    required this.emergencyStopClear,
    required this.costBudgetSatisfied,
    required this.mandatoryAuditSatisfied,
    required this.restrictedAction,
    required this.ownerAdminAuthorityPresent,
  });

  final String permissionDecisionRef;
  final String approvalDecisionRef;
  final String runtimeGateDecisionRef;
  final String guardianSecurityDecisionRef;
  final String ownerSuperAdminControlRef;
  final String masterAiControlRef;
  final String emergencyStopDecisionRef;
  final String costBudgetDecisionRef;
  final String mandatoryAuditDecisionRef;

  /// Each "Satisfied" value means the authoritative security
  /// engine either passed the requirement or determined it
  /// was not applicable. Supervisor never computes that authority.
  final bool permissionSatisfied;
  final bool approvalSatisfied;
  final bool runtimeGateSatisfied;
  final bool guardianSecuritySatisfied;
  final bool ownerSuperAdminControlSatisfied;
  final bool masterAiControlSatisfied;
  final bool emergencyStopClear;
  final bool costBudgetSatisfied;
  final bool mandatoryAuditSatisfied;

  final bool restrictedAction;
  final bool ownerAdminAuthorityPresent;

  bool get allMandatorySecuritySatisfied =>
      permissionSatisfied &&
      approvalSatisfied &&
      runtimeGateSatisfied &&
      guardianSecuritySatisfied &&
      ownerSuperAdminControlSatisfied &&
      masterAiControlSatisfied &&
      emergencyStopClear &&
      costBudgetSatisfied &&
      mandatoryAuditSatisfied &&
      (!restrictedAction || ownerAdminAuthorityPresent);

  bool get containsRawPermissionToken => false;
  bool get containsRawApprovalToken => false;
  bool get containsAuthSecret => false;
  bool get containsPrivatePayload => false;

  bool get supervisorComputedPermission => false;
  bool get supervisorComputedApproval => false;
  bool get supervisorComputedRuntimeAuthority => false;
  bool get supervisorComputedGuardianAuthority => false;

  void validateStructure() {
    final List<String> refs = <String>[
      permissionDecisionRef,
      approvalDecisionRef,
      runtimeGateDecisionRef,
      guardianSecurityDecisionRef,
      ownerSuperAdminControlRef,
      masterAiControlRef,
      emergencyStopDecisionRef,
      costBudgetDecisionRef,
      mandatoryAuditDecisionRef,
    ];

    final bool invalidRef = refs.any((String value) {
      final String trimmed = value.trim();

      return trimmed.isEmpty ||
          trimmed.length >
              AgentCrossAgentSupervisorContractLimits.opaqueIdMaxLength ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
    });

    if (invalidRef) {
      throw const FormatException(
        'Invalid Cross-Agent Supervisor security snapshot.',
      );
    }
  }
}

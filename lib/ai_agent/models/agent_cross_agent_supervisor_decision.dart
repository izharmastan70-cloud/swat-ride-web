import '../constants/agent_cross_agent_supervisor_contract_constants.dart';

class AgentCrossAgentSupervisorDecision {
  AgentCrossAgentSupervisorDecision({
    required this.status,
    required this.requestId,
    required this.recommendHold,
    required this.recommendStop,
    required this.escalateOwnerAdmin,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String requestId;

  final bool recommendHold;
  final bool recommendStop;
  final bool escalateOwnerAdmin;

  final List<String> reasonCodes;

  bool get recommendationOnly => true;
  bool get authorizesExecution => false;
  bool get actualEnforcementPerformedHere => false;
  bool get securityAuthorityAlwaysAboveSupervisor => true;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get assignsPrivilegedRole => false;
  bool get executesBusinessAction => false;

  bool get bypassesPermissionEngine => false;
  bool get bypassesApprovalEngine => false;
  bool get bypassesRuntimeGate => false;
  bool get bypassesGuardianSecurity => false;
  bool get bypassesOwnerSuperAdminControls => false;
  bool get bypassesMasterAiControls => false;
  bool get bypassesEmergencyStopControls => false;
  bool get bypassesCostBudgetControls => false;
  bool get bypassesMandatoryAudit => false;

  bool get modifiesSecurityEngine => false;
  bool get mutatesRouting => false;
  bool get mutatesProviderState => false;
  bool get mutatesBudget => false;
  bool get changesSecret => false;
  bool get persistsDecision => false;

  void validateStructure() {
    if (!AgentCrossAgentSupervisorDecisionStatus.values.contains(status) ||
        requestId.trim().isEmpty ||
        reasonCodes.isEmpty ||
        reasonCodes.length >
            AgentCrossAgentSupervisorContractLimits.maxReasonCodes) {
      throw const FormatException('Invalid Cross-Agent Supervisor decision.');
    }

    final bool validShape = switch (status) {
      AgentCrossAgentSupervisorDecisionStatus.observeOnly =>
        !recommendHold && !recommendStop && !escalateOwnerAdmin,
      AgentCrossAgentSupervisorDecisionStatus.recommendHold =>
        recommendHold && !recommendStop && !escalateOwnerAdmin,
      AgentCrossAgentSupervisorDecisionStatus.recommendStop =>
        !recommendHold && recommendStop && !escalateOwnerAdmin,
      AgentCrossAgentSupervisorDecisionStatus.escalateOwnerAdmin =>
        !recommendHold && !recommendStop && escalateOwnerAdmin,
      AgentCrossAgentSupervisorDecisionStatus.recommendHoldAndEscalate =>
        recommendHold && !recommendStop && escalateOwnerAdmin,
      AgentCrossAgentSupervisorDecisionStatus.recommendStopAndEscalate =>
        !recommendHold && recommendStop && escalateOwnerAdmin,
      _ => false,
    };

    if (!validShape) {
      throw const FormatException(
        'Cross-Agent Supervisor decision status/flags mismatch.',
      );
    }
  }
}

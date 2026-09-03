import '../constants/agent_cross_agent_supervisor_closeout_constants.dart';

class AgentCrossAgentSupervisorReadinessReport {
  AgentCrossAgentSupervisorReadinessReport({
    required this.status,
    required this.foundationReady,
    required this.adversarialReady,
    required this.coreFailureIsolationReady,
    required List<String> failedScenarioIds,
    required List<String> reasonCodes,
  }) : failedScenarioIds = List<String>.unmodifiable(failedScenarioIds),
       reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final bool foundationReady;
  final bool adversarialReady;
  final bool coreFailureIsolationReady;
  final List<String> failedScenarioIds;
  final List<String> reasonCodes;

  bool get ready =>
      status ==
          AgentCrossAgentSupervisorCloseoutStatus.readyNotProductionActive &&
      foundationReady &&
      adversarialReady &&
      coreFailureIsolationReady &&
      failedScenarioIds.isEmpty;

  bool get foundationReadyNotProductionActive => ready;
  bool get productionActive => false;
  bool get productionActivationImplementedHere => false;

  bool get supervisorIsSuperAdmin => false;
  bool get securityAuthorityAlwaysAboveSupervisor => true;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get grantsAuthority => false;
  bool get expandsScope => false;
  bool get assignsPrivilegedRole => false;
  bool get authorizesBusinessExecution => false;
  bool get executesBusinessAction => false;

  bool get modifiesSecurityEngine => false;
  bool get bypassesSecurityEngine => false;
  bool get mutatesRouting => false;
  bool get mutatesTaskOwner => false;
  bool get mutatesQueue => false;
  bool get mutatesProviderState => false;
  bool get mutatesBudget => false;
  bool get deploysAnything => false;
  bool get persistsReport => false;

  void validateStructure() {
    if (!AgentCrossAgentSupervisorCloseoutStatus.values.contains(status) ||
        reasonCodes.isEmpty ||
        reasonCodes.length >
            AgentCrossAgentSupervisorCloseoutLimits.maxReasonCodes) {
      throw const FormatException(
        'Invalid Cross-Agent Supervisor readiness report.',
      );
    }

    if (ready && failedScenarioIds.isNotEmpty) {
      throw const FormatException(
        'Ready report cannot contain failed scenarios.',
      );
    }
  }
}

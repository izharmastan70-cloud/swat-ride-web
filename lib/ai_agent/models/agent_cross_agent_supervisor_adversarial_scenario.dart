import '../constants/agent_cross_agent_supervisor_closeout_constants.dart';

class AgentCrossAgentSupervisorAdversarialScenario {
  const AgentCrossAgentSupervisorAdversarialScenario({
    required this.scenarioId,
    required this.attempted,
    required this.failClosed,
    required this.securityAuthorityPreserved,
    required this.coreAppContinues,
  });

  final String scenarioId;
  final bool attempted;
  final bool failClosed;
  final bool securityAuthorityPreserved;
  final bool coreAppContinues;

  bool get passes =>
      !attempted ||
      (failClosed && securityAuthorityPreserved && coreAppContinues);

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get grantsAuthority => false;
  bool get authorizesBusinessExecution => false;
  bool get modifiesSecurityControl => false;
  bool get mutatesBudget => false;
  bool get activatesProvider => false;
  bool get persistsScenario => false;

  void validateStructure() {
    if (!AgentCrossAgentSupervisorAdversarialScenarioId.values.contains(
      scenarioId,
    )) {
      throw const FormatException(
        'Invalid Cross-Agent Supervisor adversarial scenario.',
      );
    }
  }
}

import '../constants/agent_cross_agent_supervisor_resilience_constants.dart';

class AgentCrossAgentSupervisorResilienceAssessment {
  AgentCrossAgentSupervisorResilienceAssessment({
    required this.status,
    required this.recommendHold,
    required this.recommendStop,
    required this.escalationRecommended,
    required this.aiCoordinationDegraded,
    required this.coreAppContinues,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final bool recommendHold;
  final bool recommendStop;
  final bool escalationRecommended;
  final bool aiCoordinationDegraded;
  final bool coreAppContinues;
  final List<String> reasonCodes;

  bool get clean => status == AgentCrossAgentSupervisorResilienceStatus.clean;

  bool get recommendationOnly => true;
  bool get securityAuthorityAlwaysAboveSupervisor => true;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get assignsPrivilegedRole => false;
  bool get authorizesBusinessExecution => false;
  bool get executesBusinessAction => false;

  bool get executesRollback => false;
  bool get switchesProvider => false;
  bool get mutatesQueue => false;
  bool get mutatesTaskOwner => false;
  bool get mutatesRouting => false;
  bool get mutatesBudget => false;
  bool get modifiesSecurityEngine => false;
  bool get persistsAssessment => false;

  void validateStructure() {
    if (!AgentCrossAgentSupervisorResilienceStatus.values.contains(status) ||
        reasonCodes.isEmpty ||
        reasonCodes.length >
            AgentCrossAgentSupervisorResilienceLimits.maxReasonCodes ||
        !coreAppContinues) {
      throw const FormatException(
        'Invalid Cross-Agent Supervisor resilience assessment.',
      );
    }

    if (clean &&
        (recommendHold ||
            recommendStop ||
            escalationRecommended ||
            aiCoordinationDegraded)) {
      throw const FormatException(
        'Clean resilience assessment cannot recommend action.',
      );
    }

    if (recommendStop && !escalationRecommended) {
      throw const FormatException('STOP recommendation requires escalation.');
    }
  }
}

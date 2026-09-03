import '../constants/agent_cross_agent_supervisor_contract_constants.dart';
import '../constants/agent_cross_agent_supervisor_conflict_constants.dart';
import 'agent_cross_agent_supervisor_conflict_finding.dart';

class AgentCrossAgentSupervisorConflictAssessment {
  AgentCrossAgentSupervisorConflictAssessment({
    required this.status,
    required List<AgentCrossAgentSupervisorConflictFinding> findings,
    required this.recommendHold,
    required this.recommendStop,
    required this.escalateOwnerAdmin,
    required List<String> reasonCodes,
  }) : findings = List<AgentCrossAgentSupervisorConflictFinding>.unmodifiable(
         findings,
       ),
       reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final List<AgentCrossAgentSupervisorConflictFinding> findings;

  final bool recommendHold;
  final bool recommendStop;
  final bool escalateOwnerAdmin;

  final List<String> reasonCodes;

  bool get clean => findings.isEmpty;

  bool get recommendationOnly => true;
  bool get securityAuthorityAlwaysAboveSupervisor => true;
  bool get taskOwnershipAssignedHere => false;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get assignsRole => false;
  bool get authorizesExecution => false;
  bool get executesBusinessAction => false;

  bool get modifiesSecurityEngine => false;
  bool get mutatesRouting => false;
  bool get mutatesTask => false;
  bool get mutatesTaskOwnership => false;
  bool get persistsAssessment => false;

  void validateStructure() {
    if (!AgentCrossAgentSupervisorDecisionStatus.values.contains(status) ||
        findings.length > AgentCrossAgentSupervisorConflictLimits.maxFindings ||
        reasonCodes.isEmpty ||
        reasonCodes.length >
            AgentCrossAgentSupervisorConflictLimits.maxReasonCodes) {
      throw const FormatException(
        'Invalid Cross-Agent Supervisor conflict assessment.',
      );
    }

    for (final AgentCrossAgentSupervisorConflictFinding finding in findings) {
      finding.validateStructure();
    }
  }
}

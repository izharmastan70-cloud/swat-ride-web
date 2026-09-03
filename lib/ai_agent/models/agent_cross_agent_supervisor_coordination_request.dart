import '../constants/agent_cross_agent_supervisor_coordination_constants.dart';
import 'agent_cross_agent_supervisor_conflict_assessment.dart';
import 'agent_cross_agent_supervisor_owner_candidate.dart';
import 'agent_cross_agent_supervisor_priority_context.dart';
import 'agent_cross_agent_supervisor_security_snapshot.dart';

class AgentCrossAgentSupervisorCoordinationRequest {
  AgentCrossAgentSupervisorCoordinationRequest({
    required this.requestId,
    required this.taskId,
    required this.moduleId,
    required this.actionId,
    required this.priorityContext,
    required this.securitySnapshot,
    required this.conflictAssessment,
    required List<AgentCrossAgentSupervisorOwnerCandidate> ownerCandidates,
  }) : ownerCandidates =
           List<AgentCrossAgentSupervisorOwnerCandidate>.unmodifiable(
             ownerCandidates,
           );

  final String requestId;
  final String taskId;
  final String moduleId;
  final String actionId;

  final AgentCrossAgentSupervisorPriorityContext priorityContext;
  final AgentCrossAgentSupervisorSecuritySnapshot securitySnapshot;
  final AgentCrossAgentSupervisorConflictAssessment conflictAssessment;

  final List<AgentCrossAgentSupervisorOwnerCandidate> ownerCandidates;

  bool get containsRawUserMessage => false;
  bool get containsRawConversation => false;
  bool get containsRawPrivatePayload => false;
  bool get containsRawApprovalToken => false;
  bool get containsRawPermissionToken => false;

  bool get requestsPermissionGrant => false;
  bool get requestsApprovalCreation => false;
  bool get requestsSecurityOverride => false;

  void validateStructure() {
    final List<String> values = <String>[requestId, taskId, moduleId, actionId];

    final bool invalid = values.any((String value) {
      final String trimmed = value.trim();

      return trimmed.isEmpty ||
          trimmed.length >
              AgentCrossAgentSupervisorCoordinationLimits.opaqueIdMaxLength ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
    });

    if (invalid ||
        ownerCandidates.isEmpty ||
        ownerCandidates.length >
            AgentCrossAgentSupervisorCoordinationLimits.maxOwnerCandidates) {
      throw const FormatException(
        'Invalid Cross-Agent Supervisor coordination request.',
      );
    }

    securitySnapshot.validateStructure();
    conflictAssessment.validateStructure();

    final Set<String> candidateIds = <String>{};

    for (final AgentCrossAgentSupervisorOwnerCandidate candidate
        in ownerCandidates) {
      candidate.validateStructure();

      if (!candidateIds.add(candidate.candidateId)) {
        throw const FormatException(
          'Duplicate Cross-Agent Supervisor owner candidate.',
        );
      }
    }
  }
}

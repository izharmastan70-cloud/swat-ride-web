import '../constants/agent_cross_agent_supervisor_resilience_constants.dart';
import 'agent_cross_agent_supervisor_handoff_hop.dart';

class AgentCrossAgentSupervisorResilienceInput {
  AgentCrossAgentSupervisorResilienceInput({
    required this.requestId,
    required this.taskId,
    required List<AgentCrossAgentSupervisorHandoffHop> handoffs,
    required this.retryCount,
    required this.repeatedFailureFingerprintCount,
    required this.ownershipFlipCount,
    required this.undoAttemptCount,
    required this.noProgressCycles,
    required this.providerAvailable,
    required this.supervisorHealthy,
    required this.authoritativeSecuritySatisfied,
  }) : handoffs = List<AgentCrossAgentSupervisorHandoffHop>.unmodifiable(
         handoffs,
       );

  final String requestId;
  final String taskId;
  final List<AgentCrossAgentSupervisorHandoffHop> handoffs;

  final int retryCount;
  final int repeatedFailureFingerprintCount;
  final int ownershipFlipCount;
  final int undoAttemptCount;
  final int noProgressCycles;

  final bool providerAvailable;
  final bool supervisorHealthy;
  final bool authoritativeSecuritySatisfied;

  bool get containsRawUserMessage => false;
  bool get containsRawConversation => false;
  bool get containsPrivatePayload => false;
  bool get containsProviderSecret => false;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get authorizesExecution => false;

  void validateStructure() {
    final List<String> values = <String>[requestId, taskId];

    final bool invalidId = values.any((String value) {
      final String trimmed = value.trim();

      return trimmed.isEmpty ||
          trimmed.length >
              AgentCrossAgentSupervisorResilienceLimits.opaqueIdMaxLength ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
    });

    if (invalidId ||
        handoffs.length >
            AgentCrossAgentSupervisorResilienceLimits.maxHandoffHops ||
        retryCount < 0 ||
        repeatedFailureFingerprintCount < 0 ||
        ownershipFlipCount < 0 ||
        undoAttemptCount < 0 ||
        noProgressCycles < 0) {
      throw const FormatException(
        'Invalid Cross-Agent Supervisor resilience input.',
      );
    }

    final Set<String> handoffIds = <String>{};
    int previousSequence = -1;

    for (final AgentCrossAgentSupervisorHandoffHop hop in handoffs) {
      hop.validateStructure();

      if (hop.taskId != taskId ||
          !handoffIds.add(hop.handoffId) ||
          hop.sequenceIndex <= previousSequence) {
        throw const FormatException(
          'Invalid Cross-Agent Supervisor handoff chain.',
        );
      }

      previousSequence = hop.sequenceIndex;
    }
  }
}

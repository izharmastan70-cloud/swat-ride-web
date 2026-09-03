import '../constants/agent_cross_agent_supervisor_resilience_constants.dart';

class AgentCrossAgentSupervisorHandoffHop {
  const AgentCrossAgentSupervisorHandoffHop({
    required this.handoffId,
    required this.taskId,
    required this.fromAgentId,
    required this.toAgentId,
    required this.sequenceIndex,
    required this.progressMarker,
    required this.failureFingerprint,
  });

  final String handoffId;
  final String taskId;
  final String fromAgentId;
  final String toAgentId;
  final int sequenceIndex;

  /// Opaque metadata only. No raw task payload is stored here.
  final String progressMarker;
  final String failureFingerprint;

  bool get metadataOnly => true;
  bool get containsRawUserMessage => false;
  bool get containsRawConversation => false;
  bool get containsPrivatePayload => false;
  bool get containsSecret => false;

  bool get executesHandoff => false;
  bool get mutatesTask => false;
  bool get mutatesOwner => false;
  bool get persistsHop => false;

  void validateStructure() {
    final List<String> values = <String>[
      handoffId,
      taskId,
      fromAgentId,
      toAgentId,
      progressMarker,
      failureFingerprint,
    ];

    final bool invalid = values.any((String value) {
      final String trimmed = value.trim();

      return trimmed.isEmpty ||
          trimmed.length >
              AgentCrossAgentSupervisorResilienceLimits.opaqueIdMaxLength ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
    });

    if (invalid || sequenceIndex < 0) {
      throw const FormatException(
        'Invalid Cross-Agent Supervisor handoff hop.',
      );
    }
  }
}

import 'agent_omnichannel_identity_privacy.dart';

class AgentOmnichannelReplayDisposition {
  AgentOmnichannelReplayDisposition._();

  static const String freshWithContinuity = 'FRESH_WITH_CONTINUITY';
  static const String freshWithoutContinuity = 'FRESH_WITHOUT_CONTINUITY';
  static const String blockedDuplicateExternalRef =
      'BLOCKED_DUPLICATE_EXTERNAL_REF';
  static const String blockedDuplicateEnvelope = 'BLOCKED_DUPLICATE_ENVELOPE';
  static const String blockedStaleReplay = 'BLOCKED_STALE_REPLAY';
  static const String blockedRouting = 'BLOCKED_ROUTING';
  static const String blockedContinuityMismatch = 'BLOCKED_CONTINUITY_MISMATCH';

  static const Set<String> values = <String>{
    freshWithContinuity,
    freshWithoutContinuity,
    blockedDuplicateExternalRef,
    blockedDuplicateEnvelope,
    blockedStaleReplay,
    blockedRouting,
    blockedContinuityMismatch,
  };
}

class AgentOmnichannelReplayWindow {
  AgentOmnichannelReplayWindow({
    required Iterable<String> seenExternalMessageRefs,
    required Iterable<String> seenEnvelopeIds,
    required this.notBefore,
  }) : seenExternalMessageRefs = Set<String>.unmodifiable(
         seenExternalMessageRefs,
       ),
       seenEnvelopeIds = Set<String>.unmodifiable(seenEnvelopeIds);

  final Set<String> seenExternalMessageRefs;
  final Set<String> seenEnvelopeIds;
  final DateTime notBefore;

  bool get persistedByThisContract => false;
  bool get writesReplayState => false;

  void validate() {
    if (seenExternalMessageRefs.any((String value) => value.trim().isEmpty) ||
        seenEnvelopeIds.any((String value) => value.trim().isEmpty)) {
      throw const AgentOmnichannelContractException(
        'Replay window cannot contain empty identifiers.',
      );
    }
  }
}

class AgentOmnichannelContinuityReplayAssessment {
  AgentOmnichannelContinuityReplayAssessment({
    required this.disposition,
    required this.routeMayProceed,
    required this.continuityAccepted,
    required this.replayDetected,
    required this.continuityRejected,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String disposition;
  final bool routeMayProceed;
  final bool continuityAccepted;
  final bool replayDetected;
  final bool continuityRejected;
  final List<String> reasonCodes;

  bool get grantsAuthority => false;
  bool get invokesOrchestrator => false;
  bool get invokesTargetAgent => false;
  bool get consumesApproval => false;
  bool get writesBusinessData => false;
  bool get loadsSharedCustomerContext => false;

  void validate() {
    if (!AgentOmnichannelReplayDisposition.values.contains(disposition) ||
        reasonCodes.isEmpty) {
      throw const AgentOmnichannelContractException(
        'Continuity/replay assessment is structurally invalid.',
      );
    }

    if (replayDetected && routeMayProceed) {
      throw const AgentOmnichannelContractException(
        'Replay-detected route must fail closed.',
      );
    }

    if (continuityAccepted && continuityRejected) {
      throw const AgentOmnichannelContractException(
        'Continuity cannot be both accepted and rejected.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'disposition': disposition,
      'routeMayProceed': routeMayProceed,
      'continuityAccepted': continuityAccepted,
      'replayDetected': replayDetected,
      'continuityRejected': continuityRejected,
      'reasonCodes': List<String>.unmodifiable(reasonCodes),
      'grantsAuthority': false,
      'invokesOrchestrator': false,
      'invokesTargetAgent': false,
      'consumesApproval': false,
      'writesBusinessData': false,
      'loadsSharedCustomerContext': false,
    });
  }
}

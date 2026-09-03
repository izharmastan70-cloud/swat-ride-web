import '../constants/agent_omnichannel_constants.dart';

class AgentUnifiedContextContinuityEvidence {
  AgentUnifiedContextContinuityEvidence({
    required this.evidenceId,
    required this.previousChannel,
    required this.currentChannel,
    required this.samePseudonymousSubject,
    required this.trustedIdentityContinuity,
    required this.withinContinuityWindow,
    required this.replayAssessmentPassed,
    required this.phase51ContinuityMetadataOnly,
    required this.phase51CarriesMessageHistory,
    required this.phase51CarriesSharedCustomerContext,
    required this.emergencySafeTriageOnly,
    required this.hopCount,
  });

  final String evidenceId;
  final String previousChannel;
  final String currentChannel;

  /// These booleans must be produced by the Phase 51 identity/continuity/replay
  /// boundary. They are evidence only and never action authority.
  final bool samePseudonymousSubject;
  final bool trustedIdentityContinuity;
  final bool withinContinuityWindow;
  final bool replayAssessmentPassed;
  final bool phase51ContinuityMetadataOnly;
  final bool phase51CarriesMessageHistory;
  final bool phase51CarriesSharedCustomerContext;
  final bool emergencySafeTriageOnly;
  final int hopCount;

  bool get isCrossChannel => previousChannel != currentChannel;

  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsEvidence => false;

  void validateStructure() {
    if (evidenceId.trim().isEmpty) {
      throw const AgentUnifiedContextContinuityEvidenceException(
        'Continuity evidence id is required.',
      );
    }

    if (!AgentOmnichannelChannel.values.contains(previousChannel) ||
        !AgentOmnichannelChannel.values.contains(currentChannel)) {
      throw const AgentUnifiedContextContinuityEvidenceException(
        'Continuity evidence channel is invalid.',
      );
    }

    if (hopCount < 0 || hopCount > 8) {
      throw const AgentUnifiedContextContinuityEvidenceException(
        'Continuity evidence hop count is outside the safe boundary.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'evidenceId': evidenceId,
      'previousChannel': previousChannel,
      'currentChannel': currentChannel,
      'isCrossChannel': isCrossChannel,
      'samePseudonymousSubject': samePseudonymousSubject,
      'trustedIdentityContinuity': trustedIdentityContinuity,
      'withinContinuityWindow': withinContinuityWindow,
      'replayAssessmentPassed': replayAssessmentPassed,
      'phase51ContinuityMetadataOnly': phase51ContinuityMetadataOnly,
      'phase51CarriesMessageHistory': phase51CarriesMessageHistory,
      'phase51CarriesSharedCustomerContext':
          phase51CarriesSharedCustomerContext,
      'emergencySafeTriageOnly': emergencySafeTriageOnly,
      'hopCount': hopCount,
      'grantsAuthority': false,
      'grantsPermission': false,
      'consumesApproval': false,
      'invokesProvider': false,
      'invokesTargetAgent': false,
      'writesBusinessData': false,
      'persistsEvidence': false,
    });
  }
}

class AgentUnifiedContextContinuityEvidenceException implements Exception {
  const AgentUnifiedContextContinuityEvidenceException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentUnifiedContextContinuityEvidenceException: $message';
}

import 'agent_conversation_quality_decision.dart';

/// One read-only source signal used by the grounding assessor.
class AgentConversationGroundingSource {
  const AgentConversationGroundingSource({
    required this.evidence,
    required this.fresh,
    required this.supportsClaim,
    required this.contradictsClaim,
  });

  final AgentConversationEvidenceRef evidence;
  final bool fresh;
  final bool supportsClaim;
  final bool contradictsClaim;

  void validate() {
    evidence.validate();

    if (supportsClaim && contradictsClaim) {
      throw const AgentConversationGroundingException(
        'One source cannot both support and contradict the same claim.',
      );
    }
  }
}

/// Deterministic read-only grounding assessment.
///
/// This describes whether available evidence is sufficient to support a
/// response. It cannot fetch new evidence or execute the response.
class AgentConversationGroundingAssessment {
  const AgentConversationGroundingAssessment({
    required this.knowledgeState,
    required this.confidence,
    required this.sourceCount,
    required this.verifiedSourceCount,
    required this.freshVerifiedSourceCount,
    required this.supportingVerifiedSourceCount,
    required this.contradictionCount,
    required this.requiredVerifiedSourceCount,
    required this.freshnessRequired,
    required this.requiresVerification,
    required this.mustDiscloseUncertainty,
    required this.evidenceRefs,
  });

  final String knowledgeState;
  final double confidence;

  final int sourceCount;
  final int verifiedSourceCount;
  final int freshVerifiedSourceCount;
  final int supportingVerifiedSourceCount;
  final int contradictionCount;
  final int requiredVerifiedSourceCount;

  final bool freshnessRequired;
  final bool requiresVerification;
  final bool mustDiscloseUncertainty;

  final List<AgentConversationEvidenceRef> evidenceRefs;

  bool get isSufficient =>
      knowledgeState == 'SUFFICIENT' &&
      !requiresVerification &&
      contradictionCount == 0;

  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayCallProvider => false;
  bool get mayChangePrompt => false;
  bool get mayTrainModel => false;
  bool get mayDeploy => false;

  void validate() {
    if (confidence < 0 || confidence > 1) {
      throw const AgentConversationGroundingException(
        'Grounding confidence must be between 0.0 and 1.0.',
      );
    }

    for (final int value in <int>[
      sourceCount,
      verifiedSourceCount,
      freshVerifiedSourceCount,
      supportingVerifiedSourceCount,
      contradictionCount,
      requiredVerifiedSourceCount,
    ]) {
      if (value < 0) {
        throw const AgentConversationGroundingException(
          'Grounding counters cannot be negative.',
        );
      }
    }

    if (requiredVerifiedSourceCount < 1) {
      throw const AgentConversationGroundingException(
        'At least one verified source must be required.',
      );
    }

    if (verifiedSourceCount > sourceCount ||
        freshVerifiedSourceCount > verifiedSourceCount ||
        supportingVerifiedSourceCount > verifiedSourceCount ||
        contradictionCount > sourceCount) {
      throw const AgentConversationGroundingException(
        'Grounding counters are internally inconsistent.',
      );
    }

    if (isSufficient) {
      if (supportingVerifiedSourceCount < requiredVerifiedSourceCount) {
        throw const AgentConversationGroundingException(
          'SUFFICIENT grounding must meet required verified source count.',
        );
      }

      if (freshnessRequired &&
          freshVerifiedSourceCount < requiredVerifiedSourceCount) {
        throw const AgentConversationGroundingException(
          'SUFFICIENT grounding must meet fresh verified source count.',
        );
      }
    }
  }
}

class AgentConversationGroundingException implements Exception {
  const AgentConversationGroundingException(this.message);

  final String message;

  @override
  String toString() => 'AgentConversationGroundingException: $message';
}

import '../constants/agent_provider_quality_evidence_constants.dart';
import 'agent_provider_quality_evidence.dart';

class AgentProviderQualityEvidenceBatch {
  AgentProviderQualityEvidenceBatch({
    required List<AgentProviderQualityEvidence> evidence,
  }) : evidence = List<AgentProviderQualityEvidence>.unmodifiable(evidence);

  final List<AgentProviderQualityEvidence> evidence;

  String get providerId => evidence.first.providerId;
  String get modelReference => evidence.first.modelReference;
  String get providerTier => evidence.first.providerTier;
  String get taskType => evidence.first.taskType;
  String get family => evidence.first.family;

  bool get sameBinding => evidence.every(
    (AgentProviderQualityEvidence value) =>
        value.providerId == providerId &&
        value.modelReference == modelReference &&
        value.providerTier == providerTier &&
        value.taskType == taskType &&
        value.family == family,
  );

  bool get hasDuplicateObservationId {
    final Set<String> seen = <String>{};

    for (final AgentProviderQualityEvidence value in evidence) {
      if (!seen.add(value.observationId)) {
        return true;
      }
    }

    return false;
  }

  bool get hasDuplicateIdempotencyKey {
    final Set<String> seen = <String>{};

    for (final AgentProviderQualityEvidence value in evidence) {
      if (!seen.add(value.idempotencyKey)) {
        return true;
      }
    }

    return false;
  }

  bool get containsHardSafetyViolation => evidence.any(
    (AgentProviderQualityEvidence value) => value.hardSafetyViolation,
  );

  void validateStructure() {
    if (evidence.isEmpty ||
        evidence.length >
            AgentProviderQualityEvidencePolicyConfig.maxEvidencePerBatch ||
        !sameBinding ||
        hasDuplicateObservationId ||
        hasDuplicateIdempotencyKey) {
      throw const FormatException('Invalid provider quality evidence batch.');
    }

    for (final AgentProviderQualityEvidence value in evidence) {
      value.validateStructure();
    }
  }
}

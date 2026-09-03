import '../constants/agent_provider_quality_evidence_constants.dart';
import '../models/agent_provider_quality_evidence.dart';
import '../models/agent_provider_quality_evidence_batch.dart';

class AgentProviderQualityEvidenceProvenancePolicy {
  const AgentProviderQualityEvidenceProvenancePolicy();

  String evaluateEvidence(AgentProviderQualityEvidence evidence) {
    try {
      evidence.validateStructure();
    } catch (_) {
      return AgentProviderQualityEvidenceStatus.rejectedInvalidProvenance;
    }

    if (!evidence.trustedObservation) {
      return AgentProviderQualityEvidenceStatus.rejectedUntrusted;
    }

    if (!evidence.privacySafeMetadata) {
      return AgentProviderQualityEvidenceStatus.rejectedPrivacyUnsafe;
    }

    return AgentProviderQualityEvidenceStatus.accepted;
  }

  bool batchPassesDeduplication(AgentProviderQualityEvidenceBatch batch) {
    if (batch.evidence.isEmpty) {
      return false;
    }

    return !batch.hasDuplicateObservationId &&
        !batch.hasDuplicateIdempotencyKey;
  }

  bool get opaqueProvenanceRequired => true;
  bool get evaluatorVersionReferenceRequired => true;
  bool get idempotencyKeyRequired => true;
  bool get duplicateObservationRejected => true;
  bool get duplicateIdempotencyRejected => true;
  bool get trustedObservationRequired => true;
  bool get privacySafeMetadataRequired => true;

  bool get rawPromptForbidden => true;
  bool get rawConversationForbidden => true;
  bool get rawProviderResponseForbidden => true;
  bool get privatePayloadForbidden => true;

  bool get providerInvocationImplementedHere => false;
  bool get routingMutationImplementedHere => false;
  bool get providerStateMutationImplementedHere => false;
  bool get budgetMutationImplementedHere => false;
  bool get persistenceImplementedHere => false;
  bool get executesBusinessAction => false;
}

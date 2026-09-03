import '../constants/agent_provider_expansion_contract_constants.dart';
import '../constants/agent_provider_quality_evidence_constants.dart';
import '../constants/agent_provider_quality_signal_constants.dart';

class AgentProviderQualityEvidence {
  const AgentProviderQualityEvidence({
    required this.observationId,
    required this.idempotencyKey,
    required this.provenanceReference,
    required this.evaluatorVersionReference,
    required this.providerId,
    required this.modelReference,
    required this.providerTier,
    required this.taskType,
    required this.family,
    required this.source,
    required this.normalizedScore,
    required this.ageHours,
    required this.trustedObservation,
    required this.privacySafeMetadata,
    required this.hardSafetyViolation,
  });

  final String observationId;
  final String idempotencyKey;
  final String provenanceReference;
  final String evaluatorVersionReference;

  final String providerId;
  final String modelReference;
  final String providerTier;
  final String taskType;
  final String family;
  final String source;

  final double normalizedScore;
  final int ageHours;

  final bool trustedObservation;
  final bool privacySafeMetadata;
  final bool hardSafetyViolation;

  bool get containsRawPrompt => false;
  bool get containsRawConversation => false;
  bool get containsRawProviderResponse => false;
  bool get containsPrivatePayload => false;
  bool get containsApiSecret => false;
  bool get containsAuthToken => false;

  bool get invokesProvider => false;
  bool get mutatesRouting => false;
  bool get changesProviderState => false;
  bool get mutatesBudget => false;
  bool get changesSecret => false;
  bool get deploysModel => false;
  bool get persistsEvidence => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;

  void validateStructure() {
    if (!_validOpaque(observationId) ||
        !_validOpaque(idempotencyKey) ||
        !_validOpaque(provenanceReference) ||
        !_validOpaque(evaluatorVersionReference) ||
        !_validOpaque(providerId) ||
        !_validOpaque(modelReference) ||
        taskType.trim().isEmpty ||
        !AgentProviderExpansionTier.values.contains(providerTier) ||
        !AgentProviderQualitySignalFamily.values.contains(family) ||
        !AgentProviderQualitySignalSource.values.contains(source) ||
        !normalizedScore.isFinite ||
        normalizedScore < 0 ||
        normalizedScore > 100 ||
        ageHours < 0) {
      throw const FormatException('Invalid provider quality evidence.');
    }
  }

  bool _validOpaque(String value) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <=
            AgentProviderQualityEvidencePolicyConfig.maxOpaqueRefLength &&
        RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
  }
}

import '../constants/agent_provider_expansion_contract_constants.dart';
import '../constants/agent_provider_quality_signal_constants.dart';

class AgentProviderQualitySignal {
  const AgentProviderQualitySignal({
    required this.signalId,
    required this.providerId,
    required this.modelReference,
    required this.providerTier,
    required this.taskType,
    required this.family,
    required this.source,
    required this.normalizedScore,
    required this.sampleCount,
    required this.ageHours,
    required this.trustedObservation,
    required this.privacySafeMetadata,
    required this.hardSafetyViolation,
    required this.capabilityEligible,
    required this.privacyEligible,
  });

  final String signalId;
  final String providerId;
  final String modelReference;
  final String providerTier;
  final String taskType;
  final String family;
  final String source;

  /// Metadata score only, normalized 0..100.
  final double normalizedScore;

  final int sampleCount;
  final int ageHours;

  final bool trustedObservation;
  final bool privacySafeMetadata;
  final bool hardSafetyViolation;
  final bool capabilityEligible;
  final bool privacyEligible;

  bool get containsRawPrompt => false;
  bool get containsRawConversation => false;
  bool get containsRawProviderResponse => false;
  bool get containsPrivatePayload => false;
  bool get containsApiSecret => false;
  bool get containsAuthToken => false;

  bool get invokesProvider => false;
  bool get changesProviderEnabledState => false;
  bool get changesBudget => false;
  bool get changesSecret => false;
  bool get deploysModel => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get persistsSignal => false;

  void validateStructure() {
    if (!_validId(signalId) ||
        !_validId(providerId) ||
        modelReference.trim().isEmpty ||
        modelReference.length > AgentProviderQualityLimits.idMax ||
        taskType.trim().isEmpty ||
        !AgentProviderExpansionTier.values.contains(providerTier) ||
        !AgentProviderQualitySignalFamily.values.contains(family) ||
        !AgentProviderQualitySignalSource.values.contains(source) ||
        !normalizedScore.isFinite ||
        normalizedScore < AgentProviderQualityLimits.minScore ||
        normalizedScore > AgentProviderQualityLimits.maxScore ||
        sampleCount < 0 ||
        ageHours < 0) {
      throw const FormatException('Invalid provider quality signal.');
    }
  }

  bool _validId(String value) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <= AgentProviderQualityLimits.idMax &&
        RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
  }
}

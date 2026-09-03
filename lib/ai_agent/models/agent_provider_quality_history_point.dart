import '../constants/agent_provider_expansion_contract_constants.dart';
import '../constants/agent_provider_quality_aggregation_constants.dart';
import '../constants/agent_provider_quality_signal_constants.dart';

class AgentProviderQualityHistoryPoint {
  const AgentProviderQualityHistoryPoint({
    required this.observationId,
    required this.providerId,
    required this.modelReference,
    required this.providerTier,
    required this.taskType,
    required this.observedAtEpochHour,
    required this.weightedScore,
    required this.safetyScore,
    required this.recommendation,
    required this.confidenceLevel,
    required this.hardGateClean,
  });

  final String observationId;
  final String providerId;
  final String modelReference;
  final String providerTier;
  final String taskType;
  final int observedAtEpochHour;
  final double weightedScore;
  final double safetyScore;
  final String recommendation;
  final String confidenceLevel;
  final bool hardGateClean;

  bool get containsRawPrompt => false;
  bool get containsRawConversation => false;
  bool get containsRawProviderResponse => false;
  bool get containsPrivatePayload => false;
  bool get containsSecret => false;

  bool get invokesProvider => false;
  bool get mutatesRouting => false;
  bool get mutatesBudget => false;
  bool get changesProviderState => false;
  bool get persistsPoint => false;
  bool get executesBusinessAction => false;

  void validateStructure() {
    if (!_validId(observationId) ||
        !_validId(providerId) ||
        modelReference.trim().isEmpty ||
        modelReference.length > 220 ||
        taskType.trim().isEmpty ||
        !AgentProviderExpansionTier.values.contains(providerTier) ||
        observedAtEpochHour < 0 ||
        !weightedScore.isFinite ||
        weightedScore < 0 ||
        weightedScore > 100 ||
        !safetyScore.isFinite ||
        safetyScore < 0 ||
        safetyScore > 100 ||
        !AgentProviderQualityRecommendation.values.contains(recommendation) ||
        !AgentProviderQualityConfidenceLevel.values.contains(confidenceLevel)) {
      throw const FormatException('Invalid provider quality history point.');
    }
  }

  bool _validId(String value) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <= 220 &&
        RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
  }
}

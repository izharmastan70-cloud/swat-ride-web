import '../constants/agent_provider_quality_signal_constants.dart';

class AgentProviderQualityScoreBoundary {
  const AgentProviderQualityScoreBoundary({
    required this.recommendation,
    required this.score,
    required this.sampleSufficiency,
    required this.freshness,
    required this.qualityEligible,
  });

  final String recommendation;
  final double score;
  final String sampleSufficiency;
  final String freshness;
  final bool qualityEligible;

  bool get recommendationOnly => true;

  bool get mayOverrideProviderTierOrder => false;
  bool get mayOverridePaidAiOnOff => false;
  bool get mayOverrideAskBeforePaid => false;
  bool get mayOverrideBudgetLimit => false;
  bool get mayOverridePrivacyGate => false;
  bool get mayOverrideCapabilityGate => false;
  bool get mayOverrideCircuitBreaker => false;
  bool get mayOverrideBackendBoundary => false;

  bool get mayEnableProvider => false;
  bool get mayDisableProvider => false;
  bool get mayChangeSecret => false;
  bool get mayDeployModel => false;
  bool get mayInvokeProvider => false;
  bool get mayExecuteBusinessAction => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayMutateBudget => false;

  void validateStructure() {
    if (!AgentProviderQualityRecommendation.values.contains(recommendation) ||
        !AgentProviderQualitySampleSufficiency.values.contains(
          sampleSufficiency,
        ) ||
        !AgentProviderQualityFreshness.values.contains(freshness) ||
        !score.isFinite ||
        score < AgentProviderQualityLimits.minScore ||
        score > AgentProviderQualityLimits.maxScore) {
      throw const FormatException('Invalid provider quality score boundary.');
    }
  }
}

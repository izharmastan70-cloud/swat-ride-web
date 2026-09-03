import '../constants/agent_provider_quality_aggregation_constants.dart';
import '../constants/agent_provider_quality_signal_constants.dart';
import 'agent_provider_quality_confidence.dart';

class AgentProviderQualityProviderRecommendation {
  AgentProviderQualityProviderRecommendation({
    required this.providerId,
    required this.modelReference,
    required this.providerTier,
    required this.taskType,
    required this.recommendation,
    required this.weightedScore,
    required this.confidence,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String providerId;
  final String modelReference;
  final String providerTier;
  final String taskType;
  final String recommendation;
  final double weightedScore;
  final AgentProviderQualityConfidence confidence;
  final List<String> reasonCodes;

  bool get recommendationOnly => true;

  bool get mayOverrideProviderTierOrder => false;
  bool get mayOverridePaidAiOnOff => false;
  bool get mayOverrideAskBeforePaid => false;
  bool get mayOverrideBudgetLimit => false;
  bool get mayOverridePrivacyGate => false;
  bool get mayOverrideCapabilityGate => false;
  bool get mayOverrideCircuitBreaker => false;
  bool get mayOverrideBackendBoundary => false;

  bool get mayInvokeProvider => false;
  bool get mayEnableProvider => false;
  bool get mayDisableProvider => false;
  bool get mayChangeSecret => false;
  bool get mayDeployModel => false;
  bool get mayMutateBudget => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayExecuteBusinessAction => false;
  bool get persistsRecommendation => false;

  void validateStructure() {
    confidence.validateStructure();

    if (providerId.trim().isEmpty ||
        modelReference.trim().isEmpty ||
        providerTier.trim().isEmpty ||
        taskType.trim().isEmpty ||
        !AgentProviderQualityRecommendation.values.contains(recommendation) ||
        !weightedScore.isFinite ||
        weightedScore < 0 ||
        weightedScore > 100 ||
        reasonCodes.isEmpty ||
        reasonCodes.length >
            AgentProviderQualityAggregationPolicyConfig.maxReasonCodes) {
      throw const FormatException('Invalid provider quality recommendation.');
    }
  }
}

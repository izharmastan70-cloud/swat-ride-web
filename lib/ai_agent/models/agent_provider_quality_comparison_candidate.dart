import '../constants/agent_provider_expansion_contract_constants.dart';
import '../constants/agent_provider_quality_signal_constants.dart';
import 'agent_provider_quality_provider_recommendation.dart';

class AgentProviderQualityComparisonCandidate {
  const AgentProviderQualityComparisonCandidate({
    required this.recommendation,
    required this.routingEligible,
    required this.privacyEligible,
    required this.capabilityEligible,
    required this.backendEligible,
    required this.paidControlsEligible,
    required this.estimatedProviderCostRs,
  });

  final AgentProviderQualityProviderRecommendation recommendation;

  final bool routingEligible;
  final bool privacyEligible;
  final bool capabilityEligible;
  final bool backendEligible;
  final bool paidControlsEligible;

  /// Provider billable estimate metadata only.
  final double estimatedProviderCostRs;

  String get providerId => recommendation.providerId;
  String get modelReference => recommendation.modelReference;
  String get providerTier => recommendation.providerTier;
  String get taskType => recommendation.taskType;

  bool get paidTier =>
      providerTier == AgentProviderExpansionTier.paidLastEscalation;

  bool get recommendationEligible =>
      recommendation.recommendation !=
          AgentProviderQualityRecommendation.ineligible &&
      recommendation.recommendation !=
          AgentProviderQualityRecommendation.insufficientEvidence;

  bool get hardEligible =>
      routingEligible &&
      privacyEligible &&
      capabilityEligible &&
      backendEligible &&
      paidControlsEligible &&
      recommendationEligible;

  bool get containsRawPrompt => false;
  bool get containsRawConversation => false;
  bool get containsRawProviderResponse => false;
  bool get containsPrivatePayload => false;
  bool get invokesProvider => false;
  bool get mutatesRouting => false;
  bool get mutatesBudget => false;
  bool get changesProviderState => false;
  bool get persistsCandidate => false;
  bool get executesBusinessAction => false;

  void validateStructure() {
    recommendation.validateStructure();

    if (!estimatedProviderCostRs.isFinite || estimatedProviderCostRs < 0) {
      throw const FormatException(
        'Invalid provider quality comparison candidate.',
      );
    }

    if (!paidTier && estimatedProviderCostRs != 0) {
      throw const FormatException(
        'Free/local provider billable cost must be zero.',
      );
    }
  }
}

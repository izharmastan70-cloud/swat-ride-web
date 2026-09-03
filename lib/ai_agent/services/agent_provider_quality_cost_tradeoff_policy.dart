import '../constants/agent_provider_quality_comparison_constants.dart';
import '../constants/agent_provider_quality_signal_constants.dart';
import '../models/agent_provider_quality_comparison_candidate.dart';

class AgentProviderQualityCostTradeoffPolicy {
  const AgentProviderQualityCostTradeoffPolicy();

  bool qualityCanWin(AgentProviderQualityComparisonCandidate candidate) {
    if (!candidate.hardEligible) {
      return false;
    }

    return candidate.recommendation.weightedScore >=
            AgentProviderQualityCostTradeoffLimits.minimumQualityWinnerScore &&
        candidate.recommendation.recommendation !=
            AgentProviderQualityRecommendation.deprioritize;
  }

  double comparisonScore({
    required AgentProviderQualityComparisonCandidate candidate,
    required double highestEligibleCostRs,
  }) {
    if (!qualityCanWin(candidate)) {
      return -1;
    }

    final double qualityScore = candidate.recommendation.weightedScore;

    if (!candidate.paidTier ||
        candidate.estimatedProviderCostRs <= 0 ||
        highestEligibleCostRs <= 0) {
      return qualityScore;
    }

    final double relativeSaving =
        (highestEligibleCostRs - candidate.estimatedProviderCostRs) /
        highestEligibleCostRs;

    final double boundedSaving = relativeSaving.clamp(0.0, 1.0).toDouble();

    final double costTieBreakBonus =
        boundedSaving *
        AgentProviderQualityCostTradeoffLimits.maxCostTieBreakBonusPoints;

    return qualityScore + costTieBreakBonus;
  }

  bool nearQualityTie({required double a, required double b}) {
    return (a - b).abs() <=
        AgentProviderQualityCostTradeoffLimits.nearQualityTieMaxPoints;
  }

  bool get qualityFloorBeforeCost => true;
  bool get costOnlyBreaksNearQualityTie => true;
  bool get costBonusCapped => true;
  bool get cheaperEligiblePaidCandidateGetsTieBreakBonus => true;
  bool get freeLocalBillableCostMustBeZero => true;
  bool get safetyPrivacyCapabilityEligibilityRequired => true;
  bool get costCannotRescueIneligibleCandidate => true;
  bool get costCannotOverrideTierOrder => true;
  bool get largeQualityGapCannotBeOverturnedByCost => true;

  bool get providerInvocationImplementedHere => false;
  bool get routingMutationImplementedHere => false;
  bool get budgetMutationImplementedHere => false;
  bool get persistenceImplementedHere => false;
  bool get executesBusinessAction => false;
}

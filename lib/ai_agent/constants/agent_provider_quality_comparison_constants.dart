class AgentProviderQualityComparisonStatus {
  AgentProviderQualityComparisonStatus._();

  static const String preferredWithinTier = 'PREFERRED_WITHIN_TIER';
  static const String neutralWithinTier = 'NEUTRAL_WITHIN_TIER';
  static const String insufficientEvidence = 'INSUFFICIENT_EVIDENCE';
  static const String noEligibleCandidate = 'NO_ELIGIBLE_CANDIDATE';
  static const String blockedInvalidComparison = 'BLOCKED_INVALID_COMPARISON';
  static const String blockedCrossTierComparison =
      'BLOCKED_CROSS_TIER_COMPARISON';

  static const Set<String> values = <String>{
    preferredWithinTier,
    neutralWithinTier,
    insufficientEvidence,
    noEligibleCandidate,
    blockedInvalidComparison,
    blockedCrossTierComparison,
  };
}

class AgentProviderQualityCostTradeoffLimits {
  AgentProviderQualityCostTradeoffLimits._();

  /// Cost may only break a near-quality tie.
  static const double nearQualityTieMaxPoints = 3.0;

  /// A candidate below this quality score cannot win on cost.
  static const double minimumQualityWinnerScore = 60.0;

  /// Cost adjustment is deliberately capped.
  static const double maxCostTieBreakBonusPoints = 2.0;

  static const int maxCandidates = 12;
  static const int maxReasonCodes = 20;
}

import '../constants/agent_performance_scoring_constants.dart';
import '../models/agent_performance_comparison_request.dart';
import '../models/agent_performance_comparison_result.dart';

class AgentPerformanceFairComparisonPolicy {
  const AgentPerformanceFairComparisonPolicy();

  AgentPerformanceComparisonResult compare(
    AgentPerformanceComparisonRequest request,
  ) {
    try {
      request.validateStructure();
    } catch (_) {
      return _incomparable(
        status: AgentPerformanceComparisonStatus.blockedInvalidInput,
        request: request,
        reason: 'invalid_comparison_request',
      );
    }

    if (!request.first.comparisonEligible ||
        !request.second.comparisonEligible ||
        request.first.confidence != AgentPerformanceScoreConfidence.high ||
        request.second.confidence != AgentPerformanceScoreConfidence.high) {
      return _incomparable(
        status: AgentPerformanceComparisonStatus.incomparableLowConfidence,
        request: request,
        reason: 'both_agents_require_high_confidence',
      );
    }

    if (request.first.cohortKey != request.second.cohortKey) {
      return _incomparable(
        status: AgentPerformanceComparisonStatus.incomparableDifferentCohort,
        request: request,
        reason: 'different_comparable_cohort',
      );
    }

    if (request.first.windowId != request.second.windowId) {
      return _incomparable(
        status: AgentPerformanceComparisonStatus.incomparableDifferentWindow,
        request: request,
        reason: 'different_time_window',
      );
    }

    if (request.first.scoreContractVersion !=
        request.second.scoreContractVersion) {
      return _incomparable(
        status: AgentPerformanceComparisonStatus.incomparableDifferentContract,
        request: request,
        reason: 'different_score_contract',
      );
    }

    final Set<String> firstMetrics = request.first.includedMetricIds.toSet();
    final Set<String> secondMetrics = request.second.includedMetricIds.toSet();

    if (firstMetrics.length != secondMetrics.length ||
        !firstMetrics.containsAll(secondMetrics)) {
      return _incomparable(
        status: AgentPerformanceComparisonStatus.incomparableMetricSet,
        request: request,
        reason: 'different_metric_set',
      );
    }

    final double firstScore = request.first.overallScore!;
    final double secondScore = request.second.overallScore!;
    final double signedDifference = firstScore - secondScore;
    final double absoluteDifference = signedDifference.abs();

    final String relation;

    if (absoluteDifference <=
        AgentPerformanceScoringLimits.similarMarginPoints) {
      relation = AgentPerformanceComparisonRelation.similar;
    } else if (signedDifference > 0) {
      relation = AgentPerformanceComparisonRelation.firstHigher;
    } else {
      relation = AgentPerformanceComparisonRelation.secondHigher;
    }

    final AgentPerformanceComparisonResult result =
        AgentPerformanceComparisonResult(
          status: AgentPerformanceComparisonStatus.comparable,
          relation: relation,
          firstAgentId: request.first.agentId,
          secondAgentId: request.second.agentId,
          absoluteDifferencePoints: absoluteDifference,
          reasonCode: 'fair_visibility_comparison_only',
        );

    result.validateStructure();
    return result;
  }

  AgentPerformanceComparisonResult _incomparable({
    required String status,
    required AgentPerformanceComparisonRequest request,
    required String reason,
  }) {
    final AgentPerformanceComparisonResult result =
        AgentPerformanceComparisonResult(
          status: status,
          relation: AgentPerformanceComparisonRelation.notComparable,
          firstAgentId: request.first.agentId,
          secondAgentId: request.second.agentId,
          absoluteDifferencePoints: null,
          reasonCode: reason,
        );

    result.validateStructure();
    return result;
  }

  bool get highConfidenceRequiredForComparison => true;
  bool get sameCohortRequired => true;
  bool get sameTimeWindowRequired => true;
  bool get sameScoreContractRequired => true;
  bool get sameMetricSetRequired => true;
  bool get similarWithinTwoPoints => true;

  bool get statisticalSignificanceClaimed => false;
  bool get globalLeaderboardImplementedHere => false;
  bool get permanentRankImplementedHere => false;
  bool get disciplinaryActionImplementedHere => false;
  bool get routingChangeImplementedHere => false;
  bool get payChangeImplementedHere => false;
  bool get accessChangeImplementedHere => false;
  bool get persistenceImplementedHere => false;
}

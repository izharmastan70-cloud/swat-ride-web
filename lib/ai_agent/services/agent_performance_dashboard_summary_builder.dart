import '../constants/agent_performance_scoring_constants.dart';
import '../models/agent_performance_dashboard_agent_summary.dart';
import '../models/agent_performance_metric_aggregation_result.dart';
import '../models/agent_performance_score_result.dart';

class AgentPerformanceDashboardSummaryBuilder {
  const AgentPerformanceDashboardSummaryBuilder();

  AgentPerformanceDashboardAgentSummary build({
    required AgentPerformanceScoreResult score,
    required List<AgentPerformanceMetricAggregationResult> contextMetricResults,
  }) {
    score.validateStructure();

    final Map<String, double> contextValues = <String, double>{};
    final Set<String> insufficientContextIds = <String>{};

    for (final AgentPerformanceMetricAggregationResult result
        in contextMetricResults) {
      result.validateStructure();

      if (result.agentId != score.agentId ||
          result.windowId != score.windowId ||
          !AgentPerformanceScoreContract.contextOnlyMetricIds.contains(
            result.metricId,
          ) ||
          contextValues.containsKey(result.metricId) ||
          insufficientContextIds.contains(result.metricId)) {
        throw const FormatException('Invalid dashboard context evidence.');
      }

      if (result.sufficientForLaterInterpretation &&
          result.aggregatedValue != null) {
        contextValues[result.metricId] = result.aggregatedValue!;
      } else if (result.insufficientEvidence) {
        insufficientContextIds.add(result.metricId);
      }
    }

    final AgentPerformanceDashboardAgentSummary summary =
        AgentPerformanceDashboardAgentSummary(
          agentId: score.agentId,
          cohortKey: score.cohortKey,
          windowId: score.windowId,
          scoreContractVersion: score.scoreContractVersion,
          scoreStatus: score.status,
          overallScore: score.overallScore,
          confidence: score.confidence,
          comparisonEligible: score.comparisonEligible,
          includedScorableMetricIds: score.includedMetricIds,
          contextMetricValues: contextValues,
          insufficientContextMetricIds: insufficientContextIds,
        );

    summary.validateStructure();
    return summary;
  }

  bool get consumesVerifiedStep1CAnd1DOutputsOnly => true;
  bool get contextMetricsRemainContextOnly => true;
  bool get insufficientContextEvidenceIsLabeled => true;
  bool get readOnlySummaryOnly => true;

  bool get createsLeaderboard => false;
  bool get assignsRank => false;
  bool get createsDisciplinaryDecision => false;
  bool get changesRouting => false;
  bool get changesPay => false;
  bool get changesAccess => false;

  bool get persistenceImplementedHere => false;
  bool get providerInvocationImplementedHere => false;
}

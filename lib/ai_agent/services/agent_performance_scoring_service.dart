import '../constants/agent_performance_scoring_constants.dart';
import '../models/agent_performance_metric_aggregation_result.dart';
import '../models/agent_performance_metric_score_component.dart';
import '../models/agent_performance_score_input.dart';
import '../models/agent_performance_score_result.dart';
import 'agent_performance_scoring_policy.dart';

class AgentPerformanceScoringService {
  const AgentPerformanceScoringService({
    this.policy = const AgentPerformanceScoringPolicy(),
  });

  final AgentPerformanceScoringPolicy policy;

  AgentPerformanceScoreResult score(AgentPerformanceScoreInput input) {
    try {
      input.validateStructure();
    } catch (_) {
      return _blocked(
        input: input,
        status: AgentPerformanceScoreStatus.blockedInvalidInput,
        reason: 'invalid_score_input',
      );
    }

    final Map<String, AgentPerformanceMetricAggregationResult> byMetric =
        <String, AgentPerformanceMetricAggregationResult>{};

    for (final AgentPerformanceMetricAggregationResult result
        in input.metricResults) {
      if (!AgentPerformanceScoreContract.scorableMetricIds.contains(
        result.metricId,
      )) {
        continue;
      }

      if (byMetric.containsKey(result.metricId)) {
        return _blocked(
          input: input,
          status: AgentPerformanceScoreStatus.blockedDuplicateMetric,
          reason: 'duplicate_scorable_metric',
        );
      }

      byMetric[result.metricId] = result;
    }

    if (byMetric.length !=
            AgentPerformanceScoreContract.scorableMetricIds.length ||
        !byMetric.keys.toSet().containsAll(
          AgentPerformanceScoreContract.scorableMetricIds,
        )) {
      return _blocked(
        input: input,
        status: AgentPerformanceScoreStatus.blockedMissingMetric,
        reason: 'all_six_scorable_metrics_required',
      );
    }

    for (final AgentPerformanceMetricAggregationResult result
        in byMetric.values) {
      if (result.agentId != input.agentId ||
          result.windowId != input.windowId) {
        return _blocked(
          input: input,
          status: AgentPerformanceScoreStatus.blockedMismatchedEvidence,
          reason: 'agent_or_window_mismatch',
        );
      }

      if (!policy.scoreEvidenceIsUsable(result)) {
        return _blocked(
          input: input,
          status: AgentPerformanceScoreStatus.insufficientEvidence,
          reason: 'scorable_metric_not_sufficient',
        );
      }
    }

    final List<AgentPerformanceMetricScoreComponent> components =
        <AgentPerformanceMetricScoreComponent>[];

    bool allStrong = true;

    for (final String metricId
        in AgentPerformanceScoreContract.scorableMetricIds) {
      final AgentPerformanceMetricAggregationResult result =
          byMetric[metricId]!;

      if (!result.strongEvidence) {
        allStrong = false;
      }

      components.add(policy.componentFor(result));
    }

    final double overall = components.fold<double>(
      0,
      (double sum, AgentPerformanceMetricScoreComponent component) =>
          sum + component.weightedScore,
    );

    final AgentPerformanceScoreResult result = AgentPerformanceScoreResult(
      status: allStrong
          ? AgentPerformanceScoreStatus.scoredHighConfidence
          : AgentPerformanceScoreStatus.scoredMediumConfidence,
      agentId: input.agentId,
      cohortKey: input.cohortKey,
      windowId: input.windowId,
      scoreContractVersion: AgentPerformanceScoreContract.version,
      overallScore: overall,
      confidence: allStrong
          ? AgentPerformanceScoreConfidence.high
          : AgentPerformanceScoreConfidence.medium,
      comparisonEligible: allStrong,
      includedMetricIds: components
          .map(
            (AgentPerformanceMetricScoreComponent component) =>
                component.metricId,
          )
          .toList(growable: false),
      components: components,
      reasonCodes: <String>[
        allStrong
            ? 'all_six_metrics_strong'
            : 'all_six_metrics_sufficient_some_not_strong',
        'read_only_performance_interpretation',
        'context_only_metrics_excluded',
      ],
    );

    result.validateStructure();
    return result;
  }

  AgentPerformanceScoreResult _blocked({
    required AgentPerformanceScoreInput input,
    required String status,
    required String reason,
  }) {
    final AgentPerformanceScoreResult result = AgentPerformanceScoreResult(
      status: status,
      agentId: input.agentId,
      cohortKey: input.cohortKey,
      windowId: input.windowId,
      scoreContractVersion: AgentPerformanceScoreContract.version,
      overallScore: null,
      confidence: AgentPerformanceScoreConfidence.none,
      comparisonEligible: false,
      includedMetricIds: const <String>[],
      components: const <AgentPerformanceMetricScoreComponent>[],
      reasonCodes: <String>[reason, 'fail_closed_no_score'],
    );

    result.validateStructure();
    return result;
  }

  bool get allSixScorableMetricsRequired => true;
  bool get contextOnlyMetricsExcludedFromComposite => true;
  bool get escalationCannotReducePerformanceScore => true;
  bool get missingEvidenceProducesNoScore => true;
  bool get insufficientEvidenceProducesNoScore => true;

  bool get mediumConfidenceNotComparisonEligible => true;
  bool get highConfidenceRequiredForComparison => true;

  bool get dashboardScoreReadOnly => true;
  bool get scoreIsNotPermissionOrApproval => true;
  bool get scoreIsNotRoutingAuthority => true;
  bool get scoreIsNotDisciplinaryAuthority => true;
  bool get scoreIsNotPayAuthority => true;
  bool get scoreIsNotAccessAuthority => true;

  bool get firestoreWriteImplementedHere => false;
  bool get providerInvocationImplementedHere => false;
  bool get routingMutationImplementedHere => false;
  bool get agentStateMutationImplementedHere => false;
  bool get budgetMutationImplementedHere => false;
  bool get persistenceImplementedHere => false;

  bool get securityAuthorityAlwaysAboveDashboard => true;

  bool get step1EReadModelDashboardSeparate => true;
  bool get step1FPrivacyFailureIsolationSeparate => true;
  bool get step1GFinalCloseoutSeparate => true;
}

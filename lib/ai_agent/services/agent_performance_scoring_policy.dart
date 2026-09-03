import '../constants/agent_performance_metric_constants.dart';
import '../constants/agent_performance_scoring_constants.dart';
import '../models/agent_performance_metric_aggregation_result.dart';
import '../models/agent_performance_metric_score_component.dart';

class AgentPerformanceScoringPolicy {
  const AgentPerformanceScoringPolicy();

  AgentPerformanceMetricScoreComponent componentFor(
    AgentPerformanceMetricAggregationResult result,
  ) {
    final double value = result.aggregatedValue!;

    switch (result.metricId) {
      case AgentPerformanceMetricId.taskSuccessRate:
        return _positive(
          result.metricId,
          value,
          AgentPerformanceScoreWeight.taskSuccessRate,
        );

      case AgentPerformanceMetricId.taskFailureRate:
        return _inverse(
          result.metricId,
          value,
          AgentPerformanceScoreWeight.taskFailureRate,
        );

      case AgentPerformanceMetricId.retryRate:
        return _inverse(
          result.metricId,
          value,
          AgentPerformanceScoreWeight.retryRate,
        );

      case AgentPerformanceMetricId.qualityScore:
        return _positive(
          result.metricId,
          value,
          AgentPerformanceScoreWeight.qualityScore,
        );

      case AgentPerformanceMetricId.healthScore:
        return _positive(
          result.metricId,
          value,
          AgentPerformanceScoreWeight.healthScore,
        );

      case AgentPerformanceMetricId.feedbackScore:
        return _positive(
          result.metricId,
          value,
          AgentPerformanceScoreWeight.feedbackScore,
        );
    }

    throw const FormatException(
      'Metric is context-only and cannot enter Agent performance score.',
    );
  }

  AgentPerformanceMetricScoreComponent _positive(
    String metricId,
    double value,
    double weight,
  ) {
    return AgentPerformanceMetricScoreComponent(
      metricId: metricId,
      sourceValue: value,
      normalizedScore: value,
      weight: weight,
      weightedScore: value * weight,
      inverseDirection: false,
    );
  }

  AgentPerformanceMetricScoreComponent _inverse(
    String metricId,
    double value,
    double weight,
  ) {
    final double normalized = 100 - value;

    return AgentPerformanceMetricScoreComponent(
      metricId: metricId,
      sourceValue: value,
      normalizedScore: normalized,
      weight: weight,
      weightedScore: normalized * weight,
      inverseDirection: true,
    );
  }

  bool scoreEvidenceIsUsable(AgentPerformanceMetricAggregationResult result) {
    return result.aggregatedValue != null &&
        result.sufficientForLaterInterpretation &&
        AgentPerformanceScoreContract.scorableMetricIds.contains(
          result.metricId,
        );
  }

  bool get allSixScorableMetricsRequired => true;
  bool get escalationRateContextOnly => true;
  bool get safeEscalationNeverPenalized => true;
  bool get latencyContextOnly => true;
  bool get costContextOnly => true;
  bool get tokenUsageContextOnly => true;
  bool get workloadContextOnly => true;
  bool get auditCountContextOnly => true;

  bool get scoreCanGrantAuthority => false;
  bool get scoreCanDisciplineAgent => false;
  bool get scoreCanChangeRouting => false;
  bool get scoreCanChangePay => false;
  bool get scoreCanChangeAccess => false;
  bool get persistenceImplementedHere => false;
}

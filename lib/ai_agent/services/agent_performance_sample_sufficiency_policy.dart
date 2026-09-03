import '../constants/agent_performance_aggregation_constants.dart';
import '../constants/agent_performance_metric_constants.dart';
import '../models/agent_performance_metric_descriptor.dart';
import '../models/agent_performance_sample_sufficiency.dart';

class AgentPerformanceSampleSufficiencyPolicy {
  const AgentPerformanceSampleSufficiencyPolicy();

  AgentPerformanceSampleSufficiency assess({
    required AgentPerformanceMetricDescriptor descriptor,
    required int sampleCount,
  }) {
    descriptor.validateStructure();

    final ({int minimum, int strong}) thresholds = _thresholds(
      descriptor.aggregation,
    );

    final String level;

    if (sampleCount <= 0) {
      level = AgentPerformanceSampleSufficiencyLevel.none;
    } else if (sampleCount < thresholds.minimum) {
      level = AgentPerformanceSampleSufficiencyLevel.insufficient;
    } else if (sampleCount < thresholds.strong) {
      level = AgentPerformanceSampleSufficiencyLevel.sufficient;
    } else {
      level = AgentPerformanceSampleSufficiencyLevel.strong;
    }

    final AgentPerformanceSampleSufficiency result =
        AgentPerformanceSampleSufficiency(
          level: level,
          sampleCount: sampleCount,
          minimumRequired: thresholds.minimum,
          strongRequired: thresholds.strong,
        );

    result.validateStructure();
    return result;
  }

  ({int minimum, int strong}) _thresholds(String aggregation) {
    switch (aggregation) {
      case AgentPerformanceMetricAggregation.rate:
      case AgentPerformanceMetricAggregation.average:
        return (
          minimum: AgentPerformanceAggregationLimits.rateAverageMinimumSample,
          strong: AgentPerformanceAggregationLimits.rateAverageStrongSample,
        );

      case AgentPerformanceMetricAggregation.sum:
        return (
          minimum: AgentPerformanceAggregationLimits.sumMinimumSample,
          strong: AgentPerformanceAggregationLimits.sumStrongSample,
        );

      case AgentPerformanceMetricAggregation.latest:
        return (
          minimum: AgentPerformanceAggregationLimits.latestMinimumSample,
          strong: AgentPerformanceAggregationLimits.latestStrongSample,
        );
    }

    throw const FormatException(
      'Unsupported Agent Performance aggregation type.',
    );
  }

  bool get rateAverageMinimum20 => true;
  bool get rateAverageStrong100 => true;
  bool get sumMinimum1 => true;
  bool get sumStrong20 => true;
  bool get latestMinimum1 => true;
  bool get latestStrong5 => true;

  bool get insufficientSampleCanCreateComparativeClaim => false;
  bool get sampleEvidenceCanGrantAuthority => false;
  bool get sampleEvidenceCanDisciplineAgent => false;
  bool get persistenceImplementedHere => false;
}

import '../constants/agent_performance_metric_constants.dart';
import '../models/agent_performance_metric_descriptor.dart';

class AgentPerformanceMetricCatalog {
  const AgentPerformanceMetricCatalog();

  List<AgentPerformanceMetricDescriptor> get descriptors =>
      const <AgentPerformanceMetricDescriptor>[
        AgentPerformanceMetricDescriptor(
          metricId: AgentPerformanceMetricId.taskSuccessRate,
          family: AgentPerformanceMetricFamily.reliability,
          unit: AgentPerformanceMetricUnit.percentage,
          aggregation: AgentPerformanceMetricAggregation.rate,
          minimumNecessaryMetadataOnly: true,
          trustedProjectionRequired: true,
        ),
        AgentPerformanceMetricDescriptor(
          metricId: AgentPerformanceMetricId.taskFailureRate,
          family: AgentPerformanceMetricFamily.reliability,
          unit: AgentPerformanceMetricUnit.percentage,
          aggregation: AgentPerformanceMetricAggregation.rate,
          minimumNecessaryMetadataOnly: true,
          trustedProjectionRequired: true,
        ),
        AgentPerformanceMetricDescriptor(
          metricId: AgentPerformanceMetricId.averageLatencyMs,
          family: AgentPerformanceMetricFamily.responsiveness,
          unit: AgentPerformanceMetricUnit.milliseconds,
          aggregation: AgentPerformanceMetricAggregation.average,
          minimumNecessaryMetadataOnly: true,
          trustedProjectionRequired: true,
        ),
        AgentPerformanceMetricDescriptor(
          metricId: AgentPerformanceMetricId.retryRate,
          family: AgentPerformanceMetricFamily.reliability,
          unit: AgentPerformanceMetricUnit.percentage,
          aggregation: AgentPerformanceMetricAggregation.rate,
          minimumNecessaryMetadataOnly: true,
          trustedProjectionRequired: true,
        ),
        AgentPerformanceMetricDescriptor(
          metricId: AgentPerformanceMetricId.escalationRate,
          family: AgentPerformanceMetricFamily.reliability,
          unit: AgentPerformanceMetricUnit.percentage,
          aggregation: AgentPerformanceMetricAggregation.rate,
          minimumNecessaryMetadataOnly: true,
          trustedProjectionRequired: true,
        ),
        AgentPerformanceMetricDescriptor(
          metricId: AgentPerformanceMetricId.completedTaskCount,
          family: AgentPerformanceMetricFamily.workload,
          unit: AgentPerformanceMetricUnit.count,
          aggregation: AgentPerformanceMetricAggregation.sum,
          minimumNecessaryMetadataOnly: true,
          trustedProjectionRequired: true,
        ),
        AgentPerformanceMetricDescriptor(
          metricId: AgentPerformanceMetricId.providerUsageCount,
          family: AgentPerformanceMetricFamily.providerUsage,
          unit: AgentPerformanceMetricUnit.count,
          aggregation: AgentPerformanceMetricAggregation.sum,
          minimumNecessaryMetadataOnly: true,
          trustedProjectionRequired: true,
        ),
        AgentPerformanceMetricDescriptor(
          metricId: AgentPerformanceMetricId.inputTokenCount,
          family: AgentPerformanceMetricFamily.tokenUsage,
          unit: AgentPerformanceMetricUnit.count,
          aggregation: AgentPerformanceMetricAggregation.sum,
          minimumNecessaryMetadataOnly: true,
          trustedProjectionRequired: true,
        ),
        AgentPerformanceMetricDescriptor(
          metricId: AgentPerformanceMetricId.outputTokenCount,
          family: AgentPerformanceMetricFamily.tokenUsage,
          unit: AgentPerformanceMetricUnit.count,
          aggregation: AgentPerformanceMetricAggregation.sum,
          minimumNecessaryMetadataOnly: true,
          trustedProjectionRequired: true,
        ),
        AgentPerformanceMetricDescriptor(
          metricId: AgentPerformanceMetricId.billableCostMinorUnits,
          family: AgentPerformanceMetricFamily.cost,
          unit: AgentPerformanceMetricUnit.minorCurrencyUnits,
          aggregation: AgentPerformanceMetricAggregation.sum,
          minimumNecessaryMetadataOnly: true,
          trustedProjectionRequired: true,
        ),
        AgentPerformanceMetricDescriptor(
          metricId: AgentPerformanceMetricId.qualityScore,
          family: AgentPerformanceMetricFamily.quality,
          unit: AgentPerformanceMetricUnit.score0To100,
          aggregation: AgentPerformanceMetricAggregation.average,
          minimumNecessaryMetadataOnly: true,
          trustedProjectionRequired: true,
        ),
        AgentPerformanceMetricDescriptor(
          metricId: AgentPerformanceMetricId.healthScore,
          family: AgentPerformanceMetricFamily.health,
          unit: AgentPerformanceMetricUnit.score0To100,
          aggregation: AgentPerformanceMetricAggregation.latest,
          minimumNecessaryMetadataOnly: true,
          trustedProjectionRequired: true,
        ),
        AgentPerformanceMetricDescriptor(
          metricId: AgentPerformanceMetricId.feedbackScore,
          family: AgentPerformanceMetricFamily.feedback,
          unit: AgentPerformanceMetricUnit.score0To100,
          aggregation: AgentPerformanceMetricAggregation.average,
          minimumNecessaryMetadataOnly: true,
          trustedProjectionRequired: true,
        ),
        AgentPerformanceMetricDescriptor(
          metricId: AgentPerformanceMetricId.auditEventCount,
          family: AgentPerformanceMetricFamily.audit,
          unit: AgentPerformanceMetricUnit.count,
          aggregation: AgentPerformanceMetricAggregation.sum,
          minimumNecessaryMetadataOnly: true,
          trustedProjectionRequired: true,
        ),
      ];

  AgentPerformanceMetricDescriptor? findById(String metricId) {
    for (final AgentPerformanceMetricDescriptor descriptor in descriptors) {
      if (descriptor.metricId == metricId) {
        return descriptor;
      }
    }

    return null;
  }

  bool get reusesExistingSignals => true;
  bool get createsDuplicateTelemetryEngine => false;
  bool get readOnlyCatalog => true;
  bool get catalogContainsRawPayload => false;
  bool get catalogContainsSecrets => false;

  bool get persistenceImplementedHere => false;
  bool get providerInvocationImplementedHere => false;
  bool get businessExecutionImplementedHere => false;
}

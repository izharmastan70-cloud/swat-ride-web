import '../constants/agent_performance_metric_constants.dart';
import '../models/agent_performance_metric_descriptor.dart';
import '../models/agent_performance_metric_observation.dart';

class AgentPerformanceMetricSafetyPolicy {
  const AgentPerformanceMetricSafetyPolicy();

  String evaluate({
    required AgentPerformanceMetricDescriptor? descriptor,
    required AgentPerformanceMetricObservation observation,
  }) {
    try {
      observation.validateStructure();
    } catch (_) {
      return AgentPerformanceMetricObservationStatus.blockedInvalidMetadata;
    }

    if (descriptor == null || descriptor.metricId != observation.metricId) {
      return AgentPerformanceMetricObservationStatus.blockedUnknownMetric;
    }

    try {
      descriptor.validateStructure();
    } catch (_) {
      return AgentPerformanceMetricObservationStatus.blockedInvalidMetadata;
    }

    if (!observation.trustedSourceProjection) {
      return AgentPerformanceMetricObservationStatus.blockedUntrustedSource;
    }

    if (!observation.minimumNecessaryMetadata ||
        !observation.privacySafeProjection) {
      return AgentPerformanceMetricObservationStatus.blockedPrivacyUnsafe;
    }

    if (!_validMetricValue(
      metricId: observation.metricId,
      value: observation.numericValue,
    )) {
      return AgentPerformanceMetricObservationStatus.blockedInvalidValue;
    }

    return AgentPerformanceMetricObservationStatus.acceptedReadOnly;
  }

  bool _validMetricValue({required String metricId, required double value}) {
    if (value < 0) {
      return false;
    }

    switch (metricId) {
      case AgentPerformanceMetricId.taskSuccessRate:
      case AgentPerformanceMetricId.taskFailureRate:
      case AgentPerformanceMetricId.retryRate:
      case AgentPerformanceMetricId.escalationRate:
      case AgentPerformanceMetricId.qualityScore:
      case AgentPerformanceMetricId.healthScore:
      case AgentPerformanceMetricId.feedbackScore:
        return value <= 100;

      case AgentPerformanceMetricId.averageLatencyMs:
        return value <= AgentPerformanceMetricLimits.maxLatencyMs;

      case AgentPerformanceMetricId.billableCostMinorUnits:
        return value <= AgentPerformanceMetricLimits.maxMinorCurrencyUnits;

      case AgentPerformanceMetricId.completedTaskCount:
      case AgentPerformanceMetricId.providerUsageCount:
      case AgentPerformanceMetricId.inputTokenCount:
      case AgentPerformanceMetricId.outputTokenCount:
      case AgentPerformanceMetricId.auditEventCount:
        return value <= AgentPerformanceMetricLimits.maxCountLikeValue;
    }

    return false;
  }

  bool get acceptedMeansVisibilityOnly => true;
  bool get acceptedMeansExecutionAuthorized => false;
  bool get trustedSourceRequired => true;
  bool get minimumNecessaryMetadataRequired => true;
  bool get privacySafeProjectionRequired => true;

  bool get rawPromptMayInfluenceDashboardDirectly => false;
  bool get rawConversationMayInfluenceDashboardDirectly => false;
  bool get providerResponseMayGrantMetricAuthority => false;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get grantsOwnerAuthority => false;
  bool get executesBusinessAction => false;

  bool get persistenceImplementedHere => false;
  bool get routingMutationImplementedHere => false;
  bool get agentStateMutationImplementedHere => false;
}

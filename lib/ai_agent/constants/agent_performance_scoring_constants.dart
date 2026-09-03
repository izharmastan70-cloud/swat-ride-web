import 'agent_performance_metric_constants.dart';

class AgentPerformanceScoreContract {
  AgentPerformanceScoreContract._();

  static const String version = 'P61_S1D_V1';

  static const Set<String> scorableMetricIds = <String>{
    AgentPerformanceMetricId.taskSuccessRate,
    AgentPerformanceMetricId.taskFailureRate,
    AgentPerformanceMetricId.retryRate,
    AgentPerformanceMetricId.qualityScore,
    AgentPerformanceMetricId.healthScore,
    AgentPerformanceMetricId.feedbackScore,
  };

  static const Set<String> contextOnlyMetricIds = <String>{
    AgentPerformanceMetricId.averageLatencyMs,
    AgentPerformanceMetricId.escalationRate,
    AgentPerformanceMetricId.completedTaskCount,
    AgentPerformanceMetricId.providerUsageCount,
    AgentPerformanceMetricId.inputTokenCount,
    AgentPerformanceMetricId.outputTokenCount,
    AgentPerformanceMetricId.billableCostMinorUnits,
    AgentPerformanceMetricId.auditEventCount,
  };
}

class AgentPerformanceScoreWeight {
  AgentPerformanceScoreWeight._();

  static const double taskSuccessRate = 0.20;
  static const double taskFailureRate = 0.10;
  static const double retryRate = 0.10;
  static const double qualityScore = 0.30;
  static const double healthScore = 0.20;
  static const double feedbackScore = 0.10;

  static const double total = 1.00;
}

class AgentPerformanceScoreConfidence {
  AgentPerformanceScoreConfidence._();

  static const String none = 'NONE';
  static const String medium = 'MEDIUM';
  static const String high = 'HIGH';

  static const Set<String> values = <String>{none, medium, high};
}

class AgentPerformanceScoreStatus {
  AgentPerformanceScoreStatus._();

  static const String scoredMediumConfidence = 'SCORED_MEDIUM_CONFIDENCE';
  static const String scoredHighConfidence = 'SCORED_HIGH_CONFIDENCE';
  static const String insufficientEvidence = 'INSUFFICIENT_EVIDENCE';
  static const String blockedMissingMetric = 'BLOCKED_MISSING_METRIC';
  static const String blockedDuplicateMetric = 'BLOCKED_DUPLICATE_METRIC';
  static const String blockedMismatchedEvidence = 'BLOCKED_MISMATCHED_EVIDENCE';
  static const String blockedInvalidInput = 'BLOCKED_INVALID_INPUT';

  static const Set<String> values = <String>{
    scoredMediumConfidence,
    scoredHighConfidence,
    insufficientEvidence,
    blockedMissingMetric,
    blockedDuplicateMetric,
    blockedMismatchedEvidence,
    blockedInvalidInput,
  };
}

class AgentPerformanceComparisonStatus {
  AgentPerformanceComparisonStatus._();

  static const String comparable = 'COMPARABLE';
  static const String incomparableLowConfidence = 'INCOMPARABLE_LOW_CONFIDENCE';
  static const String incomparableDifferentCohort =
      'INCOMPARABLE_DIFFERENT_COHORT';
  static const String incomparableDifferentWindow =
      'INCOMPARABLE_DIFFERENT_WINDOW';
  static const String incomparableDifferentContract =
      'INCOMPARABLE_DIFFERENT_CONTRACT';
  static const String incomparableMetricSet = 'INCOMPARABLE_METRIC_SET';
  static const String blockedInvalidInput = 'BLOCKED_INVALID_INPUT';

  static const Set<String> values = <String>{
    comparable,
    incomparableLowConfidence,
    incomparableDifferentCohort,
    incomparableDifferentWindow,
    incomparableDifferentContract,
    incomparableMetricSet,
    blockedInvalidInput,
  };
}

class AgentPerformanceComparisonRelation {
  AgentPerformanceComparisonRelation._();

  static const String similar = 'SIMILAR';
  static const String firstHigher = 'FIRST_HIGHER';
  static const String secondHigher = 'SECOND_HIGHER';
  static const String notComparable = 'NOT_COMPARABLE';

  static const Set<String> values = <String>{
    similar,
    firstHigher,
    secondHigher,
    notComparable,
  };
}

class AgentPerformanceScoringLimits {
  AgentPerformanceScoringLimits._();

  static const int opaqueIdMaxLength = 220;
  static const double similarMarginPoints = 2.0;
}

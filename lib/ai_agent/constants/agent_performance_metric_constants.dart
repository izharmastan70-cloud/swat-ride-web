class AgentPerformanceMetricId {
  AgentPerformanceMetricId._();

  static const String taskSuccessRate = 'TASK_SUCCESS_RATE';
  static const String taskFailureRate = 'TASK_FAILURE_RATE';
  static const String averageLatencyMs = 'AVERAGE_LATENCY_MS';
  static const String retryRate = 'RETRY_RATE';
  static const String escalationRate = 'ESCALATION_RATE';
  static const String completedTaskCount = 'COMPLETED_TASK_COUNT';
  static const String providerUsageCount = 'PROVIDER_USAGE_COUNT';
  static const String inputTokenCount = 'INPUT_TOKEN_COUNT';
  static const String outputTokenCount = 'OUTPUT_TOKEN_COUNT';
  static const String billableCostMinorUnits = 'BILLABLE_COST_MINOR_UNITS';
  static const String qualityScore = 'QUALITY_SCORE';
  static const String healthScore = 'HEALTH_SCORE';
  static const String feedbackScore = 'FEEDBACK_SCORE';
  static const String auditEventCount = 'AUDIT_EVENT_COUNT';

  static const Set<String> values = <String>{
    taskSuccessRate,
    taskFailureRate,
    averageLatencyMs,
    retryRate,
    escalationRate,
    completedTaskCount,
    providerUsageCount,
    inputTokenCount,
    outputTokenCount,
    billableCostMinorUnits,
    qualityScore,
    healthScore,
    feedbackScore,
    auditEventCount,
  };
}

class AgentPerformanceMetricFamily {
  AgentPerformanceMetricFamily._();

  static const String reliability = 'RELIABILITY';
  static const String responsiveness = 'RESPONSIVENESS';
  static const String workload = 'WORKLOAD';
  static const String providerUsage = 'PROVIDER_USAGE';
  static const String tokenUsage = 'TOKEN_USAGE';
  static const String cost = 'COST';
  static const String quality = 'QUALITY';
  static const String health = 'HEALTH';
  static const String feedback = 'FEEDBACK';
  static const String audit = 'AUDIT';

  static const Set<String> values = <String>{
    reliability,
    responsiveness,
    workload,
    providerUsage,
    tokenUsage,
    cost,
    quality,
    health,
    feedback,
    audit,
  };
}

class AgentPerformanceMetricUnit {
  AgentPerformanceMetricUnit._();

  static const String percentage = 'PERCENTAGE';
  static const String milliseconds = 'MILLISECONDS';
  static const String count = 'COUNT';
  static const String minorCurrencyUnits = 'MINOR_CURRENCY_UNITS';
  static const String score0To100 = 'SCORE_0_TO_100';

  static const Set<String> values = <String>{
    percentage,
    milliseconds,
    count,
    minorCurrencyUnits,
    score0To100,
  };
}

class AgentPerformanceMetricAggregation {
  AgentPerformanceMetricAggregation._();

  static const String rate = 'RATE';
  static const String average = 'AVERAGE';
  static const String sum = 'SUM';
  static const String latest = 'LATEST';

  static const Set<String> values = <String>{rate, average, sum, latest};
}

class AgentPerformanceMetricObservationStatus {
  AgentPerformanceMetricObservationStatus._();

  static const String acceptedReadOnly = 'ACCEPTED_READ_ONLY';
  static const String blockedUnknownMetric = 'BLOCKED_UNKNOWN_METRIC';
  static const String blockedUntrustedSource = 'BLOCKED_UNTRUSTED_SOURCE';
  static const String blockedPrivacyUnsafe = 'BLOCKED_PRIVACY_UNSAFE';
  static const String blockedInvalidValue = 'BLOCKED_INVALID_VALUE';
  static const String blockedInvalidMetadata = 'BLOCKED_INVALID_METADATA';

  static const Set<String> values = <String>{
    acceptedReadOnly,
    blockedUnknownMetric,
    blockedUntrustedSource,
    blockedPrivacyUnsafe,
    blockedInvalidValue,
    blockedInvalidMetadata,
  };
}

class AgentPerformanceMetricLimits {
  AgentPerformanceMetricLimits._();

  static const int opaqueIdMaxLength = 220;
  static const int maxSampleCount = 1000000000;
  static const double maxCountLikeValue = 1000000000000;
  static const double maxLatencyMs = 86400000;
  static const double maxMinorCurrencyUnits = 1000000000000;
}

class AgentPerformanceTimeWindowId {
  AgentPerformanceTimeWindowId._();

  static const String last1Hour = 'LAST_1_HOUR';
  static const String last24Hours = 'LAST_24_HOURS';
  static const String last7Days = 'LAST_7_DAYS';
  static const String last30Days = 'LAST_30_DAYS';
  static const String custom = 'CUSTOM';

  static const Set<String> values = <String>{
    last1Hour,
    last24Hours,
    last7Days,
    last30Days,
    custom,
  };
}

class AgentPerformanceSampleSufficiencyLevel {
  AgentPerformanceSampleSufficiencyLevel._();

  static const String none = 'NONE';
  static const String insufficient = 'INSUFFICIENT';
  static const String sufficient = 'SUFFICIENT';
  static const String strong = 'STRONG';

  static const Set<String> values = <String>{
    none,
    insufficient,
    sufficient,
    strong,
  };
}

class AgentPerformanceAggregationStatus {
  AgentPerformanceAggregationStatus._();

  static const String aggregatedStrong = 'AGGREGATED_STRONG';
  static const String aggregatedSufficient = 'AGGREGATED_SUFFICIENT';
  static const String insufficientSample = 'INSUFFICIENT_SAMPLE';
  static const String noData = 'NO_DATA';
  static const String blockedUnsafeObservation = 'BLOCKED_UNSAFE_OBSERVATION';
  static const String blockedInvalidInput = 'BLOCKED_INVALID_INPUT';

  static const Set<String> values = <String>{
    aggregatedStrong,
    aggregatedSufficient,
    insufficientSample,
    noData,
    blockedUnsafeObservation,
    blockedInvalidInput,
  };
}

class AgentPerformanceAggregationLimits {
  AgentPerformanceAggregationLimits._();

  static const int millisecondsPerHour = 3600000;
  static const int millisecondsPerDay = 86400000;

  static const int last1HourMs = millisecondsPerHour;
  static const int last24HoursMs = millisecondsPerDay;
  static const int last7DaysMs = millisecondsPerDay * 7;
  static const int last30DaysMs = millisecondsPerDay * 30;
  static const int maxCustomWindowMs = millisecondsPerDay * 90;

  static const int maxObservationsPerAggregation = 5000;

  static const int rateAverageMinimumSample = 20;
  static const int rateAverageStrongSample = 100;

  static const int sumMinimumSample = 1;
  static const int sumStrongSample = 20;

  static const int latestMinimumSample = 1;
  static const int latestStrongSample = 5;

  static const int opaqueIdMaxLength = 220;
}

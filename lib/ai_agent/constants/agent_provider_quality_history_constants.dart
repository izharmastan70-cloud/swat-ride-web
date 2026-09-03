class AgentProviderQualityTrend {
  AgentProviderQualityTrend._();

  static const String improving = 'IMPROVING';
  static const String stable = 'STABLE';
  static const String degrading = 'DEGRADING';
  static const String insufficientHistory = 'INSUFFICIENT_HISTORY';

  static const Set<String> values = <String>{
    improving,
    stable,
    degrading,
    insufficientHistory,
  };
}

class AgentProviderQualityRegressionSeverity {
  AgentProviderQualityRegressionSeverity._();

  static const String none = 'NONE';
  static const String watch = 'WATCH';
  static const String significant = 'SIGNIFICANT';
  static const String critical = 'CRITICAL';

  static const Set<String> values = <String>{
    none,
    watch,
    significant,
    critical,
  };
}

class AgentProviderQualityStabilityStatus {
  AgentProviderQualityStabilityStatus._();

  static const String allowPreferenceChange = 'ALLOW_PREFERENCE_CHANGE';
  static const String holdCurrentPreference = 'HOLD_CURRENT_PREFERENCE';
  static const String failClosedIneligible = 'FAIL_CLOSED_INELIGIBLE';
  static const String insufficientHistory = 'INSUFFICIENT_HISTORY';

  static const Set<String> values = <String>{
    allowPreferenceChange,
    holdCurrentPreference,
    failClosedIneligible,
    insufficientHistory,
  };
}

class AgentProviderQualityHistoryLimits {
  AgentProviderQualityHistoryLimits._();

  static const int maxHistoryPoints = 60;
  static const int minTrendPoints = 4;
  static const int baselinePointCount = 2;
  static const int recentPointCount = 2;

  static const double stableDeltaMaxPoints = 3.0;

  static const double watchRegressionDropPoints = 5.0;
  static const double significantRegressionDropPoints = 10.0;
  static const double criticalRegressionDropPoints = 20.0;

  static const double safetyCriticalFloor = 60.0;
  static const double safetyCriticalDropPoints = 20.0;

  static const int minConsistentRecommendations = 3;
  static const int preferenceChangeCooldownHours = 24;
  static const int alternatingPatternLength = 4;

  static const int highConfidenceHistoryPoints = 8;
  static const int maxReasonCodes = 20;
}

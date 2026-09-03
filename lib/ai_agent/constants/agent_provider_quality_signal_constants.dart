class AgentProviderQualitySignalFamily {
  AgentProviderQualitySignalFamily._();

  static const String reliability = 'RELIABILITY';
  static const String responsiveness = 'RESPONSIVENESS';
  static const String taskFit = 'TASK_FIT';
  static const String outputQuality = 'OUTPUT_QUALITY';
  static const String userFeedback = 'USER_FEEDBACK';
  static const String costEfficiency = 'COST_EFFICIENCY';
  static const String stability = 'STABILITY';
  static const String safety = 'SAFETY';

  static const Set<String> values = <String>{
    reliability,
    responsiveness,
    taskFit,
    outputQuality,
    userFeedback,
    costEfficiency,
    stability,
    safety,
  };
}

class AgentProviderQualitySignalSource {
  AgentProviderQualitySignalSource._();

  static const String trustedBackendObserved = 'TRUSTED_BACKEND_OBSERVED';

  static const String evaluationMetadata = 'EVALUATION_METADATA';

  static const String privacyMinimizedUserFeedback =
      'PRIVACY_MINIMIZED_USER_FEEDBACK';

  static const Set<String> values = <String>{
    trustedBackendObserved,
    evaluationMetadata,
    privacyMinimizedUserFeedback,
  };
}

class AgentProviderQualitySampleSufficiency {
  AgentProviderQualitySampleSufficiency._();

  static const String insufficient = 'INSUFFICIENT';
  static const String sufficient = 'SUFFICIENT';
  static const String strong = 'STRONG';

  static const Set<String> values = <String>{insufficient, sufficient, strong};
}

class AgentProviderQualityFreshness {
  AgentProviderQualityFreshness._();

  static const String current = 'CURRENT';
  static const String aging = 'AGING';
  static const String stale = 'STALE';

  static const Set<String> values = <String>{current, aging, stale};
}

class AgentProviderQualityRecommendation {
  AgentProviderQualityRecommendation._();

  static const String ineligible = 'INELIGIBLE';
  static const String insufficientEvidence = 'INSUFFICIENT_EVIDENCE';
  static const String neutral = 'NEUTRAL';
  static const String prefer = 'PREFER';
  static const String deprioritize = 'DEPRIORITIZE';

  static const Set<String> values = <String>{
    ineligible,
    insufficientEvidence,
    neutral,
    prefer,
    deprioritize,
  };
}

class AgentProviderQualityLimits {
  AgentProviderQualityLimits._();

  static const int idMax = 220;
  static const int minSufficientSamples = 20;
  static const int minStrongSamples = 100;

  /// Evidence <= 7 days old is current.
  static const int currentMaxAgeHours = 168;

  /// Evidence > 30 days old is stale.
  static const int staleAfterHours = 720;

  static const double minScore = 0.0;
  static const double maxScore = 100.0;

  static const double preferScoreThreshold = 85.0;
  static const double neutralScoreThreshold = 60.0;

  static const int maxReasonCodes = 16;
}

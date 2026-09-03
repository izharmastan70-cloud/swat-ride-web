// =========================================================
// AI AGENT - PROVIDER ROUTING PROFILE
// =========================================================
//
// Phase 29 Step 2.
//
// Pure routing metadata only.
//
// Adds:
// - provider capability metadata
// - cost tier
// - daily request quota
// - rate-limit window
// - routing priority
// - fallback eligibility
//
// NO API KEYS.
// NO NETWORK CALLS.
// NO FIRESTORE WRITES.
// NO PROVIDER EXECUTION.

class AgentProviderCapability {
  AgentProviderCapability._();

  static const String textGeneration =
      'TEXT_GENERATION';

  static const String summarization =
      'SUMMARIZATION';

  static const String classification =
      'CLASSIFICATION';

  static const String structuredReasoning =
      'STRUCTURED_REASONING';

  static const String codeAnalysis =
      'CODE_ANALYSIS';

  static const String codePatchProposal =
      'CODE_PATCH_PROPOSAL';

  static const Set<String> values = <String>{
    textGeneration,
    summarization,
    classification,
    structuredReasoning,
    codeAnalysis,
    codePatchProposal,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentProviderCostTier {
  AgentProviderCostTier._();

  static const String free = 'FREE';
  static const String low = 'LOW';
  static const String medium = 'MEDIUM';
  static const String high = 'HIGH';

  static const Set<String> values = <String>{
    free,
    low,
    medium,
    high,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentProviderRoutingProfile {
  final String providerId;
  final String providerType;
  final Set<String> capabilities;
  final String costTier;
  final int priority;
  final bool enabled;
  final bool fallbackEligible;

  final int dailyRequestLimit;
  final int rateLimitMaxRequests;
  final Duration rateLimitWindow;

  const AgentProviderRoutingProfile({
    required this.providerId,
    required this.providerType,
    required this.capabilities,
    required this.costTier,
    required this.priority,
    this.enabled = true,
    this.fallbackEligible = true,
    this.dailyRequestLimit = 0,
    this.rateLimitMaxRequests = 0,
    this.rateLimitWindow = Duration.zero,
  });

  bool supportsCapability(
    String capability,
  ) {
    return capabilities.contains(capability);
  }

  bool get hasDailyQuota =>
      dailyRequestLimit > 0;

  bool get hasRateLimit =>
      rateLimitMaxRequests > 0 &&
      rateLimitWindow > Duration.zero;

  void validate() {
    if (providerId.trim().isEmpty) {
      throw const AgentProviderRoutingProfileException(
        'providerId cannot be empty.',
      );
    }

    if (providerType.trim().isEmpty) {
      throw const AgentProviderRoutingProfileException(
        'providerType cannot be empty.',
      );
    }

    if (priority < 0) {
      throw const AgentProviderRoutingProfileException(
        'priority cannot be negative.',
      );
    }

    if (!AgentProviderCostTier.isValid(costTier)) {
      throw AgentProviderRoutingProfileException(
        'Invalid provider cost tier "$costTier".',
      );
    }

    if (capabilities.isEmpty) {
      throw const AgentProviderRoutingProfileException(
        'Provider must declare at least one capability.',
      );
    }

    for (final String capability in capabilities) {
      if (!AgentProviderCapability.isValid(
        capability,
      )) {
        throw AgentProviderRoutingProfileException(
          'Invalid provider capability "$capability".',
        );
      }
    }

    if (dailyRequestLimit < 0) {
      throw const AgentProviderRoutingProfileException(
        'dailyRequestLimit cannot be negative.',
      );
    }

    if (rateLimitMaxRequests < 0) {
      throw const AgentProviderRoutingProfileException(
        'rateLimitMaxRequests cannot be negative.',
      );
    }

    if (rateLimitWindow.isNegative) {
      throw const AgentProviderRoutingProfileException(
        'rateLimitWindow cannot be negative.',
      );
    }

    final bool hasRequestCount =
        rateLimitMaxRequests > 0;

    final bool hasWindow =
        rateLimitWindow > Duration.zero;

    if (hasRequestCount != hasWindow) {
      throw const AgentProviderRoutingProfileException(
        'Rate-limit request count and window must be configured together.',
      );
    }
  }

  bool get isValid {
    try {
      validate();
      return true;
    } on AgentProviderRoutingProfileException {
      return false;
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'providerId': providerId,
      'providerType': providerType,
      'capabilities':
          capabilities.toList(growable: false),
      'costTier': costTier,
      'priority': priority,
      'enabled': enabled,
      'fallbackEligible': fallbackEligible,
      'dailyRequestLimit': dailyRequestLimit,
      'rateLimitMaxRequests':
          rateLimitMaxRequests,
      'rateLimitWindowSeconds':
          rateLimitWindow.inSeconds,
    };
  }
}

class AgentProviderRoutingProfileException
    implements Exception {
  final String message;

  const AgentProviderRoutingProfileException(
    this.message,
  );

  @override
  String toString() =>
      'AgentProviderRoutingProfileException: $message';
}
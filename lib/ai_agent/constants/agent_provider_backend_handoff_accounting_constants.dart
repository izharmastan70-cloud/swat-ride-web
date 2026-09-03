class AgentProviderBackendHandoffStatus {
  AgentProviderBackendHandoffStatus._();
  static const String eligible = 'ELIGIBLE_FOR_TRUSTED_BACKEND_EXECUTION';
  static const String invalid = 'BLOCKED_INVALID_HANDOFF';
  static const String backend = 'BLOCKED_BACKEND_BOUNDARY';
  static const String paid = 'BLOCKED_PAID_CONTROL';
  static const String cost = 'BLOCKED_COST_AUTHORIZATION';
  static const Set<String> values = <String>{
    eligible,
    invalid,
    backend,
    paid,
    cost,
  };
}

class AgentProviderUsageOutcome {
  AgentProviderUsageOutcome._();
  static const String success = 'SUCCESS';
  static const String providerFailure = 'PROVIDER_FAILURE';
  static const String timeout = 'TIMEOUT';
  static const String rateLimited = 'RATE_LIMITED';
  static const String circuitOpen = 'CIRCUIT_OPEN';
  static const String blockedBeforeInvocation = 'BLOCKED_BEFORE_INVOCATION';
  static const Set<String> values = <String>{
    success,
    providerFailure,
    timeout,
    rateLimited,
    circuitOpen,
    blockedBeforeInvocation,
  };
}

class AgentProviderUsageAccountingStatus {
  AgentProviderUsageAccountingStatus._();
  static const String eligible = 'ELIGIBLE_FOR_TRUSTED_BACKEND_COST_LOG';
  static const String overrun = 'ELIGIBLE_WITH_COST_OVERRUN_REVIEW';
  static const String invalid = 'BLOCKED_INVALID_USAGE_EVENT';
  static const String untrusted = 'BLOCKED_UNTRUSTED_OBSERVATION';
  static const String duplicate = 'BLOCKED_DUPLICATE_ACCOUNTING';
  static const String tierCost = 'BLOCKED_TIER_COST_MISMATCH';
  static const Set<String> values = <String>{
    eligible,
    overrun,
    invalid,
    untrusted,
    duplicate,
    tierCost,
  };
}

class AgentProviderBackendAccountingLimits {
  AgentProviderBackendAccountingLimits._();
  static const int idMax = 220;
  static const int modelRefMax = 180;
  static const int maxReasonCodes = 16;
  static const double absoluteMaxProviderCostRs = 1000000.0;
  static const int absoluteMaxTokens = 20000000;
}

class AgentPerformanceDashboardCloseoutStatus {
  AgentPerformanceDashboardCloseoutStatus._();

  static const String foundationReady = 'FOUNDATION_READY';
  static const String blockedInvalidMetadata = 'BLOCKED_INVALID_METADATA';
  static const String blockedFoundation = 'BLOCKED_FOUNDATION';
  static const String blockedAdversarial = 'BLOCKED_ADVERSARIAL';
  static const String blockedProductionActivation =
      'BLOCKED_PRODUCTION_ACTIVATION';

  static const Set<String> values = <String>{
    foundationReady,
    blockedInvalidMetadata,
    blockedFoundation,
    blockedAdversarial,
    blockedProductionActivation,
  };
}

class AgentPerformanceDashboardCloseoutScenarioId {
  AgentPerformanceDashboardCloseoutScenarioId._();

  static const String freshSafeVisibility = 'fresh_safe_visibility';
  static const String unsafeIdentifierPrivacy = 'unsafe_identifier_privacy';
  static const String malformedSummaryIsolation = 'malformed_summary_isolation';
  static const String staleSnapshot = 'stale_snapshot';
  static const String futureClockSkew = 'future_clock_skew';
  static const String duplicateSummaryIdentity = 'duplicate_summary_identity';
  static const String isolationBudgetExceeded = 'isolation_budget_exceeded';
  static const String blockedSource = 'blocked_source';
  static const String leaderboardAuthorityAbuse = 'leaderboard_authority_abuse';
  static const String securityAuthorityAbuse = 'security_authority_abuse';

  static const Set<String> required = <String>{
    freshSafeVisibility,
    unsafeIdentifierPrivacy,
    malformedSummaryIsolation,
    staleSnapshot,
    futureClockSkew,
    duplicateSummaryIdentity,
    isolationBudgetExceeded,
    blockedSource,
    leaderboardAuthorityAbuse,
    securityAuthorityAbuse,
  };
}

class AgentPerformanceDashboardCloseoutContract {
  AgentPerformanceDashboardCloseoutContract._();

  static const String version = 'phase61_dashboard_closeout_v1';
  static const int maxScenarios = 50;
  static const int maxOpaqueIdLength = 220;
}

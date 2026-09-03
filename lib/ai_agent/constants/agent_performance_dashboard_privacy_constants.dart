class AgentPerformanceDashboardSafeProjectionStatus {
  AgentPerformanceDashboardSafeProjectionStatus._();

  static const String ready = 'READY';
  static const String degraded = 'DEGRADED';
  static const String empty = 'EMPTY';
  static const String blockedSource = 'BLOCKED_SOURCE';
  static const String blockedPrivacy = 'BLOCKED_PRIVACY';
  static const String blockedStaleData = 'BLOCKED_STALE_DATA';
  static const String blockedClockSkew = 'BLOCKED_CLOCK_SKEW';

  static const Set<String> values = <String>{
    ready,
    degraded,
    empty,
    blockedSource,
    blockedPrivacy,
    blockedStaleData,
    blockedClockSkew,
  };
}

class AgentPerformanceDashboardFreshnessState {
  AgentPerformanceDashboardFreshnessState._();

  static const String fresh = 'FRESH';
  static const String stale = 'STALE';
  static const String futureClockSkew = 'FUTURE_CLOCK_SKEW';
  static const String invalidTimestamp = 'INVALID_TIMESTAMP';

  static const Set<String> values = <String>{
    fresh,
    stale,
    futureClockSkew,
    invalidTimestamp,
  };
}

class AgentPerformanceDashboardSafeReasonCode {
  AgentPerformanceDashboardSafeReasonCode._();

  static const String ready = 'safe_dashboard_projection_ready';
  static const String degraded = 'unsafe_or_malformed_summaries_isolated';
  static const String sourceEmpty = 'source_dashboard_empty';
  static const String sourceBlocked = 'source_dashboard_blocked';
  static const String invalidSourceEnvelope =
      'invalid_source_dashboard_envelope';
  static const String unsafeQueryId = 'unsafe_query_identifier_blocked';
  static const String allSummariesRedacted = 'all_visible_summaries_redacted';
  static const String allSummariesFailed =
      'all_visible_summaries_failed_validation';
  static const String duplicateSummary = 'duplicate_summary_identity_blocked';
  static const String isolationBudgetExceeded =
      'summary_failure_isolation_budget_exceeded';
  static const String staleSnapshot = 'stale_dashboard_snapshot_blocked';
  static const String clockSkew = 'dashboard_clock_skew_blocked';
}

class AgentPerformanceDashboardPrivacyLimits {
  AgentPerformanceDashboardPrivacyLimits._();

  static const int opaqueIdMaxLength = 220;
  static const int maxIsolatedFailures = 50;
  static const Duration defaultMaxSnapshotAge = Duration(minutes: 30);
  static const Duration maxFutureClockSkew = Duration(minutes: 5);
}

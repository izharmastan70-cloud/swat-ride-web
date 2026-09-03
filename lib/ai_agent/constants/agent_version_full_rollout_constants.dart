class AgentVersionFullRolloutPolicy {
  AgentVersionFullRolloutPolicy._();

  static const int minimumHealthyMonitoringWindows = 3;
  static const int minimumCompletedObservations = 100;

  static const Duration maximumMonitoringSummaryAge = Duration(minutes: 30);

  static const Duration maximumRollbackReadinessAge = Duration(hours: 24);

  static const Duration maximumFutureClockSkew = Duration(minutes: 5);

  static const Duration maximumOwnerApprovalValidity = Duration(minutes: 30);
}

class AgentVersionKnownGoodRollbackReadinessStatus {
  AgentVersionKnownGoodRollbackReadinessStatus._();

  static const String ready = 'READY';
  static const String blockedInvalidInput = 'BLOCKED_INVALID_INPUT';
  static const String blockedNoPreviousVersion = 'BLOCKED_NO_PREVIOUS_VERSION';
  static const String blockedTargetMismatch = 'BLOCKED_TARGET_MISMATCH';
  static const String blockedBackupUnverified = 'BLOCKED_BACKUP_UNVERIFIED';
  static const String blockedRestoreValidation = 'BLOCKED_RESTORE_VALIDATION';
  static const String blockedScopeMismatch = 'BLOCKED_SCOPE_MISMATCH';
  static const String blockedCoreIsolation = 'BLOCKED_CORE_ISOLATION';
  static const String blockedStale = 'BLOCKED_STALE';
  static const String blockedClockSkew = 'BLOCKED_CLOCK_SKEW';

  static const Set<String> values = <String>{
    ready,
    blockedInvalidInput,
    blockedNoPreviousVersion,
    blockedTargetMismatch,
    blockedBackupUnverified,
    blockedRestoreValidation,
    blockedScopeMismatch,
    blockedCoreIsolation,
    blockedStale,
    blockedClockSkew,
  };
}

class AgentVersionFullRolloutEligibilityStatus {
  AgentVersionFullRolloutEligibilityStatus._();

  static const String eligible = 'ELIGIBLE';
  static const String blockedVersionStatus = 'BLOCKED_VERSION_STATUS';
  static const String blockedMonitoring = 'BLOCKED_MONITORING';
  static const String blockedRollbackReadiness = 'BLOCKED_ROLLBACK_READINESS';
  static const String blockedOwnerApproval = 'BLOCKED_OWNER_APPROVAL';
  static const String blockedApprovalExpired = 'BLOCKED_APPROVAL_EXPIRED';
  static const String blockedIdentityMismatch = 'BLOCKED_IDENTITY_MISMATCH';
  static const String blockedInvalidInput = 'BLOCKED_INVALID_INPUT';
  static const String blockedClockSkew = 'BLOCKED_CLOCK_SKEW';

  static const Set<String> values = <String>{
    eligible,
    blockedVersionStatus,
    blockedMonitoring,
    blockedRollbackReadiness,
    blockedOwnerApproval,
    blockedApprovalExpired,
    blockedIdentityMismatch,
    blockedInvalidInput,
    blockedClockSkew,
  };
}

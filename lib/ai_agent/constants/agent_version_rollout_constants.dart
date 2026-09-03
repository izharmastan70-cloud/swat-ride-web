class AgentVersionTestEnvironmentPolicy {
  AgentVersionTestEnvironmentPolicy._();

  static const Duration maximumEvidenceAge = Duration(hours: 24);
  static const Duration maximumFutureClockSkew = Duration(minutes: 5);
}

class AgentVersionLimitedRolloutPolicy {
  AgentVersionLimitedRolloutPolicy._();

  static const double maximumEligiblePercent = 5;
  static const Duration maximumOwnerApprovalValidity = Duration(minutes: 30);
}

class AgentVersionTestReadinessStatus {
  AgentVersionTestReadinessStatus._();

  static const String ready = 'READY';
  static const String blockedInvalidEvidence = 'BLOCKED_INVALID_EVIDENCE';
  static const String blockedIdentityMismatch = 'BLOCKED_IDENTITY_MISMATCH';
  static const String blockedFailedChecks = 'BLOCKED_FAILED_CHECKS';
  static const String blockedPrivateData = 'BLOCKED_PRIVATE_DATA';
  static const String blockedProductionTraffic = 'BLOCKED_PRODUCTION_TRAFFIC';
  static const String blockedStaleEvidence = 'BLOCKED_STALE_EVIDENCE';
  static const String blockedClockSkew = 'BLOCKED_CLOCK_SKEW';

  static const Set<String> values = <String>{
    ready,
    blockedInvalidEvidence,
    blockedIdentityMismatch,
    blockedFailedChecks,
    blockedPrivateData,
    blockedProductionTraffic,
    blockedStaleEvidence,
    blockedClockSkew,
  };
}

class AgentVersionLimitedRolloutEligibilityStatus {
  AgentVersionLimitedRolloutEligibilityStatus._();

  static const String eligible = 'ELIGIBLE';
  static const String blockedVersionStatus = 'BLOCKED_VERSION_STATUS';
  static const String blockedTestEnvironment = 'BLOCKED_TEST_ENVIRONMENT';
  static const String blockedOwnerApproval = 'BLOCKED_OWNER_APPROVAL';
  static const String blockedApprovalExpired = 'BLOCKED_APPROVAL_EXPIRED';
  static const String blockedScopeMismatch = 'BLOCKED_SCOPE_MISMATCH';
  static const String blockedPercent = 'BLOCKED_PERCENT';
  static const String blockedClockSkew = 'BLOCKED_CLOCK_SKEW';
  static const String blockedInvalidInput = 'BLOCKED_INVALID_INPUT';

  static const Set<String> values = <String>{
    eligible,
    blockedVersionStatus,
    blockedTestEnvironment,
    blockedOwnerApproval,
    blockedApprovalExpired,
    blockedScopeMismatch,
    blockedPercent,
    blockedClockSkew,
    blockedInvalidInput,
  };
}

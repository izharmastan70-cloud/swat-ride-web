class AgentVersionRolloutMonitoringPolicy {
  AgentVersionRolloutMonitoringPolicy._();

  static const int minimumHealthyCompletedObservations = 20;
  static const Duration maximumObservationAge = Duration(minutes: 15);
  static const Duration maximumFutureClockSkew = Duration(minutes: 5);
}

class AgentVersionRolloutHealthStatus {
  AgentVersionRolloutHealthStatus._();

  static const String healthy = 'HEALTHY';
  static const String holdInsufficientEvidence = 'HOLD_INSUFFICIENT_EVIDENCE';
  static const String holdInvalidEvidence = 'HOLD_INVALID_EVIDENCE';
  static const String holdIdentityMismatch = 'HOLD_IDENTITY_MISMATCH';
  static const String holdStaleEvidence = 'HOLD_STALE_EVIDENCE';
  static const String holdClockSkew = 'HOLD_CLOCK_SKEW';
  static const String rollbackRequestRequired = 'ROLLBACK_REQUEST_REQUIRED';

  static const Set<String> values = <String>{
    healthy,
    holdInsufficientEvidence,
    holdInvalidEvidence,
    holdIdentityMismatch,
    holdStaleEvidence,
    holdClockSkew,
    rollbackRequestRequired,
  };
}

class AgentVersionRollbackTriggerStatus {
  AgentVersionRollbackTriggerStatus._();

  static const String notRequired = 'NOT_REQUIRED';
  static const String required = 'REQUIRED';
  static const String blockedNoKnownGoodVersion =
      'BLOCKED_NO_KNOWN_GOOD_VERSION';
  static const String blockedInvalidInput = 'BLOCKED_INVALID_INPUT';

  static const Set<String> values = <String>{
    notRequired,
    required,
    blockedNoKnownGoodVersion,
    blockedInvalidInput,
  };
}

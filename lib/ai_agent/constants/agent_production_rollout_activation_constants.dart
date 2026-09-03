class AgentProductionRolloutTrustedActorRole {
  AgentProductionRolloutTrustedActorRole._();

  static const String owner = 'OWNER';
  static const String superAdmin = 'SUPER_ADMIN';

  static const Set<String> allowed = <String>{owner, superAdmin};
}

class AgentProductionRolloutCaptureStatus {
  AgentProductionRolloutCaptureStatus._();

  static const String blockedUntrustedActor = 'BLOCKED_UNTRUSTED_ACTOR';
  static const String blockedStaleTrustedContext =
      'BLOCKED_STALE_TRUSTED_CONTEXT';
  static const String blockedFutureTrustedContext =
      'BLOCKED_FUTURE_TRUSTED_CONTEXT';
  static const String blockedReauthentication = 'BLOCKED_REAUTHENTICATION';
  static const String blockedLiveRead = 'BLOCKED_LIVE_READ';
  static const String captured = 'CAPTURED';
}

class AgentProductionRolloutMonitorPlanStatus {
  AgentProductionRolloutMonitorPlanStatus._();

  static const String blockedSnapshotPolicy = 'BLOCKED_SNAPSHOT_POLICY';
  static const String blockedEmptyRoleSet = 'BLOCKED_EMPTY_ROLE_SET';
  static const String blockedControlStateBinding =
      'BLOCKED_CONTROL_STATE_BINDING';
  static const String blockedAuditReadiness = 'BLOCKED_AUDIT_READINESS';
  static const String blockedCoreFailureIsolation =
      'BLOCKED_CORE_FAILURE_ISOLATION';
  static const String blockedProviderPolicy = 'BLOCKED_PROVIDER_POLICY';
  static const String blockedEmergencyClearance = 'BLOCKED_EMERGENCY_CLEARANCE';
  static const String eligibleMonitorOnlyPlan = 'ELIGIBLE_MONITOR_ONLY_PLAN';
}

class AgentProductionRolloutActivationLimits {
  AgentProductionRolloutActivationLimits._();

  static const Duration trustedContextMaxAge = Duration(minutes: 5);
  static const Duration trustedContextFutureSkew = Duration(minutes: 1);
  static const Duration atomicPreconditionMaxValidity = Duration(minutes: 2);

  static const int autoTrafficPercent = 0;
  static const int businessWriteTrafficPercent = 0;
}

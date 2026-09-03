class AgentProductionRolloutRepositoryPath {
  AgentProductionRolloutRepositoryPath._();

  static const String settingsCollection = 'agent_settings';
  static const String masterDocument = 'master';
  static const String rolloutStateDocument = 'production_rollout';
  static const String rolloutGuardDocument = 'production_rollout_guard';

  static const String activationsCollection =
      'agent_production_rollout_activations';
}

class AgentProductionRolloutRepositoryStatus {
  AgentProductionRolloutRepositoryStatus._();

  static const String blockedNotArmed = 'BLOCKED_NOT_ARMED';
  static const String blockedInvalidPlan = 'BLOCKED_INVALID_PLAN';
  static const String blockedExpiredPrecondition =
      'BLOCKED_EXPIRED_PRECONDITION';
  static const String blockedGuardMissing = 'BLOCKED_GUARD_MISSING';
  static const String blockedGuardDisabled = 'BLOCKED_GUARD_DISABLED';
  static const String blockedRuntimeOverlay = 'BLOCKED_RUNTIME_OVERLAY';
  static const String blockedNoAutoBoundary = 'BLOCKED_NO_AUTO_BOUNDARY';
  static const String blockedGuardRevision = 'BLOCKED_GUARD_REVISION';
  static const String blockedControlStateMismatch =
      'BLOCKED_CONTROL_STATE_MISMATCH';
  static const String blockedRoleCountMismatch = 'BLOCKED_ROLE_COUNT_MISMATCH';
  static const String blockedMasterMissing = 'BLOCKED_MASTER_MISSING';
  static const String blockedUnsafeMasterBaseline =
      'BLOCKED_UNSAFE_MASTER_BASELINE';
  static const String blockedExistingRolloutState =
      'BLOCKED_EXISTING_ROLLOUT_STATE';
  static const String blockedIdempotencyCollision =
      'BLOCKED_IDEMPOTENCY_COLLISION';
  static const String alreadyApplied = 'ALREADY_APPLIED';
  static const String appliedMonitorOnly = 'APPLIED_MONITOR_ONLY';

  static const Set<String> values = <String>{
    blockedNotArmed,
    blockedInvalidPlan,
    blockedExpiredPrecondition,
    blockedGuardMissing,
    blockedGuardDisabled,
    blockedRuntimeOverlay,
    blockedNoAutoBoundary,
    blockedGuardRevision,
    blockedControlStateMismatch,
    blockedRoleCountMismatch,
    blockedMasterMissing,
    blockedUnsafeMasterBaseline,
    blockedExistingRolloutState,
    blockedIdempotencyCollision,
    alreadyApplied,
    appliedMonitorOnly,
  };
}

class AgentProductionRolloutRepositoryRecordStatus {
  AgentProductionRolloutRepositoryRecordStatus._();

  static const String applied = 'APPLIED';
}

class AgentProductionRolloutGuardVersion {
  AgentProductionRolloutGuardVersion._();

  static const String monitorOnlyV1 = 'MONITOR_ONLY_GUARD_V1';
}

class AgentProductionRolloutMonitorPlanBinding {
  AgentProductionRolloutMonitorPlanBinding._();

  static const String algorithm = 'SHA256_MONITOR_PLAN_V1';
  static const String idempotencyAlgorithm = 'SHA256_MONITOR_IDEMPOTENCY_V1';
}

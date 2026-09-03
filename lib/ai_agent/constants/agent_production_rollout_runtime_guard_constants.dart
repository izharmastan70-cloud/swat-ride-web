class AgentProductionRolloutRuntimeGuardStatus {
  AgentProductionRolloutRuntimeGuardStatus._();

  static const String monitorOnly = 'MONITOR_ONLY';
}

class AgentProductionRolloutRuntimeGuardVersion {
  AgentProductionRolloutRuntimeGuardVersion._();

  static const String monitorOnlyV1 = 'MONITOR_ONLY_GUARD_V1';
}

class AgentProductionRolloutExternalModule {
  AgentProductionRolloutExternalModule._();

  static const Set<String> blockedDuringInitialMonitorOnly = <String>{
    'email',
    'customer_whatsapp',
    'owner_whatsapp',
    'emergency_whatsapp',
    'call',
    'voice_super_admin',
  };
}

class AgentProductionRolloutGuardPersistenceStatus {
  AgentProductionRolloutGuardPersistenceStatus._();

  static const String blockedNotArmed = 'BLOCKED_NOT_ARMED';
  static const String blockedInvalidGuard = 'BLOCKED_INVALID_GUARD';
  static const String blockedRevisionConflict = 'BLOCKED_REVISION_CONFLICT';
  static const String alreadyPersisted = 'ALREADY_PERSISTED';
  static const String persisted = 'PERSISTED';
}

class AgentProductionRolloutArmingReadinessStatus {
  AgentProductionRolloutArmingReadinessStatus._();

  static const String blockedOverlay = 'BLOCKED_OVERLAY';
  static const String blockedGuardPersistence = 'BLOCKED_GUARD_PERSISTENCE';
  static const String blockedRules = 'BLOCKED_RULES';
  static const String blockedRepositorySafety = 'BLOCKED_REPOSITORY_SAFETY';
  static const String readyForTrustedGuardPersistenceNotArmed =
      'READY_FOR_TRUSTED_GUARD_PERSISTENCE_NOT_ARMED';
  static const String readyToArmMonitorRepository =
      'READY_TO_ARM_MONITOR_REPOSITORY';
}

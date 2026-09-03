class AgentCrossAgentConflictType {
  AgentCrossAgentConflictType._();

  static const String none = 'NONE';
  static const String duplicateWork = 'DUPLICATE_WORK';
  static const String staleOrReplayWork = 'STALE_OR_REPLAY_WORK';
  static const String conflictingOutcome = 'CONFLICTING_OUTCOME';
  static const String wrongModule = 'WRONG_MODULE';
  static const String wrongScope = 'WRONG_SCOPE';
  static const String unauthorizedRoleWork = 'UNAUTHORIZED_ROLE_WORK';

  static const Set<String> values = <String>{
    none,
    duplicateWork,
    staleOrReplayWork,
    conflictingOutcome,
    wrongModule,
    wrongScope,
    unauthorizedRoleWork,
  };
}

class AgentCrossAgentWorkLifecycleStatus {
  AgentCrossAgentWorkLifecycleStatus._();

  static const String active = 'ACTIVE';
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';
  static const String expired = 'EXPIRED';

  static const Set<String> values = <String>{
    active,
    completed,
    cancelled,
    expired,
  };
}

class AgentCrossAgentSupervisorConflictLimits {
  AgentCrossAgentSupervisorConflictLimits._();

  static const int opaqueIdMaxLength = 220;
  static const int maxClaims = 12;
  static const int maxFindings = 20;
  static const int maxReasonCodes = 20;
}

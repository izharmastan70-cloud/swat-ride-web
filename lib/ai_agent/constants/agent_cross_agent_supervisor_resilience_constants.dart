class AgentCrossAgentSupervisorResilienceStatus {
  AgentCrossAgentSupervisorResilienceStatus._();

  static const String clean = 'CLEAN';
  static const String holdSecurity = 'HOLD_SECURITY';
  static const String holdLoop = 'HOLD_LOOP';
  static const String holdDeadlock = 'HOLD_DEADLOCK';
  static const String holdRetryStorm = 'HOLD_RETRY_STORM';
  static const String stopAgentFighting = 'STOP_AGENT_FIGHTING';
  static const String degradedProviderFailure = 'DEGRADED_PROVIDER_FAILURE';
  static const String degradedSupervisorFailure = 'DEGRADED_SUPERVISOR_FAILURE';
  static const String holdInvalidMetadata = 'HOLD_INVALID_METADATA';

  static const Set<String> values = <String>{
    clean,
    holdSecurity,
    holdLoop,
    holdDeadlock,
    holdRetryStorm,
    stopAgentFighting,
    degradedProviderFailure,
    degradedSupervisorFailure,
    holdInvalidMetadata,
  };
}

class AgentCrossAgentSupervisorResilienceLimits {
  AgentCrossAgentSupervisorResilienceLimits._();

  static const int opaqueIdMaxLength = 220;
  static const int maxHandoffHops = 24;

  static const int deadlockNoProgressCycles = 3;
  static const int excessiveHandoffThreshold = 8;

  static const int retryStormThreshold = 5;
  static const int repeatedFailureFingerprintThreshold = 3;

  static const int ownershipFlipThreshold = 3;
  static const int undoAttemptThreshold = 2;

  static const int maxReasonCodes = 20;
}

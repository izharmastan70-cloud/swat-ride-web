class AgentEcosystemResilienceDecisionStatus {
  AgentEcosystemResilienceDecisionStatus._();

  static const String blockUnrestrictedTraining = 'BLOCK_UNRESTRICTED_TRAINING';
  static const String blockEvaluationRequired = 'BLOCK_EVALUATION_REQUIRED';
  static const String blockOwnerApprovalRequired =
      'BLOCK_OWNER_APPROVAL_REQUIRED';
  static const String blockVersionBinding = 'BLOCK_VERSION_BINDING';
  static const String blockTestEnvironment = 'BLOCK_TEST_ENVIRONMENT';
  static const String blockAuditUnavailable = 'BLOCK_AUDIT_UNAVAILABLE';
  static const String blockCoreIsolationFailure =
      'BLOCK_CORE_ISOLATION_FAILURE';
  static const String blockRollbackTargetUnknown =
      'BLOCK_ROLLBACK_TARGET_UNKNOWN';
  static const String blockRollbackNotReady = 'BLOCK_ROLLBACK_NOT_READY';
  static const String rollbackRequestEligible = 'ROLLBACK_REQUEST_ELIGIBLE';
  static const String safeProviderFallbackEligible =
      'SAFE_PROVIDER_FALLBACK_ELIGIBLE';
  static const String aiUnavailableCoreContinues =
      'AI_UNAVAILABLE_CORE_CONTINUES';
  static const String monitoredHandoffEligible = 'MONITORED_HANDOFF_ELIGIBLE';

  static const Set<String> values = <String>{
    blockUnrestrictedTraining,
    blockEvaluationRequired,
    blockOwnerApprovalRequired,
    blockVersionBinding,
    blockTestEnvironment,
    blockAuditUnavailable,
    blockCoreIsolationFailure,
    blockRollbackTargetUnknown,
    blockRollbackNotReady,
    rollbackRequestEligible,
    safeProviderFallbackEligible,
    aiUnavailableCoreContinues,
    monitoredHandoffEligible,
  };
}

class AgentEcosystemResilienceRoute {
  AgentEcosystemResilienceRoute._();

  static const String blocked = 'BLOCKED';
  static const String evaluationGate = 'EVALUATION_GATE';
  static const String ownerApprovalGate = 'OWNER_APPROVAL_GATE';
  static const String versionGate = 'VERSION_GATE';
  static const String testEnvironmentGate = 'TEST_ENVIRONMENT_GATE';
  static const String auditGate = 'AUDIT_GATE';
  static const String rollbackReview = 'ROLLBACK_REVIEW';
  static const String providerFallbackReview = 'PROVIDER_FALLBACK_REVIEW';
  static const String aiUnavailable = 'AI_UNAVAILABLE';
  static const String monitoredHandoff = 'MONITORED_HANDOFF';
}

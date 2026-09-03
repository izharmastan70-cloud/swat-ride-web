class AgentEcosystemResilienceSafetyRequest {
  AgentEcosystemResilienceSafetyRequest({
    required this.rawConversationSelfTrainingRequested,
    required this.directProductionPromptReplacementRequested,
    required this.evaluationPassed,
    required this.ownerApprovalVerified,
    required this.exactVersionIdentityBound,
    required this.testEnvironmentPassed,
    required this.monitoringHealthy,
    required this.rollbackRequested,
    required this.knownGoodRollbackTargetExact,
    required this.rollbackReadinessVerified,
    required this.primaryProviderAvailable,
    required this.fallbackProviderAvailable,
    required this.fallbackPolicyAllows,
    required this.auditReady,
    required this.coreSwatRideIsolationVerified,
  });

  final bool rawConversationSelfTrainingRequested;
  final bool directProductionPromptReplacementRequested;

  final bool evaluationPassed;
  final bool ownerApprovalVerified;
  final bool exactVersionIdentityBound;
  final bool testEnvironmentPassed;

  final bool monitoringHealthy;
  final bool rollbackRequested;
  final bool knownGoodRollbackTargetExact;
  final bool rollbackReadinessVerified;

  final bool primaryProviderAvailable;
  final bool fallbackProviderAvailable;
  final bool fallbackPolicyAllows;

  final bool auditReady;
  final bool coreSwatRideIsolationVerified;

  bool get trainingDataGrantsAuthority => false;
  bool get requestIsEvaluationOnly => true;
}

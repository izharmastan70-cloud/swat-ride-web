class AgentVersioningFinalReadinessInput {
  const AgentVersioningFinalReadinessInput({
    required this.versionContractReady,
    required this.evaluationBindingReady,
    required this.testEnvironmentReady,
    required this.limitedRolloutReady,
    required this.monitoringRollbackReady,
    required this.fullRolloutEligibilityReady,
    required this.knownGoodRollbackReady,
    required this.phase42ImmutableEvidenceReady,
    required this.permissionBoundaryReady,
    required this.runtimeGateReady,
    required this.securityBoundaryReady,
    required this.coreAppIsolationReady,
    required this.callAgentExactFourReady,
    required this.productionActivationRequested,
    required this.deploymentRequested,
    required this.autoAuthorizationRequested,
  });

  final bool versionContractReady;
  final bool evaluationBindingReady;
  final bool testEnvironmentReady;
  final bool limitedRolloutReady;
  final bool monitoringRollbackReady;
  final bool fullRolloutEligibilityReady;
  final bool knownGoodRollbackReady;
  final bool phase42ImmutableEvidenceReady;

  final bool permissionBoundaryReady;
  final bool runtimeGateReady;
  final bool securityBoundaryReady;
  final bool coreAppIsolationReady;
  final bool callAgentExactFourReady;

  final bool productionActivationRequested;
  final bool deploymentRequested;
  final bool autoAuthorizationRequested;

  bool get foundationReady =>
      versionContractReady &&
      evaluationBindingReady &&
      testEnvironmentReady &&
      limitedRolloutReady &&
      monitoringRollbackReady &&
      fullRolloutEligibilityReady &&
      knownGoodRollbackReady &&
      phase42ImmutableEvidenceReady;

  bool get securityReady =>
      permissionBoundaryReady &&
      runtimeGateReady &&
      securityBoundaryReady &&
      coreAppIsolationReady &&
      callAgentExactFourReady;

  bool get forbiddenProductionActionRequested =>
      productionActivationRequested ||
      deploymentRequested ||
      autoAuthorizationRequested;
}

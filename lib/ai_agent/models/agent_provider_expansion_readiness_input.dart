class AgentProviderExpansionReadinessInput {
  const AgentProviderExpansionReadinessInput({
    required this.providerContractClean,
    required this.safeActivationBoundaryClean,
    required this.routingFailoverClean,
    required this.circuitBreakerClean,
    required this.coreAppFailureIsolationClean,
    required this.taskCapabilityMatrixClean,
    required this.modelCompatibilityClean,
    required this.contextTokenBoundaryClean,
    required this.privacyProjectionClean,
    required this.sensitiveTaskRestrictionClean,
    required this.trustedBackendHandoffClean,
    required this.usageAccountingClean,
    required this.costLogBoundaryClean,
    required this.paidControlsPreserved,
    required this.clientSecretsAbsent,
    required this.directProviderCallsAbsent,
    required this.permissionAuthorityAbsent,
    required this.approvalAuthorityAbsent,
    required this.businessAuthorityAbsent,
    required this.productionProviderConnectorConfigured,
    required this.productionCredentialsConfigured,
    required this.trustedBackendPersistenceConfigured,
  });

  final bool providerContractClean;
  final bool safeActivationBoundaryClean;
  final bool routingFailoverClean;
  final bool circuitBreakerClean;
  final bool coreAppFailureIsolationClean;
  final bool taskCapabilityMatrixClean;
  final bool modelCompatibilityClean;
  final bool contextTokenBoundaryClean;
  final bool privacyProjectionClean;
  final bool sensitiveTaskRestrictionClean;
  final bool trustedBackendHandoffClean;
  final bool usageAccountingClean;
  final bool costLogBoundaryClean;
  final bool paidControlsPreserved;
  final bool clientSecretsAbsent;
  final bool directProviderCallsAbsent;
  final bool permissionAuthorityAbsent;
  final bool approvalAuthorityAbsent;
  final bool businessAuthorityAbsent;

  /// These remain false in Phase 58 closeout.
  final bool productionProviderConnectorConfigured;
  final bool productionCredentialsConfigured;
  final bool trustedBackendPersistenceConfigured;

  bool get allSafetyContractsClean =>
      providerContractClean &&
      safeActivationBoundaryClean &&
      routingFailoverClean &&
      circuitBreakerClean &&
      coreAppFailureIsolationClean &&
      taskCapabilityMatrixClean &&
      modelCompatibilityClean &&
      contextTokenBoundaryClean &&
      privacyProjectionClean &&
      sensitiveTaskRestrictionClean &&
      trustedBackendHandoffClean &&
      usageAccountingClean &&
      costLogBoundaryClean &&
      paidControlsPreserved &&
      clientSecretsAbsent &&
      directProviderCallsAbsent &&
      permissionAuthorityAbsent &&
      approvalAuthorityAbsent &&
      businessAuthorityAbsent;

  bool get productionDependenciesConfigured =>
      productionProviderConnectorConfigured &&
      productionCredentialsConfigured &&
      trustedBackendPersistenceConfigured;
}

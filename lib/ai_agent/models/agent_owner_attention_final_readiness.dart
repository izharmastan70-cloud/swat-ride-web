class AgentOwnerAttentionFinalReadiness {
  const AgentOwnerAttentionFinalReadiness({
    required this.unifiedContractReady,
    required this.sourceAdaptersReady,
    required this.dedupeGateReady,
    required this.repositoryReady,
    required this.rulesReady,
    required this.reviewUiReady,
    required this.privacyBoundaryReady,
    required this.slaReady,
    required this.exactSnapshotBindingReady,
    required this.notificationBoundaryReady,
    required this.failureIsolationReady,
    required this.runtimeSecurityBoundaryReady,
  });

  final bool unifiedContractReady;
  final bool sourceAdaptersReady;
  final bool dedupeGateReady;
  final bool repositoryReady;
  final bool rulesReady;
  final bool reviewUiReady;
  final bool privacyBoundaryReady;
  final bool slaReady;
  final bool exactSnapshotBindingReady;
  final bool notificationBoundaryReady;
  final bool failureIsolationReady;
  final bool runtimeSecurityBoundaryReady;

  bool get allSafetyPillarsReady =>
      unifiedContractReady &&
      sourceAdaptersReady &&
      dedupeGateReady &&
      repositoryReady &&
      rulesReady &&
      reviewUiReady &&
      privacyBoundaryReady &&
      slaReady &&
      exactSnapshotBindingReady &&
      notificationBoundaryReady &&
      failureIsolationReady &&
      runtimeSecurityBoundaryReady;

  bool get phase64FoundationComplete => allSafetyPillarsReady;

  /// Final roadmap foundation can be complete without silently enabling
  /// background ingestion or external notification delivery.
  bool get productionRuntimeActivated => false;

  bool get automaticSourceIngestionActivated => false;
  bool get automaticNotificationDeliveryActivated => false;

  bool get approvalConsumptionAuthority => false;
  bool get permissionGrantAuthority => false;
  bool get runtimeGateOverrideAuthority => false;
  bool get providerExecutionAuthority => false;
  bool get sourceBusinessExecutionAuthority => false;
  bool get deploymentAuthority => false;

  bool get coreSwatRideDependencyIntroduced => false;
}

class AgentSecurityIncidentRuntimeActivationReadiness {
  const AgentSecurityIncidentRuntimeActivationReadiness({
    required this.status,
    required this.repositoryCodeReady,
    required this.rulesLive,
    required this.atomicAuditReady,
    required this.phase63RetentionReady,
    required this.writeGateReady,
    required this.authorizationChainReady,
    required this.repositoryCurrentlyDetached,
    required this.repositoryCurrentlyUnarmed,
    required this.liveCollectionCurrentlyInactive,
    required this.productionPersistenceCurrentlyInactive,
    required this.freshOwnerRuntimeActivationAuthorizationRequired,
    required this.freshOwnerRuntimeActivationAuthorizationPresent,
    required this.runtimeAttachmentAuthorized,
    required this.repositoryArmingAuthorized,
    required this.firstControlledIncidentWriteAuthorized,
    required this.productionPersistenceActivationAuthorized,
    required this.keepMonitorOnly,
    required this.suggestOnlyBlocked,
    required this.autoBlocked,
  });

  final String status;

  final bool repositoryCodeReady;
  final bool rulesLive;
  final bool atomicAuditReady;
  final bool phase63RetentionReady;
  final bool writeGateReady;
  final bool authorizationChainReady;

  final bool repositoryCurrentlyDetached;
  final bool repositoryCurrentlyUnarmed;
  final bool liveCollectionCurrentlyInactive;
  final bool productionPersistenceCurrentlyInactive;

  final bool freshOwnerRuntimeActivationAuthorizationRequired;
  final bool freshOwnerRuntimeActivationAuthorizationPresent;

  final bool runtimeAttachmentAuthorized;
  final bool repositoryArmingAuthorized;
  final bool firstControlledIncidentWriteAuthorized;
  final bool productionPersistenceActivationAuthorized;

  final bool keepMonitorOnly;
  final bool suggestOnlyBlocked;
  final bool autoBlocked;

  bool get readyForFreshOwnerRuntimeActivationDecision =>
      repositoryCodeReady &&
      rulesLive &&
      atomicAuditReady &&
      phase63RetentionReady &&
      writeGateReady &&
      authorizationChainReady &&
      repositoryCurrentlyDetached &&
      repositoryCurrentlyUnarmed &&
      liveCollectionCurrentlyInactive &&
      productionPersistenceCurrentlyInactive &&
      freshOwnerRuntimeActivationAuthorizationRequired &&
      !freshOwnerRuntimeActivationAuthorizationPresent;

  bool get writesFirestore => false;
  bool get readsLiveFirestore => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get createsIncident => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get changesEmergencyStop => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}

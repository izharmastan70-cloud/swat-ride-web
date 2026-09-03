class AgentSecurityIncidentRuntimeActivationOwnerGate {
  const AgentSecurityIncidentRuntimeActivationOwnerGate({
    required this.status,
    required this.offlineImplementationReady,
    required this.baseRulesLive,
    required this.replayProtectionReady,
    required this.replayProtectionRulesLive,
    required this.atomicAuditReady,
    required this.phase63RetentionReady,
    required this.writeGateReady,
    required this.repositoryDetached,
    required this.repositoryUnarmed,
    required this.productionPersistenceInactive,
    required this.freshLiveOwnerClaimPathVerified,
    required this.freshLiveOwnerClaimRequiredAgainAtExecution,
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

  final bool offlineImplementationReady;
  final bool baseRulesLive;
  final bool replayProtectionReady;
  final bool replayProtectionRulesLive;
  final bool atomicAuditReady;
  final bool phase63RetentionReady;
  final bool writeGateReady;

  final bool repositoryDetached;
  final bool repositoryUnarmed;
  final bool productionPersistenceInactive;

  // Q-C proved the production verification path works.
  // This is NOT a durable authentication assertion.
  final bool freshLiveOwnerClaimPathVerified;

  // auth_time freshness must be checked again immediately before activation.
  final bool freshLiveOwnerClaimRequiredAgainAtExecution;

  final bool freshOwnerRuntimeActivationAuthorizationRequired;
  final bool freshOwnerRuntimeActivationAuthorizationPresent;

  final bool runtimeAttachmentAuthorized;
  final bool repositoryArmingAuthorized;
  final bool firstControlledIncidentWriteAuthorized;
  final bool productionPersistenceActivationAuthorized;

  final bool keepMonitorOnly;
  final bool suggestOnlyBlocked;
  final bool autoBlocked;

  bool get readyForFreshOwnerRuntimeActivationAuthorizationDecision =>
      offlineImplementationReady &&
      baseRulesLive &&
      replayProtectionReady &&
      replayProtectionRulesLive &&
      atomicAuditReady &&
      phase63RetentionReady &&
      writeGateReady &&
      repositoryDetached &&
      repositoryUnarmed &&
      productionPersistenceInactive &&
      freshLiveOwnerClaimPathVerified &&
      freshLiveOwnerClaimRequiredAgainAtExecution &&
      freshOwnerRuntimeActivationAuthorizationRequired &&
      !freshOwnerRuntimeActivationAuthorizationPresent;

  bool get readsLiveFirestore => false;
  bool get writesFirestore => false;
  bool get readsLiveAuthToken => false;
  bool get mutatesAuthClaims => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get createsIncident => false;
  bool get createsIdempotencyReceipt => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get changesEmergencyStop => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}

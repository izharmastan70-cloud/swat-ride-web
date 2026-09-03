class AgentSecurityIncidentIdempotencyRulesDeploymentReadiness {
  const AgentSecurityIncidentIdempotencyRulesDeploymentReadiness({
    required this.status,
    required this.replayProtectionCodeReady,
    required this.idempotencyReceiptReady,
    required this.idempotencyRulesSourceReady,
    required this.phase63RetentionReady,
    required this.exactSourceEvidenceReady,
    required this.baseIncidentRulesAlreadyLive,
    required this.newIdempotencyRulesNotYetLive,
    required this.repositoryDetached,
    required this.repositoryUnarmed,
    required this.productionPersistenceInactive,
    required this.freshOwnerDeploymentAuthorizationRequired,
    required this.freshOwnerDeploymentAuthorizationPresent,
    required this.idempotencyRulesDeploymentAuthorized,
    required this.runtimeAttachmentAuthorized,
    required this.repositoryArmingAuthorized,
    required this.productionPersistenceActivationAuthorized,
    required this.keepMonitorOnly,
    required this.suggestOnlyBlocked,
    required this.autoBlocked,
  });

  final String status;

  final bool replayProtectionCodeReady;
  final bool idempotencyReceiptReady;
  final bool idempotencyRulesSourceReady;
  final bool phase63RetentionReady;
  final bool exactSourceEvidenceReady;

  final bool baseIncidentRulesAlreadyLive;
  final bool newIdempotencyRulesNotYetLive;

  final bool repositoryDetached;
  final bool repositoryUnarmed;
  final bool productionPersistenceInactive;

  final bool freshOwnerDeploymentAuthorizationRequired;
  final bool freshOwnerDeploymentAuthorizationPresent;

  final bool idempotencyRulesDeploymentAuthorized;
  final bool runtimeAttachmentAuthorized;
  final bool repositoryArmingAuthorized;
  final bool productionPersistenceActivationAuthorized;

  final bool keepMonitorOnly;
  final bool suggestOnlyBlocked;
  final bool autoBlocked;

  bool get readyForFreshOwnerRulesDeploymentDecision =>
      replayProtectionCodeReady &&
      idempotencyReceiptReady &&
      idempotencyRulesSourceReady &&
      phase63RetentionReady &&
      exactSourceEvidenceReady &&
      baseIncidentRulesAlreadyLive &&
      newIdempotencyRulesNotYetLive &&
      repositoryDetached &&
      repositoryUnarmed &&
      productionPersistenceInactive &&
      freshOwnerDeploymentAuthorizationRequired &&
      !freshOwnerDeploymentAuthorizationPresent;

  bool get writesFirestore => false;
  bool get readsLiveFirestore => false;
  bool get deploysRules => false;
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

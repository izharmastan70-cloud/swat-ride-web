class AgentSecurityIncidentPersistenceDeploymentReadiness {
  const AgentSecurityIncidentPersistenceDeploymentReadiness({
    required this.status,
    required this.repositoryCodeReady,
    required this.firestoreRulesSourceReady,
    required this.phase63RetentionReady,
    required this.atomicImmutableAuditReady,
    required this.repositoryFailClosedByDefault,
    required this.runtimeAttachmentAbsent,
    required this.firestoreRulesDeploymentAbsent,
    required this.liveCollectionActivationAbsent,
    required this.productionPersistenceInactive,
    required this.freshOwnerDeploymentAuthorizationRequired,
    required this.freshOwnerDeploymentAuthorizationPresent,
    required this.rulesDeploymentAuthorized,
    required this.runtimeAttachmentAuthorized,
    required this.liveCollectionActivationAuthorized,
    required this.productionPersistenceAuthorized,
    required this.keepMonitorOnly,
    required this.suggestOnlyBlocked,
    required this.autoBlocked,
  });

  final String status;

  final bool repositoryCodeReady;
  final bool firestoreRulesSourceReady;
  final bool phase63RetentionReady;
  final bool atomicImmutableAuditReady;
  final bool repositoryFailClosedByDefault;

  final bool runtimeAttachmentAbsent;
  final bool firestoreRulesDeploymentAbsent;
  final bool liveCollectionActivationAbsent;
  final bool productionPersistenceInactive;

  final bool freshOwnerDeploymentAuthorizationRequired;
  final bool freshOwnerDeploymentAuthorizationPresent;

  final bool rulesDeploymentAuthorized;
  final bool runtimeAttachmentAuthorized;
  final bool liveCollectionActivationAuthorized;
  final bool productionPersistenceAuthorized;

  final bool keepMonitorOnly;
  final bool suggestOnlyBlocked;
  final bool autoBlocked;

  bool get readyForFreshOwnerDeploymentDecision =>
      repositoryCodeReady &&
      firestoreRulesSourceReady &&
      phase63RetentionReady &&
      atomicImmutableAuditReady &&
      repositoryFailClosedByDefault &&
      runtimeAttachmentAbsent &&
      firestoreRulesDeploymentAbsent &&
      liveCollectionActivationAbsent &&
      productionPersistenceInactive &&
      freshOwnerDeploymentAuthorizationRequired &&
      !freshOwnerDeploymentAuthorizationPresent;

  bool get writesFirestore => false;
  bool get readsLiveFirestore => false;
  bool get deploysFirestoreRules => false;
  bool get createsCollection => false;
  bool get attachesRuntime => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get changesEmergencyStop => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}

class AgentProductionRolloutIncidentPersistenceAuthorizationDecision {
  const AgentProductionRolloutIncidentPersistenceAuthorizationDecision({
    required this.disposition,
    required this.phase54FoundationOnly,
    required this.phase54ProductionPersistenceIntentionallyAbsent,
    required this.phase65ProductionActivationAuthorityAbsent,
    required this.phase66OwnsControlledRollout,
    required this.phase63PrivacyRetentionRemainsAuthoritative,
    required this.dedicatedIncidentCollectionExists,
    required this.phase66MayInventIncidentPersistence,
    required this.requiresSeparateExplicitImplementationAuthority,
    required this.existingPersistedObservationMayContinue,
    required this.persistedObservationSources,
    required this.blocksSuggestOnly,
    required this.blocksAuto,
  });

  final String disposition;
  final bool phase54FoundationOnly;
  final bool phase54ProductionPersistenceIntentionallyAbsent;
  final bool phase65ProductionActivationAuthorityAbsent;
  final bool phase66OwnsControlledRollout;
  final bool phase63PrivacyRetentionRemainsAuthoritative;
  final bool dedicatedIncidentCollectionExists;
  final bool phase66MayInventIncidentPersistence;
  final bool requiresSeparateExplicitImplementationAuthority;
  final bool existingPersistedObservationMayContinue;
  final Set<String> persistedObservationSources;
  final bool blocksSuggestOnly;
  final bool blocksAuto;

  bool get createsIncidentCollection => false;
  bool get writesFirestore => false;
  bool get changesFirestoreRules => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get changesEmergencyStop => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
}

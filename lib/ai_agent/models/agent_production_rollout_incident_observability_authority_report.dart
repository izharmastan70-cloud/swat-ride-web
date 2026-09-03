class AgentProductionRolloutIncidentObservabilityAuthorityReport {
  const AgentProductionRolloutIncidentObservabilityAuthorityReport({
    required this.disposition,
    required this.phase54FoundationOnly,
    required this.dedicatedIncidentPersistenceAuthorityPresent,
    required this.newIncidentCollectionCreationAuthorized,
    required this.persistedOperationalSignalSources,
    required this.claimsDedicatedIncidentCountZero,
    required this.monitorOnlyObservationCanContinue,
    required this.blocksSuggestOnly,
    required this.blocksAuto,
  });

  final String disposition;
  final bool phase54FoundationOnly;
  final bool dedicatedIncidentPersistenceAuthorityPresent;
  final bool newIncidentCollectionCreationAuthorized;
  final Set<String> persistedOperationalSignalSources;
  final bool claimsDedicatedIncidentCountZero;
  final bool monitorOnlyObservationCanContinue;
  final bool blocksSuggestOnly;
  final bool blocksAuto;

  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
  bool get writesFirestore => false;
  bool get changesFirestoreRules => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get changesProductionState => false;
}

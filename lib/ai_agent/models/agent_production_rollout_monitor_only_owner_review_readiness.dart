class AgentProductionRolloutMonitorOnlyOwnerReviewReadiness {
  const AgentProductionRolloutMonitorOnlyOwnerReviewReadiness({
    required this.status,
    required this.monitorOnlyObservationComplete,
    required this.coreStabilityVerified,
    required this.persistedOperationalSignalsClear,
    required this.incidentPersistenceAuthorityGapPresent,
    required this.separateExplicitImplementationAuthorityRequired,
    required this.ownerReviewRequired,
    required this.freshOwnerDecisionRequiredBeforeAnyAdvance,
    required this.keepMonitorOnly,
    required this.suggestOnlyAdvancementBlocked,
    required this.autoAdvancementBlocked,
  });

  final String status;
  final bool monitorOnlyObservationComplete;
  final bool coreStabilityVerified;
  final bool persistedOperationalSignalsClear;
  final bool incidentPersistenceAuthorityGapPresent;
  final bool separateExplicitImplementationAuthorityRequired;
  final bool ownerReviewRequired;
  final bool freshOwnerDecisionRequiredBeforeAnyAdvance;
  final bool keepMonitorOnly;
  final bool suggestOnlyAdvancementBlocked;
  final bool autoAdvancementBlocked;

  bool get readyForOwnerReview =>
      monitorOnlyObservationComplete &&
      coreStabilityVerified &&
      persistedOperationalSignalsClear &&
      ownerReviewRequired &&
      keepMonitorOnly;

  bool get mayAdvanceToSuggestOnly => false;
  bool get mayAdvanceToAuto => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get writesFirestore => false;
  bool get changesFirestoreRules => false;
  bool get changesEmergencyStop => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}

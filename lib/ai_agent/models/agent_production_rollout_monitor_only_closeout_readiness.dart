class AgentProductionRolloutMonitorOnlyCloseoutReadiness {
  const AgentProductionRolloutMonitorOnlyCloseoutReadiness({
    required this.status,
    required this.coreObservationStable,
    required this.persistedOperationalSignalsClear,
    required this.unclassifiedCriticalAuditCount,
    required this.openCriticalCrashCount,
    required this.emergencyOwnerAttentionCount,
    required this.monitorOnlyObservationComplete,
    required this.incidentPersistenceAuthorityGapPresent,
    required this.separateExplicitImplementationAuthorityRequired,
    required this.suggestOnlyAdvancementBlocked,
    required this.autoAdvancementBlocked,
  });

  final String status;
  final bool coreObservationStable;
  final bool persistedOperationalSignalsClear;
  final int unclassifiedCriticalAuditCount;
  final int openCriticalCrashCount;
  final int emergencyOwnerAttentionCount;
  final bool monitorOnlyObservationComplete;
  final bool incidentPersistenceAuthorityGapPresent;
  final bool separateExplicitImplementationAuthorityRequired;
  final bool suggestOnlyAdvancementBlocked;
  final bool autoAdvancementBlocked;

  bool get canAdvanceToSuggestOnly => false;
  bool get canAdvanceToAuto => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get writesFirestore => false;
  bool get changesEmergencyStop => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}

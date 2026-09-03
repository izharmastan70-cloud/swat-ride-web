import '../models/agent_production_rollout_monitor_only_closeout_readiness.dart';

class AgentProductionRolloutMonitorOnlyCloseoutPolicy {
  const AgentProductionRolloutMonitorOnlyCloseoutPolicy();

  static const String cleanBlockedStatus =
      'MONITOR_ONLY_OBSERVATION_COMPLETE_ADVANCEMENT_BLOCKED';

  static const String unsafeStatus = 'MONITOR_ONLY_OBSERVATION_NOT_CLEAN';

  AgentProductionRolloutMonitorOnlyCloseoutReadiness evaluate({
    required bool coreObservationStable,
    required bool persistedOperationalSignalsClear,
    required int unclassifiedCriticalAuditCount,
    required int openCriticalCrashCount,
    required int emergencyOwnerAttentionCount,
    required bool incidentPersistenceAuthorityGapPresent,
    required bool separateExplicitImplementationAuthorityRequired,
  }) {
    final bool clean =
        coreObservationStable &&
        persistedOperationalSignalsClear &&
        unclassifiedCriticalAuditCount == 0 &&
        openCriticalCrashCount == 0 &&
        emergencyOwnerAttentionCount == 0;

    return AgentProductionRolloutMonitorOnlyCloseoutReadiness(
      status: clean ? cleanBlockedStatus : unsafeStatus,
      coreObservationStable: coreObservationStable,
      persistedOperationalSignalsClear: persistedOperationalSignalsClear,
      unclassifiedCriticalAuditCount: unclassifiedCriticalAuditCount,
      openCriticalCrashCount: openCriticalCrashCount,
      emergencyOwnerAttentionCount: emergencyOwnerAttentionCount,
      monitorOnlyObservationComplete: clean,
      incidentPersistenceAuthorityGapPresent:
          incidentPersistenceAuthorityGapPresent,
      separateExplicitImplementationAuthorityRequired:
          separateExplicitImplementationAuthorityRequired,
      suggestOnlyAdvancementBlocked: true,
      autoAdvancementBlocked: true,
    );
  }

  bool get writesFirestore => false;
  bool get changesFirestoreRules => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get changesEmergencyStop => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}

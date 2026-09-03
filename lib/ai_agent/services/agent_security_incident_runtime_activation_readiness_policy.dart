import '../models/agent_security_incident_runtime_activation_readiness.dart';

class AgentSecurityIncidentRuntimeActivationReadinessPolicy {
  const AgentSecurityIncidentRuntimeActivationReadinessPolicy();

  static const String readyAwaitingFreshOwner =
      'RUNTIME_ACTIVATION_READY_AWAITING_FRESH_OWNER_AUTHORIZATION';

  static const String notReady = 'RUNTIME_ACTIVATION_READINESS_NOT_SATISFIED';

  AgentSecurityIncidentRuntimeActivationReadiness evaluate({
    required bool repositoryCodeReady,
    required bool rulesLive,
    required bool atomicAuditReady,
    required bool phase63RetentionReady,
    required bool writeGateReady,
    required bool authorizationChainReady,
    required bool repositoryCurrentlyDetached,
    required bool repositoryCurrentlyUnarmed,
    required bool liveCollectionCurrentlyInactive,
    required bool productionPersistenceCurrentlyInactive,
  }) {
    final bool ready =
        repositoryCodeReady &&
        rulesLive &&
        atomicAuditReady &&
        phase63RetentionReady &&
        writeGateReady &&
        authorizationChainReady &&
        repositoryCurrentlyDetached &&
        repositoryCurrentlyUnarmed &&
        liveCollectionCurrentlyInactive &&
        productionPersistenceCurrentlyInactive;

    return AgentSecurityIncidentRuntimeActivationReadiness(
      status: ready ? readyAwaitingFreshOwner : notReady,
      repositoryCodeReady: repositoryCodeReady,
      rulesLive: rulesLive,
      atomicAuditReady: atomicAuditReady,
      phase63RetentionReady: phase63RetentionReady,
      writeGateReady: writeGateReady,
      authorizationChainReady: authorizationChainReady,
      repositoryCurrentlyDetached: repositoryCurrentlyDetached,
      repositoryCurrentlyUnarmed: repositoryCurrentlyUnarmed,
      liveCollectionCurrentlyInactive: liveCollectionCurrentlyInactive,
      productionPersistenceCurrentlyInactive:
          productionPersistenceCurrentlyInactive,
      freshOwnerRuntimeActivationAuthorizationRequired: true,
      freshOwnerRuntimeActivationAuthorizationPresent: false,
      runtimeAttachmentAuthorized: false,
      repositoryArmingAuthorized: false,
      firstControlledIncidentWriteAuthorized: false,
      productionPersistenceActivationAuthorized: false,
      keepMonitorOnly: true,
      suggestOnlyBlocked: true,
      autoBlocked: true,
    );
  }

  bool get gateOnly => true;
  bool get writesFirestore => false;
  bool get readsLiveFirestore => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get createsIncident => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get changesEmergencyStop => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}

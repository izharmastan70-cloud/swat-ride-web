abstract final class AgentSecurityIncidentPersistenceDeploymentEvidence {
  static const String projectId = 'swat-ride-v2';

  static const String deploymentStep = 'PHASE66_STEP1I_H_V2';

  static const String deploymentScope = 'firestore:rules';

  static const String rulesSha256 =
      '9C40BD9AE6D19E24A63869788B0F56394B535C94EF57669C171D3AFEEE11A813';

  static const String status =
      'FIRESTORE_RULES_DEPLOY_REPORTED_COMPLETE_AND_LOCAL_SOURCE_MATCHED';

  // Evidence basis:
  // - Firebase CLI final dry-run succeeded.
  // - Firebase CLI reported rules upload/release and "Deploy complete!".
  // - local source hash remained unchanged after deployment.
  //
  // This record does NOT claim any incident document exists and does NOT
  // authorize repository runtime attachment or production incident writes.
  static const bool firebaseCliReportedDeployComplete = true;
  static const bool localRulesSourceMatchedDeployedSource = true;

  static const bool incidentDataWritten = false;
  static const bool repositoryRuntimeAttached = false;
  static const bool repositoryExecutionArmed = false;
  static const bool liveCollectionActivatedByDataWrite = false;
  static const bool productionPersistenceActive = false;

  static const bool changesRolloutStage = false;
  static const bool changesAgentMode = false;
  static const bool changesEmergencyStop = false;
  static const bool authorizesSuggestOnly = false;
  static const bool authorizesAuto = false;
}

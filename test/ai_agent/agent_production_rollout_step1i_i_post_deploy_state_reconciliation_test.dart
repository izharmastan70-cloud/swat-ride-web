import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_persistence_deployment_evidence.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_persistence_implementation_state.dart';

void main() {
  test('Step1I-H deployment evidence identifies exact project and scope', () {
    expect(
      AgentSecurityIncidentPersistenceDeploymentEvidence.projectId,
      'swat-ride-v2',
    );
    expect(
      AgentSecurityIncidentPersistenceDeploymentEvidence.deploymentStep,
      'PHASE66_STEP1I_H_V2',
    );
    expect(
      AgentSecurityIncidentPersistenceDeploymentEvidence.deploymentScope,
      'firestore:rules',
    );
  });

  test('deployment evidence locks exact audited rules hash', () {
    expect(
      AgentSecurityIncidentPersistenceDeploymentEvidence.rulesSha256,
      '9C40BD9AE6D19E24A63869788B0F56394B535C94EF57669C171D3AFEEE11A813',
    );
  });

  test('Firebase CLI deployment completion is recorded', () {
    expect(
      AgentSecurityIncidentPersistenceDeploymentEvidence
          .firebaseCliReportedDeployComplete,
      isTrue,
    );
    expect(
      AgentSecurityIncidentPersistenceDeploymentEvidence
          .localRulesSourceMatchedDeployedSource,
      isTrue,
    );
  });

  test('local implementation state now records rules deployed', () {
    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .firestoreRulesDeployed,
      isTrue,
    );
  });

  test('repository remains detached after rules deployment', () {
    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .repositoryRuntimeAttached,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceDeploymentEvidence
          .repositoryRuntimeAttached,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceDeploymentEvidence
          .repositoryExecutionArmed,
      isFalse,
    );
  });

  test('live incident collection is not activated by rules deploy', () {
    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .liveCollectionActivated,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceDeploymentEvidence
          .liveCollectionActivatedByDataWrite,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceDeploymentEvidence.incidentDataWritten,
      isFalse,
    );
  });

  test('production incident persistence remains inactive', () {
    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .productionPersistenceActive,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceDeploymentEvidence
          .productionPersistenceActive,
      isFalse,
    );
  });

  test('rollout and AgentMode remain unchanged', () {
    expect(
      AgentSecurityIncidentPersistenceImplementationState.changesRolloutStage,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceImplementationState.changesAgentMode,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceImplementationState.changesEmergencyStop,
      isFalse,
    );

    expect(
      AgentSecurityIncidentPersistenceDeploymentEvidence.changesRolloutStage,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceDeploymentEvidence.changesAgentMode,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceDeploymentEvidence.changesEmergencyStop,
      isFalse,
    );
  });

  test('SUGGEST_ONLY and AUTO remain unauthorized', () {
    expect(
      AgentSecurityIncidentPersistenceImplementationState.authorizesSuggestOnly,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceImplementationState.authorizesAuto,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceDeploymentEvidence.authorizesSuggestOnly,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceDeploymentEvidence.authorizesAuto,
      isFalse,
    );
  });

  test('rules deployment does not imply runtime activation authority', () {
    expect(
      AgentSecurityIncidentPersistenceDeploymentEvidence.status,
      'FIRESTORE_RULES_DEPLOY_REPORTED_COMPLETE_AND_LOCAL_SOURCE_MATCHED',
    );
    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .repositoryRuntimeAttached,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .liveCollectionActivated,
      isFalse,
    );
    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .productionPersistenceActive,
      isFalse,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_idempotency_rules_deployment_evidence.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_persistence_implementation_state.dart';

void main() {
  test('Step1I-N deployment evidence identifies exact project and scope', () {
    expect(
      AgentSecurityIncidentIdempotencyRulesDeploymentEvidence.projectId,
      'swat-ride-v2',
    );
    expect(
      AgentSecurityIncidentIdempotencyRulesDeploymentEvidence.deploymentStep,
      'PHASE66_STEP1I_N',
    );
    expect(
      AgentSecurityIncidentIdempotencyRulesDeploymentEvidence.deploymentScope,
      'firestore:rules',
    );
  });

  test('deployment evidence locks exact audited replay-rules SHA', () {
    expect(
      AgentSecurityIncidentIdempotencyRulesDeploymentEvidence.rulesSha256,
      '605A423170A1D4CBD3FC2767E6660619B77DDBB988F78FDF09938182B6F97E9B',
    );
  });

  test('Firebase CLI deployment completion and dry-run are recorded', () {
    expect(
      AgentSecurityIncidentIdempotencyRulesDeploymentEvidence
          .firebaseCliReportedDeployComplete,
      isTrue,
    );
    expect(
      AgentSecurityIncidentIdempotencyRulesDeploymentEvidence
          .finalDryRunReportedClean,
      isTrue,
    );
    expect(
      AgentSecurityIncidentIdempotencyRulesDeploymentEvidence
          .localRulesSourceMatchedDeploymentSource,
      isTrue,
    );
  });

  test('local state now records replay-protection rules deployed', () {
    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .persistentIdempotencyReplayRulesDeployed,
      isTrue,
    );
  });

  test('replay-rules-pending runtime blocker is reconciled clear', () {
    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .runtimeActivationBlockedByReplayProtectionRulesPending,
      isFalse,
    );
  });

  test('replay-protection code remains implemented', () {
    expect(
      AgentSecurityIncidentPersistenceImplementationState
          .persistentIdempotencyReplayProtectionImplemented,
      isTrue,
    );
  });

  test('repository remains detached and production persistence inactive', () {
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
    expect(
      AgentSecurityIncidentIdempotencyRulesDeploymentEvidence
          .repositoryRuntimeAttached,
      isFalse,
    );
    expect(
      AgentSecurityIncidentIdempotencyRulesDeploymentEvidence
          .repositoryExecutionArmed,
      isFalse,
    );
  });

  test('deployment evidence records zero incident/idempotency data writes', () {
    expect(
      AgentSecurityIncidentIdempotencyRulesDeploymentEvidence
          .incidentDataWritten,
      isFalse,
    );
    expect(
      AgentSecurityIncidentIdempotencyRulesDeploymentEvidence
          .idempotencyDataWritten,
      isFalse,
    );
  });

  test('rollout, AgentMode and Emergency Stop remain unchanged', () {
    expect(
      AgentSecurityIncidentIdempotencyRulesDeploymentEvidence
          .changesRolloutStage,
      isFalse,
    );
    expect(
      AgentSecurityIncidentIdempotencyRulesDeploymentEvidence.changesAgentMode,
      isFalse,
    );
    expect(
      AgentSecurityIncidentIdempotencyRulesDeploymentEvidence
          .changesEmergencyStop,
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
      AgentSecurityIncidentIdempotencyRulesDeploymentEvidence
          .authorizesSuggestOnly,
      isFalse,
    );
    expect(
      AgentSecurityIncidentIdempotencyRulesDeploymentEvidence.authorizesAuto,
      isFalse,
    );
  });
}

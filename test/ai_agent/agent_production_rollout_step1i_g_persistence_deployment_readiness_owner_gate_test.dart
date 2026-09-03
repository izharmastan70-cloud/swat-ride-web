import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_persistence_deployment_readiness.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_persistence_deployment_readiness_policy.dart';

void main() {
  const policy = AgentSecurityIncidentPersistenceDeploymentReadinessPolicy();

  AgentSecurityIncidentPersistenceDeploymentReadiness ready() {
    return policy.evaluate(
      repositoryCodeReady: true,
      firestoreRulesSourceReady: true,
      phase63RetentionReady: true,
      atomicImmutableAuditReady: true,
      repositoryFailClosedByDefault: true,
      runtimeAttachmentAbsent: true,
      firestoreRulesDeploymentAbsent: true,
      liveCollectionActivationAbsent: true,
      productionPersistenceInactive: true,
    );
  }

  test(
    'offline implementation is ready for fresh Owner deployment decision',
    () {
      final result = ready();

      expect(
        result.status,
        AgentSecurityIncidentPersistenceDeploymentReadinessPolicy
            .readyAwaitingOwner,
      );
      expect(result.readyForFreshOwnerDeploymentDecision, isTrue);
    },
  );

  test('fresh Owner deployment authorization is required and absent', () {
    final result = ready();

    expect(result.freshOwnerDeploymentAuthorizationRequired, isTrue);
    expect(result.freshOwnerDeploymentAuthorizationPresent, isFalse);
  });

  test('rules deployment is not authorized by readiness gate', () {
    final result = ready();

    expect(result.rulesDeploymentAuthorized, isFalse);
    expect(result.deploysFirestoreRules, isFalse);
    expect(policy.deploysFirestoreRules, isFalse);
  });

  test('runtime attachment is not authorized by readiness gate', () {
    final result = ready();

    expect(result.runtimeAttachmentAuthorized, isFalse);
    expect(result.attachesRuntime, isFalse);
    expect(policy.attachesRuntime, isFalse);
  });

  test('live collection activation is not authorized', () {
    final result = ready();

    expect(result.liveCollectionActivationAuthorized, isFalse);
    expect(result.createsCollection, isFalse);
    expect(policy.createsCollection, isFalse);
  });

  test('production persistence remains unauthorized and inactive', () {
    final result = ready();

    expect(result.productionPersistenceAuthorized, isFalse);
    expect(result.productionPersistenceInactive, isTrue);
  });

  test('MONITOR_ONLY remains locked', () {
    final result = ready();

    expect(result.keepMonitorOnly, isTrue);
    expect(result.changesRolloutStage, isFalse);
    expect(result.changesAgentMode, isFalse);
    expect(policy.changesRolloutStage, isFalse);
    expect(policy.changesAgentMode, isFalse);
  });

  test('SUGGEST_ONLY and AUTO remain blocked', () {
    final result = ready();

    expect(result.suggestOnlyBlocked, isTrue);
    expect(result.autoBlocked, isTrue);
    expect(result.authorizesSuggestOnly, isFalse);
    expect(result.authorizesAuto, isFalse);
    expect(policy.authorizesSuggestOnly, isFalse);
    expect(policy.authorizesAuto, isFalse);
  });

  test('missing atomic audit readiness blocks deployment readiness', () {
    final result = policy.evaluate(
      repositoryCodeReady: true,
      firestoreRulesSourceReady: true,
      phase63RetentionReady: true,
      atomicImmutableAuditReady: false,
      repositoryFailClosedByDefault: true,
      runtimeAttachmentAbsent: true,
      firestoreRulesDeploymentAbsent: true,
      liveCollectionActivationAbsent: true,
      productionPersistenceInactive: true,
    );

    expect(
      result.status,
      AgentSecurityIncidentPersistenceDeploymentReadinessPolicy.notReady,
    );
    expect(result.readyForFreshOwnerDeploymentDecision, isFalse);
  });

  test('already deployed or active state is not pre-deployment ready', () {
    final deployed = policy.evaluate(
      repositoryCodeReady: true,
      firestoreRulesSourceReady: true,
      phase63RetentionReady: true,
      atomicImmutableAuditReady: true,
      repositoryFailClosedByDefault: true,
      runtimeAttachmentAbsent: true,
      firestoreRulesDeploymentAbsent: false,
      liveCollectionActivationAbsent: true,
      productionPersistenceInactive: true,
    );

    final active = policy.evaluate(
      repositoryCodeReady: true,
      firestoreRulesSourceReady: true,
      phase63RetentionReady: true,
      atomicImmutableAuditReady: true,
      repositoryFailClosedByDefault: true,
      runtimeAttachmentAbsent: false,
      firestoreRulesDeploymentAbsent: true,
      liveCollectionActivationAbsent: false,
      productionPersistenceInactive: false,
    );

    expect(deployed.readyForFreshOwnerDeploymentDecision, isFalse);
    expect(active.readyForFreshOwnerDeploymentDecision, isFalse);
  });

  test(
    'gate has zero Firebase, Approval, Permission or Emergency mutation',
    () {
      final result = ready();

      expect(result.writesFirestore, isFalse);
      expect(result.readsLiveFirestore, isFalse);
      expect(result.changesEmergencyStop, isFalse);
      expect(result.createsApproval, isFalse);
      expect(result.consumesApproval, isFalse);
      expect(result.grantsPermission, isFalse);

      expect(policy.writesFirestore, isFalse);
      expect(policy.readsLiveFirestore, isFalse);
      expect(policy.changesEmergencyStop, isFalse);
      expect(policy.invokesPermissionEngine, isFalse);
      expect(policy.invokesApprovalEngine, isFalse);
      expect(policy.createsApproval, isFalse);
      expect(policy.consumesApproval, isFalse);
      expect(policy.grantsPermission, isFalse);
    },
  );
}

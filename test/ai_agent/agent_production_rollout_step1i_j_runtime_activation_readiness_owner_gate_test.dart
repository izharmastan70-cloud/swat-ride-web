import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_runtime_activation_readiness.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_runtime_activation_readiness_policy.dart';

void main() {
  const policy = AgentSecurityIncidentRuntimeActivationReadinessPolicy();

  AgentSecurityIncidentRuntimeActivationReadiness ready() {
    return policy.evaluate(
      repositoryCodeReady: true,
      rulesLive: true,
      atomicAuditReady: true,
      phase63RetentionReady: true,
      writeGateReady: true,
      authorizationChainReady: true,
      repositoryCurrentlyDetached: true,
      repositoryCurrentlyUnarmed: true,
      liveCollectionCurrentlyInactive: true,
      productionPersistenceCurrentlyInactive: true,
    );
  }

  test('runtime activation readiness reaches fresh Owner decision gate', () {
    final result = ready();

    expect(
      result.status,
      AgentSecurityIncidentRuntimeActivationReadinessPolicy
          .readyAwaitingFreshOwner,
    );
    expect(result.readyForFreshOwnerRuntimeActivationDecision, isTrue);
  });

  test('fresh Owner runtime authorization is required and absent', () {
    final result = ready();

    expect(result.freshOwnerRuntimeActivationAuthorizationRequired, isTrue);
    expect(result.freshOwnerRuntimeActivationAuthorizationPresent, isFalse);
  });

  test('readiness gate does not attach runtime', () {
    final result = ready();

    expect(result.runtimeAttachmentAuthorized, isFalse);
    expect(result.attachesRuntime, isFalse);
    expect(policy.attachesRuntime, isFalse);
  });

  test('readiness gate does not arm repository', () {
    final result = ready();

    expect(result.repositoryArmingAuthorized, isFalse);
    expect(result.armsRepository, isFalse);
    expect(policy.armsRepository, isFalse);
  });

  test('first controlled incident write remains unauthorized', () {
    final result = ready();

    expect(result.firstControlledIncidentWriteAuthorized, isFalse);
    expect(result.createsIncident, isFalse);
    expect(policy.createsIncident, isFalse);
  });

  test('production persistence activation remains unauthorized', () {
    final result = ready();

    expect(result.productionPersistenceActivationAuthorized, isFalse);
    expect(result.productionPersistenceCurrentlyInactive, isTrue);
  });

  test('MONITOR_ONLY remains locked', () {
    final result = ready();

    expect(result.keepMonitorOnly, isTrue);
    expect(result.changesRolloutStage, isFalse);
    expect(result.changesAgentMode, isFalse);
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

  test('missing live rules blocks runtime activation readiness', () {
    final result = policy.evaluate(
      repositoryCodeReady: true,
      rulesLive: false,
      atomicAuditReady: true,
      phase63RetentionReady: true,
      writeGateReady: true,
      authorizationChainReady: true,
      repositoryCurrentlyDetached: true,
      repositoryCurrentlyUnarmed: true,
      liveCollectionCurrentlyInactive: true,
      productionPersistenceCurrentlyInactive: true,
    );

    expect(
      result.status,
      AgentSecurityIncidentRuntimeActivationReadinessPolicy.notReady,
    );
    expect(result.readyForFreshOwnerRuntimeActivationDecision, isFalse);
  });

  test('already armed/attached/active state is not pre-activation ready', () {
    final attached = policy.evaluate(
      repositoryCodeReady: true,
      rulesLive: true,
      atomicAuditReady: true,
      phase63RetentionReady: true,
      writeGateReady: true,
      authorizationChainReady: true,
      repositoryCurrentlyDetached: false,
      repositoryCurrentlyUnarmed: false,
      liveCollectionCurrentlyInactive: false,
      productionPersistenceCurrentlyInactive: false,
    );

    expect(attached.readyForFreshOwnerRuntimeActivationDecision, isFalse);
  });

  test('gate performs no Firebase/Approval/Permission/Emergency mutation', () {
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
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_runtime_activation_owner_gate.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_runtime_activation_owner_gate_policy.dart';

void main() {
  const policy = AgentSecurityIncidentRuntimeActivationOwnerGatePolicy();

  AgentSecurityIncidentRuntimeActivationOwnerGate ready() {
    return policy.evaluate(
      offlineImplementationReady: true,
      baseRulesLive: true,
      replayProtectionReady: true,
      replayProtectionRulesLive: true,
      atomicAuditReady: true,
      phase63RetentionReady: true,
      writeGateReady: true,
      repositoryDetached: true,
      repositoryUnarmed: true,
      productionPersistenceInactive: true,
      freshLiveOwnerClaimPathVerified: true,
    );
  }

  test('final gate reaches fresh Owner explicit authorization boundary', () {
    final result = ready();

    expect(
      result.status,
      AgentSecurityIncidentRuntimeActivationOwnerGatePolicy
          .readyAwaitingFreshOwnerAuthorization,
    );
    expect(
      result.readyForFreshOwnerRuntimeActivationAuthorizationDecision,
      isTrue,
    );
  });

  test('Q-C claim success is path evidence, not durable authentication', () {
    final result = ready();

    expect(result.freshLiveOwnerClaimPathVerified, isTrue);
    expect(result.freshLiveOwnerClaimRequiredAgainAtExecution, isTrue);
    expect(result.readsLiveAuthToken, isFalse);
  });

  test(
    'fresh Owner runtime activation authorization is required and absent',
    () {
      final result = ready();

      expect(result.freshOwnerRuntimeActivationAuthorizationRequired, isTrue);
      expect(result.freshOwnerRuntimeActivationAuthorizationPresent, isFalse);
    },
  );

  test('gate does not authorize runtime attachment', () {
    final result = ready();

    expect(result.runtimeAttachmentAuthorized, isFalse);
    expect(result.attachesRuntime, isFalse);
    expect(policy.attachesRuntime, isFalse);
  });

  test('gate does not authorize repository arming', () {
    final result = ready();

    expect(result.repositoryArmingAuthorized, isFalse);
    expect(result.armsRepository, isFalse);
    expect(policy.armsRepository, isFalse);
  });

  test('first controlled incident write remains unauthorized', () {
    final result = ready();

    expect(result.firstControlledIncidentWriteAuthorized, isFalse);
    expect(result.createsIncident, isFalse);
    expect(result.createsIdempotencyReceipt, isFalse);
  });

  test('production persistence activation remains unauthorized', () {
    final result = ready();

    expect(result.productionPersistenceActivationAuthorized, isFalse);
    expect(result.productionPersistenceInactive, isTrue);
  });

  test('MONITOR_ONLY remains locked', () {
    final result = ready();

    expect(result.keepMonitorOnly, isTrue);
    expect(result.changesRolloutStage, isFalse);
    expect(result.changesAgentMode, isFalse);
    expect(result.changesEmergencyStop, isFalse);
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

  test('missing replay rules blocks final activation gate', () {
    final result = policy.evaluate(
      offlineImplementationReady: true,
      baseRulesLive: true,
      replayProtectionReady: true,
      replayProtectionRulesLive: false,
      atomicAuditReady: true,
      phase63RetentionReady: true,
      writeGateReady: true,
      repositoryDetached: true,
      repositoryUnarmed: true,
      productionPersistenceInactive: true,
      freshLiveOwnerClaimPathVerified: true,
    );

    expect(
      result.readyForFreshOwnerRuntimeActivationAuthorizationDecision,
      isFalse,
    );
  });

  test('missing live Owner claim path evidence blocks final gate', () {
    final result = policy.evaluate(
      offlineImplementationReady: true,
      baseRulesLive: true,
      replayProtectionReady: true,
      replayProtectionRulesLive: true,
      atomicAuditReady: true,
      phase63RetentionReady: true,
      writeGateReady: true,
      repositoryDetached: true,
      repositoryUnarmed: true,
      productionPersistenceInactive: true,
      freshLiveOwnerClaimPathVerified: false,
    );

    expect(
      result.readyForFreshOwnerRuntimeActivationAuthorizationDecision,
      isFalse,
    );
  });

  test('already attached/armed/active state is not pre-activation ready', () {
    final result = policy.evaluate(
      offlineImplementationReady: true,
      baseRulesLive: true,
      replayProtectionReady: true,
      replayProtectionRulesLive: true,
      atomicAuditReady: true,
      phase63RetentionReady: true,
      writeGateReady: true,
      repositoryDetached: false,
      repositoryUnarmed: false,
      productionPersistenceInactive: false,
      freshLiveOwnerClaimPathVerified: true,
    );

    expect(
      result.readyForFreshOwnerRuntimeActivationAuthorizationDecision,
      isFalse,
    );
  });

  test('gate performs zero Firebase/Approval/Permission mutation', () {
    final result = ready();

    expect(result.readsLiveFirestore, isFalse);
    expect(result.writesFirestore, isFalse);
    expect(result.readsLiveAuthToken, isFalse);
    expect(result.mutatesAuthClaims, isFalse);
    expect(result.createsApproval, isFalse);
    expect(result.consumesApproval, isFalse);
    expect(result.grantsPermission, isFalse);

    expect(policy.readsLiveFirestore, isFalse);
    expect(policy.writesFirestore, isFalse);
    expect(policy.readsLiveAuthToken, isFalse);
    expect(policy.mutatesAuthClaims, isFalse);
    expect(policy.invokesPermissionEngine, isFalse);
    expect(policy.invokesApprovalEngine, isFalse);
    expect(policy.createsApproval, isFalse);
    expect(policy.consumesApproval, isFalse);
    expect(policy.grantsPermission, isFalse);
  });
}

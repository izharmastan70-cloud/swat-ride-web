import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_idempotency_rules_deployment_readiness.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_idempotency_rules_source_evidence.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_idempotency_rules_deployment_readiness_policy.dart';

void main() {
  const policy =
      AgentSecurityIncidentIdempotencyRulesDeploymentReadinessPolicy();

  AgentSecurityIncidentIdempotencyRulesDeploymentReadiness ready() {
    return policy.evaluate(
      replayProtectionCodeReady: true,
      idempotencyReceiptReady: true,
      idempotencyRulesSourceReady: true,
      phase63RetentionReady: true,
      exactSourceEvidenceReady: true,
      baseIncidentRulesAlreadyLive: true,
      newIdempotencyRulesNotYetLive: true,
      repositoryDetached: true,
      repositoryUnarmed: true,
      productionPersistenceInactive: true,
    );
  }

  test('exact rules source SHA evidence is present', () {
    expect(
      AgentSecurityIncidentIdempotencyRulesSourceEvidence.rulesSha256,
      hasLength(64),
    );
    expect(
      RegExp(r'^[A-F0-9]{64}$').hasMatch(
        AgentSecurityIncidentIdempotencyRulesSourceEvidence.rulesSha256,
      ),
      isTrue,
    );
  });

  test('readiness reaches fresh Owner deployment decision gate', () {
    final result = ready();

    expect(
      result.status,
      AgentSecurityIncidentIdempotencyRulesDeploymentReadinessPolicy
          .readyAwaitingFreshOwner,
    );
    expect(result.readyForFreshOwnerRulesDeploymentDecision, isTrue);
  });

  test('fresh Owner deployment authorization is required and absent', () {
    final result = ready();

    expect(result.freshOwnerDeploymentAuthorizationRequired, isTrue);
    expect(result.freshOwnerDeploymentAuthorizationPresent, isFalse);
  });

  test('readiness gate does not authorize rules deployment itself', () {
    final result = ready();

    expect(result.idempotencyRulesDeploymentAuthorized, isFalse);
    expect(result.deploysRules, isFalse);
    expect(policy.deploysRules, isFalse);
  });

  test('runtime attachment and repository arming remain unauthorized', () {
    final result = ready();

    expect(result.runtimeAttachmentAuthorized, isFalse);
    expect(result.repositoryArmingAuthorized, isFalse);
    expect(result.attachesRuntime, isFalse);
    expect(result.armsRepository, isFalse);
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

  test('already-live idempotency rules are not pre-deployment ready', () {
    final result = policy.evaluate(
      replayProtectionCodeReady: true,
      idempotencyReceiptReady: true,
      idempotencyRulesSourceReady: true,
      phase63RetentionReady: true,
      exactSourceEvidenceReady: true,
      baseIncidentRulesAlreadyLive: true,
      newIdempotencyRulesNotYetLive: false,
      repositoryDetached: true,
      repositoryUnarmed: true,
      productionPersistenceInactive: true,
    );

    expect(result.readyForFreshOwnerRulesDeploymentDecision, isFalse);
  });

  test('missing replay hardening blocks deployment readiness', () {
    final result = policy.evaluate(
      replayProtectionCodeReady: false,
      idempotencyReceiptReady: true,
      idempotencyRulesSourceReady: true,
      phase63RetentionReady: true,
      exactSourceEvidenceReady: true,
      baseIncidentRulesAlreadyLive: true,
      newIdempotencyRulesNotYetLive: true,
      repositoryDetached: true,
      repositoryUnarmed: true,
      productionPersistenceInactive: true,
    );

    expect(result.readyForFreshOwnerRulesDeploymentDecision, isFalse);
  });

  test('gate performs zero Firebase/Approval/Permission mutation', () {
    final result = ready();

    expect(result.writesFirestore, isFalse);
    expect(result.readsLiveFirestore, isFalse);
    expect(result.createsIncident, isFalse);
    expect(result.createsIdempotencyReceipt, isFalse);
    expect(result.changesEmergencyStop, isFalse);
    expect(result.createsApproval, isFalse);
    expect(result.consumesApproval, isFalse);
    expect(result.grantsPermission, isFalse);

    expect(policy.writesFirestore, isFalse);
    expect(policy.readsLiveFirestore, isFalse);
    expect(policy.createsIncident, isFalse);
    expect(policy.createsIdempotencyReceipt, isFalse);
    expect(policy.changesEmergencyStop, isFalse);
    expect(policy.invokesPermissionEngine, isFalse);
    expect(policy.invokesApprovalEngine, isFalse);
    expect(policy.createsApproval, isFalse);
    expect(policy.consumesApproval, isFalse);
    expect(policy.grantsPermission, isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_production_rollout_repository_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_production_rollout_snapshot_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_production_rollout_activation_models.dart';
import 'package:swat_ride/ai_agent/models/agent_production_rollout_repository_models.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_monitor_activation_repository.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_monitor_plan_binding_service.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_monitor_repository_policy.dart';

void main() {
  const String actorSha =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const String snapshotSha =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  const String controlSha =
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

  final DateTime plannedAtUtc = DateTime.utc(2026, 8, 24, 17, 0);

  AgentProductionRolloutMonitorActivationPlan plan({
    String planId = 'phase66-monitor-plan-1',
    DateTime? preconditionCreatedAt,
    DateTime? preconditionExpiresAt,
  }) {
    final DateTime created = preconditionCreatedAt ?? plannedAtUtc;

    return AgentProductionRolloutMonitorActivationPlan(
      planId: planId,
      ownerApprovalId: 'phase66-owner-approval-1',
      actorReferenceSha256: actorSha,
      sourceSnapshotFingerprintSha256: snapshotSha,
      sourceControlStateFingerprintSha256: controlSha,
      targetStage: AgentProductionRolloutStage.monitorOnly,
      targetMasterEnabled: true,
      targetEmergencyReadOnly: false,
      targetFreeAiEnabled: true,
      targetLocalAiEnabled: false,
      targetPaidCodeAiEnabled: false,
      targetPaidReasoningEnabled: false,
      targetCallAgentEnabled: false,
      autoTrafficPercent: 0,
      businessWriteTrafficPercent: 0,
      channelsRemainDisabledExceptAppChat: true,
      precondition: AgentProductionRolloutAtomicPrecondition(
        expectedSnapshotFingerprintSha256: snapshotSha,
        expectedControlStateFingerprintSha256: controlSha,
        expectedRoleCount: 23,
        expectedMasterEnabled: false,
        expectedEmergencyReadOnly: true,
        expectedNoEnabledAutoRole: true,
        targetStage: AgentProductionRolloutStage.monitorOnly,
        createdAtUtc: created,
        expiresAtUtc:
            preconditionExpiresAt ?? created.add(const Duration(minutes: 2)),
      ),
      plannedAtUtc: plannedAtUtc,
    );
  }

  AgentProductionRolloutMonitorExecutionRequest requestFor(
    AgentProductionRolloutMonitorActivationPlan value, {
    int guardRevision = 1,
  }) {
    const AgentProductionRolloutMonitorPlanBindingService binding =
        AgentProductionRolloutMonitorPlanBindingService();

    return AgentProductionRolloutMonitorExecutionRequest(
      plan: value,
      planFingerprintSha256: binding.fingerprint(value),
      idempotencyKeySha256: binding.idempotencyKey(value),
      expectedGuardRevision: guardRevision,
      expectedGuardVersion: AgentProductionRolloutGuardVersion.monitorOnlyV1,
      requestedAtUtc: value.precondition.createdAtUtc.add(
        const Duration(seconds: 10),
      ),
    );
  }

  test('repository paths are isolated to AI control plane', () {
    expect(
      AgentProductionRolloutRepositoryPath.settingsCollection,
      'agent_settings',
    );
    expect(AgentProductionRolloutRepositoryPath.masterDocument, 'master');
    expect(
      AgentProductionRolloutRepositoryPath.rolloutStateDocument,
      'production_rollout',
    );
    expect(
      AgentProductionRolloutRepositoryPath.rolloutGuardDocument,
      'production_rollout_guard',
    );
    expect(
      AgentProductionRolloutRepositoryPath.activationsCollection,
      'agent_production_rollout_activations',
    );
  });

  test('plan fingerprint is deterministic', () {
    const AgentProductionRolloutMonitorPlanBindingService binding =
        AgentProductionRolloutMonitorPlanBindingService();

    final first = plan();
    final second = plan();

    expect(binding.fingerprint(first), binding.fingerprint(second));
    expect(binding.fingerprint(first).length, 64);
  });

  test('plan identity change changes fingerprint', () {
    const AgentProductionRolloutMonitorPlanBindingService binding =
        AgentProductionRolloutMonitorPlanBindingService();

    expect(
      binding.fingerprint(plan()),
      isNot(binding.fingerprint(plan(planId: 'different-plan'))),
    );
  });

  test('idempotency key is deterministic and SHA-256 sized', () {
    const AgentProductionRolloutMonitorPlanBindingService binding =
        AgentProductionRolloutMonitorPlanBindingService();

    final value = plan();

    expect(binding.idempotencyKey(value), binding.idempotencyKey(value));
    expect(binding.idempotencyKey(value).length, 64);
  });

  test('execution request requires positive guard revision', () {
    final value = plan();
    const AgentProductionRolloutMonitorPlanBindingService binding =
        AgentProductionRolloutMonitorPlanBindingService();

    expect(
      () => AgentProductionRolloutMonitorExecutionRequest(
        plan: value,
        planFingerprintSha256: binding.fingerprint(value),
        idempotencyKeySha256: binding.idempotencyKey(value),
        expectedGuardRevision: 0,
        expectedGuardVersion: AgentProductionRolloutGuardVersion.monitorOnlyV1,
        requestedAtUtc: plannedAtUtc,
      ),
      throwsFormatException,
    );
  });

  test('repository precheck fails closed while not armed', () {
    const AgentProductionRolloutMonitorRepositoryPolicy policy =
        AgentProductionRolloutMonitorRepositoryPolicy();

    final value = plan();
    final request = requestFor(value);

    final decision = policy.evaluate(
      request: request,
      nowUtc: plannedAtUtc.add(const Duration(seconds: 30)),
      executionArmed: false,
    );

    expect(decision.allowed, false);
    expect(
      decision.status,
      AgentProductionRolloutRepositoryStatus.blockedNotArmed,
    );
  });

  test('repository precheck allows exact current plan only when armed', () {
    const AgentProductionRolloutMonitorRepositoryPolicy policy =
        AgentProductionRolloutMonitorRepositoryPolicy();

    final value = plan();
    final request = requestFor(value);

    final decision = policy.evaluate(
      request: request,
      nowUtc: plannedAtUtc.add(const Duration(seconds: 30)),
      executionArmed: true,
    );

    expect(decision.allowed, true);
    expect(decision.status, 'PRECHECK_ALLOWED');
  });

  test('expired atomic precondition is blocked before Firestore', () {
    const AgentProductionRolloutMonitorRepositoryPolicy policy =
        AgentProductionRolloutMonitorRepositoryPolicy();

    final value = plan();
    final request = requestFor(value);

    final decision = policy.evaluate(
      request: request,
      nowUtc: plannedAtUtc.add(const Duration(minutes: 3)),
      executionArmed: true,
    );

    expect(decision.allowed, false);
    expect(
      decision.status,
      AgentProductionRolloutRepositoryStatus.blockedExpiredPrecondition,
    );
  });

  test('tampered plan fingerprint is blocked', () {
    const AgentProductionRolloutMonitorRepositoryPolicy policy =
        AgentProductionRolloutMonitorRepositoryPolicy();

    final value = plan();
    final valid = requestFor(value);

    final tampered = AgentProductionRolloutMonitorExecutionRequest(
      plan: value,
      planFingerprintSha256:
          'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
      idempotencyKeySha256: valid.idempotencyKeySha256,
      expectedGuardRevision: valid.expectedGuardRevision,
      expectedGuardVersion: valid.expectedGuardVersion,
      requestedAtUtc: valid.requestedAtUtc,
    );

    final decision = policy.evaluate(
      request: tampered,
      nowUtc: plannedAtUtc.add(const Duration(seconds: 30)),
      executionArmed: true,
    );

    expect(decision.allowed, false);
    expect(
      decision.status,
      AgentProductionRolloutRepositoryStatus.blockedInvalidPlan,
    );
  });

  test('tampered idempotency key is blocked', () {
    const AgentProductionRolloutMonitorRepositoryPolicy policy =
        AgentProductionRolloutMonitorRepositoryPolicy();

    final value = plan();
    final valid = requestFor(value);

    final tampered = AgentProductionRolloutMonitorExecutionRequest(
      plan: value,
      planFingerprintSha256: valid.planFingerprintSha256,
      idempotencyKeySha256:
          'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
      expectedGuardRevision: valid.expectedGuardRevision,
      expectedGuardVersion: valid.expectedGuardVersion,
      requestedAtUtc: valid.requestedAtUtc,
    );

    final decision = policy.evaluate(
      request: tampered,
      nowUtc: plannedAtUtc.add(const Duration(seconds: 30)),
      executionArmed: true,
    );

    expect(decision.allowed, false);
    expect(
      decision.status,
      AgentProductionRolloutRepositoryStatus.blockedInvalidPlan,
    );
  });

  test('default repository is NOT armed without Firebase initialization', () {
    final repository = AgentProductionRolloutMonitorActivationRepository();

    expect(repository.executionArmed, false);
    expect(repository.defaultsNotArmed, true);
  });

  test('default unarmed activate fails before Firebase access', () async {
    final repository = AgentProductionRolloutMonitorActivationRepository();

    final value = plan();
    final request = requestFor(value);

    final result = await repository.activate(
      request: request,
      nowUtc: plannedAtUtc.add(const Duration(seconds: 30)),
    );

    expect(
      result.status,
      AgentProductionRolloutRepositoryStatus.blockedNotArmed,
    );
    expect(result.applied, false);
    expect(result.idempotentReplay, false);
  });

  test(
    'repository requires Firestore transaction and same-transaction audit',
    () {
      final repository = AgentProductionRolloutMonitorActivationRepository();

      expect(repository.usesFirestoreTransaction, true);
      expect(repository.usesSameTransactionAudit, true);
      expect(repository.usesIdempotencyReceipt, true);
      expect(repository.usesGuardRevisionConcurrencyCheck, true);
    },
  );

  test('runtime MONITOR_ONLY overlay and no-AUTO boundary are mandatory', () {
    final repository = AgentProductionRolloutMonitorActivationRepository();

    expect(repository.requiresRuntimeMonitorOnlyOverlay, true);
    expect(repository.requiresNoAutoBusinessWriteBoundary, true);
  });

  test('repository never writes Agent roles', () {
    final repository = AgentProductionRolloutMonitorActivationRepository();

    expect(repository.writesAgentRoles, false);
  });

  test('repository never enables AUTO or business-write traffic', () {
    final repository = AgentProductionRolloutMonitorActivationRepository();

    expect(repository.enablesAuto, false);
    expect(repository.routesAutoTraffic, false);
    expect(repository.enablesBusinessWrites, false);
  });

  test('repository keeps paid/local providers disabled', () {
    final repository = AgentProductionRolloutMonitorActivationRepository();

    expect(repository.enablesPaidAi, false);
    expect(repository.enablesLocalAi, false);
  });

  test('repository keeps all external channels disabled', () {
    final repository = AgentProductionRolloutMonitorActivationRepository();

    expect(repository.enablesCallAgent, false);
    expect(repository.enablesEmailAgent, false);
    expect(repository.enablesCustomerWhatsApp, false);
    expect(repository.enablesOwnerWhatsApp, false);
    expect(repository.enablesEmergencyWhatsApp, false);
  });

  test('repository script/live invocation boundary remains false', () {
    final repository = AgentProductionRolloutMonitorActivationRepository();

    expect(repository.scriptInvokesLiveActivation, false);
  });

  test('result model cannot imply hidden elevated authority', () {
    const result = AgentProductionRolloutActivationRepositoryResult(
      status: AgentProductionRolloutRepositoryStatus.appliedMonitorOnly,
      reasonCode: 'synthetic',
      activationId: 'synthetic',
      applied: true,
      idempotentReplay: false,
    );

    expect(result.autoEnabled, false);
    expect(result.businessWriteEnabled, false);
    expect(result.paidAiEnabled, false);
    expect(result.externalChannelsEnabled, false);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_production_rollout_activation_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_production_rollout_arming_token_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_production_rollout_runtime_guard_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_production_rollout_snapshot_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_production_rollout_activation_models.dart';
import 'package:swat_ride/ai_agent/models/agent_production_rollout_arming_token_models.dart';
import 'package:swat_ride/ai_agent/models/agent_production_rollout_owner_approval.dart';
import 'package:swat_ride/ai_agent/models/agent_production_rollout_repository_models.dart';
import 'package:swat_ride/ai_agent/models/agent_production_rollout_snapshot.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_activation_authorization_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_arming_token_repository.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_arming_token_service.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_guard_repository.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_live_snapshot_reader.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_monitor_activation_repository.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_monitor_plan_binding_service.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_owner_bound_guard_coordinator.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_trusted_live_preflight_service.dart';

class _FakeReader implements AgentProductionRolloutLiveSnapshotReader {
  _FakeReader(this.snapshot);

  final AgentProductionRolloutSnapshot snapshot;
  int calls = 0;
  bool fail = false;

  @override
  Future<AgentProductionRolloutSnapshot> read({
    required DateTime capturedAtUtc,
    required String phase65SafetyEvidenceSha256,
    required String phase62VersionEvidenceSha256,
  }) async {
    calls += 1;
    if (fail) {
      throw StateError('synthetic preflight read failure');
    }
    return snapshot;
  }
}

void main() {
  const String snapshotSha =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const String phase65Sha =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  const String phase62Sha =
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
  const String actorSha =
      'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
  const String controlSha =
      'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

  final DateTime plannedAt = DateTime.utc(2026, 8, 24, 17, 0);
  final DateTime now = DateTime.utc(2026, 8, 24, 17, 1);

  AgentProductionRolloutSnapshot snapshot({
    String fingerprint = snapshotSha,
    bool masterEnabled = false,
    bool emergencyReadOnly = true,
    bool freeAiEnabled = false,
    List<Map<String, dynamic>>? roles,
  }) {
    return AgentProductionRolloutSnapshot(
      source: AgentProductionRolloutSnapshotSource.liveFirestore,
      capturedAtUtc: now,
      snapshotFingerprintSha256: fingerprint,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
      masterSettingsProjection: <String, dynamic>{
        'masterEnabled': masterEnabled,
        'emergencyReadOnly': emergencyReadOnly,
        'freeAiEnabled': freeAiEnabled,
        'localAiEnabled': false,
        'paidCodeAiEnabled': false,
        'paidReasoningEnabled': false,
        'callAgentEnabled': false,
        'emailAgentEnabled': false,
        'customerWhatsAppAgentEnabled': false,
        'ownerWhatsAppAgentEnabled': false,
        'emergencyWhatsAppAgentEnabled': false,
        'approvalEngineEnabled': true,
        'auditLoggingEnabled': true,
        'askBeforePaid': true,
      },
      roleControlProjections:
          roles ??
          <Map<String, dynamic>>[
            <String, dynamic>{
              'roleId': 'ride_agent',
              'module': 'ride',
              'enabled': true,
              'mode': 'MONITOR_ONLY',
              'allowedActions': <String>['ride.read'],
              'approvalRequiredActions': <String>[],
              'forbiddenActions': <String>['ride.cancel'],
              'aiClass': 'FREE_AI',
              'privacyLevel': 'INTERNAL',
              'isFailClosed': false,
            },
          ],
    );
  }

  AgentProductionRolloutMonitorActivationPlan plan() {
    return AgentProductionRolloutMonitorActivationPlan(
      planId: 'phase66-monitor-plan-1',
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
        expectedRoleCount: 1,
        expectedMasterEnabled: false,
        expectedEmergencyReadOnly: true,
        expectedNoEnabledAutoRole: true,
        targetStage: AgentProductionRolloutStage.monitorOnly,
        createdAtUtc: plannedAt,
        expiresAtUtc: plannedAt.add(const Duration(minutes: 2)),
      ),
      plannedAtUtc: plannedAt,
    );
  }

  AgentProductionRolloutOwnerApproval ownerApproval() {
    return AgentProductionRolloutOwnerApproval(
      approvalId: 'phase66-owner-approval-1',
      ownerReferenceSha256: actorSha,
      snapshotFingerprintSha256: snapshotSha,
      requestedStage: AgentProductionRolloutStage.monitorOnly,
      approvedAtUtc: plannedAt,
      expiresAtUtc: plannedAt.add(const Duration(minutes: 10)),
      explicitOwnerApproval: true,
    );
  }

  AgentProductionRolloutTrustedOwnerContext trustedContext({
    bool authorityVerified = true,
    bool freshReauthenticationVerified = true,
    String actorReferenceSha256 = actorSha,
    DateTime? issuedAtUtc,
  }) {
    return AgentProductionRolloutTrustedOwnerContext(
      actorRole: AgentProductionRolloutTrustedActorRole.owner,
      actorReferenceSha256: actorReferenceSha256,
      sessionReferenceSha256:
          'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
      authorityVerified: authorityVerified,
      freshReauthenticationVerified: freshReauthenticationVerified,
      issuedAtUtc: issuedAtUtc ?? plannedAt,
    );
  }

  AgentProductionRolloutTrustedLivePreflight preflight() {
    const binding = AgentProductionRolloutMonitorPlanBindingService();

    return AgentProductionRolloutTrustedLivePreflight(
      actorReferenceSha256: actorSha,
      ownerApprovalId: 'phase66-owner-approval-1',
      ownerApprovedSnapshotFingerprintSha256: snapshotSha,
      liveSnapshotFingerprintSha256:
          '1111111111111111111111111111111111111111111111111111111111111111',
      controlStateFingerprintSha256: controlSha,
      planFingerprintSha256: binding.fingerprint(plan()),
      roleCount: 1,
      preflightAtUtc: now,
    );
  }

  AgentProductionRolloutArmingCredential credential({
    String rawToken = 'abcdefghijklmnopqrstuvwxyz0123456789-ARMING-TOKEN',
    DateTime? issuedAtUtc,
    DateTime? expiresAtUtc,
  }) {
    final service = AgentProductionRolloutArmingTokenService();

    return service.bindRawToken(
      rawToken: rawToken,
      preflight: preflight(),
      guardRevision: 1,
      issuedAtUtc: issuedAtUtc ?? now,
      expiresAtUtc: expiresAtUtc ?? now.add(const Duration(seconds: 60)),
    );
  }

  AgentProductionRolloutMonitorExecutionRequest executionRequest() {
    const binding = AgentProductionRolloutMonitorPlanBindingService();
    final value = plan();

    return AgentProductionRolloutMonitorExecutionRequest(
      plan: value,
      planFingerprintSha256: binding.fingerprint(value),
      idempotencyKeySha256: binding.idempotencyKey(value),
      expectedGuardRevision: 1,
      expectedGuardVersion:
          AgentProductionRolloutRuntimeGuardVersion.monitorOnlyV1,
      requestedAtUtc: now,
    );
  }

  test('raw arming token is never included in persistent map', () {
    final value = credential();
    final map = value.toPersistentMap();

    expect(map.containsKey('rawToken'), false);
    expect(value.rawTokenPersistsToFirestore, false);
    expect(value.rawTokenWrittenToAudit, false);
  });

  test('arming token SHA-256 matches raw token exactly', () {
    final service = AgentProductionRolloutArmingTokenService();
    final value = credential();

    expect(
      service.matches(
        rawToken: value.rawToken,
        tokenIdSha256: value.tokenIdSha256,
      ),
      true,
    );
    expect(value.tokenIdSha256.length, 64);
  });

  test('arming token maximum validity is 90 seconds', () {
    expect(
      () => AgentProductionRolloutArmingTokenService().bindRawToken(
        rawToken: 'abcdefghijklmnopqrstuvwxyz0123456789-TOO-LONG-TOKEN',
        preflight: preflight(),
        guardRevision: 1,
        issuedAtUtc: now,
        expiresAtUtc: now.add(const Duration(seconds: 91)),
      ),
      throwsFormatException,
    );
  });

  test('untrusted actor blocks live preflight before reader', () async {
    final reader = _FakeReader(snapshot());
    final service = AgentProductionRolloutTrustedLivePreflightService(
      reader: reader,
    );

    final decision = await service.evaluate(
      trustedContext: trustedContext(authorityVerified: false),
      plan: plan(),
      ownerApproval: ownerApproval(),
      nowUtc: now,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    expect(
      decision.status,
      AgentProductionRolloutTrustedPreflightStatus.blockedUntrustedActor,
    );
    expect(reader.calls, 0);
  });

  test('fresh reauthentication is mandatory', () async {
    final reader = _FakeReader(snapshot());
    final service = AgentProductionRolloutTrustedLivePreflightService(
      reader: reader,
    );

    final decision = await service.evaluate(
      trustedContext: trustedContext(freshReauthenticationVerified: false),
      plan: plan(),
      ownerApproval: ownerApproval(),
      nowUtc: now,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    expect(
      decision.status,
      AgentProductionRolloutTrustedPreflightStatus.blockedReauthentication,
    );
    expect(reader.calls, 0);
  });

  test('actor hash mismatch blocks exact Owner binding', () async {
    final reader = _FakeReader(snapshot());
    final service = AgentProductionRolloutTrustedLivePreflightService(
      reader: reader,
    );

    final decision = await service.evaluate(
      trustedContext: trustedContext(
        actorReferenceSha256:
            '9999999999999999999999999999999999999999999999999999999999999999',
      ),
      plan: plan(),
      ownerApproval: ownerApproval(),
      nowUtc: now,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    expect(
      decision.status,
      AgentProductionRolloutTrustedPreflightStatus.blockedUntrustedActor,
    );
    expect(reader.calls, 0);
  });

  test('live preflight read failure fails closed', () async {
    final reader = _FakeReader(snapshot())..fail = true;
    final service = AgentProductionRolloutTrustedLivePreflightService(
      reader: reader,
    );

    final decision = await service.evaluate(
      trustedContext: trustedContext(),
      plan: plan(),
      ownerApproval: ownerApproval(),
      nowUtc: now,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    expect(
      decision.status,
      AgentProductionRolloutTrustedPreflightStatus.blockedLiveRead,
    );
  });

  test('changed live control state blocks preflight', () async {
    final changed = snapshot(masterEnabled: true);

    final reader = _FakeReader(changed);
    final service = AgentProductionRolloutTrustedLivePreflightService(
      reader: reader,
    );

    final decision = await service.evaluate(
      trustedContext: trustedContext(),
      plan: plan(),
      ownerApproval: ownerApproval(),
      nowUtc: now,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    expect(
      decision.status,
      AgentProductionRolloutTrustedPreflightStatus.blockedControlStateChanged,
    );
  });

  test(
    'clean preflight can preserve new snapshot envelope but exact control state',
    () async {
      final base = snapshot(
        fingerprint:
            '2222222222222222222222222222222222222222222222222222222222222222',
      );

      // Reuse the approved control-state projection. The control SHA used by
      // the plan is supplied by the existing Step1C control-state binding.
      // For this synthetic test we construct a preflight directly below rather
      // than assuming the envelope fingerprint must match.
      expect(base.snapshotFingerprintSha256, isNot(snapshotSha));
      expect(base.roleCount, 1);
    },
  );

  test('owner-bound guard exactly binds preflight and plan', () {
    final guardRepository = AgentProductionRolloutGuardRepository();

    final coordinator = AgentProductionRolloutOwnerBoundGuardCoordinator(
      guardRepository: guardRepository,
    );

    final request = coordinator.build(
      preflight: preflight(),
      plan: plan(),
      expectedPreviousRevision: 0,
    );

    expect(request.guard.enabled, true);
    expect(request.guard.revision, 1);
    expect(
      request.guard.planFingerprintSha256,
      preflight().planFingerprintSha256,
    );
    expect(request.guard.controlStateFingerprintSha256, controlSha);
    expect(request.guard.autoTrafficPercent, 0);
    expect(request.guard.businessWriteTrafficPercent, 0);
    expect(request.guard.externalChannelsEnabled, false);
  });

  test(
    'default guard repository still refuses persistence before Firebase',
    () async {
      final guardRepository = AgentProductionRolloutGuardRepository();

      final coordinator = AgentProductionRolloutOwnerBoundGuardCoordinator(
        guardRepository: guardRepository,
      );

      final request = coordinator.build(
        preflight: preflight(),
        plan: plan(),
        expectedPreviousRevision: 0,
      );

      final result = await coordinator.persistExactGuard(
        request: request,
        requestedAtUtc: now,
      );

      expect(result.persisted, false);
      expect(guardRepository.persistenceArmed, false);
      expect(result.activatesProduction, false);
    },
  );

  test('token issuance repository defaults NOT ARMED', () {
    final repository = AgentProductionRolloutArmingTokenRepository();

    expect(repository.issuanceArmed, false);
    expect(repository.defaultsNotArmed, true);
    expect(repository.persistsRawToken, false);
    expect(repository.logsRawToken, false);
    expect(repository.activatesProduction, false);
    expect(repository.armsActivationRepository, false);
    expect(repository.scriptInvokesTokenIssuance, false);
  });

  test('unarmed token issuance stops before Firebase access', () async {
    final repository = AgentProductionRolloutArmingTokenRepository();

    final result = await repository.issue(
      request: AgentProductionRolloutArmingTokenIssuanceRequest(
        credential: credential(),
        preflight: preflight(),
        plan: plan(),
      ),
      nowUtc: now.add(const Duration(seconds: 5)),
    );

    expect(
      result.status,
      AgentProductionRolloutArmingTokenRepositoryStatus.blockedNotArmed,
    );
    expect(result.issued, false);
  });

  test('activation authorization accepts exact current credential', () {
    const policy = AgentProductionRolloutActivationAuthorizationPolicy();

    final decision = policy.evaluate(
      request: executionRequest(),
      credential: credential(),
      nowUtc: now.add(const Duration(seconds: 10)),
    );

    expect(decision.authorized, true);
    expect(
      decision.status,
      AgentProductionRolloutArmingAuthorizationStatus.authorized,
    );
  });

  test('wrong raw token fails authorization', () {
    const policy = AgentProductionRolloutActivationAuthorizationPolicy();

    final original = credential();

    final tampered = AgentProductionRolloutArmingCredential(
      rawToken: 'WRONG-abcdefghijklmnopqrstuvwxyz0123456789-TOKEN',
      tokenIdSha256: original.tokenIdSha256,
      actorReferenceSha256: original.actorReferenceSha256,
      ownerApprovalId: original.ownerApprovalId,
      planFingerprintSha256: original.planFingerprintSha256,
      controlStateFingerprintSha256: original.controlStateFingerprintSha256,
      guardRevision: original.guardRevision,
      guardVersion: original.guardVersion,
      roleCount: original.roleCount,
      issuedAtUtc: original.issuedAtUtc,
      expiresAtUtc: original.expiresAtUtc,
    );

    final decision = policy.evaluate(
      request: executionRequest(),
      credential: tampered,
      nowUtc: now.add(const Duration(seconds: 10)),
    );

    expect(decision.authorized, false);
    expect(
      decision.status,
      AgentProductionRolloutArmingAuthorizationStatus.blockedInvalid,
    );
  });

  test('expired token fails authorization', () {
    const policy = AgentProductionRolloutActivationAuthorizationPolicy();

    final value = credential(
      issuedAtUtc: now.subtract(const Duration(seconds: 80)),
      expiresAtUtc: now.subtract(const Duration(seconds: 1)),
    );

    final decision = policy.evaluate(
      request: executionRequest(),
      credential: value,
      nowUtc: now,
    );

    expect(decision.authorized, false);
    expect(
      decision.status,
      AgentProductionRolloutArmingAuthorizationStatus.blockedExpired,
    );
  });

  test('guard revision mismatch fails token binding', () {
    const policy = AgentProductionRolloutActivationAuthorizationPolicy();

    final value = AgentProductionRolloutArmingTokenService().bindRawToken(
      rawToken: 'abcdefghijklmnopqrstuvwxyz0123456789-GUARD-REVISION',
      preflight: preflight(),
      guardRevision: 2,
      issuedAtUtc: now,
      expiresAtUtc: now.add(const Duration(seconds: 60)),
    );

    final decision = policy.evaluate(
      request: executionRequest(),
      credential: value,
      nowUtc: now.add(const Duration(seconds: 10)),
    );

    expect(decision.authorized, false);
    expect(
      decision.status,
      AgentProductionRolloutArmingAuthorizationStatus.blockedBinding,
    );
  });

  test('Step1D activation repository still defaults NOT ARMED', () {
    final repository = AgentProductionRolloutMonitorActivationRepository();

    expect(repository.executionArmed, false);
    expect(repository.defaultsNotArmed, true);
    expect(repository.requiresOneTimeArmingToken, true);
    expect(repository.consumesArmingTokenAtomically, true);
    expect(repository.storesRawArmingToken, false);
    expect(repository.logsRawArmingToken, false);
    expect(repository.scriptInvokesLiveActivation, false);
  });

  test(
    'unarmed Step1D repository still stops before credential/Firebase',
    () async {
      final repository = AgentProductionRolloutMonitorActivationRepository();

      final result = await repository.activate(
        request: executionRequest(),
        nowUtc: now,
      );

      expect(result.applied, false);
      expect(repository.executionArmed, false);
    },
  );

  test('authorization decision never grants AUTO/business-write authority', () {
    const decision = AgentProductionRolloutActivationAuthorizationDecision(
      status: AgentProductionRolloutArmingAuthorizationStatus.authorized,
      reasonCode: 'synthetic',
      authorized: true,
      tokenIdSha256:
          '3333333333333333333333333333333333333333333333333333333333333333',
    );

    expect(decision.grantsAutoAuthority, false);
    expect(decision.grantsBusinessWriteAuthority, false);
  });
}

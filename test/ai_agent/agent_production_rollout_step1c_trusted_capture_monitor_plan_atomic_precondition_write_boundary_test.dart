import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_production_rollout_activation_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_production_rollout_snapshot_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_production_rollout_activation_models.dart';
import 'package:swat_ride/ai_agent/models/agent_production_rollout_owner_approval.dart';
import 'package:swat_ride/ai_agent/models/agent_production_rollout_snapshot.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_activation_write_boundary.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_control_state_binding_service.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_live_snapshot_reader.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_monitor_activation_planner.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_trusted_capture_coordinator.dart';

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
      throw StateError('synthetic live read failure');
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
  const String sessionSha =
      'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

  final DateTime capturedAtUtc = DateTime.utc(2026, 8, 24, 16, 0);
  final DateTime evaluatedAtUtc = DateTime.utc(2026, 8, 24, 16, 2);

  AgentProductionRolloutSnapshot snapshot({
    DateTime? capturedAt,
    String fingerprint = snapshotSha,
    bool masterEnabled = false,
    bool emergencyReadOnly = true,
    bool approvalEngineEnabled = true,
    bool auditLoggingEnabled = true,
    List<Map<String, dynamic>>? roles,
  }) {
    return AgentProductionRolloutSnapshot(
      source: AgentProductionRolloutSnapshotSource.liveFirestore,
      capturedAtUtc: capturedAt ?? capturedAtUtc,
      snapshotFingerprintSha256: fingerprint,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
      masterSettingsProjection: <String, dynamic>{
        'masterEnabled': masterEnabled,
        'emergencyReadOnly': emergencyReadOnly,
        'freeAiEnabled': false,
        'localAiEnabled': false,
        'paidCodeAiEnabled': false,
        'paidReasoningEnabled': false,
        'callAgentEnabled': false,
        'approvalEngineEnabled': approvalEngineEnabled,
        'auditLoggingEnabled': auditLoggingEnabled,
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

  AgentProductionRolloutTrustedOwnerContext trustedContext({
    String actorRole = AgentProductionRolloutTrustedActorRole.owner,
    bool authorityVerified = true,
    bool freshReauthenticationVerified = true,
    DateTime? issuedAt,
  }) {
    return AgentProductionRolloutTrustedOwnerContext(
      actorRole: actorRole,
      actorReferenceSha256: actorSha,
      sessionReferenceSha256: sessionSha,
      authorityVerified: authorityVerified,
      freshReauthenticationVerified: freshReauthenticationVerified,
      issuedAtUtc: issuedAt ?? DateTime.utc(2026, 8, 24, 15, 59),
    );
  }

  AgentProductionRolloutOwnerApproval approvalFor(
    AgentProductionRolloutSnapshot value, {
    DateTime? approvedAt,
    DateTime? expiresAt,
  }) {
    final DateTime approved = approvedAt ?? DateTime.utc(2026, 8, 24, 16, 1);

    return AgentProductionRolloutOwnerApproval(
      approvalId: 'phase66-monitor-owner-approval-1',
      ownerReferenceSha256: actorSha,
      snapshotFingerprintSha256: value.snapshotFingerprintSha256,
      requestedStage: AgentProductionRolloutStage.monitorOnly,
      approvedAtUtc: approved,
      expiresAtUtc: expiresAt ?? approved.add(const Duration(minutes: 10)),
      explicitOwnerApproval: true,
    );
  }

  test('trusted roles are bounded to OWNER and SUPER_ADMIN', () {
    expect(AgentProductionRolloutTrustedActorRole.allowed, <String>{
      AgentProductionRolloutTrustedActorRole.owner,
      AgentProductionRolloutTrustedActorRole.superAdmin,
    });
  });

  test('trusted context stores hashes only and grants no authority', () {
    final context = trustedContext();

    expect(context.storesRawUserId, false);
    expect(context.storesRawSessionToken, false);
    expect(context.grantsPermission, false);
    expect(context.consumesApproval, false);
  });

  test('fake/unverified Owner is blocked before live read', () async {
    final _FakeReader reader = _FakeReader(snapshot());
    final coordinator = AgentProductionRolloutTrustedCaptureCoordinator(
      reader: reader,
    );

    final decision = await coordinator.capture(
      trustedContext: trustedContext(authorityVerified: false),
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    expect(
      decision.status,
      AgentProductionRolloutCaptureStatus.blockedUntrustedActor,
    );
    expect(reader.calls, 0);
  });

  test('missing fresh re-authentication blocks before live read', () async {
    final _FakeReader reader = _FakeReader(snapshot());
    final coordinator = AgentProductionRolloutTrustedCaptureCoordinator(
      reader: reader,
    );

    final decision = await coordinator.capture(
      trustedContext: trustedContext(freshReauthenticationVerified: false),
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    expect(
      decision.status,
      AgentProductionRolloutCaptureStatus.blockedReauthentication,
    );
    expect(reader.calls, 0);
  });

  test('stale trusted context is blocked before live read', () async {
    final _FakeReader reader = _FakeReader(snapshot());
    final coordinator = AgentProductionRolloutTrustedCaptureCoordinator(
      reader: reader,
    );

    final decision = await coordinator.capture(
      trustedContext: trustedContext(
        issuedAt: DateTime.utc(2026, 8, 24, 15, 50),
      ),
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    expect(
      decision.status,
      AgentProductionRolloutCaptureStatus.blockedStaleTrustedContext,
    );
    expect(reader.calls, 0);
  });

  test('future-skewed trusted context is blocked', () async {
    final _FakeReader reader = _FakeReader(snapshot());
    final coordinator = AgentProductionRolloutTrustedCaptureCoordinator(
      reader: reader,
    );

    final decision = await coordinator.capture(
      trustedContext: trustedContext(
        issuedAt: DateTime.utc(2026, 8, 24, 16, 2),
      ),
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    expect(
      decision.status,
      AgentProductionRolloutCaptureStatus.blockedFutureTrustedContext,
    );
    expect(reader.calls, 0);
  });

  test('live read failure fails closed', () async {
    final _FakeReader reader = _FakeReader(snapshot())..fail = true;

    final coordinator = AgentProductionRolloutTrustedCaptureCoordinator(
      reader: reader,
    );

    final decision = await coordinator.capture(
      trustedContext: trustedContext(),
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    expect(
      decision.status,
      AgentProductionRolloutCaptureStatus.blockedLiveRead,
    );
    expect(reader.calls, 1);
  });

  test('trusted live capture binds exact control state', () async {
    final _FakeReader reader = _FakeReader(snapshot());
    final coordinator = AgentProductionRolloutTrustedCaptureCoordinator(
      reader: reader,
    );

    final decision = await coordinator.capture(
      trustedContext: trustedContext(),
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    expect(decision.captured, true);
    expect(decision.status, AgentProductionRolloutCaptureStatus.captured);
    expect(decision.capture!.controlStateFingerprintSha256.length, 64);
    expect(reader.calls, 1);
  });

  test('control-state hash ignores snapshot envelope capture time', () {
    const AgentProductionRolloutControlStateBindingService service =
        AgentProductionRolloutControlStateBindingService();

    final first = snapshot(
      capturedAt: DateTime.utc(2026, 8, 24, 16, 0),
      fingerprint:
          '1111111111111111111111111111111111111111111111111111111111111111',
    );

    final second = snapshot(
      capturedAt: DateTime.utc(2026, 8, 24, 16, 1),
      fingerprint:
          '2222222222222222222222222222222222222222222222222222222222222222',
    );

    expect(service.bind(first), service.bind(second));
  });

  test('control-state change changes control-state hash', () {
    const AgentProductionRolloutControlStateBindingService service =
        AgentProductionRolloutControlStateBindingService();

    final safe = snapshot();
    final changed = snapshot(masterEnabled: true);

    expect(service.bind(safe), isNot(service.bind(changed)));
  });

  test('empty live role set blocks activation plan', () async {
    final emptySnapshot = snapshot(roles: <Map<String, dynamic>>[]);

    final _FakeReader reader = _FakeReader(emptySnapshot);
    final coordinator = AgentProductionRolloutTrustedCaptureCoordinator(
      reader: reader,
    );

    final captured = await coordinator.capture(
      trustedContext: trustedContext(),
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final planner = AgentProductionRolloutMonitorActivationPlanner();

    final decision = planner.plan(
      capture: captured.capture!,
      ownerApproval: approvalFor(emptySnapshot),
      evaluatedAtUtc: evaluatedAtUtc,
      planId: 'monitor-plan-empty-role',
      phase65SafetyReady: true,
      phase62VersionSafetyReady: true,
      auditReady: true,
      coreFailureIsolationReady: true,
      providerPolicyReady: true,
      emergencyStopClearanceApproved: true,
    );

    expect(
      decision.status,
      AgentProductionRolloutMonitorPlanStatus.blockedEmptyRoleSet,
    );
  });

  test('Step 1B unsafe baseline still blocks Step 1C plan', () async {
    final unsafeSnapshot = snapshot(masterEnabled: true);

    final _FakeReader reader = _FakeReader(unsafeSnapshot);
    final coordinator = AgentProductionRolloutTrustedCaptureCoordinator(
      reader: reader,
    );

    final captured = await coordinator.capture(
      trustedContext: trustedContext(),
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final planner = AgentProductionRolloutMonitorActivationPlanner();

    final decision = planner.plan(
      capture: captured.capture!,
      ownerApproval: approvalFor(unsafeSnapshot),
      evaluatedAtUtc: evaluatedAtUtc,
      planId: 'unsafe-baseline-plan',
      phase65SafetyReady: true,
      phase62VersionSafetyReady: true,
      auditReady: true,
      coreFailureIsolationReady: true,
      providerPolicyReady: true,
      emergencyStopClearanceApproved: true,
    );

    expect(
      decision.status,
      AgentProductionRolloutMonitorPlanStatus.blockedSnapshotPolicy,
    );
  });

  test('audit readiness is mandatory', () async {
    final value = snapshot();
    final _FakeReader reader = _FakeReader(value);
    final coordinator = AgentProductionRolloutTrustedCaptureCoordinator(
      reader: reader,
    );

    final captured = await coordinator.capture(
      trustedContext: trustedContext(),
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final decision = const AgentProductionRolloutMonitorActivationPlanner()
        .plan(
          capture: captured.capture!,
          ownerApproval: approvalFor(value),
          evaluatedAtUtc: evaluatedAtUtc,
          planId: 'audit-block-plan',
          phase65SafetyReady: true,
          phase62VersionSafetyReady: true,
          auditReady: false,
          coreFailureIsolationReady: true,
          providerPolicyReady: true,
          emergencyStopClearanceApproved: true,
        );

    expect(
      decision.status,
      AgentProductionRolloutMonitorPlanStatus.blockedAuditReadiness,
    );
  });

  test('core failure isolation is mandatory', () async {
    final value = snapshot();
    final _FakeReader reader = _FakeReader(value);
    final coordinator = AgentProductionRolloutTrustedCaptureCoordinator(
      reader: reader,
    );

    final captured = await coordinator.capture(
      trustedContext: trustedContext(),
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final decision = const AgentProductionRolloutMonitorActivationPlanner()
        .plan(
          capture: captured.capture!,
          ownerApproval: approvalFor(value),
          evaluatedAtUtc: evaluatedAtUtc,
          planId: 'core-isolation-block-plan',
          phase65SafetyReady: true,
          phase62VersionSafetyReady: true,
          auditReady: true,
          coreFailureIsolationReady: false,
          providerPolicyReady: true,
          emergencyStopClearanceApproved: true,
        );

    expect(
      decision.status,
      AgentProductionRolloutMonitorPlanStatus.blockedCoreFailureIsolation,
    );
  });

  test('free-first provider policy readiness is mandatory', () async {
    final value = snapshot();
    final _FakeReader reader = _FakeReader(value);
    final coordinator = AgentProductionRolloutTrustedCaptureCoordinator(
      reader: reader,
    );

    final captured = await coordinator.capture(
      trustedContext: trustedContext(),
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final decision = const AgentProductionRolloutMonitorActivationPlanner()
        .plan(
          capture: captured.capture!,
          ownerApproval: approvalFor(value),
          evaluatedAtUtc: evaluatedAtUtc,
          planId: 'provider-policy-block-plan',
          phase65SafetyReady: true,
          phase62VersionSafetyReady: true,
          auditReady: true,
          coreFailureIsolationReady: true,
          providerPolicyReady: false,
          emergencyStopClearanceApproved: true,
        );

    expect(
      decision.status,
      AgentProductionRolloutMonitorPlanStatus.blockedProviderPolicy,
    );
  });

  test('Emergency Read-Only clearance must be explicit', () async {
    final value = snapshot();
    final _FakeReader reader = _FakeReader(value);
    final coordinator = AgentProductionRolloutTrustedCaptureCoordinator(
      reader: reader,
    );

    final captured = await coordinator.capture(
      trustedContext: trustedContext(),
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final decision = const AgentProductionRolloutMonitorActivationPlanner()
        .plan(
          capture: captured.capture!,
          ownerApproval: approvalFor(value),
          evaluatedAtUtc: evaluatedAtUtc,
          planId: 'emergency-clearance-block-plan',
          phase65SafetyReady: true,
          phase62VersionSafetyReady: true,
          auditReady: true,
          coreFailureIsolationReady: true,
          providerPolicyReady: true,
          emergencyStopClearanceApproved: false,
        );

    expect(
      decision.status,
      AgentProductionRolloutMonitorPlanStatus.blockedEmergencyClearance,
    );
  });

  test('clean capture produces MONITOR_ONLY plan only', () async {
    final value = snapshot();
    final _FakeReader reader = _FakeReader(value);
    final coordinator = AgentProductionRolloutTrustedCaptureCoordinator(
      reader: reader,
    );

    final captured = await coordinator.capture(
      trustedContext: trustedContext(),
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final decision = const AgentProductionRolloutMonitorActivationPlanner()
        .plan(
          capture: captured.capture!,
          ownerApproval: approvalFor(value),
          evaluatedAtUtc: evaluatedAtUtc,
          planId: 'initial-monitor-only-plan',
          phase65SafetyReady: true,
          phase62VersionSafetyReady: true,
          auditReady: true,
          coreFailureIsolationReady: true,
          providerPolicyReady: true,
          emergencyStopClearanceApproved: true,
        );

    expect(decision.eligible, true);
    expect(
      decision.status,
      AgentProductionRolloutMonitorPlanStatus.eligibleMonitorOnlyPlan,
    );

    final plan = decision.plan!;

    expect(plan.targetStage, AgentProductionRolloutStage.monitorOnly);
    expect(plan.targetMasterEnabled, true);
    expect(plan.targetEmergencyReadOnly, false);
    expect(plan.targetFreeAiEnabled, true);
    expect(plan.targetLocalAiEnabled, false);
    expect(plan.targetPaidCodeAiEnabled, false);
    expect(plan.targetPaidReasoningEnabled, false);
    expect(plan.targetCallAgentEnabled, false);
    expect(plan.autoTrafficPercent, 0);
    expect(plan.businessWriteTrafficPercent, 0);
    expect(plan.channelsRemainDisabledExceptAppChat, true);
    expect(plan.performsWrite, false);
  });

  test('atomic precondition is exact and expires within two minutes', () async {
    final value = snapshot();
    final _FakeReader reader = _FakeReader(value);
    final coordinator = AgentProductionRolloutTrustedCaptureCoordinator(
      reader: reader,
    );

    final captured = await coordinator.capture(
      trustedContext: trustedContext(),
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final decision = const AgentProductionRolloutMonitorActivationPlanner()
        .plan(
          capture: captured.capture!,
          ownerApproval: approvalFor(value),
          evaluatedAtUtc: evaluatedAtUtc,
          planId: 'atomic-precondition-plan',
          phase65SafetyReady: true,
          phase62VersionSafetyReady: true,
          auditReady: true,
          coreFailureIsolationReady: true,
          providerPolicyReady: true,
          emergencyStopClearanceApproved: true,
        );

    final precondition = decision.plan!.precondition;

    expect(precondition.requiresTransactionalReread, true);
    expect(precondition.requiresExactControlStateMatch, true);
    expect(precondition.requiresAtomicAudit, true);
    expect(precondition.authorizesWriteByItself, false);
    expect(precondition.expectedMasterEnabled, false);
    expect(precondition.expectedEmergencyReadOnly, true);
    expect(precondition.expectedNoEnabledAutoRole, true);
    expect(
      precondition.expiresAtUtc.difference(precondition.createdAtUtc),
      lessThanOrEqualTo(const Duration(minutes: 2)),
    );
  });

  test('write boundary exposes zero Step 1C execution authority', () async {
    final value = snapshot();
    final _FakeReader reader = _FakeReader(value);
    final coordinator = AgentProductionRolloutTrustedCaptureCoordinator(
      reader: reader,
    );

    final captured = await coordinator.capture(
      trustedContext: trustedContext(),
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final decision = const AgentProductionRolloutMonitorActivationPlanner()
        .plan(
          capture: captured.capture!,
          ownerApproval: approvalFor(value),
          evaluatedAtUtc: evaluatedAtUtc,
          planId: 'write-boundary-plan',
          phase65SafetyReady: true,
          phase62VersionSafetyReady: true,
          auditReady: true,
          coreFailureIsolationReady: true,
          providerPolicyReady: true,
          emergencyStopClearanceApproved: true,
        );

    const boundary = AgentProductionRolloutActivationWriteBoundary();

    expect(boundary.canStep1CExecute(decision.plan!), false);
    expect(boundary.transactionExecutorAttached, false);
    expect(boundary.trustedBackendExecutorAttached, false);
    expect(boundary.requiresFreshTransactionalReread, true);
    expect(boundary.requiresExactControlStateSha256Match, true);
    expect(boundary.requiresAtomicAuditInSameTransaction, true);
    expect(boundary.mayWriteMasterSettings, false);
    expect(boundary.mayWriteRoles, false);
    expect(boundary.mayEnableProvider, false);
    expect(boundary.mayConsumeApproval, false);
    expect(boundary.mayGrantPermission, false);
    expect(boundary.mayOverrideRuntimeGate, false);
    expect(boundary.mayClearEmergencyStop, false);
    expect(boundary.mayRouteTraffic, false);
    expect(boundary.mayExecuteBusinessAction, false);
    expect(boundary.mayActivateProduction, false);
  });

  test(
    'capture coordinator and planner themselves have no write authority',
    () {
      final _FakeReader reader = _FakeReader(snapshot());
      final coordinator = AgentProductionRolloutTrustedCaptureCoordinator(
        reader: reader,
      );
      const planner = AgentProductionRolloutMonitorActivationPlanner();

      expect(coordinator.captureOnly, true);
      expect(coordinator.storesRawOwnerIdentity, false);
      expect(coordinator.storesRawSessionToken, false);
      expect(coordinator.consumesApproval, false);
      expect(coordinator.grantsPermission, false);
      expect(coordinator.writesFirestore, false);
      expect(coordinator.activatesRollout, false);

      expect(planner.plannerOnly, true);
      expect(planner.writesFirestore, false);
      expect(planner.consumesApproval, false);
      expect(planner.grantsPermission, false);
      expect(planner.changesMasterSettings, false);
      expect(planner.changesAgentMode, false);
      expect(planner.activatesRollout, false);
      expect(planner.routesTraffic, false);
      expect(planner.callsProvider, false);
      expect(planner.executesBusinessAction, false);
    },
  );
}

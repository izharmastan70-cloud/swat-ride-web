import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_enums.dart';
import 'package:swat_ride/ai_agent/constants/agent_production_rollout_snapshot_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_production_rollout_owner_approval.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_live_state_source.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_snapshot_binding_service.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_snapshot_policy.dart';

void main() {
  const AgentProductionRolloutSnapshotBindingService binding =
      AgentProductionRolloutSnapshotBindingService();

  const AgentProductionRolloutSnapshotPolicy policy =
      AgentProductionRolloutSnapshotPolicy();

  const String phase65Sha =
      '1111111111111111111111111111111111111111111111111111111111111111';
  const String phase62Sha =
      '2222222222222222222222222222222222222222222222222222222222222222';
  const String ownerSha =
      '3333333333333333333333333333333333333333333333333333333333333333';

  final DateTime capturedAtUtc = DateTime.utc(2026, 8, 24, 16, 0);
  final DateTime evaluatedAtUtc = DateTime.utc(2026, 8, 24, 16, 2);

  AgentMasterSettings settings({
    bool masterEnabled = false,
    bool emergencyReadOnly = true,
    bool approvalEngineEnabled = true,
    bool auditLoggingEnabled = true,
  }) {
    return AgentMasterSettings.safeDefaults().copyWith(
      masterEnabled: masterEnabled,
      emergencyReadOnly: emergencyReadOnly,
      approvalEngineEnabled: approvalEngineEnabled,
      auditLoggingEnabled: auditLoggingEnabled,
    );
  }

  AgentRole role({
    required String roleId,
    String mode = AgentMode.monitorOnly,
    bool enabled = true,
    List<String> allowedActions = const <String>[],
  }) {
    return AgentRole(
      roleId: roleId,
      name: roleId,
      description: 'Synthetic Phase 66 role.',
      module: 'core',
      enabled: enabled,
      mode: mode,
      allowedActions: allowedActions,
      approvalRequiredActions: const <String>[],
      forbiddenActions: const <String>[],
      aiClass: 'FREE_AI',
      privacyLevel: 'INTERNAL',
      createdAt: DateTime.utc(2026, 8, 1),
    );
  }

  AgentProductionRolloutOwnerApproval approvalFor(
    String snapshotSha, {
    String requestedStage = AgentProductionRolloutStage.monitorOnly,
    DateTime? approvedAt,
    DateTime? expiresAt,
  }) {
    final DateTime approved = approvedAt ?? DateTime.utc(2026, 8, 24, 16, 1);

    return AgentProductionRolloutOwnerApproval(
      approvalId: 'owner-phase66-monitor-only-approval-1',
      ownerReferenceSha256: ownerSha,
      snapshotFingerprintSha256: snapshotSha,
      requestedStage: requestedStage,
      approvedAtUtc: approved,
      expiresAtUtc: expiresAt ?? approved.add(const Duration(minutes: 10)),
      explicitOwnerApproval: true,
    );
  }

  test('locked rollout order is preserved', () {
    expect(AgentProductionRolloutStage.controlledOrder, <String>[
      AgentProductionRolloutStage.off,
      AgentProductionRolloutStage.monitorOnly,
      AgentProductionRolloutStage.suggestOnly,
      AgentProductionRolloutStage.askFirst,
      AgentProductionRolloutStage.limitedAuto,
      AgentProductionRolloutStage.fullSafeAuto,
    ]);
  });

  test('same exact live state produces same SHA-256 fingerprint', () {
    final first = binding.bind(
      settings: settings(),
      roles: <AgentRole>[
        role(
          roleId: 'b_agent',
          allowedActions: <String>['core.read_b', 'core.read_a'],
        ),
        role(roleId: 'a_agent'),
      ],
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final second = binding.bind(
      settings: settings(),
      roles: <AgentRole>[
        role(roleId: 'a_agent'),
        role(
          roleId: 'b_agent',
          allowedActions: <String>['core.read_a', 'core.read_b'],
        ),
      ],
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    expect(first.snapshotFingerprintSha256, second.snapshotFingerprintSha256);
    expect(first.snapshotFingerprintSha256.length, 64);
  });

  test('control-state change changes snapshot fingerprint', () {
    final safe = binding.bind(
      settings: settings(),
      roles: <AgentRole>[role(roleId: 'ride_agent')],
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final changed = binding.bind(
      settings: settings(masterEnabled: true),
      roles: <AgentRole>[role(roleId: 'ride_agent')],
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    expect(
      changed.snapshotFingerprintSha256,
      isNot(safe.snapshotFingerprintSha256),
    );
  });

  test('snapshot contains control metadata only', () {
    final snapshot = binding.bind(
      settings: settings(),
      roles: <AgentRole>[role(roleId: 'ride_agent')],
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    expect(snapshot.liveReadOnlySnapshot, true);
    expect(snapshot.containsRawSecrets, false);
    expect(snapshot.containsAuthTokens, false);
    expect(snapshot.containsPaymentCredentials, false);
    expect(snapshot.containsPrivateCustomerPayload, false);
  });

  test(
    'safe baseline + exact Owner binding yields MONITOR_ONLY handoff only',
    () {
      final snapshot = binding.bind(
        settings: settings(),
        roles: <AgentRole>[
          role(roleId: 'ride_agent'),
          role(roleId: 'food_agent', mode: AgentMode.off, enabled: false),
        ],
        capturedAtUtc: capturedAtUtc,
        phase65SafetyEvidenceSha256: phase65Sha,
        phase62VersionEvidenceSha256: phase62Sha,
      );

      final decision = policy.evaluate(
        snapshot: snapshot,
        ownerApproval: approvalFor(snapshot.snapshotFingerprintSha256),
        evaluatedAtUtc: evaluatedAtUtc,
        phase65SafetyReady: true,
        phase62VersionSafetyReady: true,
      );

      expect(
        decision.status,
        AgentProductionRolloutSnapshotPolicyStatus.eligibleMonitorOnlyHandoff,
      );
      expect(decision.monitorOnlyHandoffEligible, true);
      expect(decision.activatesRollout, false);
      expect(decision.changesAgentMode, false);
      expect(decision.changesMasterSettings, false);
    },
  );

  test('stale live snapshot fails closed', () {
    final snapshot = binding.bind(
      settings: settings(),
      roles: <AgentRole>[role(roleId: 'ride_agent')],
      capturedAtUtc: DateTime.utc(2026, 8, 24, 15, 50),
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final decision = policy.evaluate(
      snapshot: snapshot,
      ownerApproval: approvalFor(snapshot.snapshotFingerprintSha256),
      evaluatedAtUtc: evaluatedAtUtc,
      phase65SafetyReady: true,
      phase62VersionSafetyReady: true,
    );

    expect(
      decision.status,
      AgentProductionRolloutSnapshotPolicyStatus.blockedStaleSnapshot,
    );
  });

  test('future-skewed live snapshot fails closed', () {
    final snapshot = binding.bind(
      settings: settings(),
      roles: <AgentRole>[role(roleId: 'ride_agent')],
      capturedAtUtc: DateTime.utc(2026, 8, 24, 16, 4),
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final decision = policy.evaluate(
      snapshot: snapshot,
      ownerApproval: approvalFor(snapshot.snapshotFingerprintSha256),
      evaluatedAtUtc: evaluatedAtUtc,
      phase65SafetyReady: true,
      phase62VersionSafetyReady: true,
    );

    expect(
      decision.status,
      AgentProductionRolloutSnapshotPolicyStatus.blockedFutureSnapshot,
    );
  });

  test('Phase 65 safety readiness is mandatory', () {
    final snapshot = binding.bind(
      settings: settings(),
      roles: <AgentRole>[role(roleId: 'ride_agent')],
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final decision = policy.evaluate(
      snapshot: snapshot,
      ownerApproval: approvalFor(snapshot.snapshotFingerprintSha256),
      evaluatedAtUtc: evaluatedAtUtc,
      phase65SafetyReady: false,
      phase62VersionSafetyReady: true,
    );

    expect(
      decision.status,
      AgentProductionRolloutSnapshotPolicyStatus.blockedPhase65Evidence,
    );
  });

  test('Phase 62 version/rollback readiness is mandatory', () {
    final snapshot = binding.bind(
      settings: settings(),
      roles: <AgentRole>[role(roleId: 'ride_agent')],
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final decision = policy.evaluate(
      snapshot: snapshot,
      ownerApproval: approvalFor(snapshot.snapshotFingerprintSha256),
      evaluatedAtUtc: evaluatedAtUtc,
      phase65SafetyReady: true,
      phase62VersionSafetyReady: false,
    );

    expect(
      decision.status,
      AgentProductionRolloutSnapshotPolicyStatus.blockedPhase62Evidence,
    );
  });

  test('master already enabled before initial rollout fails closed', () {
    final snapshot = binding.bind(
      settings: settings(masterEnabled: true),
      roles: <AgentRole>[role(roleId: 'ride_agent')],
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final decision = policy.evaluate(
      snapshot: snapshot,
      ownerApproval: approvalFor(snapshot.snapshotFingerprintSha256),
      evaluatedAtUtc: evaluatedAtUtc,
      phase65SafetyReady: true,
      phase62VersionSafetyReady: true,
    );

    expect(
      decision.status,
      AgentProductionRolloutSnapshotPolicyStatus.blockedUnsafeBaseline,
    );
  });

  test('enabled live AUTO role before controlled rollout fails closed', () {
    final snapshot = binding.bind(
      settings: settings(),
      roles: <AgentRole>[
        role(roleId: 'unexpected_auto_agent', mode: AgentMode.auto),
      ],
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final decision = policy.evaluate(
      snapshot: snapshot,
      ownerApproval: approvalFor(snapshot.snapshotFingerprintSha256),
      evaluatedAtUtc: evaluatedAtUtc,
      phase65SafetyReady: true,
      phase62VersionSafetyReady: true,
    );

    expect(
      decision.status,
      AgentProductionRolloutSnapshotPolicyStatus.blockedLiveAutoDetected,
    );
  });

  test('Owner approval cannot bind an old/different snapshot', () {
    final snapshot = binding.bind(
      settings: settings(),
      roles: <AgentRole>[role(roleId: 'ride_agent')],
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final decision = policy.evaluate(
      snapshot: snapshot,
      ownerApproval: approvalFor(
        'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
      ),
      evaluatedAtUtc: evaluatedAtUtc,
      phase65SafetyReady: true,
      phase62VersionSafetyReady: true,
    );

    expect(
      decision.status,
      AgentProductionRolloutSnapshotPolicyStatus.blockedApprovalBinding,
    );
  });

  test('expired Owner approval fails closed', () {
    final snapshot = binding.bind(
      settings: settings(),
      roles: <AgentRole>[role(roleId: 'ride_agent')],
      capturedAtUtc: capturedAtUtc,
      phase65SafetyEvidenceSha256: phase65Sha,
      phase62VersionEvidenceSha256: phase62Sha,
    );

    final approvedAt = DateTime.utc(2026, 8, 24, 15, 50);

    final decision = policy.evaluate(
      snapshot: snapshot,
      ownerApproval: approvalFor(
        snapshot.snapshotFingerprintSha256,
        approvedAt: approvedAt,
        expiresAt: approvedAt.add(const Duration(minutes: 10)),
      ),
      evaluatedAtUtc: evaluatedAtUtc,
      phase65SafetyReady: true,
      phase62VersionSafetyReady: true,
    );

    expect(
      decision.status,
      AgentProductionRolloutSnapshotPolicyStatus.blockedApprovalExpired,
    );
  });

  test('Owner approval validity cannot exceed 15 minutes', () {
    final approvedAt = DateTime.utc(2026, 8, 24, 16, 1);

    expect(
      () => AgentProductionRolloutOwnerApproval(
        approvalId: 'too-long',
        ownerReferenceSha256: ownerSha,
        snapshotFingerprintSha256: phase65Sha,
        requestedStage: AgentProductionRolloutStage.monitorOnly,
        approvedAtUtc: approvedAt,
        expiresAtUtc: approvedAt.add(const Duration(minutes: 16)),
        explicitOwnerApproval: true,
      ),
      throwsFormatException,
    );
  });

  test('Step 1B Owner approval model cannot request stage skip', () {
    final approvedAt = DateTime.utc(2026, 8, 24, 16, 1);

    expect(
      () => AgentProductionRolloutOwnerApproval(
        approvalId: 'skip-stage',
        ownerReferenceSha256: ownerSha,
        snapshotFingerprintSha256: phase65Sha,
        requestedStage: AgentProductionRolloutStage.suggestOnly,
        approvedAtUtc: approvedAt,
        expiresAtUtc: approvedAt.add(const Duration(minutes: 10)),
        explicitOwnerApproval: true,
      ),
      throwsFormatException,
    );
  });

  test('Owner approval metadata consumes nothing and activates nothing', () {
    final approval = approvalFor(phase65Sha);

    expect(approval.metadataOnly, true);
    expect(approval.approvalEngineConsumptionPerformed, false);
    expect(approval.permissionGranted, false);
    expect(approval.runtimeGateOverridden, false);
    expect(approval.rolloutActivated, false);
    expect(approval.agentModeChanged, false);
  });

  test('live source declares read-only/no execution authority', () {
    final AgentProductionRolloutLiveStateSource source =
        AgentProductionRolloutLiveStateSource();

    expect(source.readOnly, true);
    expect(source.writesMasterSettings, false);
    expect(source.writesRoles, false);
    expect(source.createsApproval, false);
    expect(source.consumesApproval, false);
    expect(source.changesAgentMode, false);
    expect(source.activatesRollout, false);
    expect(source.callsProvider, false);
    expect(source.writesBusinessData, false);
  });

  test('binding/policy themselves grant no runtime authority', () {
    expect(binding.readsFirestore, false);
    expect(binding.writesFirestore, false);
    expect(binding.callsProvider, false);
    expect(binding.consumesApproval, false);
    expect(binding.grantsPermission, false);
    expect(binding.activatesRollout, false);

    expect(policy.policyOnly, true);
    expect(policy.activatesRollout, false);
    expect(policy.changesAgentMode, false);
    expect(policy.changesMasterSettings, false);
    expect(policy.consumesApproval, false);
    expect(policy.grantsPermission, false);
    expect(policy.overridesRuntimeGate, false);
    expect(policy.changesEmergencyStop, false);
    expect(policy.callsProvider, false);
    expect(policy.readsFirestore, false);
    expect(policy.writesFirestore, false);
    expect(policy.writesBusinessData, false);
  });
}

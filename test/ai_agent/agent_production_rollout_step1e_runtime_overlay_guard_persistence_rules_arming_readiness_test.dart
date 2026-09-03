import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/constants/agent_enums.dart';
import 'package:swat_ride/ai_agent/constants/agent_production_rollout_runtime_guard_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_production_rollout_runtime_guard.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_arming_readiness_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_guard_repository.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_runtime_monitor_only_overlay.dart';

void main() {
  const String controlSha =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const String planSha =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
  const String actorSha =
      'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

  AgentProductionRolloutRuntimeGuard guard({
    bool enabled = true,
    int revision = 1,
  }) {
    return AgentProductionRolloutRuntimeGuard(
      enabled: enabled,
      guardVersion: AgentProductionRolloutRuntimeGuardVersion.monitorOnlyV1,
      revision: revision,
      targetStage: AgentProductionRolloutRuntimeGuardStatus.monitorOnly,
      runtimeMonitorOnlyOverlayEnforced: true,
      noAutoBusinessWriteBoundaryEnforced: true,
      appChatOnly: true,
      autoTrafficPercent: 0,
      businessWriteTrafficPercent: 0,
      externalChannelsEnabled: false,
      controlStateFingerprintSha256: controlSha,
      planFingerprintSha256: planSha,
      roleCount: 23,
      ownerApprovalId: 'owner-approval-monitor-1',
      actorReferenceSha256: actorSha,
    );
  }

  AgentMasterSettings settings({
    bool masterEnabled = true,
    bool emergencyReadOnly = false,
    bool freeAiEnabled = true,
  }) {
    return AgentMasterSettings.safeDefaults().copyWith(
      masterEnabled: masterEnabled,
      emergencyReadOnly: emergencyReadOnly,
      freeAiEnabled: freeAiEnabled,
    );
  }

  AgentRole role({
    required String roleId,
    required String module,
    required String mode,
    required List<String> allowedActions,
    List<String> approvalRequiredActions = const <String>[],
    bool enabled = true,
    String aiClass = AiClass.freeAi,
  }) {
    return AgentRole(
      roleId: roleId,
      name: roleId,
      description: 'Synthetic Phase 66 Step 1E role.',
      module: module,
      enabled: enabled,
      mode: mode,
      allowedActions: allowedActions,
      approvalRequiredActions: approvalRequiredActions,
      forbiddenActions: const <String>[],
      aiClass: aiClass,
      privacyLevel: 'INTERNAL',
      createdAt: DateTime.utc(2026, 8, 1),
    );
  }

  test('valid MONITOR_ONLY guard serializes round-trip', () {
    final value = guard();
    final restored = AgentProductionRolloutRuntimeGuard.fromMap(value.toMap());

    expect(restored.enabled, true);
    expect(restored.revision, 1);
    expect(
      restored.guardVersion,
      AgentProductionRolloutRuntimeGuardVersion.monitorOnlyV1,
    );
    expect(restored.autoTrafficPercent, 0);
    expect(restored.businessWriteTrafficPercent, 0);
    expect(restored.externalChannelsEnabled, false);
  });

  test('invalid auto traffic cannot enter runtime guard', () {
    expect(
      () => AgentProductionRolloutRuntimeGuard(
        enabled: true,
        guardVersion: AgentProductionRolloutRuntimeGuardVersion.monitorOnlyV1,
        revision: 1,
        targetStage: AgentProductionRolloutRuntimeGuardStatus.monitorOnly,
        runtimeMonitorOnlyOverlayEnforced: true,
        noAutoBusinessWriteBoundaryEnforced: true,
        appChatOnly: true,
        autoTrafficPercent: 1,
        businessWriteTrafficPercent: 0,
        externalChannelsEnabled: false,
        controlStateFingerprintSha256: controlSha,
        planFingerprintSha256: planSha,
        roleCount: 23,
        ownerApprovalId: 'approval',
        actorReferenceSha256: actorSha,
      ),
      throwsFormatException,
    );
  });

  test('AUTO read role is reduced to MONITOR_ONLY at runtime', () {
    const overlay = AgentProductionRolloutRuntimeMonitorOnlyOverlay();

    final decision = overlay.evaluate(
      guard: guard(),
      settings: settings(),
      role: role(
        roleId: 'core_auto_agent',
        module: 'core',
        mode: AgentMode.auto,
        allowedActions: const <String>[AgentActionId.readSystemHealth],
      ),
      actionId: AgentActionId.readSystemHealth,
    );

    expect(decision.isAllowed, true);
    expect(decision.effectiveMode, AgentMode.monitorOnly);
  });

  test('AUTO write action is denied by MONITOR_ONLY ceiling', () {
    const overlay = AgentProductionRolloutRuntimeMonitorOnlyOverlay();

    final decision = overlay.evaluate(
      guard: guard(),
      settings: settings(),
      role: role(
        roleId: 'core_auto_agent',
        module: 'core',
        mode: AgentMode.auto,
        allowedActions: const <String>[AgentActionId.createSuggestion],
      ),
      actionId: AgentActionId.createSuggestion,
    );

    expect(decision.isDenied, true);
    expect(decision.reason, contains('MONITOR_ONLY'));
  });

  test('SUGGEST_ONLY write action is reduced and denied', () {
    const overlay = AgentProductionRolloutRuntimeMonitorOnlyOverlay();

    final decision = overlay.evaluate(
      guard: guard(),
      settings: settings(),
      role: role(
        roleId: 'suggest_agent',
        module: 'core',
        mode: AgentMode.suggestOnly,
        allowedActions: const <String>[AgentActionId.createSuggestion],
      ),
      actionId: AgentActionId.createSuggestion,
    );

    expect(decision.isDenied, true);
  });

  test('OFF role is never elevated by overlay', () {
    const overlay = AgentProductionRolloutRuntimeMonitorOnlyOverlay();

    final decision = overlay.evaluate(
      guard: guard(),
      settings: settings(),
      role: role(
        roleId: 'off_agent',
        module: 'core',
        mode: AgentMode.off,
        allowedActions: const <String>[AgentActionId.readSystemHealth],
      ),
      actionId: AgentActionId.readSystemHealth,
    );

    expect(decision.isDenied, true);
    expect(decision.reason, contains('OFF role'));
  });

  test('ASK_FIRST role remains blocked during MONITOR_ONLY', () {
    const overlay = AgentProductionRolloutRuntimeMonitorOnlyOverlay();

    final decision = overlay.evaluate(
      guard: guard(),
      settings: settings(),
      role: role(
        roleId: 'high_risk_agent',
        module: 'core',
        mode: AgentMode.askFirst,
        allowedActions: const <String>[AgentActionId.readSystemHealth],
      ),
      actionId: AgentActionId.readSystemHealth,
    );

    expect(decision.isDenied, true);
    expect(decision.reason, contains('ASK_FIRST'));
  });

  test('role-level approval requirement is blocked', () {
    const overlay = AgentProductionRolloutRuntimeMonitorOnlyOverlay();

    final decision = overlay.evaluate(
      guard: guard(),
      settings: settings(),
      role: role(
        roleId: 'approval_read_agent',
        module: 'core',
        mode: AgentMode.auto,
        allowedActions: const <String>[AgentActionId.readSystemHealth],
        approvalRequiredActions: const <String>[AgentActionId.readSystemHealth],
      ),
      actionId: AgentActionId.readSystemHealth,
    );

    expect(decision.isDenied, true);
    expect(decision.reason, contains('approval-required'));
  });

  test('external Email module is blocked even for read action', () {
    const overlay = AgentProductionRolloutRuntimeMonitorOnlyOverlay();

    final decision = overlay.evaluate(
      guard: guard(),
      settings: settings(),
      role: role(
        roleId: 'email_agent',
        module: 'email',
        mode: AgentMode.monitorOnly,
        allowedActions: const <String>[AgentActionId.readSystemHealth],
      ),
      actionId: AgentActionId.readSystemHealth,
    );

    expect(decision.isDenied, true);
    expect(decision.reason, contains('External channel'));
  });

  test('external Call module is blocked before call authority', () {
    const overlay = AgentProductionRolloutRuntimeMonitorOnlyOverlay();

    final decision = overlay.evaluate(
      guard: guard(),
      settings: settings(),
      role: role(
        roleId: 'call_agent',
        module: 'call',
        mode: AgentMode.auto,
        allowedActions: const <String>[AgentActionId.createCallRideBooking],
      ),
      actionId: AgentActionId.createCallRideBooking,
    );

    expect(decision.isDenied, true);
    expect(decision.reason, contains('External channel'));
  });

  test('disabled production guard fails closed', () {
    const overlay = AgentProductionRolloutRuntimeMonitorOnlyOverlay();

    final decision = overlay.evaluate(
      guard: guard(enabled: false),
      settings: settings(),
      role: role(
        roleId: 'core_agent',
        module: 'core',
        mode: AgentMode.monitorOnly,
        allowedActions: const <String>[AgentActionId.readSystemHealth],
      ),
      actionId: AgentActionId.readSystemHealth,
    );

    expect(decision.isDenied, true);
    expect(decision.reason, contains('guard is disabled'));
  });

  test('Master OFF remains authoritative', () {
    const overlay = AgentProductionRolloutRuntimeMonitorOnlyOverlay();

    final decision = overlay.evaluate(
      guard: guard(),
      settings: settings(masterEnabled: false),
      role: role(
        roleId: 'core_agent',
        module: 'core',
        mode: AgentMode.monitorOnly,
        allowedActions: const <String>[AgentActionId.readSystemHealth],
      ),
      actionId: AgentActionId.readSystemHealth,
    );

    expect(decision.isDenied, true);
    expect(decision.reason, contains('Master Control is OFF'));
  });

  test('Free AI OFF remains authoritative', () {
    const overlay = AgentProductionRolloutRuntimeMonitorOnlyOverlay();

    final decision = overlay.evaluate(
      guard: guard(),
      settings: settings(freeAiEnabled: false),
      role: role(
        roleId: 'core_agent',
        module: 'core',
        mode: AgentMode.monitorOnly,
        allowedActions: const <String>[AgentActionId.readSystemHealth],
      ),
      actionId: AgentActionId.readSystemHealth,
    );

    expect(decision.isDenied, true);
  });

  test('overlay exposes no mutation or AUTO authority', () {
    const overlay = AgentProductionRolloutRuntimeMonitorOnlyOverlay();

    expect(overlay.privilegeCeilingOnly, true);
    expect(overlay.rewritesPersistedRole, false);
    expect(overlay.grantsPermission, false);
    expect(overlay.consumesApproval, false);
    expect(overlay.writesFirestore, false);
    expect(overlay.routesAutoTraffic, false);
    expect(overlay.executesBusinessWrite, false);
    expect(overlay.enablesExternalChannel, false);
  });

  test('guard persistence request binds next exact revision', () {
    final request = AgentProductionRolloutGuardPersistenceRequest(
      guard: guard(revision: 2),
      expectedPreviousRevision: 1,
      requestedAtUtc: DateTime.utc(2026, 8, 24, 17, 30),
    );

    expect(request.guard.revision, 2);
    expect(request.expectedPreviousRevision, 1);
  });

  test('guard repository defaults NOT ARMED without Firebase init', () {
    final repository = AgentProductionRolloutGuardRepository();

    expect(repository.persistenceArmed, false);
    expect(repository.defaultsNotArmed, true);
    expect(repository.usesFirestoreTransaction, true);
    expect(repository.usesSameTransactionAudit, true);
    expect(repository.activatesProduction, false);
    expect(repository.armsActivationRepository, false);
    expect(repository.scriptInvokesGuardPersistence, false);
  });

  test('unarmed guard persistence fails before Firebase access', () async {
    final repository = AgentProductionRolloutGuardRepository();

    final result = await repository.persist(
      request: AgentProductionRolloutGuardPersistenceRequest(
        guard: guard(),
        expectedPreviousRevision: 0,
        requestedAtUtc: DateTime.utc(2026, 8, 24, 17, 30),
      ),
    );

    expect(
      result.status,
      AgentProductionRolloutGuardPersistenceStatus.blockedNotArmed,
    );
    expect(result.persisted, false);
    expect(result.activatesProduction, false);
    expect(result.armsActivationRepository, false);
  });

  test('readiness stays NOT ARMED until exact live guard is persisted', () {
    const policy = AgentProductionRolloutArmingReadinessPolicy();

    final decision = policy.evaluate(
      runtimeOverlayVerified: true,
      guardPersistenceContractVerified: true,
      firestoreRulesHardened: true,
      firestoreRulesDeployed: true,
      step1DRepositoryDefaultsNotArmed: true,
      liveGuardPersisted: false,
    );

    expect(
      decision.status,
      AgentProductionRolloutArmingReadinessStatus
          .readyForTrustedGuardPersistenceNotArmed,
    );
    expect(decision.safeArmingReady, false);
    expect(decision.activatesProduction, false);
    expect(decision.armsRepository, false);
  });

  test('readiness can become arm-eligible only after live guard proof', () {
    const policy = AgentProductionRolloutArmingReadinessPolicy();

    final decision = policy.evaluate(
      runtimeOverlayVerified: true,
      guardPersistenceContractVerified: true,
      firestoreRulesHardened: true,
      firestoreRulesDeployed: true,
      step1DRepositoryDefaultsNotArmed: true,
      liveGuardPersisted: true,
    );

    expect(
      decision.status,
      AgentProductionRolloutArmingReadinessStatus.readyToArmMonitorRepository,
    );
    expect(decision.safeArmingReady, true);
    expect(decision.activatesProduction, false);
    expect(decision.armsRepository, false);
  });
}

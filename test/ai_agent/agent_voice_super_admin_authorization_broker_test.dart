import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/constants/agent_enums.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_permission_decision.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_authorization.dart';
import 'package:swat_ride/ai_agent/models/agent_voice_super_admin_foundation.dart';
import 'package:swat_ride/ai_agent/services/agent_action_registry.dart';
import 'package:swat_ride/ai_agent/services/agent_permission_engine.dart';
import 'package:swat_ride/ai_agent/services/agent_runtime_gate.dart';
import 'package:swat_ride/ai_agent/services/agent_voice_super_admin_authorization_broker.dart';

class _MemoryVoiceAudit implements AgentVoiceSuperAdminAuthorizationAudit {
  final List<AgentPermissionDecision> decisions = <AgentPermissionDecision>[];

  @override
  Future<void> recordPermissionDecision({
    required AgentRole role,
    required AgentPermissionDecision decision,
    required String actorId,
  }) async {
    decisions.add(decision);
  }
}

AgentRole _voiceRole() {
  return buildInitialAgentRoles().firstWhere(
    (AgentRole role) => role.roleId == AgentVoiceSuperAdminFoundation.roleId,
  );
}

AgentMasterSettings _enabledSettings() {
  return AgentMasterSettings.safeDefaults().copyWith(
    masterEnabled: true,
    freeAiEnabled: true,
    voiceSuperAdminAgentEnabled: true,
  );
}

AgentVoiceSuperAdminSessionBinding _session({
  AgentVoiceSuperAdminVerificationLevel verificationLevel =
      AgentVoiceSuperAdminVerificationLevel.linkedAccount,
}) {
  return AgentVoiceSuperAdminSessionBinding(
    principalType: AgentVoiceSuperAdminPrincipalType.superAdmin,
    principalUid: 'owner-1',
    deviceBindingId: 'device-binding-1',
    sessionId: 'session-1',
    verificationLevel: verificationLevel,
    verifiedAt: DateTime.utc(2026, 8, 18, 4),
    expiresAt: DateTime.utc(2026, 8, 18, 6),
  );
}

AgentVoiceSuperAdminAuthorizationRequest _request({
  String actionId = AgentActionId.readVoiceSuperAdminVerifiedReport,
  String actorId = 'owner-1',
  String deviceBindingId = 'device-binding-1',
  String sessionId = 'session-1',
}) {
  return AgentVoiceSuperAdminAuthorizationRequest(
    actionId: actionId,
    actorId: actorId,
    expectedDeviceBindingId: deviceBindingId,
    expectedSessionId: sessionId,
  );
}

void main() {
  group('Phase 48 Step 2C-B central configuration', () {
    test('dedicated Voice Super Admin action is known read-only action', () {
      expect(
        AgentActionId.isKnown(AgentActionId.readVoiceSuperAdminVerifiedReport),
        isTrue,
      );

      final action = AgentActionRegistry.get(
        AgentActionId.readVoiceSuperAdminVerifiedReport,
      );

      expect(action, isNotNull);
      expect(action!.module, AgentVoiceSuperAdminFoundation.module);
      expect(action.readOnly, isTrue);
      expect(action.alwaysRequiresApproval, isFalse);
    });

    test('isolated role allows only dedicated Voice report action', () {
      final role = _voiceRole();

      expect(role.module, AgentVoiceSuperAdminFoundation.module);
      expect(role.mode, AgentMode.monitorOnly);
      expect(role.privacyLevel, PrivacyLevel.highlySensitive);
      expect(role.allowedActions, <String>[
        AgentActionId.readVoiceSuperAdminVerifiedReport,
      ]);
      expect(role.approvalRequiredActions, isEmpty);
      expect(role.forbiddenActions, isEmpty);
    });

    test('Voice master switch defaults OFF and round-trips', () {
      final defaults = AgentMasterSettings.safeDefaults();
      expect(defaults.voiceSuperAdminAgentEnabled, isFalse);

      final enabled = defaults.copyWith(voiceSuperAdminAgentEnabled: true);
      expect(enabled.voiceSuperAdminAgentEnabled, isTrue);

      final roundTrip = AgentMasterSettings.fromMap(enabled.toMap());
      expect(roundTrip.voiceSuperAdminAgentEnabled, isTrue);
    });

    test('Runtime Gate denies Voice role while dedicated switch is OFF', () {
      final role = _voiceRole();
      const permissionEngine = AgentPermissionEngine();
      const runtimeGate = AgentRuntimeGate();

      final permission = permissionEngine.evaluate(
        role: role,
        actionId: AgentActionId.readVoiceSuperAdminVerifiedReport,
      );

      final runtime = runtimeGate.apply(
        settings: AgentMasterSettings.safeDefaults().copyWith(
          masterEnabled: true,
          freeAiEnabled: true,
        ),
        role: role,
        permissionDecision: permission,
      );

      expect(runtime.isDenied, isTrue);
      expect(runtime.reason, contains('Voice Super Admin Agent master switch'));
    });

    test('Runtime Gate permits dedicated pure read when switches allow it', () {
      final role = _voiceRole();
      const permissionEngine = AgentPermissionEngine();
      const runtimeGate = AgentRuntimeGate();

      final permission = permissionEngine.evaluate(
        role: role,
        actionId: AgentActionId.readVoiceSuperAdminVerifiedReport,
      );

      final runtime = runtimeGate.apply(
        settings: _enabledSettings(),
        role: role,
        permissionDecision: permission,
      );

      expect(permission.isAllowed, isTrue);
      expect(runtime.isAllowed, isTrue);
      expect(runtime.needsApproval, isFalse);
    });
  });

  group('Phase 48 Step 2C-B exact session binding', () {
    test('voice/text/voiceprint content never grants authority', () {
      final session = _session();

      expect(session.voiceContentGrantsAuthority, isFalse);
      expect(session.textContentGrantsAuthority, isFalse);
      expect(session.biometricOrVoiceprintAloneGrantsAuthority, isFalse);
    });

    test('linked exact active session can read Owner data', () {
      final session = _session();

      expect(
        session.canReadOwnerData(
          now: DateTime.utc(2026, 8, 18, 5),
          expectedDeviceBindingId: 'device-binding-1',
          expectedSessionId: 'session-1',
        ),
        isTrue,
      );
    });

    test('wrong device/session or unverified session fails closed', () {
      final linked = _session();

      expect(
        linked.canReadOwnerData(
          now: DateTime.utc(2026, 8, 18, 5),
          expectedDeviceBindingId: 'wrong-device',
          expectedSessionId: 'session-1',
        ),
        isFalse,
      );

      final unverified = _session(
        verificationLevel: AgentVoiceSuperAdminVerificationLevel.none,
      );

      expect(
        unverified.canReadOwnerData(
          now: DateTime.utc(2026, 8, 18, 5),
          expectedDeviceBindingId: 'device-binding-1',
          expectedSessionId: 'session-1',
        ),
        isFalse,
      );
    });
  });

  group('Phase 48 Step 2C-B authorization broker', () {
    test(
      'exact session + Permission + Runtime allows section acquisition',
      () async {
        final audit = _MemoryVoiceAudit();
        final broker = AgentVoiceSuperAdminAuthorizationBroker(audit: audit);

        final result = await broker.evaluate(
          settings: _enabledSettings(),
          role: _voiceRole(),
          session: _session(),
          request: _request(),
          now: DateTime.utc(2026, 8, 18, 5),
        );

        expect(result.isDenied, isFalse);
        expect(result.decision.isAllowed, isTrue);
        expect(result.mayAcquireVerifiedSections, isTrue);
        expect(audit.decisions, hasLength(1));
      },
    );

    test('actor mismatch fails before central data acquisition', () async {
      final audit = _MemoryVoiceAudit();
      final broker = AgentVoiceSuperAdminAuthorizationBroker(audit: audit);

      final result = await broker.evaluate(
        settings: _enabledSettings(),
        role: _voiceRole(),
        session: _session(),
        request: _request(actorId: 'different-owner'),
        now: DateTime.utc(2026, 8, 18, 5),
      );

      expect(result.isDenied, isTrue);
      expect(result.reachedCentralGate, isFalse);
      expect(result.mayAcquireVerifiedSections, isFalse);
      expect(audit.decisions, hasLength(1));
    });

    test(
      'wrong action fails closed and cannot impersonate module actions',
      () async {
        final audit = _MemoryVoiceAudit();
        final broker = AgentVoiceSuperAdminAuthorizationBroker(audit: audit);

        final result = await broker.evaluate(
          settings: _enabledSettings(),
          role: _voiceRole(),
          session: _session(),
          request: _request(actionId: AgentActionId.readRide),
          now: DateTime.utc(2026, 8, 18, 5),
        );

        expect(result.isDenied, isTrue);
        expect(result.mayAcquireVerifiedSections, isFalse);
      },
    );

    test('master switch OFF fails at Runtime Gate and is audited', () async {
      final audit = _MemoryVoiceAudit();
      final broker = AgentVoiceSuperAdminAuthorizationBroker(audit: audit);

      final settings = _enabledSettings().copyWith(
        voiceSuperAdminAgentEnabled: false,
      );

      final result = await broker.evaluate(
        settings: settings,
        role: _voiceRole(),
        session: _session(),
        request: _request(),
        now: DateTime.utc(2026, 8, 18, 5),
      );

      expect(result.isDenied, isTrue);
      expect(result.reachedCentralGate, isTrue);
      expect(result.reason, contains('master switch'));
      expect(audit.decisions, hasLength(1));
    });

    test('pure read unexpectedly requiring approval fails closed', () async {
      final audit = _MemoryVoiceAudit();
      final broker = AgentVoiceSuperAdminAuthorizationBroker(audit: audit);
      final base = _voiceRole();

      final askFirstRole = AgentRole(
        roleId: base.roleId,
        name: base.name,
        description: base.description,
        module: base.module,
        enabled: true,
        mode: AgentMode.askFirst,
        allowedActions: base.allowedActions,
        approvalRequiredActions: const <String>[],
        forbiddenActions: const <String>[],
        aiClass: base.aiClass,
        privacyLevel: base.privacyLevel,
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
      );

      final result = await broker.evaluate(
        settings: _enabledSettings().copyWith(emergencyReadOnly: false),
        role: askFirstRole,
        session: _session(),
        request: _request(),
        now: DateTime.utc(2026, 8, 18, 5),
      );

      expect(result.isDenied, isTrue);
      expect(result.decision.needsApproval, isFalse);
      expect(result.reason, contains('unexpectedly requires approval'));
      expect(audit.decisions, hasLength(2));
    });

    test(
      'authorization result never grants write/approval/Safety/provider authority',
      () async {
        final audit = _MemoryVoiceAudit();
        final broker = AgentVoiceSuperAdminAuthorizationBroker(audit: audit);

        final result = await broker.evaluate(
          settings: _enabledSettings(),
          role: _voiceRole(),
          session: _session(),
          request: _request(),
          now: DateTime.utc(2026, 8, 18, 5),
        );

        expect(result.mayExecuteBusinessOrAdminWrite, isFalse);
        expect(result.mayConsumeApproval, isFalse);
        expect(result.mayMutateSafety, isFalse);
        expect(result.mayCallProvider, isFalse);
        expect(result.mayUseSpeechTransport, isFalse);
        expect(result.mayDeploy, isFalse);
      },
    );
  });
}

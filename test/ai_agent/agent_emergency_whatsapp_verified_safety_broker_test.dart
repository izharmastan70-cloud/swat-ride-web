import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_emergency_whatsapp_foundation.dart';
import 'package:swat_ride/ai_agent/models/agent_emergency_whatsapp_verified_safety_snapshot.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_permission_decision.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_emergency_whatsapp_verified_safety_broker.dart';
import 'package:swat_ride/ai_agent/services/agent_permission_engine.dart';
import 'package:swat_ride/ai_agent/services/agent_runtime_gate.dart';

AgentRole _role({bool enabled = true}) {
  final seeded = buildInitialAgentRoles().singleWhere(
    (AgentRole item) => item.roleId == AgentEmergencyWhatsAppFoundation.roleId,
  );

  return seeded.copyWith(enabled: enabled);
}

AgentMasterSettings _settings({
  bool emergencyWhatsAppEnabled = true,
  bool emergencyReadOnly = false,
}) {
  return AgentMasterSettings.safeDefaults().copyWith(
    masterEnabled: true,
    freeAiEnabled: true,
    emergencyWhatsAppAgentEnabled: emergencyWhatsAppEnabled,
    emergencyReadOnly: emergencyReadOnly,
  );
}

AgentEmergencyWhatsAppSessionBinding _session(
  DateTime now, {
  String principalUid = 'user_1',
  String conversationId = 'conversation_1',
  String senderBindingId = 'sender_1',
  String sessionId = 'session_1',
  AgentEmergencyWhatsAppVerificationLevel verificationLevel =
      AgentEmergencyWhatsAppVerificationLevel.accountVerified,
}) {
  return AgentEmergencyWhatsAppSessionBinding(
    subjectType: AgentEmergencyWhatsAppSubjectType.customer,
    principalUid: principalUid,
    conversationId: conversationId,
    senderBindingId: senderBindingId,
    sessionId: sessionId,
    verificationLevel: verificationLevel,
    verifiedAt: now.subtract(const Duration(minutes: 1)),
    expiresAt: now.add(const Duration(minutes: 10)),
  );
}

AgentEmergencyWhatsAppVerifiedSafetyRequest _request({
  String userId = 'user_1',
  String conversationId = 'conversation_1',
  String senderBindingId = 'sender_1',
  String sessionId = 'session_1',
}) {
  return AgentEmergencyWhatsAppVerifiedSafetyRequest(
    userId: userId,
    expectedConversationId: conversationId,
    expectedSenderBindingId: senderBindingId,
    expectedSessionId: sessionId,
  );
}

class _Harness {
  _Harness({
    this.snapshot = const AgentEmergencyWhatsAppVerifiedSafetySnapshot(
      incidentSourceVerified: true,
      hasActiveIncident: true,
      eligibleSosContactCountVerified: true,
      status: 'responding',
      category: 'immediateDanger',
      severity: 'critical',
      serviceType: 'normalRide',
      initiatedByRole: 'customer',
      locationStatus: 'available',
      eligibleSosContactCount: 2,
    ),
  });

  final AgentEmergencyWhatsAppVerifiedSafetySnapshot snapshot;

  int sourceCalls = 0;
  int auditCalls = 0;
  final List<AgentPermissionDecision> audited = <AgentPermissionDecision>[];

  AgentEmergencyWhatsAppVerifiedSafetyBroker build() {
    return AgentEmergencyWhatsAppVerifiedSafetyBroker(
      permissionEngine: const AgentPermissionEngine(),
      runtimeGate: const AgentRuntimeGate(),
      auditPermissionDecision:
          ({
            required AgentRole role,
            required AgentPermissionDecision decision,
            required String actorId,
          }) async {
            auditCalls++;
            audited.add(decision);
          },
      loadVerifiedSafety: ({required String userId}) async {
        sourceCalls++;
        return snapshot;
      },
    );
  }
}

void main() {
  group('Phase 47 Step 5B Emergency verified-safety broker', () {
    test(
      'valid exact session reaches sanitized source after central gates',
      () async {
        final now = DateTime.utc(2026, 8, 18, 2, 45);
        final harness = _Harness();
        final broker = harness.build();

        final result = await broker.read(
          settings: _settings(),
          role: _role(),
          session: _session(now),
          request: _request(),
          now: now,
        );

        expect(result.authorizationReachedCentralGate, isTrue);
        expect(result.authorizationPassed, isTrue);
        expect(result.decision.isAllowed, isTrue);
        expect(result.sourceVerified, isTrue);
        expect(result.snapshot.status, 'responding');
        expect(harness.sourceCalls, 1);
        expect(harness.auditCalls, 1);

        expect(result.mayWriteSafetyIncident, isFalse);
        expect(result.maySendWhatsApp, isFalse);
        expect(result.maySendSms, isFalse);
        expect(result.mayPlaceEmergencyCall, isFalse);
        expect(result.mayCallProvider, isFalse);
        expect(result.mayHandleLiveWebhook, isFalse);
        expect(result.mayDeploy, isFalse);
      },
    );

    test(
      'principal mismatch denies before source access and is audited',
      () async {
        final now = DateTime.utc(2026, 8, 18, 2, 45);
        final harness = _Harness();

        final result = await harness.build().read(
          settings: _settings(),
          role: _role(),
          session: _session(now, principalUid: 'user_2'),
          request: _request(userId: 'user_1'),
          now: now,
        );

        expect(result.authorizationPassed, isFalse);
        expect(result.authorizationReachedCentralGate, isFalse);
        expect(result.decision.isDenied, isTrue);
        expect(harness.sourceCalls, 0);
        expect(harness.auditCalls, 1);
      },
    );

    test('channel-bound-only identity denies before source access', () async {
      final now = DateTime.utc(2026, 8, 18, 2, 45);
      final harness = _Harness();

      final result = await harness.build().read(
        settings: _settings(),
        role: _role(),
        session: _session(
          now,
          verificationLevel:
              AgentEmergencyWhatsAppVerificationLevel.channelBound,
        ),
        request: _request(),
        now: now,
      );

      expect(result.authorizationPassed, isFalse);
      expect(result.decision.isDenied, isTrue);
      expect(harness.sourceCalls, 0);
      expect(harness.auditCalls, 1);
    });

    test('exact channel mismatch denies before source access', () async {
      final now = DateTime.utc(2026, 8, 18, 2, 45);
      final harness = _Harness();

      final result = await harness.build().read(
        settings: _settings(),
        role: _role(),
        session: _session(now),
        request: _request(conversationId: 'wrong_conversation'),
        now: now,
      );

      expect(result.authorizationPassed, isFalse);
      expect(result.decision.isDenied, isTrue);
      expect(harness.sourceCalls, 0);
      expect(harness.auditCalls, 1);
    });

    test('wrong role cannot inherit Emergency WhatsApp authority', () async {
      final now = DateTime.utc(2026, 8, 18, 2, 45);
      final harness = _Harness();
      final owner = buildInitialAgentRoles()
          .singleWhere(
            (AgentRole item) => item.roleId == 'owner_whatsapp_agent',
          )
          .copyWith(enabled: true);

      final result = await harness.build().read(
        settings: _settings(),
        role: owner,
        session: _session(now),
        request: _request(),
        now: now,
      );

      expect(result.authorizationPassed, isFalse);
      expect(result.authorizationReachedCentralGate, isFalse);
      expect(result.decision.isDenied, isTrue);
      expect(harness.sourceCalls, 0);
      expect(harness.auditCalls, 1);
    });

    test(
      'Emergency master switch OFF fails closed before source access',
      () async {
        final now = DateTime.utc(2026, 8, 18, 2, 45);
        final harness = _Harness();

        final result = await harness.build().read(
          settings: _settings(emergencyWhatsAppEnabled: false),
          role: _role(),
          session: _session(now),
          request: _request(),
          now: now,
        );

        expect(result.authorizationReachedCentralGate, isTrue);
        expect(result.authorizationPassed, isFalse);
        expect(result.decision.isDenied, isTrue);
        expect(
          result.reason,
          contains('Emergency WhatsApp Agent master switch is OFF'),
        );
        expect(harness.sourceCalls, 0);
        expect(harness.auditCalls, 1);
      },
    );

    test(
      'global Emergency Read-Only still permits pure suggest-only read',
      () async {
        final now = DateTime.utc(2026, 8, 18, 2, 45);
        final harness = _Harness();

        final result = await harness.build().read(
          settings: _settings(emergencyReadOnly: true),
          role: _role(),
          session: _session(now),
          request: _request(),
          now: now,
        );

        expect(result.authorizationPassed, isTrue);
        expect(result.decision.isAllowed, isTrue);
        expect(harness.sourceCalls, 1);
      },
    );

    test('unexpected approval requirement on pure read fails closed', () async {
      final now = DateTime.utc(2026, 8, 18, 2, 45);
      final harness = _Harness();

      final seeded = _role();
      final corruptedPolicyRole = seeded.copyWith(
        approvalRequiredActions: <String>[
          ...seeded.approvalRequiredActions,
          AgentActionId.readEmergencyWhatsAppVerifiedSafety,
        ],
      );

      final result = await harness.build().read(
        settings: _settings(),
        role: corruptedPolicyRole,
        session: _session(now),
        request: _request(),
        now: now,
      );

      expect(result.authorizationPassed, isFalse);
      expect(result.decision.isDenied, isTrue);
      expect(result.reason, contains('unexpectedly requires approval'));
      expect(harness.sourceCalls, 0);
      expect(harness.auditCalls, 2);
    });

    test('source unavailable is explicit and never fabricated', () async {
      final now = DateTime.utc(2026, 8, 18, 2, 45);
      final harness = _Harness(
        snapshot:
            const AgentEmergencyWhatsAppVerifiedSafetySnapshot.unavailable(
              reason: 'verified source unavailable',
            ),
      );

      final result = await harness.build().read(
        settings: _settings(),
        role: _role(),
        session: _session(now),
        request: _request(),
        now: now,
      );

      expect(result.authorizationPassed, isTrue);
      expect(result.sourceVerified, isFalse);
      expect(result.snapshot.status, isNull);
      expect(result.snapshot.category, isNull);
      expect(result.snapshot.eligibleSosContactCount, isNull);
      expect(result.reason, contains('source is unavailable'));
      expect(harness.sourceCalls, 1);
    });

    test(
      'coordinator loads exact current Emergency role and settings',
      () async {
        final now = DateTime.utc(2026, 8, 18, 2, 45);
        final harness = _Harness();

        int settingsLoads = 0;
        int roleLoads = 0;
        String loadedRoleId = '';

        final coordinator = AgentEmergencyWhatsAppVerifiedSafetyCoordinator(
          loadSettings: () async {
            settingsLoads++;
            return _settings();
          },
          loadRole: (String roleId) async {
            roleLoads++;
            loadedRoleId = roleId;
            return _role();
          },
          broker: harness.build(),
        );

        final result = await coordinator.read(
          session: _session(now),
          request: _request(),
          now: now,
        );

        expect(result.authorizationPassed, isTrue);
        expect(settingsLoads, 1);
        expect(roleLoads, 1);
        expect(loadedRoleId, AgentEmergencyWhatsAppFoundation.roleId);
        expect(harness.sourceCalls, 1);
      },
    );

    test('missing Emergency role fails closed without source access', () async {
      final now = DateTime.utc(2026, 8, 18, 2, 45);
      final harness = _Harness();

      final coordinator = AgentEmergencyWhatsAppVerifiedSafetyCoordinator(
        loadSettings: () async => _settings(),
        loadRole: (String roleId) async => null,
        broker: harness.build(),
      );

      final result = await coordinator.read(
        session: _session(now),
        request: _request(),
        now: now,
      );

      expect(result.authorizationPassed, isFalse);
      expect(result.decision.isDenied, isTrue);
      expect(result.snapshot.incidentSourceVerified, isFalse);
      expect(harness.sourceCalls, 0);
    });
  });
}

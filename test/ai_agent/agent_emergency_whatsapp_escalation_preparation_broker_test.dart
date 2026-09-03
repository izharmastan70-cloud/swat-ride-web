import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_emergency_whatsapp_foundation.dart';
import 'package:swat_ride/ai_agent/models/agent_emergency_whatsapp_prepared_escalation.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_permission_decision.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_emergency_whatsapp_escalation_preparation_broker.dart';
import 'package:swat_ride/ai_agent/services/agent_permission_engine.dart';
import 'package:swat_ride/ai_agent/services/agent_runtime_gate.dart';

AgentRole _role() {
  return buildInitialAgentRoles()
      .singleWhere(
        (AgentRole role) =>
            role.roleId == AgentEmergencyWhatsAppFoundation.roleId,
      )
      .copyWith(enabled: true);
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
  Duration remaining = const Duration(minutes: 10),
}) {
  return AgentEmergencyWhatsAppSessionBinding(
    subjectType: AgentEmergencyWhatsAppSubjectType.customer,
    principalUid: principalUid,
    conversationId: conversationId,
    senderBindingId: senderBindingId,
    sessionId: sessionId,
    verificationLevel: verificationLevel,
    verifiedAt: now.subtract(const Duration(minutes: 1)),
    expiresAt: now.add(remaining),
  );
}

AgentEmergencyWhatsAppEscalationPreparationRequest _request({
  String userId = 'user_1',
  String conversationId = 'conversation_1',
  String senderBindingId = 'sender_1',
  String sessionId = 'session_1',
  String reasonCode =
      AgentEmergencyWhatsAppEscalationReasonCode.userRequestsEmergencyHelp,
}) {
  return AgentEmergencyWhatsAppEscalationPreparationRequest(
    userId: userId,
    expectedConversationId: conversationId,
    expectedSenderBindingId: senderBindingId,
    expectedSessionId: sessionId,
    reasonCode: reasonCode,
  );
}

class _Harness {
  int auditCalls = 0;
  final List<AgentPermissionDecision> decisions = <AgentPermissionDecision>[];

  AgentEmergencyWhatsAppEscalationPreparationBroker build() {
    return AgentEmergencyWhatsAppEscalationPreparationBroker(
      permissionEngine: const AgentPermissionEngine(),
      runtimeGate: const AgentRuntimeGate(),
      auditDecision:
          ({
            required AgentRole role,
            required AgentPermissionDecision decision,
            required String actorId,
          }) async {
            auditCalls++;
            decisions.add(decision);
          },
    );
  }
}

void main() {
  group('Phase 47 Step 6B Emergency escalation preparation', () {
    test(
      'valid verified session prepares only REQUIRE_APPROVAL object',
      () async {
        final DateTime now = DateTime.utc(2026, 8, 18, 3);
        final _Harness harness = _Harness();

        final result = await harness.build().prepare(
          settings: _settings(),
          role: _role(),
          session: _session(now),
          request: _request(),
          now: now,
        );

        expect(result.reachedCentralGate, isTrue);
        expect(result.prepared, isTrue);
        expect(result.decision.needsApproval, isTrue);
        expect(result.escalation, isNotNull);
        expect(
          result.escalation!.actionId,
          AgentActionId.requestEmergencyWhatsAppEscalation,
        );
        expect(
          result.escalation!.reasonCode,
          AgentEmergencyWhatsAppEscalationReasonCode.userRequestsEmergencyHelp,
        );
        expect(harness.auditCalls, 1);

        expect(result.persistentApprovalCreated, isFalse);
        expect(result.approvalConsumed, isFalse);
        expect(result.mayCreateSafetyIncident, isFalse);
        expect(result.mayMutateSafetyIncident, isFalse);
        expect(result.maySendSafetyAlert, isFalse);
        expect(result.maySendWhatsApp, isFalse);
        expect(result.maySendSms, isFalse);
        expect(result.mayPlaceEmergencyCall, isFalse);
        expect(result.mayCallProvider, isFalse);
        expect(result.mayHandleLiveWebhook, isFalse);
        expect(result.mayDeploy, isFalse);
      },
    );

    test(
      'prepared safe map contains no channel IDs or sensitive data',
      () async {
        final DateTime now = DateTime.utc(2026, 8, 18, 3);
        final result = await _Harness().build().prepare(
          settings: _settings(),
          role: _role(),
          session: _session(now),
          request: _request(),
          now: now,
        );

        final prepared = result.escalation!;
        final String safeText = prepared.toSafeMap().toString().toLowerCase();

        expect(safeText, isNot(contains('conversation_1')));
        expect(safeText, isNot(contains('sender_1')));
        expect(safeText, isNot(contains('session_1')));
        expect(safeText, isNot(contains('phone')));
        expect(safeText, isNot(contains('latitude')));
        expect(safeText, isNot(contains('longitude')));
        expect(safeText, isNot(contains('medical')));

        expect(prepared.rawMessageIncluded, isFalse);
        expect(prepared.rawPhoneIncluded, isFalse);
        expect(prepared.conversationIdIncluded, isFalse);
        expect(prepared.senderBindingIdIncluded, isFalse);
        expect(prepared.sessionIdIncluded, isFalse);
        expect(prepared.exactLocationIncluded, isFalse);
        expect(prepared.trustedContactDetailsIncluded, isFalse);
        expect(prepared.medicalProfileIncluded, isFalse);
      },
    );

    test('principal mismatch fails before preparation', () async {
      final DateTime now = DateTime.utc(2026, 8, 18, 3);
      final _Harness harness = _Harness();

      final result = await harness.build().prepare(
        settings: _settings(),
        role: _role(),
        session: _session(now, principalUid: 'user_2'),
        request: _request(userId: 'user_1'),
        now: now,
      );

      expect(result.prepared, isFalse);
      expect(result.decision.isDenied, isTrue);
      expect(result.escalation, isNull);
      expect(harness.auditCalls, 1);
    });

    test('channel-bound identity cannot prepare escalation', () async {
      final DateTime now = DateTime.utc(2026, 8, 18, 3);
      final _Harness harness = _Harness();

      final result = await harness.build().prepare(
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

      expect(result.prepared, isFalse);
      expect(result.decision.isDenied, isTrue);
      expect(result.escalation, isNull);
    });

    test('exact session mismatch fails closed', () async {
      final DateTime now = DateTime.utc(2026, 8, 18, 3);

      final result = await _Harness().build().prepare(
        settings: _settings(),
        role: _role(),
        session: _session(now),
        request: _request(sessionId: 'wrong_session'),
        now: now,
      );

      expect(result.prepared, isFalse);
      expect(result.decision.isDenied, isTrue);
    });

    test('invalid reason code fails closed', () async {
      final DateTime now = DateTime.utc(2026, 8, 18, 3);

      final result = await _Harness().build().prepare(
        settings: _settings(),
        role: _role(),
        session: _session(now),
        request: _request(reasonCode: 'FREE_TEXT_OR_UNKNOWN'),
        now: now,
      );

      expect(result.prepared, isFalse);
      expect(result.decision.isDenied, isTrue);
      expect(result.escalation, isNull);
    });

    test('Emergency WhatsApp master OFF fails closed', () async {
      final DateTime now = DateTime.utc(2026, 8, 18, 3);

      final result = await _Harness().build().prepare(
        settings: _settings(emergencyWhatsAppEnabled: false),
        role: _role(),
        session: _session(now),
        request: _request(),
        now: now,
      );

      expect(result.prepared, isFalse);
      expect(result.decision.isDenied, isTrue);
      expect(
        result.reason,
        contains('Emergency WhatsApp Agent master switch is OFF'),
      );
    });

    test('global Emergency Read-Only blocks escalation preparation', () async {
      final DateTime now = DateTime.utc(2026, 8, 18, 3);

      final result = await _Harness().build().prepare(
        settings: _settings(emergencyReadOnly: true),
        role: _role(),
        session: _session(now),
        request: _request(),
        now: now,
      );

      expect(result.prepared, isFalse);
      expect(result.decision.isDenied, isTrue);
    });

    test('wrong role cannot inherit escalation authority', () async {
      final DateTime now = DateTime.utc(2026, 8, 18, 3);
      final owner = buildInitialAgentRoles()
          .singleWhere(
            (AgentRole role) => role.roleId == 'owner_whatsapp_agent',
          )
          .copyWith(enabled: true);

      final result = await _Harness().build().prepare(
        settings: _settings(),
        role: owner,
        session: _session(now),
        request: _request(),
        now: now,
      );

      expect(result.prepared, isFalse);
      expect(result.decision.isDenied, isTrue);
    });

    test('preparation lifetime cannot exceed verified session', () async {
      final DateTime now = DateTime.utc(2026, 8, 18, 3);
      final session = _session(now, remaining: const Duration(minutes: 2));

      final result = await _Harness().build().prepare(
        settings: _settings(),
        role: _role(),
        session: session,
        request: _request(),
        now: now,
      );

      expect(result.prepared, isTrue);
      expect(result.escalation!.validUntil, session.expiresAt);
      expect(result.escalation!.isValidAt(now), isTrue);
    });

    test('central action remains approval-required in seeded role', () {
      final role = _role();

      expect(
        role.allowedActions,
        contains(AgentActionId.requestEmergencyWhatsAppEscalation),
      );
      expect(
        role.approvalRequiredActions,
        contains(AgentActionId.requestEmergencyWhatsAppEscalation),
      );

      final decision = const AgentPermissionEngine().evaluate(
        role: role,
        actionId: AgentActionId.requestEmergencyWhatsAppEscalation,
      );

      expect(decision.needsApproval, isTrue);
    });
  });
}

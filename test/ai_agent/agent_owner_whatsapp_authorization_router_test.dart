import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_owner_whatsapp_foundation.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_whatsapp_authorization_router.dart';

void main() {
  group('Phase 46 Owner WhatsApp authorization preflight', () {
    const AgentOwnerWhatsAppAuthorizationPreflight preflight =
        AgentOwnerWhatsAppAuthorizationPreflight();
    const AgentOwnerWhatsAppFoundation foundation =
        AgentOwnerWhatsAppFoundation();

    final DateTime verifiedAt = DateTime.utc(2026, 8, 18, 0, 0);
    final DateTime now = DateTime.utc(2026, 8, 18, 0, 5);

    AgentOwnerWhatsAppSessionBinding session({
      AgentOwnerWhatsAppVerificationLevel level =
          AgentOwnerWhatsAppVerificationLevel.strongReauth,
    }) {
      return AgentOwnerWhatsAppSessionBinding(
        principalType: AgentOwnerWhatsAppPrincipalType.owner,
        principalUid: 'owner_uid',
        whatsappBindingId: 'binding_ref',
        conversationId: 'conversation_1',
        senderBindingId: 'sender_hash_1',
        sessionId: 'session_1',
        verificationLevel: level,
        verifiedAt: verifiedAt,
        expiresAt: verifiedAt.add(const Duration(minutes: 15)),
      );
    }

    AgentOwnerWhatsAppAuthorizationRequest request({
      AgentOwnerWhatsAppControlArea area = AgentOwnerWhatsAppControlArea.report,
      AgentOwnerWhatsAppCommandPolicy policy =
          const AgentOwnerWhatsAppCommandPolicy.readReport(),
      String conversationId = 'conversation_1',
      String senderBindingId = 'sender_hash_1',
      String sessionId = 'session_1',
    }) {
      return AgentOwnerWhatsAppAuthorizationRequest(
        actionId: 'owner_whatsapp.synthetic_test_action',
        actorId: 'owner_uid',
        controlArea: area,
        commandPolicy: policy,
        expectedConversationId: conversationId,
        expectedSenderBindingId: senderBindingId,
        expectedSessionId: sessionId,
      );
    }

    test('Owner WhatsApp master OFF blocks before central gate', () {
      final AgentOwnerWhatsAppLocalPreflightDecision decision = preflight
          .evaluate(
            channelSettings: const AgentOwnerWhatsAppControlSettings(
              enabled: false,
              reportsEnabled: true,
            ),
            session: session(),
            request: request(),
            now: now,
          );

      expect(decision.allowedToReachCentralGate, isFalse);
      expect(decision.reason, contains('master switch is OFF'));
    });

    test('service/control-area OFF blocks before central gate', () {
      final AgentOwnerWhatsAppLocalPreflightDecision decision = preflight
          .evaluate(
            channelSettings: const AgentOwnerWhatsAppControlSettings(
              enabled: true,
              reportsEnabled: false,
            ),
            session: session(),
            request: request(),
            now: now,
          );

      expect(decision.allowedToReachCentralGate, isFalse);
      expect(decision.reason, contains('control area is OFF'));
    });

    test('exact verified linked session may reach central gate for report', () {
      final AgentOwnerWhatsAppLocalPreflightDecision decision = preflight
          .evaluate(
            channelSettings: const AgentOwnerWhatsAppControlSettings(
              enabled: true,
              reportsEnabled: true,
            ),
            session: session(
              level: AgentOwnerWhatsAppVerificationLevel.linkedAccount,
            ),
            request: request(),
            now: now,
          );

      expect(decision.allowedToReachCentralGate, isTrue);
    });

    test('sender mismatch fails closed before central permission engine', () {
      final AgentOwnerWhatsAppLocalPreflightDecision decision = preflight
          .evaluate(
            channelSettings: const AgentOwnerWhatsAppControlSettings(
              enabled: true,
              reportsEnabled: true,
            ),
            session: session(),
            request: request(senderBindingId: 'wrong_sender'),
            now: now,
          );

      expect(decision.allowedToReachCentralGate, isFalse);
    });

    test('consequential command requires strong re-auth', () {
      final AgentOwnerWhatsAppLocalPreflightDecision decision = preflight
          .evaluate(
            channelSettings: const AgentOwnerWhatsAppControlSettings(
              enabled: true,
              operationalCommandsEnabled: true,
            ),
            session: session(
              level: AgentOwnerWhatsAppVerificationLevel.linkedAccount,
            ),
            request: request(
              area: AgentOwnerWhatsAppControlArea.operations,
              policy:
                  const AgentOwnerWhatsAppCommandPolicy.consequentialAction(),
            ),
            now: now,
          );

      expect(decision.allowedToReachCentralGate, isFalse);
      expect(decision.reason, contains('Strong re-auth'));
    });

    test(
      'strongly re-authenticated consequential request may only reach central gate',
      () {
        final AgentOwnerWhatsAppLocalPreflightDecision decision = preflight
            .evaluate(
              channelSettings: const AgentOwnerWhatsAppControlSettings(
                enabled: true,
                operationalCommandsEnabled: true,
              ),
              session: session(),
              request: request(
                area: AgentOwnerWhatsAppControlArea.operations,
                policy:
                    const AgentOwnerWhatsAppCommandPolicy.consequentialAction(),
              ),
              now: now,
            );

        expect(decision.allowedToReachCentralGate, isTrue);
      },
    );

    test('financial control has separate OFF switch', () {
      final AgentOwnerWhatsAppLocalPreflightDecision decision = preflight
          .evaluate(
            channelSettings: const AgentOwnerWhatsAppControlSettings(
              enabled: true,
              operationalCommandsEnabled: true,
              financialCommandsEnabled: false,
            ),
            session: session(),
            request: request(
              area: AgentOwnerWhatsAppControlArea.financial,
              policy:
                  const AgentOwnerWhatsAppCommandPolicy.consequentialAction(),
            ),
            now: now,
          );

      expect(decision.allowedToReachCentralGate, isFalse);
    });

    test('account security control has separate OFF switch', () {
      final AgentOwnerWhatsAppLocalPreflightDecision decision = preflight
          .evaluate(
            channelSettings: const AgentOwnerWhatsAppControlSettings(
              enabled: true,
              accountSecurityCommandsEnabled: false,
            ),
            session: session(),
            request: request(
              area: AgentOwnerWhatsAppControlArea.accountSecurity,
              policy:
                  const AgentOwnerWhatsAppCommandPolicy.consequentialAction(),
            ),
            now: now,
          );

      expect(decision.allowedToReachCentralGate, isFalse);
    });

    test('unknown command policy fails closed', () {
      final AgentOwnerWhatsAppLocalPreflightDecision decision = preflight
          .evaluate(
            channelSettings: const AgentOwnerWhatsAppControlSettings(
              enabled: true,
              reportsEnabled: true,
            ),
            session: session(),
            request: request(
              policy: const AgentOwnerWhatsAppCommandPolicy.forbidden(),
            ),
            now: now,
          );

      expect(decision.allowedToReachCentralGate, isFalse);
    });

    test(
      'Phase 46 still exposes zero direct execution/send/deploy authority',
      () {
        expect(foundation.mayExecuteBusinessWrite, isFalse);
        expect(foundation.mayChangeAdminSetting, isFalse);
        expect(foundation.maySendWhatsApp, isFalse);
        expect(foundation.mayDeploy, isFalse);
        expect(foundation.customerPrivilegeInheritanceAllowed, isFalse);
      },
    );
  });
}

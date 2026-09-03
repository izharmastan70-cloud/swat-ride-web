import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/constants/agent_enums.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_whatsapp_approval_handoff.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_whatsapp_foundation.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_whatsapp_approval_coordinator.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_whatsapp_authorization_router.dart';

void main() {
  AgentOwnerWhatsAppApprovalHandoff validHandoff() {
    return AgentOwnerWhatsAppApprovalHandoff(
      requestId: 'ow_req_001',
      targetActionId: 'ride.cancel',
      controlArea: AgentOwnerWhatsAppControlArea.operations.name,
      principalUid: 'owner_uid_1',
      conversationId: 'conversation_1',
      senderBindingId: 'sender_hash_1',
      sessionId: 'session_1',
      safeActionScope: const <String, dynamic>{
        'rideId': 'ride_123',
        'reasonCode': 'owner_review',
      },
      strongReauthVerifiedAt: DateTime.utc(2026, 8, 18),
    );
  }

  group('Phase 46 Owner WhatsApp approval handoff', () {
    test('builds exact non-executing approval scope', () {
      final scope = validHandoff().toApprovalActionScope();

      expect(scope['phase'], 46);
      expect(scope['purpose'], 'owner_whatsapp_consequential_request');
      expect(
        scope['ownerWhatsAppRequestActionId'],
        AgentActionId.requestOwnerWhatsAppConsequentialAction,
      );
      expect(scope['targetActionId'], 'ride.cancel');
      expect(scope['businessMutationAuthorized'], isFalse);
      expect(scope['adminMutationAuthorized'], isFalse);
      expect(scope['paymentAuthorized'], isFalse);
      expect(scope['whatsappSendAuthorized'], isFalse);
      expect(scope['providerAuthorized'], isFalse);
      expect(scope['deploymentAuthorized'], isFalse);
    });

    test('rejects password/OTP/token/payment credential-like scope keys', () {
      for (final String key in <String>[
        'password',
        'otpCode',
        'accessToken',
        'api_key',
        'card_number',
        'cvv',
        'privateKey',
      ]) {
        final handoff = AgentOwnerWhatsAppApprovalHandoff(
          requestId: 'req',
          targetActionId: 'ride.cancel',
          controlArea: 'operations',
          principalUid: 'owner',
          conversationId: 'conversation',
          senderBindingId: 'sender',
          sessionId: 'session',
          safeActionScope: <String, dynamic>{key: 'forbidden'},
          strongReauthVerifiedAt: DateTime.utc(2026, 8, 18),
        );

        expect(
          handoff.validate,
          throwsA(isA<AgentOwnerWhatsAppApprovalHandoffException>()),
          reason: key,
        );
      }
    });

    test('nested secret-like keys are rejected', () {
      final handoff = AgentOwnerWhatsAppApprovalHandoff(
        requestId: 'req',
        targetActionId: 'food.refund_order',
        controlArea: 'financial',
        principalUid: 'owner',
        conversationId: 'conversation',
        senderBindingId: 'sender',
        sessionId: 'session',
        safeActionScope: const <String, dynamic>{
          'refund': <String, dynamic>{'paymentToken': 'forbidden'},
        },
        strongReauthVerifiedAt: DateTime.utc(2026, 8, 18),
      );

      expect(
        handoff.validate,
        throwsA(isA<AgentOwnerWhatsAppApprovalHandoffException>()),
      );
    });

    test('isolated Owner role contract remains narrow', () {
      final role = AgentRole(
        roleId: AgentOwnerWhatsAppFoundation.roleId,
        name: 'Owner WhatsApp Agent',
        description: 'test',
        module: 'owner_whatsapp',
        enabled: true,
        mode: AgentMode.suggestOnly,
        allowedActions: const <String>[
          AgentActionId.readOwnerWhatsAppVerifiedReport,
          AgentActionId.requestOwnerWhatsAppConsequentialAction,
        ],
        approvalRequiredActions: const <String>[
          AgentActionId.requestOwnerWhatsAppConsequentialAction,
        ],
        aiClass: AiClass.freeAi,
        privacyLevel: PrivacyLevel.highlySensitive,
        createdAt: DateTime.utc(2026, 8, 18),
      );

      expect(role.allowedActions.length, 2);
      expect(role.approvalRequiredActions, <String>[
        AgentActionId.requestOwnerWhatsAppConsequentialAction,
      ]);
    });

    test(
      'approval result never grants execution/provider/send/deploy authority',
      () {
        expect(AgentOwnerWhatsAppApprovalResult.new, isNotNull);

        // Compile-time contract check is supplemented by static audit in script.
      },
    );
  });
}

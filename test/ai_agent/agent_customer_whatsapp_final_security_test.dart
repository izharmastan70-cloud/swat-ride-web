import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/models/agent_customer_whatsapp_business_action_handoff.dart';
import 'package:swat_ride/ai_agent/models/agent_customer_whatsapp_production_activation.dart';
import 'package:swat_ride/ai_agent/services/agent_action_registry.dart';

void main() {
  test(
    'Customer WhatsApp business handoff is request-only and approval-bound',
    () {
      final handoff = AgentCustomerWhatsAppBusinessActionHandoff(
        handoffId: 'handoff-1',
        sessionId: 'session-1',
        conversationId: 'conversation-1',
        senderRefHash: 'sender-hash-1',
        customerIdAlias: 'customer-alias-1',
        service: 'ride',
        operation: AgentCustomerWhatsAppBusinessOperation.rideBookingRequest,
        customerConfirmed: true,
        backendFactsVerified: true,
        safeActionScope: const <String, dynamic>{
          'pickupReferenceId': 'pickup-ref-1',
          'destinationReferenceId': 'destination-ref-1',
          'vehicleType': 'car',
          'verifiedFare': 850,
          'currency': 'PKR',
        },
        createdAt: DateTime.utc(2026, 8, 17),
      );

      handoff.validate();

      expect(
        handoff.approvalActionId,
        AgentActionId.requestCustomerWhatsAppBusinessAction,
      );
      expect(handoff.requiresPermissionEngine, isTrue);
      expect(handoff.requiresRuntimeGate, isTrue);
      expect(handoff.requiresApprovalEngine, isTrue);
      expect(handoff.requiresCustomerConfirmation, isTrue);
      expect(handoff.actionRegistryRequiresApproval, isTrue);
      expect(handoff.readyForApprovalRequest, isTrue);

      expect(handoff.mayExecuteBusinessWrite, isFalse);
      expect(handoff.mayChargePayment, isFalse);
      expect(handoff.maySendWhatsApp, isFalse);
    },
  );

  test(
    'registered WhatsApp business request action remains non-read-only and always approval-required',
    () {
      final action = AgentActionRegistry.get(
        AgentActionId.requestCustomerWhatsAppBusinessAction,
      );

      expect(action, isNotNull);
      expect(action!.readOnly, isFalse);
      expect(action.alwaysRequiresApproval, isTrue);
      expect(action.module, 'customer_whatsapp');
    },
  );

  test('business handoff rejects missing explicit customer confirmation', () {
    final handoff = AgentCustomerWhatsAppBusinessActionHandoff(
      handoffId: 'handoff-2',
      sessionId: 'session-1',
      conversationId: 'conversation-1',
      senderRefHash: 'sender-hash-1',
      customerIdAlias: 'customer-alias-1',
      service: 'food',
      operation: AgentCustomerWhatsAppBusinessOperation.foodOrderRequest,
      customerConfirmed: false,
      backendFactsVerified: true,
      safeActionScope: const <String, dynamic>{'orderDraftId': 'order-draft-1'},
      createdAt: DateTime.utc(2026, 8, 17),
    );

    expect(
      handoff.validate,
      throwsA(isA<AgentCustomerWhatsAppBusinessActionException>()),
    );
  });

  test('business handoff rejects unverified booking/fare facts', () {
    final handoff = AgentCustomerWhatsAppBusinessActionHandoff(
      handoffId: 'handoff-3',
      sessionId: 'session-1',
      conversationId: 'conversation-1',
      senderRefHash: 'sender-hash-1',
      customerIdAlias: 'customer-alias-1',
      service: 'hotel',
      operation: AgentCustomerWhatsAppBusinessOperation.hotelBookingRequest,
      customerConfirmed: true,
      backendFactsVerified: false,
      safeActionScope: const <String, dynamic>{'hotelId': 'hotel-1'},
      createdAt: DateTime.utc(2026, 8, 17),
    );

    expect(
      handoff.validate,
      throwsA(isA<AgentCustomerWhatsAppBusinessActionException>()),
    );
  });

  test('business handoff rejects OTP/token/card credential fields', () {
    for (final Map<String, dynamic> badScope in <Map<String, dynamic>>[
      <String, dynamic>{'otpCode': '000000'},
      <String, dynamic>{'accessToken': 'not-a-real-secret'},
      <String, dynamic>{'cardNumber': '0000'},
      <String, dynamic>{
        'payment': <String, dynamic>{'cvv': '000'},
      },
    ]) {
      final handoff = AgentCustomerWhatsAppBusinessActionHandoff(
        handoffId: 'handoff-secret',
        sessionId: 'session-1',
        conversationId: 'conversation-1',
        senderRefHash: 'sender-hash-1',
        customerIdAlias: 'customer-alias-1',
        service: 'ride',
        operation: AgentCustomerWhatsAppBusinessOperation.rideBookingRequest,
        customerConfirmed: true,
        backendFactsVerified: true,
        safeActionScope: badScope,
        createdAt: DateTime.utc(2026, 8, 17),
      );

      expect(
        handoff.validate,
        throwsA(isA<AgentCustomerWhatsAppBusinessActionException>()),
      );
    }
  });

  test(
    'production activation defaults fail closed with no selected provider',
    () {
      const activation = AgentCustomerWhatsAppProductionActivation();

      expect(activation.implementationDefaultIsSafe, isTrue);
      expect(activation.liveTransportAllowed, isFalse);

      expect(
        activation.missingActivationGates(),
        containsAll(<String>[
          'PROVIDER_SELECTION',
          'SERVER_SECRETS',
          'INBOUND_SIGNATURE_VERIFICATION',
          'PERSISTENT_REPLAY_STORE',
          'INBOUND_IDEMPOTENCY',
          'WEBHOOK_ROUTE',
          'CURRENT_PROVIDER_POLICY_REVIEW',
          'OUTBOUND_CONSENT_POLICY',
          'OUTBOUND_TRANSPORT',
          'OWNER_EXPLICIT_ACTIVATION',
        ]),
      );
    },
  );

  test(
    'live transport cannot activate if even one production gate is missing',
    () {
      const activation = AgentCustomerWhatsAppProductionActivation(
        providerId: 'future-provider',
        providerSelected: true,
        serverSecretsConfigured: true,
        inboundSignatureVerificationConfigured: true,
        persistentReplayStoreConfigured: true,
        inboundIdempotencyConfigured: true,
        webhookRouteConfigured: true,
        providerPolicyReviewComplete: true,
        outboundConsentPolicyConfigured: true,
        outboundTransportConfigured: true,
        ownerExplicitActivation: false,
      );

      expect(activation.liveTransportAllowed, isFalse);
      expect(
        activation.missingActivationGates(),
        contains('OWNER_EXPLICIT_ACTIVATION'),
      );
    },
  );

  test(
    'production activation contract requires every gate explicitly true',
    () {
      const activation = AgentCustomerWhatsAppProductionActivation(
        providerId: 'future-provider',
        providerSelected: true,
        serverSecretsConfigured: true,
        inboundSignatureVerificationConfigured: true,
        persistentReplayStoreConfigured: true,
        inboundIdempotencyConfigured: true,
        webhookRouteConfigured: true,
        providerPolicyReviewComplete: true,
        outboundConsentPolicyConfigured: true,
        outboundTransportConfigured: true,
        ownerExplicitActivation: true,
      );

      expect(activation.liveTransportAllowed, isTrue);
      expect(activation.missingActivationGates(), isEmpty);
    },
  );
}

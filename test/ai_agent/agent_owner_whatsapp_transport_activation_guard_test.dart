import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_owner_whatsapp_production_activation.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_whatsapp_server_transport_handoff.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_whatsapp_transport_activation_guard.dart';

const AgentOwnerWhatsAppProductionActivation _readyActivation =
    AgentOwnerWhatsAppProductionActivation(
      providerId: 'provider-neutral-id',
      providerSelected: true,
      serverSecretsConfigured: true,
      inboundSignatureVerificationConfigured: true,
      persistentReplayStoreConfigured: true,
      inboundIdempotencyConfigured: true,
      webhookRouteConfigured: true,
      ownerIdentityBindingConfigured: true,
      strongReauthBoundaryConfigured: true,
      providerPolicyReviewComplete: true,
    );

AgentOwnerWhatsAppServerTransportHandoff _handoff({
  String providerId = 'provider-neutral-id',
  String webhookRouteRef = 'server.route.owner_whatsapp.inbound',
  String serverSecretBundleRef = 'secret_manager.owner_whatsapp',
}) {
  return AgentOwnerWhatsAppServerTransportHandoff(
    handoffId: 'handoff_1',
    providerId: providerId,
    webhookRouteRef: webhookRouteRef,
    serverSecretBundleRef: serverSecretBundleRef,
    signatureVerifierRef: 'server.signature.owner_whatsapp',
    persistentReplayStoreRef: 'store.owner_whatsapp.replay',
    inboundIdempotencyStoreRef: 'store.owner_whatsapp.idempotency',
    ownerIdentityBindingRef: 'identity.owner_whatsapp.binding',
    strongReauthBoundaryRef: 'reauth.owner_whatsapp.strong',
    preparedAt: DateTime.utc(2026, 8, 18),
  );
}

void main() {
  group('Phase 46 Step 9C transport activation guard', () {
    test('incomplete production activation fails closed before handoff', () {
      const guard = AgentOwnerWhatsAppTransportActivationGuard();

      final decision = guard.evaluate(
        activation: const AgentOwnerWhatsAppProductionActivation(),
        handoff: _handoff(),
      );

      expect(decision.readyForSeparateTrustedServerImplementation, isFalse);
      expect(decision.missingRequirements, isNotEmpty);
      expect(decision.safeReferenceMap, isEmpty);
      expect(decision.liveTransportActivated, isFalse);
    });

    test('ready declaration plus valid references permits handoff only', () {
      const guard = AgentOwnerWhatsAppTransportActivationGuard();

      final decision = guard.evaluate(
        activation: _readyActivation,
        handoff: _handoff(),
      );

      expect(decision.readyForSeparateTrustedServerImplementation, isTrue);
      expect(decision.safeReferenceMap, isNotEmpty);

      // Still no runtime transport authority.
      expect(decision.liveTransportActivated, isFalse);
      expect(decision.mayHandleLiveInboundWebhook, isFalse);
      expect(decision.maySendWhatsApp, isFalse);
      expect(decision.mayCallProvider, isFalse);
      expect(decision.mayExecuteBusinessOrAdminWrite, isFalse);
      expect(decision.mayDeploy, isFalse);
    });

    test('provider mismatch fails closed', () {
      const guard = AgentOwnerWhatsAppTransportActivationGuard();

      final decision = guard.evaluate(
        activation: _readyActivation,
        handoff: _handoff(providerId: 'different-provider'),
      );

      expect(decision.readyForSeparateTrustedServerImplementation, isFalse);
      expect(decision.safeReferenceMap, isEmpty);
    });

    test('live webhook URL is rejected from reference-only handoff', () {
      const guard = AgentOwnerWhatsAppTransportActivationGuard();

      final decision = guard.evaluate(
        activation: _readyActivation,
        handoff: _handoff(
          webhookRouteRef: 'https://example.com/api/owner-whatsapp',
        ),
      );

      expect(decision.readyForSeparateTrustedServerImplementation, isFalse);
      expect(decision.safeReferenceMap, isEmpty);
    });

    test('secret-like reference material is rejected', () {
      const guard = AgentOwnerWhatsAppTransportActivationGuard();

      final decision = guard.evaluate(
        activation: _readyActivation,
        handoff: _handoff(
          serverSecretBundleRef: 'token=actual-secret-material',
        ),
      );

      expect(decision.readyForSeparateTrustedServerImplementation, isFalse);
      expect(decision.safeReferenceMap, isEmpty);
    });

    test('safe reference map explicitly denies authority', () {
      final map = _handoff().toSafeReferenceMap();

      expect(map['containsSecretValue'], isFalse);
      expect(map['containsRawWebhookPayload'], isFalse);
      expect(map['containsRawPhoneNumber'], isFalse);
      expect(map['containsOtp'], isFalse);
      expect(map['containsPaymentCredential'], isFalse);
      expect(map['networkAuthorized'], isFalse);
      expect(map['whatsappSendAuthorized'], isFalse);
      expect(map['businessMutationAuthorized'], isFalse);
      expect(map['deploymentAuthorized'], isFalse);
    });

    test(
      'handoff itself never grants provider/send/write/deploy authority',
      () {
        final handoff = _handoff();

        expect(handoff.mayHandleLiveInboundWebhook, isFalse);
        expect(handoff.maySendWhatsApp, isFalse);
        expect(handoff.mayCallProvider, isFalse);
        expect(handoff.mayExecuteBusinessOrAdminWrite, isFalse);
        expect(handoff.mayDeploy, isFalse);
      },
    );
  });
}

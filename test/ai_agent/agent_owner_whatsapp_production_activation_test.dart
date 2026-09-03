import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_owner_whatsapp_production_activation.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_whatsapp_disabled_transport.dart';

void main() {
  group('Phase 46 Step 9B Owner WhatsApp production activation', () {
    test('default state is fully fail-closed and not production ready', () {
      const activation = AgentOwnerWhatsAppProductionActivation();

      expect(activation.isSafePreProviderDefault, isTrue);
      expect(activation.isProductionReady, isFalse);
      expect(
        activation.missingRequirements.toSet(),
        AgentOwnerWhatsAppProductionRequirement.values,
      );
    });

    test('all server/security requirements are mandatory for readiness', () {
      const activation = AgentOwnerWhatsAppProductionActivation(
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

      expect(activation.isProductionReady, isTrue);
      expect(activation.missingRequirements, isEmpty);

      // Readiness declaration still grants no authority by itself.
      expect(activation.mayHandleLiveInboundWebhook, isFalse);
      expect(activation.maySendWhatsApp, isFalse);
      expect(activation.mayCallProvider, isFalse);
      expect(activation.mayExecuteBusinessOrAdminWrite, isFalse);
      expect(activation.mayDeploy, isFalse);
    });

    test('missing signature verification blocks production readiness', () {
      const activation = AgentOwnerWhatsAppProductionActivation(
        providerId: 'provider-neutral-id',
        providerSelected: true,
        serverSecretsConfigured: true,
        persistentReplayStoreConfigured: true,
        inboundIdempotencyConfigured: true,
        webhookRouteConfigured: true,
        ownerIdentityBindingConfigured: true,
        strongReauthBoundaryConfigured: true,
        providerPolicyReviewComplete: true,
      );

      expect(activation.isProductionReady, isFalse);
      expect(
        activation.missingRequirements,
        contains(
          AgentOwnerWhatsAppProductionRequirement.inboundSignatureVerification,
        ),
      );
    });

    test('missing persistent replay store blocks production readiness', () {
      const activation = AgentOwnerWhatsAppProductionActivation(
        providerId: 'provider-neutral-id',
        providerSelected: true,
        serverSecretsConfigured: true,
        inboundSignatureVerificationConfigured: true,
        inboundIdempotencyConfigured: true,
        webhookRouteConfigured: true,
        ownerIdentityBindingConfigured: true,
        strongReauthBoundaryConfigured: true,
        providerPolicyReviewComplete: true,
      );

      expect(activation.isProductionReady, isFalse);
      expect(
        activation.missingRequirements,
        contains(AgentOwnerWhatsAppProductionRequirement.persistentReplayStore),
      );
    });

    test('missing Owner identity binding blocks production readiness', () {
      const activation = AgentOwnerWhatsAppProductionActivation(
        providerId: 'provider-neutral-id',
        providerSelected: true,
        serverSecretsConfigured: true,
        inboundSignatureVerificationConfigured: true,
        persistentReplayStoreConfigured: true,
        inboundIdempotencyConfigured: true,
        webhookRouteConfigured: true,
        strongReauthBoundaryConfigured: true,
        providerPolicyReviewComplete: true,
      );

      expect(activation.isProductionReady, isFalse);
      expect(
        activation.missingRequirements,
        contains(AgentOwnerWhatsAppProductionRequirement.ownerIdentityBinding),
      );
    });

    test('missing strong reauth server boundary blocks readiness', () {
      const activation = AgentOwnerWhatsAppProductionActivation(
        providerId: 'provider-neutral-id',
        providerSelected: true,
        serverSecretsConfigured: true,
        inboundSignatureVerificationConfigured: true,
        persistentReplayStoreConfigured: true,
        inboundIdempotencyConfigured: true,
        webhookRouteConfigured: true,
        ownerIdentityBindingConfigured: true,
        providerPolicyReviewComplete: true,
      );

      expect(activation.isProductionReady, isFalse);
      expect(
        activation.missingRequirements,
        contains(AgentOwnerWhatsAppProductionRequirement.strongReauthBoundary),
      );
    });

    test('disabled transport remains disabled even for ready declaration', () {
      const transport = AgentOwnerWhatsAppDisabledTransport();
      const activation = AgentOwnerWhatsAppProductionActivation(
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

      final result = transport.inspectActivation(activation);

      expect(result.productionReadyDeclaration, isTrue);
      expect(result.transportStillDisabled, isTrue);
      expect(result.mayHandleLiveInboundWebhook, isFalse);
      expect(result.maySendWhatsApp, isFalse);
      expect(result.mayCallProvider, isFalse);
      expect(result.mayExecuteBusinessOrAdminWrite, isFalse);
      expect(result.mayDeploy, isFalse);
    });

    test('disabled transport rejects inbound webhook and outbound send', () {
      const transport = AgentOwnerWhatsAppDisabledTransport();

      expect(
        transport.receiveLiveWebhook,
        throwsA(isA<AgentOwnerWhatsAppTransportDisabledException>()),
      );

      expect(
        transport.sendMessage,
        throwsA(isA<AgentOwnerWhatsAppTransportDisabledException>()),
      );
    });

    test(
      'disabled transport never exposes client/server secret capability',
      () {
        const transport = AgentOwnerWhatsAppDisabledTransport();

        expect(transport.providerSelected, isFalse);
        expect(transport.inboundProviderNetworkEnabled, isFalse);
        expect(transport.outboundProviderNetworkEnabled, isFalse);
        expect(transport.webhookEnabled, isFalse);
        expect(transport.signatureVerificationEnabled, isFalse);
        expect(transport.persistentReplayStoreEnabled, isFalse);
        expect(transport.inboundIdempotencyEnabled, isFalse);
        expect(transport.serverSecretsAvailableToClient, isFalse);
        expect(transport.maySendWhatsApp, isFalse);
        expect(transport.mayExecuteBusinessOrAdminWrite, isFalse);
        expect(transport.mayDeploy, isFalse);
      },
    );
  });
}

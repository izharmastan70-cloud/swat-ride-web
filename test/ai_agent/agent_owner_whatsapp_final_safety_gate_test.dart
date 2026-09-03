import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_owner_whatsapp_foundation.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_whatsapp_production_activation.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_whatsapp_server_transport_handoff.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_whatsapp_verified_report.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_whatsapp_disabled_transport.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_whatsapp_transport_activation_guard.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_whatsapp_verified_report_composition.dart';

void main() {
  group('Phase 46 final Owner WhatsApp safety gate', () {
    test(
      'WhatsApp message/phone/customer channel never grant Owner authority',
      () {
        const foundation = AgentOwnerWhatsAppFoundation();

        expect(foundation.messageGrantsAuthority, isFalse);
        expect(foundation.phoneNumberMatchAloneIsAuthority, isFalse);
        expect(foundation.customerPrivilegeInheritanceAllowed, isFalse);
        expect(foundation.emergencyAuthorityIncluded, isFalse);
        expect(foundation.requiresLinkedOwnerAccount, isTrue);
        expect(foundation.requiresPermissionEngine, isTrue);
        expect(foundation.requiresRuntimeGate, isTrue);
        expect(
          foundation.requiresApprovalEngineForConsequentialActions,
          isTrue,
        );
        expect(foundation.requiresAudit, isTrue);
      },
    );

    test('foundation grants no write/payment/send/deploy authority', () {
      const foundation = AgentOwnerWhatsAppFoundation();

      expect(foundation.mayExecuteBusinessWrite, isFalse);
      expect(foundation.mayChangeAdminSetting, isFalse);
      expect(foundation.mayChargePayment, isFalse);
      expect(foundation.maySendWhatsApp, isFalse);
      expect(foundation.mayDeploy, isFalse);
    });

    test('production default is fully fail-closed', () {
      const activation = AgentOwnerWhatsAppProductionActivation();

      expect(activation.isSafePreProviderDefault, isTrue);
      expect(activation.isProductionReady, isFalse);
      expect(activation.missingRequirements, isNotEmpty);
      expect(activation.mayHandleLiveInboundWebhook, isFalse);
      expect(activation.maySendWhatsApp, isFalse);
      expect(activation.mayCallProvider, isFalse);
      expect(activation.mayExecuteBusinessOrAdminWrite, isFalse);
      expect(activation.mayDeploy, isFalse);
    });

    test('disabled transport remains completely disabled', () {
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
    });

    test('only audited verified report sections are connected', () {
      expect(
        AgentOwnerWhatsAppVerifiedReportComposition.connectedSectionIds,
        const <String>{
          AgentOwnerWhatsAppReportSectionId.approvals,
          AgentOwnerWhatsAppReportSectionId.agentStatus,
          AgentOwnerWhatsAppReportSectionId.security,
          AgentOwnerWhatsAppReportSectionId.crashes,
        },
      );

      for (final String sectionId in <String>[
        AgentOwnerWhatsAppReportSectionId.ride,
        AgentOwnerWhatsAppReportSectionId.driver,
        AgentOwnerWhatsAppReportSectionId.food,
        AgentOwnerWhatsAppReportSectionId.hotel,
        AgentOwnerWhatsAppReportSectionId.tour,
        AgentOwnerWhatsAppReportSectionId.cargo,
        AgentOwnerWhatsAppReportSectionId.student,
        AgentOwnerWhatsAppReportSectionId.revenue,
        AgentOwnerWhatsAppReportSectionId.complaints,
        AgentOwnerWhatsAppReportSectionId.refundsDisputes,
        AgentOwnerWhatsAppReportSectionId.tasks,
        AgentOwnerWhatsAppReportSectionId.agentActivity,
        AgentOwnerWhatsAppReportSectionId.developmentStatus,
        AgentOwnerWhatsAppReportSectionId.recommendations,
      ]) {
        expect(
          AgentOwnerWhatsAppVerifiedReportComposition.isSectionIntentionallyUnavailable(
            sectionId,
          ),
          isTrue,
          reason: sectionId,
        );
      }
    });

    test(
      'fully declared readiness still does not activate Flutter transport',
      () {
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

        final handoff = AgentOwnerWhatsAppServerTransportHandoff(
          handoffId: 'final_gate_handoff',
          providerId: 'provider-neutral-id',
          webhookRouteRef: 'server.route.owner_whatsapp.inbound',
          serverSecretBundleRef: 'secret_manager.owner_whatsapp',
          signatureVerifierRef: 'server.signature.owner_whatsapp',
          persistentReplayStoreRef: 'store.owner_whatsapp.replay',
          inboundIdempotencyStoreRef: 'store.owner_whatsapp.idempotency',
          ownerIdentityBindingRef: 'identity.owner_whatsapp.binding',
          strongReauthBoundaryRef: 'reauth.owner_whatsapp.strong',
          preparedAt: DateTime.utc(2026, 8, 18),
        );

        const guard = AgentOwnerWhatsAppTransportActivationGuard();
        final decision = guard.evaluate(
          activation: activation,
          handoff: handoff,
        );

        expect(decision.readyForSeparateTrustedServerImplementation, isTrue);
        expect(decision.liveTransportActivated, isFalse);
        expect(decision.mayHandleLiveInboundWebhook, isFalse);
        expect(decision.maySendWhatsApp, isFalse);
        expect(decision.mayCallProvider, isFalse);
        expect(decision.mayExecuteBusinessOrAdminWrite, isFalse);
        expect(decision.mayDeploy, isFalse);
      },
    );

    test('safe server handoff contains references only and no authority', () {
      final handoff = AgentOwnerWhatsAppServerTransportHandoff(
        handoffId: 'safe_handoff',
        providerId: 'provider-neutral-id',
        webhookRouteRef: 'server.route.owner_whatsapp.inbound',
        serverSecretBundleRef: 'secret_manager.owner_whatsapp',
        signatureVerifierRef: 'server.signature.owner_whatsapp',
        persistentReplayStoreRef: 'store.owner_whatsapp.replay',
        inboundIdempotencyStoreRef: 'store.owner_whatsapp.idempotency',
        ownerIdentityBindingRef: 'identity.owner_whatsapp.binding',
        strongReauthBoundaryRef: 'reauth.owner_whatsapp.strong',
        preparedAt: DateTime.utc(2026, 8, 18),
      );

      final map = handoff.toSafeReferenceMap();

      expect(map['containsSecretValue'], isFalse);
      expect(map['containsRawWebhookPayload'], isFalse);
      expect(map['containsRawPhoneNumber'], isFalse);
      expect(map['containsOtp'], isFalse);
      expect(map['containsPaymentCredential'], isFalse);
      expect(map['networkAuthorized'], isFalse);
      expect(map['whatsappSendAuthorized'], isFalse);
      expect(map['businessMutationAuthorized'], isFalse);
      expect(map['deploymentAuthorized'], isFalse);

      expect(handoff.mayHandleLiveInboundWebhook, isFalse);
      expect(handoff.maySendWhatsApp, isFalse);
      expect(handoff.mayCallProvider, isFalse);
      expect(handoff.mayExecuteBusinessOrAdminWrite, isFalse);
      expect(handoff.mayDeploy, isFalse);
    });
  });
}

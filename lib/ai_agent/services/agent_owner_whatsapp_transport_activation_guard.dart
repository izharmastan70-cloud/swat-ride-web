import '../models/agent_owner_whatsapp_production_activation.dart';
import '../models/agent_owner_whatsapp_server_transport_handoff.dart';

class AgentOwnerWhatsAppTransportActivationDecision {
  const AgentOwnerWhatsAppTransportActivationDecision({
    required this.readyForSeparateTrustedServerImplementation,
    required this.reason,
    required this.missingRequirements,
    required this.safeReferenceMap,
  });

  final bool readyForSeparateTrustedServerImplementation;
  final String reason;
  final List<String> missingRequirements;
  final Map<String, dynamic> safeReferenceMap;

  /// Even a READY handoff does not activate networking in Flutter.
  bool get liveTransportActivated => false;
  bool get mayHandleLiveInboundWebhook => false;
  bool get maySendWhatsApp => false;
  bool get mayCallProvider => false;
  bool get mayExecuteBusinessOrAdminWrite => false;
  bool get mayDeploy => false;
}

/// Phase 46 trusted-server transport activation guard.
///
/// It checks whether a future server implementation has all declared
/// prerequisites and a valid non-secret reference handoff.
///
/// It does NOT:
/// - verify a real provider signature;
/// - store replay/idempotency records;
/// - open a webhook route;
/// - call a provider;
/// - send WhatsApp messages;
/// - execute business/admin actions;
/// - deploy infrastructure.
class AgentOwnerWhatsAppTransportActivationGuard {
  const AgentOwnerWhatsAppTransportActivationGuard();

  AgentOwnerWhatsAppTransportActivationDecision evaluate({
    required AgentOwnerWhatsAppProductionActivation activation,
    required AgentOwnerWhatsAppServerTransportHandoff handoff,
  }) {
    if (!activation.isProductionReady) {
      return AgentOwnerWhatsAppTransportActivationDecision(
        readyForSeparateTrustedServerImplementation: false,
        reason:
            'Owner WhatsApp production requirements are incomplete. Live '
            'transport remains disabled.',
        missingRequirements: activation.missingRequirements,
        safeReferenceMap: const <String, dynamic>{},
      );
    }

    try {
      handoff.validate();
    } on AgentOwnerWhatsAppServerTransportHandoffException catch (error) {
      return AgentOwnerWhatsAppTransportActivationDecision(
        readyForSeparateTrustedServerImplementation: false,
        reason: error.message,
        missingRequirements: const <String>[],
        safeReferenceMap: const <String, dynamic>{},
      );
    }

    if (handoff.providerId != activation.providerId.trim()) {
      return const AgentOwnerWhatsAppTransportActivationDecision(
        readyForSeparateTrustedServerImplementation: false,
        reason:
            'Trusted-server handoff provider does not match the reviewed '
            'production activation provider.',
        missingRequirements: <String>[],
        safeReferenceMap: <String, dynamic>{},
      );
    }

    return AgentOwnerWhatsAppTransportActivationDecision(
      readyForSeparateTrustedServerImplementation: true,
      reason:
          'All declared prerequisites and non-secret references are present. '
          'This permits only a separately audited trusted-server '
          'implementation step; no network transport has been activated.',
      missingRequirements: const <String>[],
      safeReferenceMap: handoff.toSafeReferenceMap(),
    );
  }
}

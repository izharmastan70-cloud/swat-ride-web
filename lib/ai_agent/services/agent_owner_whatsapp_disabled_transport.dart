import '../models/agent_owner_whatsapp_production_activation.dart';

/// Fail-closed Owner WhatsApp transport used before a trusted production
/// server boundary exists.
///
/// It intentionally exposes NO provider/network/webhook/send capability.
/// It must not be replaced with a live transport until every production
/// requirement is implemented and independently verified server-side.
class AgentOwnerWhatsAppDisabledTransport {
  const AgentOwnerWhatsAppDisabledTransport();

  bool get providerSelected => false;
  bool get inboundProviderNetworkEnabled => false;
  bool get outboundProviderNetworkEnabled => false;
  bool get webhookEnabled => false;
  bool get signatureVerificationEnabled => false;
  bool get persistentReplayStoreEnabled => false;
  bool get inboundIdempotencyEnabled => false;
  bool get serverSecretsAvailableToClient => false;
  bool get maySendWhatsApp => false;
  bool get mayExecuteBusinessOrAdminWrite => false;
  bool get mayDeploy => false;

  AgentOwnerWhatsAppTransportDisabledResult inspectActivation(
    AgentOwnerWhatsAppProductionActivation activation,
  ) {
    return AgentOwnerWhatsAppTransportDisabledResult(
      productionReadyDeclaration: activation.isProductionReady,
      transportStillDisabled: true,
      missingRequirements: activation.missingRequirements,
      reason: activation.isProductionReady
          ? 'Readiness declaration is complete, but this disabled transport '
                'still cannot activate networking. A separately audited trusted '
                'server transport is required.'
          : 'Owner WhatsApp live transport is disabled because production '
                'requirements are incomplete.',
    );
  }

  Never receiveLiveWebhook() {
    throw const AgentOwnerWhatsAppTransportDisabledException(
      'Owner WhatsApp inbound webhook transport is disabled. Configure and '
      'audit the trusted server signature/replay/idempotency boundary first.',
    );
  }

  Never sendMessage() {
    throw const AgentOwnerWhatsAppTransportDisabledException(
      'Owner WhatsApp outbound send transport is disabled. Provider selection '
      'and trusted server transport activation are required first.',
    );
  }
}

class AgentOwnerWhatsAppTransportDisabledResult {
  const AgentOwnerWhatsAppTransportDisabledResult({
    required this.productionReadyDeclaration,
    required this.transportStillDisabled,
    required this.missingRequirements,
    required this.reason,
  });

  final bool productionReadyDeclaration;
  final bool transportStillDisabled;
  final List<String> missingRequirements;
  final String reason;

  bool get mayHandleLiveInboundWebhook => false;
  bool get maySendWhatsApp => false;
  bool get mayCallProvider => false;
  bool get mayExecuteBusinessOrAdminWrite => false;
  bool get mayDeploy => false;
}

class AgentOwnerWhatsAppTransportDisabledException implements Exception {
  const AgentOwnerWhatsAppTransportDisabledException(this.message);

  final String message;

  @override
  String toString() => 'AgentOwnerWhatsAppTransportDisabledException: $message';
}

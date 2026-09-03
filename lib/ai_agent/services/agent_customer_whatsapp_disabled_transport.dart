import '../models/agent_customer_whatsapp_transport.dart';

/// Phase 45 default transport.
///
/// This is intentionally incapable of network I/O.
/// A later production activation step must add a separately reviewed
/// provider adapter without changing this safe default.
class AgentCustomerWhatsAppDisabledTransport
    implements AgentCustomerWhatsAppTransport {
  const AgentCustomerWhatsAppDisabledTransport();

  @override
  String get transportId => 'customer_whatsapp.disabled';

  @override
  bool get networkEnabled => false;

  @override
  bool get liveSendCapable => false;

  bool get providerSelected => false;
  bool get webhookEnabled => false;
  bool get inboundProviderNetworkEnabled => false;
  bool get outboundProviderNetworkEnabled => false;

  @override
  Future<AgentCustomerWhatsAppTransportReceipt> sendDraft(
    AgentCustomerWhatsAppOutboundDraft draft,
  ) async {
    draft.validate();

    return const AgentCustomerWhatsAppTransportReceipt(
      status: AgentCustomerWhatsAppTransportStatus.disabled,
      message: 'Customer WhatsApp transport is disabled. No message was sent.',
    );
  }
}

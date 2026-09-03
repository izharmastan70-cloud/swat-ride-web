import '../models/agent_customer_whatsapp_control_settings.dart';
import '../models/agent_customer_whatsapp_verified_read.dart';

class AgentCustomerWhatsAppVerifiedReadRouter {
  const AgentCustomerWhatsAppVerifiedReadRouter({required this.sources});

  final Map<String, AgentCustomerWhatsAppVerifiedReadSource> sources;

  bool get providerTransportAllowed => false;
  bool get whatsappNetworkAllowed => false;
  bool get businessWriteAllowed => false;
  bool get approvalBypassAllowed => false;
  bool get runtimeGateBypassAllowed => false;

  Future<AgentCustomerWhatsAppVerifiedReadResult> route({
    required AgentCustomerWhatsAppControlSettings controls,
    required AgentCustomerWhatsAppVerifiedReadRequest request,
  }) async {
    request.validate();

    if (!controls.enabled) {
      return AgentCustomerWhatsAppVerifiedReadResult.denied(
        'CUSTOMER_WHATSAPP_AGENT_OFF',
      );
    }

    if (!controls.isServiceEnabled(request.service)) {
      return AgentCustomerWhatsAppVerifiedReadResult.denied(
        'CUSTOMER_WHATSAPP_SERVICE_OFF',
      );
    }

    if (request.sensitive && !request.customerVerified) {
      return AgentCustomerWhatsAppVerifiedReadResult.denied(
        'CUSTOMER_VERIFICATION_REQUIRED',
        requiresCustomerVerification: true,
      );
    }

    final AgentCustomerWhatsAppVerifiedReadSource? source =
        sources[request.service];

    if (source == null) {
      return AgentCustomerWhatsAppVerifiedReadResult.denied(
        'VERIFIED_BACKEND_SOURCE_UNAVAILABLE',
        requiresHumanEscalation: true,
      );
    }

    final AgentCustomerWhatsAppVerifiedReadResult result = await source
        .readVerified(request);

    if (!result.ok || !result.backendVerified) {
      return AgentCustomerWhatsAppVerifiedReadResult.denied(
        'BACKEND_FACT_NOT_VERIFIED',
        requiresHumanEscalation: result.requiresHumanEscalation,
      );
    }

    return result;
  }
}

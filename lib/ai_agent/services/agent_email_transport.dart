import '../models/agent_email_delivery_receipt.dart';
import '../models/agent_email_transport_handoff.dart';

abstract class AgentEmailTransport {
  String get providerId;

  bool get enabled;
  bool get liveSendCapable;

  Future<AgentEmailDeliveryReceipt> deliver(AgentEmailTransportHandoff handoff);
}

class DisabledAgentEmailTransport implements AgentEmailTransport {
  const DisabledAgentEmailTransport({
    this.providerId = 'email_transport_disabled',
  });

  @override
  final String providerId;

  @override
  bool get enabled => false;

  @override
  bool get liveSendCapable => false;

  bool get networkAccessAllowed => false;
  bool get smtpAccessAllowed => false;
  bool get mailboxWriteAllowed => false;
  bool get providerSecretAccessAllowed => false;

  @override
  Future<AgentEmailDeliveryReceipt> deliver(
    AgentEmailTransportHandoff handoff,
  ) async {
    handoff.validate();

    final AgentEmailDeliveryReceipt receipt = AgentEmailDeliveryReceipt(
      receiptId: 'disabled_${handoff.handoffId}',
      handoffId: handoff.handoffId,
      providerId: providerId,
      status: AgentEmailDeliveryStatus.disabled,
      reason:
          'Email transport is disabled. No provider/network/mailbox call was attempted.',
      createdAt: DateTime.now(),
    );

    receipt.validate();
    return receipt;
  }
}

import 'agent_customer_whatsapp_media.dart';

class AgentCustomerWhatsAppTransportStatus {
  AgentCustomerWhatsAppTransportStatus._();

  static const String disabled = 'DISABLED';
  static const String notAttempted = 'NOT_ATTEMPTED';
  static const String accepted = 'ACCEPTED';
  static const String failed = 'FAILED';
}

class AgentCustomerWhatsAppInboundEnvelope {
  const AgentCustomerWhatsAppInboundEnvelope({
    required this.messageId,
    required this.conversationId,
    required this.senderRefHash,
    required this.text,
    required this.media,
    required this.receivedAt,
  });

  final String messageId;
  final String conversationId;
  final String senderRefHash;
  final String text;
  final List<AgentCustomerWhatsAppMediaDescriptor> media;
  final DateTime receivedAt;

  bool get grantsAuthority => false;
  bool get containsRawPhone => false;
  bool get containsProviderSecret => false;

  void validate() {
    if (messageId.trim().isEmpty ||
        conversationId.trim().isEmpty ||
        senderRefHash.trim().isEmpty) {
      throw const AgentCustomerWhatsAppTransportException(
        'Inbound identity fields cannot be empty.',
      );
    }

    if (text.trim().isEmpty && media.isEmpty) {
      throw const AgentCustomerWhatsAppTransportException(
        'Inbound message must contain text or approved media metadata.',
      );
    }
  }
}

class AgentCustomerWhatsAppOutboundDraft {
  const AgentCustomerWhatsAppOutboundDraft({
    required this.draftId,
    required this.conversationId,
    required this.recipientRefHash,
    required this.text,
    required this.createdAt,
  });

  final String draftId;
  final String conversationId;
  final String recipientRefHash;
  final String text;
  final DateTime createdAt;

  bool get maySend => false;
  bool get requiresTransportAuthorization => true;
  bool get allowsBulkBroadcast => false;
  bool get allowsRecipientRebinding => false;

  void validate() {
    if (draftId.trim().isEmpty ||
        conversationId.trim().isEmpty ||
        recipientRefHash.trim().isEmpty ||
        text.trim().isEmpty) {
      throw const AgentCustomerWhatsAppTransportException(
        'Outbound draft binding/text cannot be empty.',
      );
    }
  }
}

class AgentCustomerWhatsAppTransportReceipt {
  const AgentCustomerWhatsAppTransportReceipt({
    required this.status,
    required this.message,
    this.providerMessageId = '',
  });

  final String status;
  final String message;
  final String providerMessageId;
}

abstract class AgentCustomerWhatsAppTransport {
  String get transportId;
  bool get networkEnabled;
  bool get liveSendCapable;

  Future<AgentCustomerWhatsAppTransportReceipt> sendDraft(
    AgentCustomerWhatsAppOutboundDraft draft,
  );
}

class AgentCustomerWhatsAppTransportException implements Exception {
  const AgentCustomerWhatsAppTransportException(this.message);

  final String message;

  @override
  String toString() => 'AgentCustomerWhatsAppTransportException: $message';
}

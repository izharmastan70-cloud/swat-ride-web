class AgentEmailDeliveryStatus {
  AgentEmailDeliveryStatus._();

  static const String disabled = 'DISABLED';
  static const String notAttempted = 'NOT_ATTEMPTED';
  static const String accepted = 'ACCEPTED';
  static const String delivered = 'DELIVERED';
  static const String failed = 'FAILED';

  static const Set<String> values = <String>{
    disabled,
    notAttempted,
    accepted,
    delivered,
    failed,
  };
}

class AgentEmailDeliveryReceipt {
  const AgentEmailDeliveryReceipt({
    required this.receiptId,
    required this.handoffId,
    required this.providerId,
    required this.status,
    required this.reason,
    required this.createdAt,
    this.providerMessageId,
  });

  final String receiptId;
  final String handoffId;
  final String providerId;
  final String status;
  final String reason;
  final DateTime createdAt;
  final String? providerMessageId;

  bool get attempted =>
      status != AgentEmailDeliveryStatus.notAttempted &&
      status != AgentEmailDeliveryStatus.disabled;

  bool get acceptedOrDelivered =>
      status == AgentEmailDeliveryStatus.accepted ||
      status == AgentEmailDeliveryStatus.delivered;

  bool get disabled => status == AgentEmailDeliveryStatus.disabled;

  void validate() {
    if (receiptId.trim().isEmpty) {
      throw const AgentEmailDeliveryReceiptException(
        'receiptId cannot be empty.',
      );
    }

    if (handoffId.trim().isEmpty) {
      throw const AgentEmailDeliveryReceiptException(
        'handoffId cannot be empty.',
      );
    }

    if (providerId.trim().isEmpty) {
      throw const AgentEmailDeliveryReceiptException(
        'providerId cannot be empty.',
      );
    }

    if (!AgentEmailDeliveryStatus.values.contains(status)) {
      throw AgentEmailDeliveryReceiptException(
        'Unknown delivery status: $status',
      );
    }

    if (reason.trim().isEmpty) {
      throw const AgentEmailDeliveryReceiptException('reason cannot be empty.');
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'receiptId': receiptId.trim(),
      'handoffId': handoffId.trim(),
      'providerId': providerId.trim(),
      'status': status,
      'reason': reason.trim(),
      'createdAt': createdAt.toUtc().toIso8601String(),
      'providerMessageId': providerMessageId?.trim(),
    };
  }
}

class AgentEmailDeliveryReceiptException implements Exception {
  const AgentEmailDeliveryReceiptException(this.message);

  final String message;

  @override
  String toString() => 'AgentEmailDeliveryReceiptException: $message';
}

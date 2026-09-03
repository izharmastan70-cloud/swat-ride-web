class AgentCustomerWhatsAppVerificationLevel {
  AgentCustomerWhatsAppVerificationLevel._();

  static const String unverified = 'UNVERIFIED';
  static const String customerBound = 'CUSTOMER_BOUND';
  static const String sensitiveVerified = 'SENSITIVE_VERIFIED';

  static const Set<String> values = <String>{
    unverified,
    customerBound,
    sensitiveVerified,
  };
}

/// Privacy-minimized Customer WhatsApp identity/session binding.
///
/// IMPORTANT:
/// - No raw phone number.
/// - No OTP.
/// - No password.
/// - No API/provider token.
/// - senderRefHash is a one-way/reference-safe identifier supplied by the
///   trusted WhatsApp ingress layer later.
/// - A WhatsApp message never becomes authority merely because it came from
///   the same chat/number.
class AgentCustomerWhatsAppIdentitySession {
  const AgentCustomerWhatsAppIdentitySession({
    required this.sessionId,
    required this.conversationId,
    required this.senderRefHash,
    required this.customerIdAlias,
    required this.verificationLevel,
    required this.verificationEvidenceId,
    required this.createdAt,
    required this.expiresAt,
  });

  final String sessionId;
  final String conversationId;
  final String senderRefHash;
  final String customerIdAlias;
  final String verificationLevel;

  /// Opaque ID of trusted backend verification evidence.
  /// The evidence content/OTP itself does not belong in this AI model.
  final String verificationEvidenceId;

  final DateTime createdAt;
  final DateTime expiresAt;

  bool get whatsappMessageGrantsAuthority => false;
  bool get storesRawPhone => false;
  bool get storesOtp => false;
  bool get storesPassword => false;
  bool get storesProviderSecret => false;

  bool get isCustomerBound =>
      verificationLevel ==
          AgentCustomerWhatsAppVerificationLevel.customerBound ||
      verificationLevel ==
          AgentCustomerWhatsAppVerificationLevel.sensitiveVerified;

  bool get mayReadSensitiveCustomerData =>
      verificationLevel ==
      AgentCustomerWhatsAppVerificationLevel.sensitiveVerified;

  bool get mayRequestCustomerBusinessAction => isCustomerBound;

  bool isExpiredAt(DateTime now) => !expiresAt.toUtc().isAfter(now.toUtc());

  bool matchesConversation({
    required String expectedConversationId,
    required String expectedSenderRefHash,
  }) {
    return conversationId == expectedConversationId.trim() &&
        senderRefHash == expectedSenderRefHash.trim();
  }

  void validate() {
    if (sessionId.trim().isEmpty ||
        conversationId.trim().isEmpty ||
        senderRefHash.trim().isEmpty) {
      throw const AgentCustomerWhatsAppIdentitySessionException(
        'Session, conversation, and sender binding cannot be empty.',
      );
    }

    if (!AgentCustomerWhatsAppVerificationLevel.values.contains(
      verificationLevel,
    )) {
      throw const AgentCustomerWhatsAppIdentitySessionException(
        'Unknown Customer WhatsApp verification level.',
      );
    }

    if (isCustomerBound &&
        (customerIdAlias.trim().isEmpty ||
            verificationEvidenceId.trim().isEmpty)) {
      throw const AgentCustomerWhatsAppIdentitySessionException(
        'Verified session requires customer alias and trusted evidence ID.',
      );
    }

    if (!expiresAt.toUtc().isAfter(createdAt.toUtc())) {
      throw const AgentCustomerWhatsAppIdentitySessionException(
        'Session expiry must be after creation time.',
      );
    }
  }
}

class AgentCustomerWhatsAppIdentitySessionException implements Exception {
  const AgentCustomerWhatsAppIdentitySessionException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentCustomerWhatsAppIdentitySessionException: $message';
}

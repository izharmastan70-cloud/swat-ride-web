class AgentEmailSenderIdentity {
  const AgentEmailSenderIdentity({
    required this.senderIdentityId,
    required this.providerId,
    required this.fromAddress,
    required this.displayName,
    required this.enabled,
    required this.verifiedAt,
  });

  final String senderIdentityId;
  final String providerId;
  final String fromAddress;
  final String displayName;
  final bool enabled;
  final DateTime? verifiedAt;

  bool get isVerified => verifiedAt != null;

  bool get mayBeUsedForTransport => enabled && isVerified;

  bool get containsCredentialMaterial => false;
  bool get mayStoreProviderSecret => false;
  bool get mayStorePassword => false;
  bool get mayStoreApiKey => false;

  void validate() {
    if (senderIdentityId.trim().isEmpty) {
      throw const AgentEmailSenderIdentityException(
        'senderIdentityId cannot be empty.',
      );
    }

    if (providerId.trim().isEmpty) {
      throw const AgentEmailSenderIdentityException(
        'providerId cannot be empty.',
      );
    }

    if (!_looksLikeEmail(fromAddress)) {
      throw const AgentEmailSenderIdentityException(
        'fromAddress must be a valid email-like address.',
      );
    }

    if (displayName.trim().isEmpty) {
      throw const AgentEmailSenderIdentityException(
        'displayName cannot be empty.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'senderIdentityId': senderIdentityId.trim(),
      'providerId': providerId.trim(),
      'fromAddress': fromAddress.trim().toLowerCase(),
      'displayName': displayName.trim(),
      'enabled': enabled,
      'verifiedAt': verifiedAt?.toUtc().toIso8601String(),
    };
  }

  static bool _looksLikeEmail(String value) {
    final String normalized = value.trim();
    if (normalized.isEmpty || normalized.contains(RegExp(r'[\r\n]'))) {
      return false;
    }

    final int at = normalized.indexOf('@');
    if (at <= 0 || at != normalized.lastIndexOf('@')) {
      return false;
    }

    final String domain = normalized.substring(at + 1);
    return domain.contains('.') &&
        !domain.startsWith('.') &&
        !domain.endsWith('.');
  }
}

class AgentEmailSenderIdentityException implements Exception {
  const AgentEmailSenderIdentityException(this.message);

  final String message;

  @override
  String toString() => 'AgentEmailSenderIdentityException: $message';
}

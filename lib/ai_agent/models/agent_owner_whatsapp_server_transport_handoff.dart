class AgentOwnerWhatsAppServerTransportHandoff {
  AgentOwnerWhatsAppServerTransportHandoff({
    required String handoffId,
    required String providerId,
    required String webhookRouteRef,
    required String serverSecretBundleRef,
    required String signatureVerifierRef,
    required String persistentReplayStoreRef,
    required String inboundIdempotencyStoreRef,
    required String ownerIdentityBindingRef,
    required String strongReauthBoundaryRef,
    required DateTime preparedAt,
  }) : handoffId = handoffId.trim(),
       providerId = providerId.trim(),
       webhookRouteRef = webhookRouteRef.trim(),
       serverSecretBundleRef = serverSecretBundleRef.trim(),
       signatureVerifierRef = signatureVerifierRef.trim(),
       persistentReplayStoreRef = persistentReplayStoreRef.trim(),
       inboundIdempotencyStoreRef = inboundIdempotencyStoreRef.trim(),
       ownerIdentityBindingRef = ownerIdentityBindingRef.trim(),
       strongReauthBoundaryRef = strongReauthBoundaryRef.trim(),
       preparedAt = preparedAt.toUtc();

  final String handoffId;
  final String providerId;

  /// Reference/identifier only. Never a live URL with credentials.
  final String webhookRouteRef;

  /// Secret manager reference/bundle name only. Never secret material.
  final String serverSecretBundleRef;

  /// Trusted-server verifier component reference only.
  final String signatureVerifierRef;

  /// Persistent replay store reference only.
  final String persistentReplayStoreRef;

  /// Persistent inbound idempotency store reference only.
  final String inboundIdempotencyStoreRef;

  /// Server-side Owner/Super Admin identity binding component reference only.
  final String ownerIdentityBindingRef;

  /// Server-side strong re-auth component reference only.
  final String strongReauthBoundaryRef;

  final DateTime preparedAt;

  static const Set<String> _forbiddenReferenceFragments = <String>{
    'password',
    'passcode',
    'otp',
    'token=',
    'secret=',
    'apikey=',
    'api_key=',
    'authorization:',
    'bearer ',
    'cookie:',
    'cvv',
    'cvc',
    'cardnumber',
    'card_number',
    'privatekey',
    'private_key',
  };

  void validate() {
    final Map<String, String> values = <String, String>{
      'handoffId': handoffId,
      'providerId': providerId,
      'webhookRouteRef': webhookRouteRef,
      'serverSecretBundleRef': serverSecretBundleRef,
      'signatureVerifierRef': signatureVerifierRef,
      'persistentReplayStoreRef': persistentReplayStoreRef,
      'inboundIdempotencyStoreRef': inboundIdempotencyStoreRef,
      'ownerIdentityBindingRef': ownerIdentityBindingRef,
      'strongReauthBoundaryRef': strongReauthBoundaryRef,
    };

    for (final MapEntry<String, String> entry in values.entries) {
      if (entry.value.isEmpty) {
        throw AgentOwnerWhatsAppServerTransportHandoffException(
          '${entry.key} cannot be empty.',
        );
      }

      _rejectSecretLikeReference(entry.key, entry.value);
    }

    if (webhookRouteRef.startsWith('http://') ||
        webhookRouteRef.startsWith('https://')) {
      throw const AgentOwnerWhatsAppServerTransportHandoffException(
        'webhookRouteRef must be a provider-neutral server route reference, '
        'not a live URL.',
      );
    }
  }

  Map<String, dynamic> toSafeReferenceMap() {
    validate();

    return <String, dynamic>{
      'handoffId': handoffId,
      'providerId': providerId,
      'webhookRouteRef': webhookRouteRef,
      'serverSecretBundleRef': serverSecretBundleRef,
      'signatureVerifierRef': signatureVerifierRef,
      'persistentReplayStoreRef': persistentReplayStoreRef,
      'inboundIdempotencyStoreRef': inboundIdempotencyStoreRef,
      'ownerIdentityBindingRef': ownerIdentityBindingRef,
      'strongReauthBoundaryRef': strongReauthBoundaryRef,
      'preparedAt': preparedAt.toIso8601String(),
      'containsSecretValue': false,
      'containsRawWebhookPayload': false,
      'containsRawPhoneNumber': false,
      'containsOtp': false,
      'containsPaymentCredential': false,
      'networkAuthorized': false,
      'whatsappSendAuthorized': false,
      'businessMutationAuthorized': false,
      'deploymentAuthorized': false,
    };
  }

  static void _rejectSecretLikeReference(String field, String value) {
    final String normalized = value.toLowerCase();

    for (final String fragment in _forbiddenReferenceFragments) {
      if (normalized.contains(fragment)) {
        throw AgentOwnerWhatsAppServerTransportHandoffException(
          '$field appears to contain secret/credential material.',
        );
      }
    }
  }

  bool get mayHandleLiveInboundWebhook => false;
  bool get maySendWhatsApp => false;
  bool get mayCallProvider => false;
  bool get mayExecuteBusinessOrAdminWrite => false;
  bool get mayDeploy => false;
}

class AgentOwnerWhatsAppServerTransportHandoffException implements Exception {
  const AgentOwnerWhatsAppServerTransportHandoffException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentOwnerWhatsAppServerTransportHandoffException: $message';
}

class AgentCustomerWhatsAppProductionActivation {
  const AgentCustomerWhatsAppProductionActivation({
    this.providerId = '',
    this.providerSelected = false,
    this.serverSecretsConfigured = false,
    this.inboundSignatureVerificationConfigured = false,
    this.persistentReplayStoreConfigured = false,
    this.inboundIdempotencyConfigured = false,
    this.webhookRouteConfigured = false,
    this.providerPolicyReviewComplete = false,
    this.outboundConsentPolicyConfigured = false,
    this.outboundTransportConfigured = false,
    this.ownerExplicitActivation = false,
  });

  final String providerId;
  final bool providerSelected;
  final bool serverSecretsConfigured;
  final bool inboundSignatureVerificationConfigured;
  final bool persistentReplayStoreConfigured;
  final bool inboundIdempotencyConfigured;
  final bool webhookRouteConfigured;
  final bool providerPolicyReviewComplete;
  final bool outboundConsentPolicyConfigured;
  final bool outboundTransportConfigured;
  final bool ownerExplicitActivation;

  bool get liveTransportAllowed =>
      providerSelected &&
      providerId.trim().isNotEmpty &&
      serverSecretsConfigured &&
      inboundSignatureVerificationConfigured &&
      persistentReplayStoreConfigured &&
      inboundIdempotencyConfigured &&
      webhookRouteConfigured &&
      providerPolicyReviewComplete &&
      outboundConsentPolicyConfigured &&
      outboundTransportConfigured &&
      ownerExplicitActivation;

  bool get implementationDefaultIsSafe =>
      !providerSelected &&
      providerId.trim().isEmpty &&
      !serverSecretsConfigured &&
      !inboundSignatureVerificationConfigured &&
      !persistentReplayStoreConfigured &&
      !inboundIdempotencyConfigured &&
      !webhookRouteConfigured &&
      !outboundTransportConfigured &&
      !ownerExplicitActivation;

  List<String> missingActivationGates() {
    final List<String> missing = <String>[];

    if (!providerSelected || providerId.trim().isEmpty) {
      missing.add('PROVIDER_SELECTION');
    }
    if (!serverSecretsConfigured) {
      missing.add('SERVER_SECRETS');
    }
    if (!inboundSignatureVerificationConfigured) {
      missing.add('INBOUND_SIGNATURE_VERIFICATION');
    }
    if (!persistentReplayStoreConfigured) {
      missing.add('PERSISTENT_REPLAY_STORE');
    }
    if (!inboundIdempotencyConfigured) {
      missing.add('INBOUND_IDEMPOTENCY');
    }
    if (!webhookRouteConfigured) {
      missing.add('WEBHOOK_ROUTE');
    }
    if (!providerPolicyReviewComplete) {
      missing.add('CURRENT_PROVIDER_POLICY_REVIEW');
    }
    if (!outboundConsentPolicyConfigured) {
      missing.add('OUTBOUND_CONSENT_POLICY');
    }
    if (!outboundTransportConfigured) {
      missing.add('OUTBOUND_TRANSPORT');
    }
    if (!ownerExplicitActivation) {
      missing.add('OWNER_EXPLICIT_ACTIVATION');
    }

    return List<String>.unmodifiable(missing);
  }
}

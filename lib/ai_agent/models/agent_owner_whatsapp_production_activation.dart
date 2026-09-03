class AgentOwnerWhatsAppProductionRequirement {
  AgentOwnerWhatsAppProductionRequirement._();

  static const String providerSelection = 'PROVIDER_SELECTION';
  static const String serverSecrets = 'SERVER_SECRETS';
  static const String inboundSignatureVerification =
      'INBOUND_SIGNATURE_VERIFICATION';
  static const String persistentReplayStore = 'PERSISTENT_REPLAY_STORE';
  static const String inboundIdempotency = 'INBOUND_IDEMPOTENCY';
  static const String webhookRoute = 'WEBHOOK_ROUTE';
  static const String ownerIdentityBinding = 'OWNER_IDENTITY_BINDING';
  static const String strongReauthBoundary = 'STRONG_REAUTH_BOUNDARY';
  static const String currentProviderPolicyReview =
      'CURRENT_PROVIDER_POLICY_REVIEW';

  static const Set<String> values = <String>{
    providerSelection,
    serverSecrets,
    inboundSignatureVerification,
    persistentReplayStore,
    inboundIdempotency,
    webhookRoute,
    ownerIdentityBinding,
    strongReauthBoundary,
    currentProviderPolicyReview,
  };
}

/// Provider-neutral production-readiness declaration only.
///
/// IMPORTANT:
/// This model does NOT configure a provider, secret, webhook, signature
/// verifier, replay database, idempotency database, or outbound send.
///
/// Every security requirement must be independently implemented at the
/// trusted server boundary before [isProductionReady] may become true.
class AgentOwnerWhatsAppProductionActivation {
  const AgentOwnerWhatsAppProductionActivation({
    this.providerId = '',
    this.providerSelected = false,
    this.serverSecretsConfigured = false,
    this.inboundSignatureVerificationConfigured = false,
    this.persistentReplayStoreConfigured = false,
    this.inboundIdempotencyConfigured = false,
    this.webhookRouteConfigured = false,
    this.ownerIdentityBindingConfigured = false,
    this.strongReauthBoundaryConfigured = false,
    this.providerPolicyReviewComplete = false,
  });

  final String providerId;
  final bool providerSelected;
  final bool serverSecretsConfigured;
  final bool inboundSignatureVerificationConfigured;
  final bool persistentReplayStoreConfigured;
  final bool inboundIdempotencyConfigured;
  final bool webhookRouteConfigured;
  final bool ownerIdentityBindingConfigured;
  final bool strongReauthBoundaryConfigured;
  final bool providerPolicyReviewComplete;

  bool get isProductionReady =>
      providerSelected &&
      providerId.trim().isNotEmpty &&
      serverSecretsConfigured &&
      inboundSignatureVerificationConfigured &&
      persistentReplayStoreConfigured &&
      inboundIdempotencyConfigured &&
      webhookRouteConfigured &&
      ownerIdentityBindingConfigured &&
      strongReauthBoundaryConfigured &&
      providerPolicyReviewComplete;

  bool get isSafePreProviderDefault =>
      !providerSelected &&
      providerId.trim().isEmpty &&
      !serverSecretsConfigured &&
      !inboundSignatureVerificationConfigured &&
      !persistentReplayStoreConfigured &&
      !inboundIdempotencyConfigured &&
      !webhookRouteConfigured &&
      !ownerIdentityBindingConfigured &&
      !strongReauthBoundaryConfigured &&
      !providerPolicyReviewComplete;

  List<String> get missingRequirements {
    final List<String> missing = <String>[];

    if (!providerSelected || providerId.trim().isEmpty) {
      missing.add(AgentOwnerWhatsAppProductionRequirement.providerSelection);
    }

    if (!serverSecretsConfigured) {
      missing.add(AgentOwnerWhatsAppProductionRequirement.serverSecrets);
    }

    if (!inboundSignatureVerificationConfigured) {
      missing.add(
        AgentOwnerWhatsAppProductionRequirement.inboundSignatureVerification,
      );
    }

    if (!persistentReplayStoreConfigured) {
      missing.add(
        AgentOwnerWhatsAppProductionRequirement.persistentReplayStore,
      );
    }

    if (!inboundIdempotencyConfigured) {
      missing.add(AgentOwnerWhatsAppProductionRequirement.inboundIdempotency);
    }

    if (!webhookRouteConfigured) {
      missing.add(AgentOwnerWhatsAppProductionRequirement.webhookRoute);
    }

    if (!ownerIdentityBindingConfigured) {
      missing.add(AgentOwnerWhatsAppProductionRequirement.ownerIdentityBinding);
    }

    if (!strongReauthBoundaryConfigured) {
      missing.add(AgentOwnerWhatsAppProductionRequirement.strongReauthBoundary);
    }

    if (!providerPolicyReviewComplete) {
      missing.add(
        AgentOwnerWhatsAppProductionRequirement.currentProviderPolicyReview,
      );
    }

    return List<String>.unmodifiable(missing);
  }

  /// Readiness flags never grant runtime/transport/business authority.
  bool get mayHandleLiveInboundWebhook => false;
  bool get maySendWhatsApp => false;
  bool get mayCallProvider => false;
  bool get mayExecuteBusinessOrAdminWrite => false;
  bool get mayDeploy => false;
}

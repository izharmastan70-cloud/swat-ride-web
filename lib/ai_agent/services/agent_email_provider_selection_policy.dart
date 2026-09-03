import '../models/agent_email_remote_transport_config.dart';

class AgentEmailProviderSelection {
  const AgentEmailProviderSelection({
    required this.providerId,
    required this.serverBoundaryId,
    required this.enabled,
    required this.ownerConfigured,
    required this.reason,
  });

  final String providerId;
  final String serverBoundaryId;
  final bool enabled;
  final bool ownerConfigured;
  final String reason;

  bool get maySend => false;
  bool get mayAccessProviderSecret => false;
  bool get mayOpenNetworkConnection => false;
  bool get mayDeploy => false;
}

class AgentEmailProviderSelectionPolicy {
  const AgentEmailProviderSelectionPolicy();

  /// Current initial FREE-FIRST recommendation.
  ///
  /// This is a default only, not a permanent hard-coded provider lock.
  /// Owner configuration may select another supported provider later.
  static const String initialFreeFirstProviderId = AgentEmailProviderId.brevo;

  static const String initialServerBoundaryId =
      AgentEmailServerBoundaryId.vercelServerless;

  static const String providerApiKeySecretName = 'BREVO_API_KEY';

  static const String firebaseAdminCredentialSecretName =
      'FIREBASE_SERVICE_ACCOUNT_JSON';

  bool get providerPermanentlyHardcoded => false;
  bool get ownerMayChangeProvider => true;
  bool get clientSecretStorageAllowed => false;
  bool get directFlutterProviderCallAllowed => false;
  bool get transportEnabledByDefault => false;

  AgentEmailRemoteTransportConfig buildInitialDisabledConfig({
    String endpointUrl = '',
  }) {
    final AgentEmailRemoteTransportConfig config =
        AgentEmailRemoteTransportConfig(
          providerId: initialFreeFirstProviderId,
          serverBoundaryId: initialServerBoundaryId,
          enabled: false,
          endpointUrl: endpointUrl,
          providerApiKeySecretName: providerApiKeySecretName,
          firebaseAdminCredentialSecretName: firebaseAdminCredentialSecretName,
          requiresFirebaseIdToken: true,
          requiresServerApprovalRecheck: true,
          requiresVerifiedSenderIdentity: true,
          credentialSource:
              AgentEmailCredentialSource.serverSensitiveEnvironment,
          ownerConfigurable: true,
        );

    config.validate();
    return config;
  }

  AgentEmailProviderSelection select({
    required List<AgentEmailRemoteTransportConfig> configs,
    String? ownerConfiguredProviderId,
  }) {
    if (configs.isEmpty) {
      return const AgentEmailProviderSelection(
        providerId: '',
        serverBoundaryId: '',
        enabled: false,
        ownerConfigured: false,
        reason: 'No Email provider configuration exists.',
      );
    }

    for (final AgentEmailRemoteTransportConfig config in configs) {
      config.validate();
    }

    final String ownerChoice = ownerConfiguredProviderId?.trim() ?? '';

    if (ownerChoice.isNotEmpty) {
      for (final AgentEmailRemoteTransportConfig config in configs) {
        if (config.providerId == ownerChoice) {
          return AgentEmailProviderSelection(
            providerId: config.providerId,
            serverBoundaryId: config.serverBoundaryId,
            enabled: config.enabled,
            ownerConfigured: true,
            reason: 'Owner-selected supported Email provider configuration.',
          );
        }
      }

      return AgentEmailProviderSelection(
        providerId: ownerChoice,
        serverBoundaryId: '',
        enabled: false,
        ownerConfigured: true,
        reason:
            'Owner-selected Email provider is unavailable/unsupported in the supplied configuration.',
      );
    }

    for (final AgentEmailRemoteTransportConfig config in configs) {
      if (config.providerId == initialFreeFirstProviderId) {
        return AgentEmailProviderSelection(
          providerId: config.providerId,
          serverBoundaryId: config.serverBoundaryId,
          enabled: config.enabled,
          ownerConfigured: false,
          reason:
              'Initial Free-First provider preference selected; transport remains controlled by config.enabled.',
        );
      }
    }

    final AgentEmailRemoteTransportConfig fallback = configs.first;

    return AgentEmailProviderSelection(
      providerId: fallback.providerId,
      serverBoundaryId: fallback.serverBoundaryId,
      enabled: fallback.enabled,
      ownerConfigured: false,
      reason:
          'Configured fallback selected because initial Free-First provider is not present.',
    );
  }
}

class AgentEmailProviderId {
  AgentEmailProviderId._();

  static const String brevo = 'brevo';
  static const String resend = 'resend';

  static const Set<String> supported = <String>{brevo, resend};
}

class AgentEmailServerBoundaryId {
  AgentEmailServerBoundaryId._();

  static const String vercelServerless = 'vercel_serverless';

  static const Set<String> supported = <String>{vercelServerless};
}

class AgentEmailCredentialSource {
  AgentEmailCredentialSource._();

  static const String serverSensitiveEnvironment =
      'SERVER_SENSITIVE_ENVIRONMENT';
}

class AgentEmailRemoteTransportConfig {
  const AgentEmailRemoteTransportConfig({
    required this.providerId,
    required this.serverBoundaryId,
    required this.enabled,
    required this.endpointUrl,
    required this.providerApiKeySecretName,
    required this.firebaseAdminCredentialSecretName,
    required this.requiresFirebaseIdToken,
    required this.requiresServerApprovalRecheck,
    required this.requiresVerifiedSenderIdentity,
    required this.credentialSource,
    required this.ownerConfigurable,
  });

  final String providerId;
  final String serverBoundaryId;
  final bool enabled;

  /// Public HTTPS endpoint only. No credential belongs here.
  final String endpointUrl;

  /// Names/references only; NEVER actual secret values.
  final String providerApiKeySecretName;
  final String firebaseAdminCredentialSecretName;

  final bool requiresFirebaseIdToken;
  final bool requiresServerApprovalRecheck;
  final bool requiresVerifiedSenderIdentity;
  final String credentialSource;
  final bool ownerConfigurable;

  bool get mayExposeProviderSecretToClient => false;
  bool get mayStoreProviderApiKeyInFlutter => false;
  bool get mayStoreFirebaseAdminCredentialInFlutter => false;
  bool get liveSendEnabled => enabled;

  bool get secureServerBoundaryRequired =>
      credentialSource ==
          AgentEmailCredentialSource.serverSensitiveEnvironment &&
      requiresFirebaseIdToken &&
      requiresServerApprovalRecheck &&
      requiresVerifiedSenderIdentity;

  void validate() {
    if (!AgentEmailProviderId.supported.contains(providerId)) {
      throw AgentEmailRemoteTransportConfigException(
        'Unsupported Email provider: $providerId',
      );
    }

    if (!AgentEmailServerBoundaryId.supported.contains(serverBoundaryId)) {
      throw AgentEmailRemoteTransportConfigException(
        'Unsupported Email server boundary: $serverBoundaryId',
      );
    }

    if (credentialSource !=
        AgentEmailCredentialSource.serverSensitiveEnvironment) {
      throw const AgentEmailRemoteTransportConfigException(
        'Email provider credentials must remain in a server-sensitive environment.',
      );
    }

    if (providerApiKeySecretName.trim().isEmpty ||
        firebaseAdminCredentialSecretName.trim().isEmpty) {
      throw const AgentEmailRemoteTransportConfigException(
        'Server secret reference names cannot be empty.',
      );
    }

    if (!requiresFirebaseIdToken ||
        !requiresServerApprovalRecheck ||
        !requiresVerifiedSenderIdentity) {
      throw const AgentEmailRemoteTransportConfigException(
        'Email remote transport must require auth, server approval recheck, and verified sender identity.',
      );
    }

    final String endpoint = endpointUrl.trim();

    if (enabled) {
      final Uri? uri = Uri.tryParse(endpoint);
      if (uri == null ||
          uri.scheme.toLowerCase() != 'https' ||
          uri.host.trim().isEmpty) {
        throw const AgentEmailRemoteTransportConfigException(
          'Enabled Email transport requires a valid HTTPS server endpoint.',
        );
      }
    } else if (endpoint.isNotEmpty) {
      final Uri? uri = Uri.tryParse(endpoint);
      if (uri == null ||
          uri.scheme.toLowerCase() != 'https' ||
          uri.host.trim().isEmpty) {
        throw const AgentEmailRemoteTransportConfigException(
          'Configured Email endpoint must use HTTPS.',
        );
      }
    }
  }

  Map<String, dynamic> toSafeClientMap() {
    return <String, dynamic>{
      'providerId': providerId,
      'serverBoundaryId': serverBoundaryId,
      'enabled': enabled,
      'endpointUrl': endpointUrl.trim(),
      'providerApiKeySecretName': providerApiKeySecretName.trim(),
      'firebaseAdminCredentialSecretName': firebaseAdminCredentialSecretName
          .trim(),
      'requiresFirebaseIdToken': requiresFirebaseIdToken,
      'requiresServerApprovalRecheck': requiresServerApprovalRecheck,
      'requiresVerifiedSenderIdentity': requiresVerifiedSenderIdentity,
      'credentialSource': credentialSource,
      'ownerConfigurable': ownerConfigurable,
      'containsSecretValue': false,
    };
  }
}

class AgentEmailRemoteTransportConfigException implements Exception {
  const AgentEmailRemoteTransportConfigException(this.message);

  final String message;

  @override
  String toString() => 'AgentEmailRemoteTransportConfigException: $message';
}

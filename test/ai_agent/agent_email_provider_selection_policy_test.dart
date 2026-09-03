import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_email_remote_transport_config.dart';
import 'package:swat_ride/ai_agent/services/agent_email_provider_selection_policy.dart';

void main() {
  const AgentEmailProviderSelectionPolicy policy =
      AgentEmailProviderSelectionPolicy();

  test('initial Free-First config is Brevo + Vercel and disabled', () {
    final AgentEmailRemoteTransportConfig config = policy
        .buildInitialDisabledConfig();

    expect(config.providerId, AgentEmailProviderId.brevo);
    expect(
      config.serverBoundaryId,
      AgentEmailServerBoundaryId.vercelServerless,
    );
    expect(config.enabled, isFalse);
    expect(config.liveSendEnabled, isFalse);
    expect(config.secureServerBoundaryRequired, isTrue);
    expect(config.ownerConfigurable, isTrue);
  });

  test('initial config stores only secret reference names, never values', () {
    final AgentEmailRemoteTransportConfig config = policy
        .buildInitialDisabledConfig();

    expect(config.providerApiKeySecretName, 'BREVO_API_KEY');
    expect(
      config.firebaseAdminCredentialSecretName,
      'FIREBASE_SERVICE_ACCOUNT_JSON',
    );

    expect(config.mayExposeProviderSecretToClient, isFalse);
    expect(config.mayStoreProviderApiKeyInFlutter, isFalse);
    expect(config.mayStoreFirebaseAdminCredentialInFlutter, isFalse);

    final Map<String, dynamic> safeMap = config.toSafeClientMap();

    expect(safeMap['containsSecretValue'], isFalse);
    expect(
      safeMap.values.any(
        (dynamic value) =>
            value is String && value.toLowerCase().contains('actual-secret'),
      ),
      isFalse,
    );
  });

  test('provider is not permanently hard-coded and owner may change it', () {
    expect(policy.providerPermanentlyHardcoded, isFalse);
    expect(policy.ownerMayChangeProvider, isTrue);
    expect(policy.clientSecretStorageAllowed, isFalse);
    expect(policy.directFlutterProviderCallAllowed, isFalse);
    expect(policy.transportEnabledByDefault, isFalse);
  });

  test(
    'default selection chooses initial Free-First provider but stays OFF',
    () {
      final AgentEmailRemoteTransportConfig brevo = policy
          .buildInitialDisabledConfig();

      final AgentEmailProviderSelection selection = policy.select(
        configs: <AgentEmailRemoteTransportConfig>[brevo],
      );

      expect(selection.providerId, AgentEmailProviderId.brevo);
      expect(selection.enabled, isFalse);
      expect(selection.ownerConfigured, isFalse);
      expect(selection.maySend, isFalse);
      expect(selection.mayAccessProviderSecret, isFalse);
      expect(selection.mayOpenNetworkConnection, isFalse);
    },
  );

  test('owner can select another supported provider configuration', () {
    final AgentEmailRemoteTransportConfig brevo = policy
        .buildInitialDisabledConfig();

    const AgentEmailRemoteTransportConfig resend =
        AgentEmailRemoteTransportConfig(
          providerId: AgentEmailProviderId.resend,
          serverBoundaryId: AgentEmailServerBoundaryId.vercelServerless,
          enabled: false,
          endpointUrl: '',
          providerApiKeySecretName: 'RESEND_API_KEY',
          firebaseAdminCredentialSecretName: 'FIREBASE_SERVICE_ACCOUNT_JSON',
          requiresFirebaseIdToken: true,
          requiresServerApprovalRecheck: true,
          requiresVerifiedSenderIdentity: true,
          credentialSource:
              AgentEmailCredentialSource.serverSensitiveEnvironment,
          ownerConfigurable: true,
        );

    final AgentEmailProviderSelection selection = policy.select(
      configs: <AgentEmailRemoteTransportConfig>[brevo, resend],
      ownerConfiguredProviderId: AgentEmailProviderId.resend,
    );

    expect(selection.providerId, AgentEmailProviderId.resend);
    expect(selection.ownerConfigured, isTrue);
    expect(selection.enabled, isFalse);
  });

  test('unsupported owner provider fails closed', () {
    final AgentEmailProviderSelection selection = policy.select(
      configs: <AgentEmailRemoteTransportConfig>[
        policy.buildInitialDisabledConfig(),
      ],
      ownerConfiguredProviderId: 'unknown_provider',
    );

    expect(selection.providerId, 'unknown_provider');
    expect(selection.enabled, isFalse);
    expect(selection.ownerConfigured, isTrue);
    expect(selection.maySend, isFalse);
  });

  test('enabled config must use HTTPS endpoint', () {
    const AgentEmailRemoteTransportConfig invalid =
        AgentEmailRemoteTransportConfig(
          providerId: AgentEmailProviderId.brevo,
          serverBoundaryId: AgentEmailServerBoundaryId.vercelServerless,
          enabled: true,
          endpointUrl: 'http://example.com/api/email/send',
          providerApiKeySecretName: 'BREVO_API_KEY',
          firebaseAdminCredentialSecretName: 'FIREBASE_SERVICE_ACCOUNT_JSON',
          requiresFirebaseIdToken: true,
          requiresServerApprovalRecheck: true,
          requiresVerifiedSenderIdentity: true,
          credentialSource:
              AgentEmailCredentialSource.serverSensitiveEnvironment,
          ownerConfigurable: true,
        );

    expect(
      invalid.validate,
      throwsA(isA<AgentEmailRemoteTransportConfigException>()),
    );
  });

  test('missing server approval recheck fails validation', () {
    const AgentEmailRemoteTransportConfig invalid =
        AgentEmailRemoteTransportConfig(
          providerId: AgentEmailProviderId.brevo,
          serverBoundaryId: AgentEmailServerBoundaryId.vercelServerless,
          enabled: false,
          endpointUrl: '',
          providerApiKeySecretName: 'BREVO_API_KEY',
          firebaseAdminCredentialSecretName: 'FIREBASE_SERVICE_ACCOUNT_JSON',
          requiresFirebaseIdToken: true,
          requiresServerApprovalRecheck: false,
          requiresVerifiedSenderIdentity: true,
          credentialSource:
              AgentEmailCredentialSource.serverSensitiveEnvironment,
          ownerConfigurable: true,
        );

    expect(
      invalid.validate,
      throwsA(isA<AgentEmailRemoteTransportConfigException>()),
    );
  });
}

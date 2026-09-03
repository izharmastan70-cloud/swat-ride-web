import '../models/agent_git_connected_vercel_provider_config.dart';
import 'agent_git_connected_vercel_deployment_adapter.dart';
import 'agent_website_deployment_adapter.dart';

/// Phase 34 Step 3D-E3C3.
///
/// Explicit website deployment provider selection boundary.
///
/// This selector performs no deployment itself.
///
/// Supported selections:
/// - DISABLED
/// - GIT_CONNECTED_VERCEL
///
/// The Git-connected adapter remains fail-closed in this phase.
/// No Git push, Vercel API, token, shell/process, DNS, or secret
/// authority exists in this selector.
class AgentWebsiteDeploymentProviderSelector {
  const AgentWebsiteDeploymentProviderSelector();

  AgentWebsiteDeploymentAdapter select({
    required String providerId,
    AgentGitConnectedVercelProviderConfig? gitConnectedVercelConfig,
  }) {
    final String normalized = providerId.trim().toUpperCase();

    switch (normalized) {
      case AgentWebsiteDeploymentProviderId.disabled:
        return const AgentDisabledWebsiteDeploymentAdapter();

      case AgentWebsiteDeploymentProviderId.gitConnectedVercel:
        final AgentGitConnectedVercelProviderConfig? config =
            gitConnectedVercelConfig;

        if (config == null) {
          throw const AgentWebsiteDeploymentProviderSelectionException(
            'Git-connected Vercel selection requires provider configuration.',
          );
        }

        config.validate();

        return AgentGitConnectedVercelDeploymentAdapter(config: config);

      default:
        throw AgentWebsiteDeploymentProviderSelectionException(
          'Unsupported website deployment provider: $providerId',
        );
    }
  }
}

class AgentWebsiteDeploymentProviderId {
  AgentWebsiteDeploymentProviderId._();

  static const String disabled = 'DISABLED';

  static const String gitConnectedVercel = 'GIT_CONNECTED_VERCEL';

  static const Set<String> values = <String>{disabled, gitConnectedVercel};
}

class AgentWebsiteDeploymentProviderSelectionException implements Exception {
  final String message;

  const AgentWebsiteDeploymentProviderSelectionException(this.message);

  @override
  String toString() =>
      'AgentWebsiteDeploymentProviderSelectionException: $message';
}

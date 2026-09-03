/// Phase 34 Step 3D-E3C2.
///
/// Safe configuration contract for a Git-connected Vercel provider.
///
/// This model intentionally contains NO:
/// - GitHub token;
/// - Vercel token;
/// - password/private key;
/// - shell command;
/// - DNS/domain credential.
///
/// Current selected strategy:
/// GitHub repository -> protected production branch -> Vercel Git integration.
class AgentGitConnectedVercelProviderConfig {
  final String repositoryUrl;
  final String productionBranch;

  /// Human-readable provider name only.
  final String providerName;

  /// Whether the external Git/Vercel project relationship has been
  /// confirmed by the Owner/admin setup.
  final bool gitProviderConnected;

  /// Whether Vercel is confirmed to watch the configured repository.
  ///
  /// This does not contain credentials and does not itself deploy.
  final bool vercelProjectConnected;

  /// Must remain false until a later explicit execution-authority phase.
  final bool livePushAuthorityEnabled;

  /// Must remain false until a later explicit execution-authority phase.
  final bool liveDeploymentAuthorityEnabled;

  const AgentGitConnectedVercelProviderConfig({
    required this.repositoryUrl,
    required this.productionBranch,
    this.providerName = 'GIT_CONNECTED_VERCEL',
    required this.gitProviderConnected,
    required this.vercelProjectConnected,
    this.livePushAuthorityEnabled = false,
    this.liveDeploymentAuthorityEnabled = false,
  });

  bool get hasRepositoryIdentity =>
      repositoryUrl.trim().isNotEmpty && productionBranch.trim().isNotEmpty;

  bool get providerRelationshipReady =>
      hasRepositoryIdentity && gitProviderConnected && vercelProjectConnected;

  bool get liveExecutionAllowed =>
      providerRelationshipReady &&
      livePushAuthorityEnabled &&
      liveDeploymentAuthorityEnabled;

  void validate() {
    final String repo = repositoryUrl.trim();
    final String branch = productionBranch.trim();

    if (repo.isEmpty || branch.isEmpty) {
      throw const AgentGitConnectedVercelProviderConfigException(
        'Repository URL and production branch are required.',
      );
    }

    final Uri? uri = Uri.tryParse(repo);

    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw const AgentGitConnectedVercelProviderConfigException(
        'Repository URL must be a valid HTTP/HTTPS URI.',
      );
    }

    if (branch.contains('..') ||
        branch.contains('~') ||
        branch.contains('^') ||
        branch.contains(':') ||
        branch.contains(r'\')) {
      throw const AgentGitConnectedVercelProviderConfigException(
        'Production branch contains unsupported Git reference characters.',
      );
    }

    if (livePushAuthorityEnabled || liveDeploymentAuthorityEnabled) {
      throw const AgentGitConnectedVercelProviderConfigException(
        'Phase 34 E3C2 is provider-contract-only. '
        'Live push/deployment authority must remain disabled.',
      );
    }
  }
}

class AgentGitConnectedVercelProviderConfigException implements Exception {
  final String message;

  const AgentGitConnectedVercelProviderConfigException(this.message);

  @override
  String toString() =>
      'AgentGitConnectedVercelProviderConfigException: $message';
}

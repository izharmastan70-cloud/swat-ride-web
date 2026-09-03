import '../models/agent_website_change_request.dart';

/// Phase 34 website safety boundary.
///
/// This policy is deliberately pure:
/// - no filesystem access;
/// - no shell/process execution;
/// - no Git client;
/// - no Vercel API;
/// - no secrets;
/// - no DNS/domain mutation.
///
/// It only validates whether a website proposal is structurally safe
/// to enter the Permission / Runtime / Approval pipeline.
class AgentWebsiteChangePolicy {
  const AgentWebsiteChangePolicy();

  static const Set<String> allowedSourcePrefixes = <String>{'src/', 'public/'};

  static const Set<String> allowedRootFiles = <String>{
    'next.config.mjs',
    'package.json',
  };

  AgentWebsitePolicyDecision evaluate(AgentWebsiteChangeRequest request) {
    try {
      request.validate();
    } catch (error) {
      return AgentWebsitePolicyDecision.deny(
        'Website change request validation failed: $error',
      );
    }

    final normalized = request.requestedFilePaths
        .map((path) => path.trim().replaceAll(r'\', '/'))
        .toList(growable: false);

    for (final path in normalized) {
      final allowed =
          allowedRootFiles.contains(path) ||
          allowedSourcePrefixes.any(path.startsWith);

      if (!allowed) {
        return AgentWebsitePolicyDecision.deny(
          'Website path is outside Phase 34 controlled source scope: $path',
        );
      }

      if (_isGeneratedOrDependencyPath(path)) {
        return AgentWebsitePolicyDecision.deny(
          'Generated/dependency paths cannot be edited by Website Agent: $path',
        );
      }
    }

    return AgentWebsitePolicyDecision.allow(normalized);
  }

  bool _isGeneratedOrDependencyPath(String path) {
    final lower = path.toLowerCase();

    return lower.startsWith('node_modules/') ||
        lower.startsWith('.next/') ||
        lower.startsWith('.git/') ||
        lower.startsWith('dist/') ||
        lower.startsWith('build/');
  }
}

class AgentWebsitePolicyDecision {
  final bool allowed;
  final String reason;
  final List<String> normalizedApprovedPaths;

  const AgentWebsitePolicyDecision._({
    required this.allowed,
    required this.reason,
    required this.normalizedApprovedPaths,
  });

  factory AgentWebsitePolicyDecision.allow(List<String> paths) {
    return AgentWebsitePolicyDecision._(
      allowed: true,
      reason:
          'Website proposal is inside controlled source scope. '
          'Permission/Runtime/Approval checks are still required.',
      normalizedApprovedPaths: List<String>.unmodifiable(paths),
    );
  }

  factory AgentWebsitePolicyDecision.deny(String reason) {
    return AgentWebsitePolicyDecision._(
      allowed: false,
      reason: reason,
      normalizedApprovedPaths: const <String>[],
    );
  }
}

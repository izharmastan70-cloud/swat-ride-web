import 'agent_website_preview.dart';

class AgentWebsiteDeploymentTarget {
  AgentWebsiteDeploymentTarget._();

  static const String preview = 'PREVIEW';
  static const String production = 'PRODUCTION';

  static const Set<String> values = <String>{preview, production};
}

class AgentWebsiteDeploymentDecision {
  AgentWebsiteDeploymentDecision._();

  static const String pendingOwnerReview = 'PENDING_OWNER_REVIEW';

  static const String approved = 'APPROVED';

  static const String rejected = 'REJECTED';

  static const String kept = 'KEPT';

  static const String rollbackRequested = 'ROLLBACK_REQUESTED';

  static const String rolledBack = 'ROLLED_BACK';

  static const Set<String> values = <String>{
    pendingOwnerReview,
    approved,
    rejected,
    kept,
    rollbackRequested,
    rolledBack,
  };
}

/// Controlled deployment plan only.
///
/// This model contains NO Vercel token, GitHub token,
/// domain credential, DNS credential, shell command,
/// process runner, or deployment implementation.
class AgentWebsiteDeploymentPlan {
  final String deploymentId;
  final String changeId;
  final String approvalId;

  final String target;
  final String decision;

  final AgentWebsitePreview preview;

  /// Exact approved source scope copied from the preview.
  final List<String> approvedFilePaths;

  /// Production is never allowed without a separate
  /// explicit production approval.
  final bool productionApprovalConsumed;

  /// Owner KEEP is separate from deployment success.
  final bool ownerKeepConfirmed;

  final DateTime createdAt;

  const AgentWebsiteDeploymentPlan({
    required this.deploymentId,
    required this.changeId,
    required this.approvalId,
    required this.target,
    required this.decision,
    required this.preview,
    required this.approvedFilePaths,
    required this.productionApprovalConsumed,
    required this.ownerKeepConfirmed,
    required this.createdAt,
  });

  bool get canDeployToPreview =>
      target == AgentWebsiteDeploymentTarget.preview &&
      decision == AgentWebsiteDeploymentDecision.approved &&
      preview.isReviewReady;

  bool get canDeployToProduction =>
      target == AgentWebsiteDeploymentTarget.production &&
      decision == AgentWebsiteDeploymentDecision.approved &&
      productionApprovalConsumed &&
      preview.isReviewReady;

  void validate() {
    preview.validate();

    if (deploymentId.trim().isEmpty ||
        changeId.trim().isEmpty ||
        approvalId.trim().isEmpty) {
      throw const AgentWebsiteDeploymentValidationException(
        'Deployment identity fields cannot be empty.',
      );
    }

    if (!AgentWebsiteDeploymentTarget.values.contains(target)) {
      throw AgentWebsiteDeploymentValidationException(
        'Invalid website deployment target: $target',
      );
    }

    if (!AgentWebsiteDeploymentDecision.values.contains(decision)) {
      throw AgentWebsiteDeploymentValidationException(
        'Invalid website deployment decision: $decision',
      );
    }

    if (changeId != preview.changeId || approvalId != preview.approvalId) {
      throw const AgentWebsiteDeploymentValidationException(
        'Deployment identity does not match preview approval identity.',
      );
    }

    if (!_sameExactScope(approvedFilePaths, preview.approvedFilePaths)) {
      throw const AgentWebsiteDeploymentValidationException(
        'Deployment file scope must exactly match preview-approved scope.',
      );
    }

    if (target == AgentWebsiteDeploymentTarget.production &&
        !productionApprovalConsumed) {
      throw const AgentWebsiteDeploymentValidationException(
        'Production deployment requires a separately consumed owner approval.',
      );
    }

    if (ownerKeepConfirmed && decision != AgentWebsiteDeploymentDecision.kept) {
      throw const AgentWebsiteDeploymentValidationException(
        'ownerKeepConfirmed requires KEPT deployment decision.',
      );
    }
  }

  static bool _sameExactScope(List<String> a, List<String> b) {
    final first = a
        .map((item) => item.trim().replaceAll(r'\', '/'))
        .toList(growable: false);

    final second = b
        .map((item) => item.trim().replaceAll(r'\', '/'))
        .toList(growable: false);

    if (first.length != second.length) {
      return false;
    }

    final firstSet = first.toSet();
    final secondSet = second.toSet();

    return firstSet.length == first.length &&
        secondSet.length == second.length &&
        firstSet.containsAll(secondSet) &&
        secondSet.containsAll(firstSet);
  }
}

class AgentWebsiteDeploymentValidationException implements Exception {
  final String message;

  const AgentWebsiteDeploymentValidationException(this.message);

  @override
  String toString() => 'AgentWebsiteDeploymentValidationException: $message';
}

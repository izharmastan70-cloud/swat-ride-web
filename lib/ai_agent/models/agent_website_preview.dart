class AgentWebsitePreview {
  final String changeId;
  final String approvalId;

  /// Preview only.
  ///
  /// This URL is never interpreted as production authorization.
  final Uri previewUri;

  /// Exact website-relative files included in this preview.
  final List<String> approvedFilePaths;

  final bool buildPassed;
  final bool lintPassed;

  /// Future test runner may populate this separately.
  /// Missing tests must not be silently reported as passing.
  final bool testsAvailable;
  final bool testsPassed;

  final DateTime createdAt;

  const AgentWebsitePreview({
    required this.changeId,
    required this.approvalId,
    required this.previewUri,
    required this.approvedFilePaths,
    required this.buildPassed,
    required this.lintPassed,
    required this.testsAvailable,
    required this.testsPassed,
    required this.createdAt,
  });

  bool get isReviewReady {
    if (!buildPassed || !lintPassed) {
      return false;
    }

    if (testsAvailable && !testsPassed) {
      return false;
    }

    return true;
  }

  void validate() {
    if (changeId.trim().isEmpty || approvalId.trim().isEmpty) {
      throw const AgentWebsitePreviewValidationException(
        'Preview changeId and approvalId are required.',
      );
    }

    if (!previewUri.hasScheme || !previewUri.hasAuthority) {
      throw const AgentWebsitePreviewValidationException(
        'Preview URL must be an absolute URL.',
      );
    }

    if (previewUri.scheme != 'https' && previewUri.scheme != 'http') {
      throw const AgentWebsitePreviewValidationException(
        'Preview URL must use HTTP or HTTPS.',
      );
    }

    if (approvedFilePaths.isEmpty) {
      throw const AgentWebsitePreviewValidationException(
        'Preview must preserve exact approved file scope.',
      );
    }

    final normalized = approvedFilePaths
        .map((path) => path.trim().replaceAll(r'\', '/'))
        .toList(growable: false);

    if (normalized.any((path) => path.isEmpty)) {
      throw const AgentWebsitePreviewValidationException(
        'Approved preview file path cannot be empty.',
      );
    }

    if (normalized.toSet().length != normalized.length) {
      throw const AgentWebsitePreviewValidationException(
        'Duplicate approved preview file paths are not allowed.',
      );
    }

    if (testsAvailable && !testsPassed) {
      throw const AgentWebsitePreviewValidationException(
        'Preview cannot be review-ready when available tests failed.',
      );
    }
  }
}

class AgentWebsitePreviewValidationException implements Exception {
  final String message;

  const AgentWebsitePreviewValidationException(this.message);

  @override
  String toString() => 'AgentWebsitePreviewValidationException: $message';
}

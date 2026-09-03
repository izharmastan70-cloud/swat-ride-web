class AgentWebsiteChangeRequest {
  final String changeId;
  final String requestedBy;
  final String summary;

  /// Website-relative paths only.
  ///
  /// Example:
  /// src/app/hotels/page.tsx
  ///
  /// Absolute paths, ../ traversal, .env files, credentials,
  /// DNS/domain configuration, and deployment-secret files are forbidden.
  final List<String> requestedFilePaths;

  /// Human-readable reason for each requested website change.
  final String reason;

  /// Website changes are proposals first.
  /// This flag NEVER means production deployment is authorized.
  final bool productionDeploymentRequested;

  final DateTime createdAt;

  const AgentWebsiteChangeRequest({
    required this.changeId,
    required this.requestedBy,
    required this.summary,
    required this.requestedFilePaths,
    required this.reason,
    required this.productionDeploymentRequested,
    required this.createdAt,
  });

  void validate() {
    if (changeId.trim().isEmpty ||
        requestedBy.trim().isEmpty ||
        summary.trim().isEmpty ||
        reason.trim().isEmpty) {
      throw const AgentWebsiteChangeValidationException(
        'Website change identity, requester, summary and reason are required.',
      );
    }

    if (requestedFilePaths.isEmpty) {
      throw const AgentWebsiteChangeValidationException(
        'At least one website file must be explicitly requested.',
      );
    }

    final normalized = <String>{};

    for (final rawPath in requestedFilePaths) {
      final path = rawPath.trim().replaceAll(r'\', '/');

      if (path.isEmpty) {
        throw const AgentWebsiteChangeValidationException(
          'Website file path cannot be empty.',
        );
      }

      if (_looksAbsolute(path)) {
        throw AgentWebsiteChangeValidationException(
          'Absolute website path is forbidden: $rawPath',
        );
      }

      if (path == '..' || path.startsWith('../') || path.contains('/../')) {
        throw AgentWebsiteChangeValidationException(
          'Parent-directory traversal is forbidden: $rawPath',
        );
      }

      if (_isSensitiveOrInfrastructurePath(path)) {
        throw AgentWebsiteChangeValidationException(
          'Sensitive/domain/DNS/deployment credential path is forbidden: '
          '$rawPath',
        );
      }

      normalized.add(path);
    }

    if (normalized.length != requestedFilePaths.length) {
      throw const AgentWebsiteChangeValidationException(
        'Duplicate website file paths are not allowed.',
      );
    }
  }

  static bool _looksAbsolute(String path) {
    if (path.startsWith('/')) return true;

    final drivePath = RegExp(r'^[A-Za-z]:/');

    return drivePath.hasMatch(path);
  }

  static bool _isSensitiveOrInfrastructurePath(String path) {
    final lower = path.toLowerCase();

    final segments = lower.split('/');

    for (final segment in segments) {
      if (segment == '.env' ||
          segment.startsWith('.env.') ||
          segment.contains('secret') ||
          segment.contains('credential') ||
          segment.contains('apikey') ||
          segment.contains('api_key') ||
          segment.contains('token')) {
        return true;
      }
    }

    // Website Agent must not directly control these areas.
    if (lower == 'vercel.json' ||
        lower.startsWith('.vercel/') ||
        lower == '.vercel' ||
        lower.contains('dns') ||
        lower.contains('domain')) {
      return true;
    }

    return false;
  }
}

class AgentWebsiteChangeValidationException implements Exception {
  final String message;

  const AgentWebsiteChangeValidationException(this.message);

  @override
  String toString() => 'AgentWebsiteChangeValidationException: $message';
}

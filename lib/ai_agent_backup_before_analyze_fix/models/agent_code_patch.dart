// =========================================================
// AI AGENT — CODE PATCH
// =========================================================
//
// A proposed replacement for one approved file.
// Phase 16 does not apply it to the real SWAT RIDE project yet.

class AgentCodePatch {
  final String filePath;
  final String originalHash;
  final String proposedContent;
  final String reason;

  const AgentCodePatch({
    required this.filePath,
    required this.originalHash,
    required this.proposedContent,
    required this.reason,
  });

  void validate() {
    if (filePath.trim().isEmpty) {
      throw const AgentCodePatchException(
        'filePath cannot be empty.',
      );
    }

    if (proposedContent.isEmpty) {
      throw const AgentCodePatchException(
        'proposedContent cannot be empty.',
      );
    }
  }
}

class AgentCodePatchException implements Exception {
  final String message;
  const AgentCodePatchException(this.message);

  @override
  String toString() => 'AgentCodePatchException: $message';
}

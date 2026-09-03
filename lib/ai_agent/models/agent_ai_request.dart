// =========================================================
// AI AGENT — AI REQUEST
// =========================================================
//
// Provider-neutral request.
// Phase 9 carries only non-secret text/context.
// Privacy Router is added later and will harden classification/redaction.

class AgentAiRequest {
  final String requestId;
  final String roleId;
  final String purpose;
  final String prompt;
  final Map<String, dynamic> context;
  final DateTime createdAt;

  const AgentAiRequest({
    required this.requestId,
    required this.roleId,
    required this.purpose,
    required this.prompt,
    required this.context,
    required this.createdAt,
  });

  void validate() {
    if (requestId.trim().isEmpty ||
        roleId.trim().isEmpty ||
        purpose.trim().isEmpty ||
        prompt.trim().isEmpty) {
      throw const AgentAiRequestValidationException(
        'AI request identity/prompt fields cannot be empty.',
      );
    }
  }
}

class AgentAiRequestValidationException implements Exception {
  final String message;
  const AgentAiRequestValidationException(this.message);

  @override
  String toString() => 'AgentAiRequestValidationException: $message';
}

// =========================================================
// AI AGENT — SUPPORT REQUEST
// =========================================================
//
// Provider-neutral, module-neutral support input.
// No secret/payment credential fields exist here.

class AgentSupportRequest {
  final String requestId;
  final String userMessage;
  final String module;
  final String referenceId;
  final String userIdAlias;
  final Map<String, dynamic> context;
  final DateTime createdAt;

  const AgentSupportRequest({
    required this.requestId,
    required this.userMessage,
    required this.module,
    required this.referenceId,
    required this.userIdAlias,
    required this.context,
    required this.createdAt,
  });

  void validate() {
    if (requestId.trim().isEmpty || userMessage.trim().isEmpty) {
      throw const AgentSupportRequestException(
        'Support request ID/message cannot be empty.',
      );
    }
  }
}

class AgentSupportRequestException implements Exception {
  final String message;
  const AgentSupportRequestException(this.message);

  @override
  String toString() => 'AgentSupportRequestException: $message';
}

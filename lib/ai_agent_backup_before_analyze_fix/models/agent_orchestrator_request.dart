// =========================================================
// AI AGENT — ORCHESTRATOR REQUEST
// =========================================================
//
// This is the narrow message passed to an orchestrator.
// It contains no backend handle, Firebase instance, payment object,
// file-system handle, or arbitrary tool executor.

class AgentOrchestratorRequest {
  final String requestId;
  final String roleId;
  final String purpose;
  final String prompt;
  final Map<String, dynamic> sanitizedContext;
  final List<String> allowedReadOnlyToolIds;
  final DateTime createdAt;

  const AgentOrchestratorRequest({
    required this.requestId,
    required this.roleId,
    required this.purpose,
    required this.prompt,
    required this.sanitizedContext,
    required this.allowedReadOnlyToolIds,
    required this.createdAt,
  });

  void validate() {
    if (requestId.trim().isEmpty ||
        roleId.trim().isEmpty ||
        purpose.trim().isEmpty ||
        prompt.trim().isEmpty) {
      throw const AgentOrchestratorRequestException(
        'Orchestrator request fields cannot be empty.',
      );
    }

    for (final String toolId in allowedReadOnlyToolIds) {
      if (!toolId.startsWith('tool.')) {
        throw const AgentOrchestratorRequestException(
          'Invalid controlled tool ID.',
        );
      }
    }
  }
}

class AgentOrchestratorRequestException implements Exception {
  final String message;

  const AgentOrchestratorRequestException(this.message);

  @override
  String toString() => 'AgentOrchestratorRequestException: $message';
}

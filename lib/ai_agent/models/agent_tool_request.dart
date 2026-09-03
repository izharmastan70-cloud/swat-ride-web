// =========================================================
// AI AGENT — CONTROLLED TOOL REQUEST
// =========================================================
//
// actionScope is the exact approved/requested scope.
// A future connector must never silently widen this scope.

class AgentToolRequest {
  final String requestId;
  final String roleId;
  final String actionId;
  final String toolId;
  final String requestedBy;
  final Map<String, dynamic> actionScope;
  final String? approvalId;
  final DateTime createdAt;

  const AgentToolRequest({
    required this.requestId,
    required this.roleId,
    required this.actionId,
    required this.toolId,
    required this.requestedBy,
    required this.actionScope,
    required this.createdAt,
    this.approvalId,
  });

  void validate() {
    if (requestId.trim().isEmpty ||
        roleId.trim().isEmpty ||
        actionId.trim().isEmpty ||
        toolId.trim().isEmpty ||
        requestedBy.trim().isEmpty) {
      throw const AgentToolRequestValidationException(
        'Tool request identity fields cannot be empty.',
      );
    }
  }
}

class AgentToolRequestValidationException implements Exception {
  final String message;
  const AgentToolRequestValidationException(this.message);

  @override
  String toString() => 'AgentToolRequestValidationException: $message';
}

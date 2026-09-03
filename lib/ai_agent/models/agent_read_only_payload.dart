// =========================================================
// AI AGENT — READ-ONLY PAYLOAD
// =========================================================
//
// Safe structured result returned by Phase 7 read-only connectors.
// No write instructions, secrets, credentials, or executable callbacks.

class AgentReadOnlyPayload {
  final String actionId;
  final String module;
  final Map<String, dynamic> data;
  final DateTime generatedAt;

  const AgentReadOnlyPayload({
    required this.actionId,
    required this.module,
    required this.data,
    required this.generatedAt,
  });
}

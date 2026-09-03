// =========================================================
// AI AGENT — ORCHESTRATOR RESPONSE
// =========================================================

class AgentOrchestratorResponse {
  final String requestId;
  final String status;
  final String text;
  final List<String> requestedToolIds;
  final String message;

  const AgentOrchestratorResponse({
    required this.requestId,
    required this.status,
    required this.text,
    required this.requestedToolIds,
    required this.message,
  });

  bool get isSuccess => status == 'SUCCESS';
}

// =========================================================
// AI AGENT — AI RESPONSE
// =========================================================

class AgentAiResponse {
  final String requestId;
  final String providerId;
  final String providerType;
  final String status;
  final String text;
  final String message;
  final Map<String, dynamic> metadata;

  const AgentAiResponse({
    required this.requestId,
    required this.providerId,
    required this.providerType,
    required this.status,
    required this.text,
    required this.message,
    this.metadata = const <String, dynamic>{},
  });

  bool get isSuccess => status == 'SUCCESS';
}

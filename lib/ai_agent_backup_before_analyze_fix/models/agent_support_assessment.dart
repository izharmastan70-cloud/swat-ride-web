// =========================================================
// AI AGENT — SUPPORT ASSESSMENT
// =========================================================

class AgentSupportAssessment {
  final String intent;
  final String priority;
  final String escalation;
  final bool safeForAutomaticReply;
  final bool requiresBusinessData;
  final String reason;

  const AgentSupportAssessment({
    required this.intent,
    required this.priority,
    required this.escalation,
    required this.safeForAutomaticReply,
    required this.requiresBusinessData,
    required this.reason,
  });
}

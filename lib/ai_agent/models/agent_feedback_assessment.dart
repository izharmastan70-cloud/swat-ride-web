// =========================================================
// AI AGENT — FEEDBACK ASSESSMENT
// =========================================================

class AgentFeedbackAssessment {
  final String sentiment;
  final String escalation;
  final bool suspectedSpam;
  final bool canDraftReply;
  final bool canAutoReplyLater;
  final String summary;
  final String reason;

  const AgentFeedbackAssessment({
    required this.sentiment,
    required this.escalation,
    required this.suspectedSpam,
    required this.canDraftReply,
    required this.canAutoReplyLater,
    required this.summary,
    required this.reason,
  });
}

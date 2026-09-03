// =========================================================
// AI AGENT — FEEDBACK DRAFT
// =========================================================
//
// Phase 12 drafts only.
// No review/feedback reply is sent automatically.

class AgentFeedbackDraft {
  final String feedbackId;
  final String replyText;
  final String sentiment;
  final String escalation;
  final bool suspectedSpam;
  final bool canAutoReplyLater;
  final String note;

  const AgentFeedbackDraft({
    required this.feedbackId,
    required this.replyText,
    required this.sentiment,
    required this.escalation,
    required this.suspectedSpam,
    required this.canAutoReplyLater,
    required this.note,
  });
}

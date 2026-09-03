// =========================================================
// AI AGENT — SUPPORT DRAFT
// =========================================================
//
// Phase 11 only drafts responses.
// It never sends a customer-facing reply itself.

class AgentSupportDraft {
  final String requestId;
  final String status;
  final String replyText;
  final String intent;
  final String priority;
  final String escalation;
  final bool canAutoSendLater;
  final String note;

  const AgentSupportDraft({
    required this.requestId,
    required this.status,
    required this.replyText,
    required this.intent,
    required this.priority,
    required this.escalation,
    required this.canAutoSendLater,
    required this.note,
  });
}

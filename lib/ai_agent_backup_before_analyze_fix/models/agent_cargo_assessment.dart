// =========================================================
// AI AGENT — CARGO ASSESSMENT
// =========================================================

class AgentCargoAssessment {
  final String intent;
  final String risk;
  final bool canAnswerReadOnly;
  final bool requiresHumanReview;
  final bool requiresApprovalForAction;
  final String reason;

  const AgentCargoAssessment({
    required this.intent,
    required this.risk,
    required this.canAnswerReadOnly,
    required this.requiresHumanReview,
    required this.requiresApprovalForAction,
    required this.reason,
  });
}

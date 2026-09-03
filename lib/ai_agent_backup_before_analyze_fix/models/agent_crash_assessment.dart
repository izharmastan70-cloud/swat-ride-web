// =========================================================
// AI AGENT — CRASH ASSESSMENT
// =========================================================

class AgentCrashAssessment {
  final String severity;
  final String category;
  final bool likelyCodeIssue;
  final bool shouldHandoffToCodeAgent;
  final bool shouldNotifyOwner;
  final String summary;
  final String reason;

  const AgentCrashAssessment({
    required this.severity,
    required this.category,
    required this.likelyCodeIssue,
    required this.shouldHandoffToCodeAgent,
    required this.shouldNotifyOwner,
    required this.summary,
    required this.reason,
  });
}

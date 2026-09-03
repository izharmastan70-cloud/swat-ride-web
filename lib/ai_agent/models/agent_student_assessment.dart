// =========================================================
// AI AGENT — STUDENT RIDE ASSESSMENT
// =========================================================

class AgentStudentAssessment {
  final String intent;
  final String risk;
  final bool requiresHuman;
  final bool requiresSafetyEscalation;
  final bool requiresApprovalForWrite;
  final String reason;

  const AgentStudentAssessment({
    required this.intent,
    required this.risk,
    required this.requiresHuman,
    required this.requiresSafetyEscalation,
    required this.requiresApprovalForWrite,
    required this.reason,
  });
}

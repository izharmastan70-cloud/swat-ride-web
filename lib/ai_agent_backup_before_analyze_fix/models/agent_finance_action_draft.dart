// =========================================================
// AI AGENT — FINANCE ACTION DRAFT
// =========================================================
//
// Phase 18 prepares money actions only.
// No refund/withdrawal/settlement is executed.

class AgentFinanceActionDraft {
  final String draftId;
  final String actionId;
  final String module;
  final String referenceId;
  final int amountRs;
  final String reason;
  final bool requiresApproval;
  final DateTime createdAt;

  const AgentFinanceActionDraft({
    required this.draftId,
    required this.actionId,
    required this.module,
    required this.referenceId,
    required this.amountRs,
    required this.reason,
    required this.requiresApproval,
    required this.createdAt,
  });
}

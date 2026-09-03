// =========================================================
// AI AGENT — FINANCE SUMMARY
// =========================================================

class AgentFinanceSummary {
  final int grossRs;
  final int commissionRs;
  final int netRs;
  final int pendingRs;
  final int preparedSettlements;
  final int refundsPrepared;
  final int withdrawalsPrepared;
  final bool businessConnectorsAttached;
  final DateTime generatedAt;

  const AgentFinanceSummary({
    required this.grossRs,
    required this.commissionRs,
    required this.netRs,
    required this.pendingRs,
    required this.preparedSettlements,
    required this.refundsPrepared,
    required this.withdrawalsPrepared,
    required this.businessConnectorsAttached,
    required this.generatedAt,
  });
}

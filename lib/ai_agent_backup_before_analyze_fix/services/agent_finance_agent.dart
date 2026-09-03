import '../models/agent_finance_action_draft.dart';
import '../models/agent_finance_summary.dart';
import 'agent_finance_action_planner.dart';
import 'agent_finance_monitor_service.dart';

// =========================================================
// AI AGENT — FINANCE AGENT
// =========================================================
//
// Phase 18 = READ-ONLY MONITORING + ACTION DRAFTS.
//
// It never moves money, refunds, approves withdrawals or settles balances.

class AgentFinanceAgent {
  final AgentFinanceMonitorService monitorService;
  final AgentFinanceActionPlanner planner;

  AgentFinanceAgent({
    AgentFinanceMonitorService? monitorService,
    AgentFinanceActionPlanner? planner,
  })  : monitorService =
            monitorService ?? AgentFinanceMonitorService(),
        planner = planner ?? const AgentFinanceActionPlanner();

  Future<AgentFinanceSummary> summary() {
    return monitorService.buildSummary();
  }

  AgentFinanceActionDraft draftRefund({
    required String module,
    required String referenceId,
    required int amountRs,
    required String reason,
  }) {
    return planner.prepareRefund(
      module: module,
      referenceId: referenceId,
      amountRs: amountRs,
      reason: reason,
    );
  }

  AgentFinanceActionDraft draftSettlement({
    required String module,
    required String referenceId,
    required int amountRs,
    required String reason,
  }) {
    return planner.prepareSettlement(
      module: module,
      referenceId: referenceId,
      amountRs: amountRs,
      reason: reason,
    );
  }

  AgentFinanceActionDraft draftWithdrawalApproval({
    required String referenceId,
    required int amountRs,
    required String reason,
  }) {
    return planner.prepareWithdrawalApproval(
      referenceId: referenceId,
      amountRs: amountRs,
      reason: reason,
    );
  }
}

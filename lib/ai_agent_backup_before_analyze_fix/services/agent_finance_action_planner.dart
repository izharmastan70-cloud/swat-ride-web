import '../constants/agent_action_ids.dart';
import '../models/agent_finance_action_draft.dart';

// =========================================================
// AI AGENT — FINANCE ACTION PLANNER
// =========================================================
//
// Drafts money actions only.
// Every real money action remains approval-gated and unconnected.

class AgentFinanceActionPlanner {
  const AgentFinanceActionPlanner();

  AgentFinanceActionDraft prepareSettlement({
    required String module,
    required String referenceId,
    required int amountRs,
    required String reason,
  }) {
    return _draft(
      actionId: AgentActionId.prepareSettlement,
      module: module,
      referenceId: referenceId,
      amountRs: amountRs,
      reason: reason,
      requiresApproval: true,
    );
  }

  AgentFinanceActionDraft prepareRefund({
    required String module,
    required String referenceId,
    required int amountRs,
    required String reason,
  }) {
    return _draft(
      actionId: AgentActionId.executeRefund,
      module: module,
      referenceId: referenceId,
      amountRs: amountRs,
      reason: reason,
      requiresApproval: true,
    );
  }

  AgentFinanceActionDraft prepareWithdrawalApproval({
    required String referenceId,
    required int amountRs,
    required String reason,
  }) {
    return _draft(
      actionId: AgentActionId.approveWithdrawal,
      module: 'finance',
      referenceId: referenceId,
      amountRs: amountRs,
      reason: reason,
      requiresApproval: true,
    );
  }

  AgentFinanceActionDraft _draft({
    required String actionId,
    required String module,
    required String referenceId,
    required int amountRs,
    required String reason,
    required bool requiresApproval,
  }) {
    if (amountRs <= 0) {
      throw ArgumentError.value(
        amountRs,
        'amountRs',
        'Finance action amount must be positive.',
      );
    }

    return AgentFinanceActionDraft(
      draftId: 'finance_${DateTime.now().microsecondsSinceEpoch}',
      actionId: actionId,
      module: module,
      referenceId: referenceId,
      amountRs: amountRs,
      reason: reason.trim(),
      requiresApproval: requiresApproval,
      createdAt: DateTime.now(),
    );
  }
}

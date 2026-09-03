import '../models/agent_monetization_assessment.dart';

class AgentMonetizationPolicy {
  const AgentMonetizationPolicy();

  static const Set<String> directFinancialWriteActions = <String>{
    AgentMonetizationAction.changeCommission,
    AgentMonetizationAction.changePricing,
    AgentMonetizationAction.changeDiscount,
    AgentMonetizationAction.changeReward,
    AgentMonetizationAction.walletCredit,
    AgentMonetizationAction.walletDebit,
    AgentMonetizationAction.payout,
    AgentMonetizationAction.withdrawal,
    AgentMonetizationAction.settlement,
    AgentMonetizationAction.refund,
  };

  bool isDirectFinancialWrite(String action) {
    return directFinancialWriteActions.contains(action);
  }

  bool canExecuteWithoutApproval(String action) {
    switch (action) {
      case AgentMonetizationAction.observe:
      case AgentMonetizationAction.recommend:
        return true;

      case AgentMonetizationAction.proposeChange:
      case AgentMonetizationAction.changeCommission:
      case AgentMonetizationAction.changePricing:
      case AgentMonetizationAction.changeDiscount:
      case AgentMonetizationAction.changeReward:
      case AgentMonetizationAction.walletCredit:
      case AgentMonetizationAction.walletDebit:
      case AgentMonetizationAction.payout:
      case AgentMonetizationAction.withdrawal:
      case AgentMonetizationAction.settlement:
      case AgentMonetizationAction.refund:
        return false;

      default:
        return false;
    }
  }

  bool requiresSuperAdminReview(String action) {
    switch (action) {
      case AgentMonetizationAction.changeCommission:
      case AgentMonetizationAction.changePricing:
      case AgentMonetizationAction.walletCredit:
      case AgentMonetizationAction.walletDebit:
      case AgentMonetizationAction.payout:
      case AgentMonetizationAction.withdrawal:
      case AgentMonetizationAction.settlement:
      case AgentMonetizationAction.refund:
        return true;

      default:
        return false;
    }
  }

  AgentMonetizationAssessment buildAssessment({
    required String module,
    required String subject,
    required String summary,
    required String recommendation,
    required String action,
    double? currentValue,
    double? proposedValue,
  }) {
    final bool financialWrite = isDirectFinancialWrite(action);

    final bool superAdminReview = requiresSuperAdminReview(action);

    final bool adminReview = !canExecuteWithoutApproval(action);

    final String riskLevel;

    if (superAdminReview) {
      riskLevel = AgentMonetizationRisk.high;
    } else if (adminReview) {
      riskLevel = AgentMonetizationRisk.medium;
    } else {
      riskLevel = AgentMonetizationRisk.low;
    }

    final assessment = AgentMonetizationAssessment(
      module: module,
      subject: subject,
      summary: summary,
      recommendation: recommendation,
      riskLevel: riskLevel,
      currentValue: currentValue,
      proposedValue: proposedValue,
      requiresAdminReview: adminReview,
      requiresSuperAdminReview: superAdminReview,
      financialWriteRequested: financialWrite,
      createdAt: DateTime.now(),
    );

    assessment.validate();

    return assessment;
  }
}

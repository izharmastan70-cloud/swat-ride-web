class AgentContentPaidAiBudget {
  const AgentContentPaidAiBudget({
    required this.paidAiEnabled,
    required this.askBeforePaid,
    required this.ownerApprovedThisTask,
    required this.perTaskLimitRs,
    required this.dailyLimitRs,
    required this.monthlyLimitRs,
    required this.spentTodayRs,
    required this.spentThisMonthRs,
    required this.estimatedTaskCostRs,
  });

  final bool paidAiEnabled;
  final bool askBeforePaid;
  final bool ownerApprovedThisTask;
  final double perTaskLimitRs;
  final double dailyLimitRs;
  final double monthlyLimitRs;
  final double spentTodayRs;
  final double spentThisMonthRs;
  final double estimatedTaskCostRs;

  bool get costLoggingRequired => true;
  bool get budgetExhaustionStopsSystem => false;
  bool get budgetExhaustionStopsPaidOnly => true;
  bool get ownerCanChangeLimits => true;
  bool get providerCanChangeLimits => false;
  bool get agentCanChangeLimits => false;
  bool get paidCanBypassApproval => false;

  bool get valid {
    final List<double> values = <double>[
      perTaskLimitRs,
      dailyLimitRs,
      monthlyLimitRs,
      spentTodayRs,
      spentThisMonthRs,
      estimatedTaskCostRs,
    ];

    return values.every((double value) => value.isFinite && value >= 0);
  }

  bool get withinPerTaskLimit => estimatedTaskCostRs <= perTaskLimitRs;

  bool get withinDailyLimit =>
      spentTodayRs + estimatedTaskCostRs <= dailyLimitRs;

  bool get withinMonthlyLimit =>
      spentThisMonthRs + estimatedTaskCostRs <= monthlyLimitRs;

  bool get budgetAllowsPaid =>
      valid && withinPerTaskLimit && withinDailyLimit && withinMonthlyLimit;

  bool get approvalAllowsPaid => !askBeforePaid || ownerApprovedThisTask;
}

class AdminIntelligenceReasoningProviderClass {
  const AdminIntelligenceReasoningProviderClass._();

  static const String none = 'none';
  static const String freeOnline = 'free_online';
  static const String localAi = 'local_ai';
  static const String paidAi = 'paid_ai';
  static const String askPaidApproval = 'ask_paid_approval';
  static const String safeFallback = 'safe_fallback';
}

class AdminIntelligenceReasoningOutcome {
  const AdminIntelligenceReasoningOutcome._();

  static const String notAttempted = 'not_attempted';
  static const String completed = 'completed';
  static const String unavailable = 'unavailable';
  static const String failed = 'failed';
  static const String insufficient = 'insufficient';

  static const Set<String> values = <String>{
    notAttempted,
    completed,
    unavailable,
    failed,
    insufficient,
  };
}

class AdminIntelligencePaidBudget {
  const AdminIntelligencePaidBudget({
    required this.perTaskLimitRs,
    required this.dailyLimitRs,
    required this.monthlyLimitRs,
    required this.spentTodayRs,
    required this.spentThisMonthRs,
    required this.estimatedTaskCostRs,
  });

  final double perTaskLimitRs;
  final double dailyLimitRs;
  final double monthlyLimitRs;
  final double spentTodayRs;
  final double spentThisMonthRs;
  final double estimatedTaskCostRs;

  bool get hasKnownPositiveEstimate => estimatedTaskCostRs > 0;

  bool get withinPerTaskLimit =>
      perTaskLimitRs > 0 && estimatedTaskCostRs <= perTaskLimitRs;

  bool get withinDailyLimit =>
      dailyLimitRs > 0 && spentTodayRs + estimatedTaskCostRs <= dailyLimitRs;

  bool get withinMonthlyLimit =>
      monthlyLimitRs > 0 &&
      spentThisMonthRs + estimatedTaskCostRs <= monthlyLimitRs;

  bool get canSpendPaid {
    return hasKnownPositiveEstimate &&
        withinPerTaskLimit &&
        withinDailyLimit &&
        withinMonthlyLimit;
  }
}

class AdminIntelligenceReasoningState {
  const AdminIntelligenceReasoningState({
    this.deterministicReasoningComplete = false,
    this.freeOutcome = AdminIntelligenceReasoningOutcome.notAttempted,
    this.localOutcome = AdminIntelligenceReasoningOutcome.notAttempted,
    this.paidOutcome = AdminIntelligenceReasoningOutcome.notAttempted,
  });

  final bool deterministicReasoningComplete;
  final String freeOutcome;
  final String localOutcome;
  final String paidOutcome;
}

class AdminIntelligenceReasoningDecision {
  const AdminIntelligenceReasoningDecision({
    required this.providerClass,
    required this.reason,
    required this.requiresOwnerApproval,
    required this.paidCostAllowed,
    required this.systemMayContinue,
  });

  final String providerClass;
  final String reason;

  /// True only when Ask Before Paid is active and approval is still needed.
  final bool requiresOwnerApproval;

  /// This is a budget/policy gate, not permission to charge by itself.
  final bool paidCostAllowed;

  /// Budget/provider failure must not stop the Admin Intelligence system.
  final bool systemMayContinue;

  bool get shouldUsePaidAi =>
      providerClass == AdminIntelligenceReasoningProviderClass.paidAi;
}

class AdminIntelligenceReasoningPolicy {
  const AdminIntelligenceReasoningPolicy({
    this.freeOnlineEnabled = true,
    this.localAiEnabled = false,
    this.paidAiEnabled = false,
    this.askBeforePaid = true,
    this.paidApprovalGranted = false,
    this.minimizeContextAndTokens = true,
  });

  /// Free Online AI is first AI priority.
  final bool freeOnlineEnabled;

  /// Local AI is optional/future and must not be a core dependency.
  final bool localAiEnabled;

  /// Paid AI is the last escalation only.
  final bool paidAiEnabled;

  /// Owner-controlled guard.
  final bool askBeforePaid;

  /// Explicit approval state supplied by the existing approval architecture.
  final bool paidApprovalGranted;

  /// Keeps token/context usage minimal where possible.
  final bool minimizeContextAndTokens;

  AdminIntelligenceReasoningDecision decideNext({
    required AdminIntelligenceReasoningState state,
    required AdminIntelligencePaidBudget paidBudget,
  }) {
    _validateOutcome(state.freeOutcome, 'freeOutcome');
    _validateOutcome(state.localOutcome, 'localOutcome');
    _validateOutcome(state.paidOutcome, 'paidOutcome');

    if (state.deterministicReasoningComplete) {
      return const AdminIntelligenceReasoningDecision(
        providerClass: AdminIntelligenceReasoningProviderClass.none,
        reason: 'deterministic_reasoning_complete',
        requiresOwnerApproval: false,
        paidCostAllowed: false,
        systemMayContinue: true,
      );
    }

    if (state.freeOutcome == AdminIntelligenceReasoningOutcome.completed) {
      return const AdminIntelligenceReasoningDecision(
        providerClass: AdminIntelligenceReasoningProviderClass.none,
        reason: 'free_ai_completed',
        requiresOwnerApproval: false,
        paidCostAllowed: false,
        systemMayContinue: true,
      );
    }

    if (freeOnlineEnabled &&
        state.freeOutcome == AdminIntelligenceReasoningOutcome.notAttempted) {
      return const AdminIntelligenceReasoningDecision(
        providerClass: AdminIntelligenceReasoningProviderClass.freeOnline,
        reason: 'free_ai_first_priority',
        requiresOwnerApproval: false,
        paidCostAllowed: false,
        systemMayContinue: true,
      );
    }

    final freeExhausted = !freeOnlineEnabled || _isExhausted(state.freeOutcome);

    if (!freeExhausted) {
      return const AdminIntelligenceReasoningDecision(
        providerClass: AdminIntelligenceReasoningProviderClass.safeFallback,
        reason: 'free_ai_still_in_progress',
        requiresOwnerApproval: false,
        paidCostAllowed: false,
        systemMayContinue: true,
      );
    }

    if (state.localOutcome == AdminIntelligenceReasoningOutcome.completed) {
      return const AdminIntelligenceReasoningDecision(
        providerClass: AdminIntelligenceReasoningProviderClass.none,
        reason: 'local_ai_completed',
        requiresOwnerApproval: false,
        paidCostAllowed: false,
        systemMayContinue: true,
      );
    }

    if (localAiEnabled &&
        state.localOutcome == AdminIntelligenceReasoningOutcome.notAttempted) {
      return const AdminIntelligenceReasoningDecision(
        providerClass: AdminIntelligenceReasoningProviderClass.localAi,
        reason: 'local_ai_optional_second_priority',
        requiresOwnerApproval: false,
        paidCostAllowed: false,
        systemMayContinue: true,
      );
    }

    final localExhausted = !localAiEnabled || _isExhausted(state.localOutcome);

    if (!localExhausted) {
      return const AdminIntelligenceReasoningDecision(
        providerClass: AdminIntelligenceReasoningProviderClass.safeFallback,
        reason: 'local_ai_still_in_progress',
        requiresOwnerApproval: false,
        paidCostAllowed: false,
        systemMayContinue: true,
      );
    }

    if (state.paidOutcome == AdminIntelligenceReasoningOutcome.completed) {
      return const AdminIntelligenceReasoningDecision(
        providerClass: AdminIntelligenceReasoningProviderClass.none,
        reason: 'paid_ai_completed',
        requiresOwnerApproval: false,
        paidCostAllowed: false,
        systemMayContinue: true,
      );
    }

    if (!paidAiEnabled) {
      return const AdminIntelligenceReasoningDecision(
        providerClass: AdminIntelligenceReasoningProviderClass.safeFallback,
        reason: 'paid_ai_disabled_system_continues',
        requiresOwnerApproval: false,
        paidCostAllowed: false,
        systemMayContinue: true,
      );
    }

    if (!paidBudget.canSpendPaid) {
      return const AdminIntelligenceReasoningDecision(
        providerClass: AdminIntelligenceReasoningProviderClass.safeFallback,
        reason: 'paid_budget_blocked_system_continues',
        requiresOwnerApproval: false,
        paidCostAllowed: false,
        systemMayContinue: true,
      );
    }

    if (askBeforePaid && !paidApprovalGranted) {
      return const AdminIntelligenceReasoningDecision(
        providerClass: AdminIntelligenceReasoningProviderClass.askPaidApproval,
        reason: 'paid_ai_requires_owner_approval',
        requiresOwnerApproval: true,
        paidCostAllowed: true,
        systemMayContinue: true,
      );
    }

    if (state.paidOutcome == AdminIntelligenceReasoningOutcome.notAttempted) {
      return const AdminIntelligenceReasoningDecision(
        providerClass: AdminIntelligenceReasoningProviderClass.paidAi,
        reason: 'paid_ai_last_escalation',
        requiresOwnerApproval: false,
        paidCostAllowed: true,
        systemMayContinue: true,
      );
    }

    return const AdminIntelligenceReasoningDecision(
      providerClass: AdminIntelligenceReasoningProviderClass.safeFallback,
      reason: 'paid_ai_failed_system_continues',
      requiresOwnerApproval: false,
      paidCostAllowed: false,
      systemMayContinue: true,
    );
  }

  bool _isExhausted(String outcome) {
    return outcome == AdminIntelligenceReasoningOutcome.unavailable ||
        outcome == AdminIntelligenceReasoningOutcome.failed ||
        outcome == AdminIntelligenceReasoningOutcome.insufficient;
  }

  void _validateOutcome(String outcome, String field) {
    if (!AdminIntelligenceReasoningOutcome.values.contains(outcome)) {
      throw ArgumentError('Unsupported $field: $outcome');
    }
  }
}

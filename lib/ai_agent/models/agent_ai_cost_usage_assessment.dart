// =========================================================
// AI AGENT - AI COST & USAGE ASSESSMENT
// =========================================================
//
// Phase 30 Step 2.
//
// PURE MODEL ONLY.
//
// Tracks:
// - input/output/total tokens
// - estimated provider cost
// - expensive operation flag
// - cache opportunity
// - budget threshold state
//
// NO API CALLS.
// NO FIRESTORE WRITES.
// NO PROVIDER EXECUTION.
// NO PAYMENT/BILLING ACTION.
// NO SECRET STORAGE.

class AgentAiBudgetThresholdStatus {
  AgentAiBudgetThresholdStatus._();

  static const String normal = 'NORMAL';
  static const String warning = 'WARNING';
  static const String critical = 'CRITICAL';
  static const String exhausted = 'EXHAUSTED';

  static const Set<String> values = <String>{
    normal,
    warning,
    critical,
    exhausted,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentAiCacheOpportunity {
  AgentAiCacheOpportunity._();

  static const String none = 'NONE';
  static const String low = 'LOW';
  static const String medium = 'MEDIUM';
  static const String high = 'HIGH';

  static const Set<String> values = <String>{
    none,
    low,
    medium,
    high,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentAiCostUsageAssessment {
  final String taskId;
  final String providerId;
  final String operationName;

  final int inputTokens;
  final int outputTokens;
  final int totalTokens;

  final double estimatedCostRs;

  final bool expensiveOperation;

  final String cacheOpportunity;

  final int monthlyBudgetRs;
  final int monthlyUsedRs;
  final double budgetUsagePercent;
  final String budgetThresholdStatus;

  final String reason;

  const AgentAiCostUsageAssessment({
    required this.taskId,
    required this.providerId,
    required this.operationName,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.estimatedCostRs,
    required this.expensiveOperation,
    required this.cacheOpportunity,
    required this.monthlyBudgetRs,
    required this.monthlyUsedRs,
    required this.budgetUsagePercent,
    required this.budgetThresholdStatus,
    required this.reason,
  });

  bool get budgetWarning =>
      budgetThresholdStatus ==
          AgentAiBudgetThresholdStatus.warning ||
      budgetThresholdStatus ==
          AgentAiBudgetThresholdStatus.critical ||
      budgetThresholdStatus ==
          AgentAiBudgetThresholdStatus.exhausted;

  bool get budgetBlocked =>
      budgetThresholdStatus ==
      AgentAiBudgetThresholdStatus.exhausted;

  bool get cacheRecommended =>
      cacheOpportunity ==
          AgentAiCacheOpportunity.medium ||
      cacheOpportunity ==
          AgentAiCacheOpportunity.high;

  void validate() {
    if (taskId.trim().isEmpty) {
      throw const AgentAiCostUsageValidationException(
        'taskId cannot be empty.',
      );
    }

    if (providerId.trim().isEmpty) {
      throw const AgentAiCostUsageValidationException(
        'providerId cannot be empty.',
      );
    }

    if (operationName.trim().isEmpty) {
      throw const AgentAiCostUsageValidationException(
        'operationName cannot be empty.',
      );
    }

    if (inputTokens < 0 ||
        outputTokens < 0 ||
        totalTokens < 0) {
      throw const AgentAiCostUsageValidationException(
        'Token counts cannot be negative.',
      );
    }

    if (totalTokens !=
        inputTokens + outputTokens) {
      throw const AgentAiCostUsageValidationException(
        'totalTokens must equal inputTokens + outputTokens.',
      );
    }

    if (estimatedCostRs < 0) {
      throw const AgentAiCostUsageValidationException(
        'estimatedCostRs cannot be negative.',
      );
    }

    if (!AgentAiCacheOpportunity.isValid(
      cacheOpportunity,
    )) {
      throw AgentAiCostUsageValidationException(
        'Invalid cache opportunity "$cacheOpportunity".',
      );
    }

    if (monthlyBudgetRs < 0 ||
        monthlyUsedRs < 0) {
      throw const AgentAiCostUsageValidationException(
        'Budget values cannot be negative.',
      );
    }

    if (budgetUsagePercent < 0) {
      throw const AgentAiCostUsageValidationException(
        'budgetUsagePercent cannot be negative.',
      );
    }

    if (!AgentAiBudgetThresholdStatus.isValid(
      budgetThresholdStatus,
    )) {
      throw AgentAiCostUsageValidationException(
        'Invalid budget threshold status '
        '"$budgetThresholdStatus".',
      );
    }

    if (reason.trim().isEmpty) {
      throw const AgentAiCostUsageValidationException(
        'Assessment reason cannot be empty.',
      );
    }

    if (budgetThresholdStatus ==
            AgentAiBudgetThresholdStatus.exhausted &&
        monthlyBudgetRs > 0 &&
        monthlyUsedRs < monthlyBudgetRs) {
      throw const AgentAiCostUsageValidationException(
        'EXHAUSTED status requires used budget to reach or exceed budget.',
      );
    }
  }

  bool get isValid {
    try {
      validate();
      return true;
    } on AgentAiCostUsageValidationException {
      return false;
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'taskId': taskId,
      'providerId': providerId,
      'operationName': operationName,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'totalTokens': totalTokens,
      'estimatedCostRs': estimatedCostRs,
      'expensiveOperation': expensiveOperation,
      'cacheOpportunity': cacheOpportunity,
      'monthlyBudgetRs': monthlyBudgetRs,
      'monthlyUsedRs': monthlyUsedRs,
      'budgetUsagePercent': budgetUsagePercent,
      'budgetThresholdStatus':
          budgetThresholdStatus,
      'budgetWarning': budgetWarning,
      'budgetBlocked': budgetBlocked,
      'cacheRecommended': cacheRecommended,
      'reason': reason,
    };
  }
}

class AgentAiCostUsageValidationException
    implements Exception {
  final String message;

  const AgentAiCostUsageValidationException(
    this.message,
  );

  @override
  String toString() =>
      'AgentAiCostUsageValidationException: $message';
}
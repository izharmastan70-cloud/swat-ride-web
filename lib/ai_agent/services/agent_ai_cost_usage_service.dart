import '../models/agent_ai_cost_usage_assessment.dart';

// =========================================================
// AI AGENT - COST & USAGE ASSESSMENT SERVICE
// =========================================================
//
// Phase 30 Step 3.
//
// PURE MONITORING / RECOMMENDATION LOGIC.
//
// Calculates:
// - token totals
// - estimated provider cost
// - expensive operation flag
// - cache opportunity
// - budget usage percentage
// - budget threshold state
//
// NO API CALL.
// NO FIRESTORE WRITE.
// NO PROVIDER EXECUTION.
// NO PAYMENT/BILLING ACTION.
// NO AUTOMATIC BUDGET CHANGE.

class AgentAiCostUsageService {
  const AgentAiCostUsageService();

  AgentAiCostUsageAssessment assess({
    required String taskId,
    required String providerId,
    required String operationName,
    required int inputTokens,
    required int outputTokens,
    double inputCostPer1kTokensRs = 0,
    double outputCostPer1kTokensRs = 0,
    int monthlyBudgetRs = 0,
    int monthlyUsedRs = 0,
    int expensiveTokenThreshold = 8000,
    double expensiveCostThresholdRs = 50,
    bool repeatedOperation = false,
    bool deterministicOperation = false,
    bool reusableResult = false,
  }) {
    if (inputTokens < 0 || outputTokens < 0) {
      throw const AgentAiCostUsageServiceException(
        'Token counts cannot be negative.',
      );
    }

    if (inputCostPer1kTokensRs < 0 ||
        outputCostPer1kTokensRs < 0) {
      throw const AgentAiCostUsageServiceException(
        'Token cost rates cannot be negative.',
      );
    }

    if (monthlyBudgetRs < 0 ||
        monthlyUsedRs < 0) {
      throw const AgentAiCostUsageServiceException(
        'Budget values cannot be negative.',
      );
    }

    if (expensiveTokenThreshold < 0 ||
        expensiveCostThresholdRs < 0) {
      throw const AgentAiCostUsageServiceException(
        'Expensive-operation thresholds cannot be negative.',
      );
    }

    final int totalTokens =
        inputTokens + outputTokens;

    final double inputCost =
        (inputTokens / 1000) *
        inputCostPer1kTokensRs;

    final double outputCost =
        (outputTokens / 1000) *
        outputCostPer1kTokensRs;

    final double estimatedCostRs =
        inputCost + outputCost;

    final bool expensiveOperation =
        totalTokens >= expensiveTokenThreshold ||
        estimatedCostRs >=
            expensiveCostThresholdRs;

    final String cacheOpportunity =
        _cacheOpportunity(
      repeatedOperation: repeatedOperation,
      deterministicOperation:
          deterministicOperation,
      reusableResult: reusableResult,
      expensiveOperation:
          expensiveOperation,
    );

    final double budgetUsagePercent =
        monthlyBudgetRs <= 0
            ? 0
            : (monthlyUsedRs /
                    monthlyBudgetRs) *
                100;

    final String budgetThresholdStatus =
        _budgetStatus(
      monthlyBudgetRs: monthlyBudgetRs,
      monthlyUsedRs: monthlyUsedRs,
      budgetUsagePercent:
          budgetUsagePercent,
    );

    final String reason = _reason(
      expensiveOperation:
          expensiveOperation,
      cacheOpportunity:
          cacheOpportunity,
      budgetThresholdStatus:
          budgetThresholdStatus,
      totalTokens:
          totalTokens,
      estimatedCostRs:
          estimatedCostRs,
    );

    final AgentAiCostUsageAssessment result =
        AgentAiCostUsageAssessment(
      taskId: taskId,
      providerId: providerId,
      operationName: operationName,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: totalTokens,
      estimatedCostRs: estimatedCostRs,
      expensiveOperation:
          expensiveOperation,
      cacheOpportunity:
          cacheOpportunity,
      monthlyBudgetRs:
          monthlyBudgetRs,
      monthlyUsedRs:
          monthlyUsedRs,
      budgetUsagePercent:
          budgetUsagePercent,
      budgetThresholdStatus:
          budgetThresholdStatus,
      reason: reason,
    );

    result.validate();

    return result;
  }

  String _budgetStatus({
    required int monthlyBudgetRs,
    required int monthlyUsedRs,
    required double budgetUsagePercent,
  }) {
    if (monthlyBudgetRs > 0 &&
        monthlyUsedRs >= monthlyBudgetRs) {
      return AgentAiBudgetThresholdStatus.exhausted;
    }

    if (budgetUsagePercent >= 90) {
      return AgentAiBudgetThresholdStatus.critical;
    }

    if (budgetUsagePercent >= 75) {
      return AgentAiBudgetThresholdStatus.warning;
    }

    return AgentAiBudgetThresholdStatus.normal;
  }

  String _cacheOpportunity({
    required bool repeatedOperation,
    required bool deterministicOperation,
    required bool reusableResult,
    required bool expensiveOperation,
  }) {
    int score = 0;

    if (repeatedOperation) {
      score++;
    }

    if (deterministicOperation) {
      score++;
    }

    if (reusableResult) {
      score++;
    }

    if (expensiveOperation) {
      score++;
    }

    if (score >= 4) {
      return AgentAiCacheOpportunity.high;
    }

    if (score >= 2) {
      return AgentAiCacheOpportunity.medium;
    }

    if (score == 1) {
      return AgentAiCacheOpportunity.low;
    }

    return AgentAiCacheOpportunity.none;
  }

  String _reason({
    required bool expensiveOperation,
    required String cacheOpportunity,
    required String budgetThresholdStatus,
    required int totalTokens,
    required double estimatedCostRs,
  }) {
    final List<String> parts = <String>[
      'Tokens: $totalTokens.',
      'Estimated cost: Rs ${estimatedCostRs.toStringAsFixed(2)}.',
      'Budget state: $budgetThresholdStatus.',
    ];

    if (expensiveOperation) {
      parts.add(
        'Operation is classified as expensive.',
      );
    }

    if (cacheOpportunity ==
            AgentAiCacheOpportunity.medium ||
        cacheOpportunity ==
            AgentAiCacheOpportunity.high) {
      parts.add(
        'Caching/reuse opportunity detected.',
      );
    }

    return parts.join(' ');
  }
}

class AgentAiCostUsageServiceException
    implements Exception {
  final String message;

  const AgentAiCostUsageServiceException(
    this.message,
  );

  @override
  String toString() =>
      'AgentAiCostUsageServiceException: $message';
}
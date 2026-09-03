import 'agent_ai_cost_usage_assessment.dart';

// =========================================================
// AI AGENT - COST & USAGE REPORT
// =========================================================
//
// Phase 30 Step 5.
//
// Consolidated monitoring/recommendation report.
//
// Includes:
// - total token usage
// - estimated total cost
// - expensive operations
// - cache opportunities
// - budget warnings
// - optimization recommendations
//
// RECOMMEND-ONLY.
//
// NO FIRESTORE WRITE.
// NO PROVIDER EXECUTION.
// NO PAYMENT ACTION.
// NO BUDGET MUTATION.
// NO SECRET ACCESS.

class AgentAiCostUsageReport {
  final List<AgentAiCostUsageAssessment> assessments;

  final int totalInputTokens;
  final int totalOutputTokens;
  final int totalTokens;

  final double estimatedTotalCostRs;

  final int expensiveOperationCount;
  final int cacheOpportunityCount;
  final int budgetWarningCount;
  final int budgetCriticalCount;
  final int budgetExhaustedCount;

  final List<String> recommendations;

  const AgentAiCostUsageReport({
    required this.assessments,
    required this.totalInputTokens,
    required this.totalOutputTokens,
    required this.totalTokens,
    required this.estimatedTotalCostRs,
    required this.expensiveOperationCount,
    required this.cacheOpportunityCount,
    required this.budgetWarningCount,
    required this.budgetCriticalCount,
    required this.budgetExhaustedCount,
    required this.recommendations,
  });

  bool get hasOptimizationOpportunity =>
      expensiveOperationCount > 0 ||
      cacheOpportunityCount > 0 ||
      budgetWarningCount > 0 ||
      budgetCriticalCount > 0 ||
      budgetExhaustedCount > 0;

  bool get budgetAtRisk =>
      budgetCriticalCount > 0 ||
      budgetExhaustedCount > 0;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'totalInputTokens': totalInputTokens,
      'totalOutputTokens': totalOutputTokens,
      'totalTokens': totalTokens,
      'estimatedTotalCostRs': estimatedTotalCostRs,
      'expensiveOperationCount':
          expensiveOperationCount,
      'cacheOpportunityCount':
          cacheOpportunityCount,
      'budgetWarningCount':
          budgetWarningCount,
      'budgetCriticalCount':
          budgetCriticalCount,
      'budgetExhaustedCount':
          budgetExhaustedCount,
      'hasOptimizationOpportunity':
          hasOptimizationOpportunity,
      'budgetAtRisk': budgetAtRisk,
      'recommendations':
          List<String>.from(recommendations),
      'assessments': assessments
          .map(
            (AgentAiCostUsageAssessment item) =>
                item.toMap(),
          )
          .toList(growable: false),
    };
  }
}

class AgentAiCostUsageReportService {
  const AgentAiCostUsageReportService();

  AgentAiCostUsageReport build({
    required Iterable<AgentAiCostUsageAssessment>
        assessments,
  }) {
    final List<AgentAiCostUsageAssessment> items =
        assessments.toList(growable: false);

    int totalInputTokens = 0;
    int totalOutputTokens = 0;
    int totalTokens = 0;

    double estimatedTotalCostRs = 0;

    int expensiveOperationCount = 0;
    int cacheOpportunityCount = 0;
    int budgetWarningCount = 0;
    int budgetCriticalCount = 0;
    int budgetExhaustedCount = 0;

    for (final AgentAiCostUsageAssessment item
        in items) {
      item.validate();

      totalInputTokens += item.inputTokens;
      totalOutputTokens += item.outputTokens;
      totalTokens += item.totalTokens;

      estimatedTotalCostRs +=
          item.estimatedCostRs;

      if (item.expensiveOperation) {
        expensiveOperationCount++;
      }

      if (item.cacheRecommended) {
        cacheOpportunityCount++;
      }

      switch (item.budgetThresholdStatus) {
        case AgentAiBudgetThresholdStatus.warning:
          budgetWarningCount++;
          break;

        case AgentAiBudgetThresholdStatus.critical:
          budgetCriticalCount++;
          break;

        case AgentAiBudgetThresholdStatus.exhausted:
          budgetExhaustedCount++;
          break;

        case AgentAiBudgetThresholdStatus.normal:
          break;
      }
    }

    final List<String> recommendations =
        _recommendations(
      expensiveOperationCount:
          expensiveOperationCount,
      cacheOpportunityCount:
          cacheOpportunityCount,
      budgetWarningCount:
          budgetWarningCount,
      budgetCriticalCount:
          budgetCriticalCount,
      budgetExhaustedCount:
          budgetExhaustedCount,
    );

    return AgentAiCostUsageReport(
      assessments:
          List<AgentAiCostUsageAssessment>.unmodifiable(
        items,
      ),
      totalInputTokens:
          totalInputTokens,
      totalOutputTokens:
          totalOutputTokens,
      totalTokens:
          totalTokens,
      estimatedTotalCostRs:
          estimatedTotalCostRs,
      expensiveOperationCount:
          expensiveOperationCount,
      cacheOpportunityCount:
          cacheOpportunityCount,
      budgetWarningCount:
          budgetWarningCount,
      budgetCriticalCount:
          budgetCriticalCount,
      budgetExhaustedCount:
          budgetExhaustedCount,
      recommendations:
          List<String>.unmodifiable(
        recommendations,
      ),
    );
  }

  List<String> _recommendations({
    required int expensiveOperationCount,
    required int cacheOpportunityCount,
    required int budgetWarningCount,
    required int budgetCriticalCount,
    required int budgetExhaustedCount,
  }) {
    final List<String> items = <String>[];

    if (expensiveOperationCount > 0) {
      items.add(
        'Review expensive AI operations and consider lower-cost providers, smaller prompts, or narrower task scope where quality permits.',
      );
    }

    if (cacheOpportunityCount > 0) {
      items.add(
        'Review repeated/deterministic AI operations for safe caching or result reuse.',
      );
    }

    if (budgetWarningCount > 0) {
      items.add(
        'Paid AI budget has entered warning range. Monitor usage more closely.',
      );
    }

    if (budgetCriticalCount > 0) {
      items.add(
        'Paid AI budget is in critical range. Prefer free/local-capable work where appropriate and review expensive operations.',
      );
    }

    if (budgetExhaustedCount > 0) {
      items.add(
        'Paid AI budget is exhausted. Do not increase budget or re-enable paid usage automatically; Super Admin review is required.',
      );
    }

    if (items.isEmpty) {
      items.add(
        'No immediate AI cost optimization issue detected.',
      );
    }

    return items;
  }
}
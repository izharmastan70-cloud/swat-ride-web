import '../models/agent_ai_cost_usage_assessment.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_provider_health.dart';
import 'agent_ai_cost_usage_service.dart';
import 'agent_provider_usage_accounting_service.dart';

// =========================================================
// AI AGENT - COST & USAGE RUNTIME BRIDGE
// =========================================================
//
// Phase 30 Step 4.
//
// READ-ONLY bridge between existing runtime accounting and
// the AI Cost & Usage assessment service.
//
// Reuses:
// - AgentProviderHealth.requestsToday
// - AgentProviderUsageSnapshot
// - AgentMasterSettings paid-code monthly budget
//
// NO FIRESTORE WRITE.
// NO PROVIDER EXECUTION.
// NO PAYMENT ACTION.
// NO BUDGET MUTATION.
// NO SECRET ACCESS.

class AgentAiCostUsageRuntimeBridge {
  final AgentAiCostUsageService costUsageService;

  const AgentAiCostUsageRuntimeBridge({
    this.costUsageService =
        const AgentAiCostUsageService(),
  });

  AgentAiCostUsageAssessment assessFromRuntime({
    required String taskId,
    required String providerId,
    required String operationName,
    required int inputTokens,
    required int outputTokens,
    required double inputCostPer1kTokensRs,
    required double outputCostPer1kTokensRs,
    required AgentProviderHealth providerHealth,
    required AgentProviderUsageSnapshot usageSnapshot,
    required AgentMasterSettings settings,
    int expensiveTokenThreshold = 8000,
    double expensiveCostThresholdRs = 50,
    bool repeatedOperation = false,
    bool deterministicOperation = false,
    bool reusableResult = false,
  }) {
    if (providerId.trim().isEmpty) {
      throw const AgentAiCostUsageRuntimeBridgeException(
        'providerId cannot be empty.',
      );
    }

    if (providerHealth.providerId != providerId) {
      throw AgentAiCostUsageRuntimeBridgeException(
        'Provider health ID mismatch: '
        '${providerHealth.providerId} != $providerId.',
      );
    }

    if (usageSnapshot.providerId != providerId) {
      throw AgentAiCostUsageRuntimeBridgeException(
        'Usage snapshot ID mismatch: '
        '${usageSnapshot.providerId} != $providerId.',
      );
    }

    if (providerHealth.requestsToday !=
        usageSnapshot.requestsToday) {
      throw const AgentAiCostUsageRuntimeBridgeException(
        'Provider health and usage snapshot request counts do not match.',
      );
    }

    return costUsageService.assess(
      taskId: taskId,
      providerId: providerId,
      operationName: operationName,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      inputCostPer1kTokensRs:
          inputCostPer1kTokensRs,
      outputCostPer1kTokensRs:
          outputCostPer1kTokensRs,
      monthlyBudgetRs:
          settings.monthlyPaidCodeBudgetRs,
      monthlyUsedRs:
          settings.paidCodeBudgetUsedRs,
      expensiveTokenThreshold:
          expensiveTokenThreshold,
      expensiveCostThresholdRs:
          expensiveCostThresholdRs,
      repeatedOperation:
          repeatedOperation,
      deterministicOperation:
          deterministicOperation,
      reusableResult:
          reusableResult,
    );
  }

  Map<String, dynamic> buildRuntimeSnapshot({
    required AgentProviderHealth providerHealth,
    required AgentProviderUsageSnapshot usageSnapshot,
    required AgentMasterSettings settings,
  }) {
    if (providerHealth.providerId !=
        usageSnapshot.providerId) {
      throw const AgentAiCostUsageRuntimeBridgeException(
        'Provider health and usage snapshot IDs do not match.',
      );
    }

    return <String, dynamic>{
      'providerId':
          providerHealth.providerId,
      'providerStatus':
          providerHealth.status,
      'requestsToday':
          providerHealth.requestsToday,
      'remainingDailyRequests':
          usageSnapshot.remainingDailyRequests,
      'remainingWindowRequests':
          usageSnapshot.remainingWindowRequests,
      'dailyQuotaReached':
          usageSnapshot.dailyQuotaReached,
      'rateLimitReached':
          usageSnapshot.rateLimitReached,
      'monthlyPaidCodeBudgetRs':
          settings.monthlyPaidCodeBudgetRs,
      'paidCodeBudgetUsedRs':
          settings.paidCodeBudgetUsedRs,
      'paidBudgetAvailable':
          settings.paidBudgetAvailable,
    };
  }
}

class AgentAiCostUsageRuntimeBridgeException
    implements Exception {
  final String message;

  const AgentAiCostUsageRuntimeBridgeException(
    this.message,
  );

  @override
  String toString() =>
      'AgentAiCostUsageRuntimeBridgeException: $message';
}
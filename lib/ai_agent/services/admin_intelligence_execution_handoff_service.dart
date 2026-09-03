import '../models/admin_intelligence_execution_handoff.dart';
import '../models/agent_project_context.dart';
import '../models/admin_intelligence_reasoning_policy.dart';
import 'admin_intelligence_paid_runtime_gate.dart';
import 'admin_intelligence_provider_routing_adapter.dart';
import 'agent_provider_router_coordinator.dart';

/// Creates a short-lived execution handoff after routing + cost gates.
///
/// This service DOES NOT execute the provider.
/// A later authorized execution layer must re-check:
/// - handoff expiry
/// - existing Permission Engine
/// - existing Approval Engine
/// - runtime master controls
/// - provider health/capacity
/// before any real provider call.
class AdminIntelligenceExecutionHandoffService {
  const AdminIntelligenceExecutionHandoffService();

  AdminIntelligenceExecutionHandoff preparePaidReasoning({
    required String handoffId,
    required String taskId,
    required String requiredCapability,
    required DateTime now,
    required AdminIntelligenceProviderRoutingResult routingResult,
    required AdminIntelligencePaidRuntimeGateResult runtimeGate,
    AgentProjectContext? projectContext,
    Duration ttl = const Duration(minutes: 5),
  }) {
    if (handoffId.trim().isEmpty) {
      throw ArgumentError('Admin Intelligence handoff ID is required.');
    }

    if (taskId.trim().isEmpty) {
      throw ArgumentError('Admin Intelligence task ID is required.');
    }

    if (ttl <= Duration.zero) {
      throw ArgumentError('Admin Intelligence handoff TTL must be positive.');
    }

    projectContext?.validate(now: now);

    final plan = routingResult.routingPlan;

    final bool paidDecision =
        runtimeGate.reasoningDecision.providerClass ==
        AdminIntelligenceReasoningProviderClass.paidAi;

    final bool correctLane =
        plan?.routingLane == AgentProviderRoutingLane.paidReasoning;

    final bool routingPlanReady =
        paidDecision &&
        correctLane &&
        routingResult.hasRoutingPlan &&
        plan?.primaryProviderId != null;

    final bool ownerApprovalSatisfied =
        !runtimeGate.reasoningDecision.requiresOwnerApproval;

    final bool budgetAllowed =
        runtimeGate.paidBudget.canSpendPaid &&
        runtimeGate.reasoningDecision.paidCostAllowed;

    final bool providerCapacityAllowed = runtimeGate.providerCapacityAvailable;

    String? blockedReason;

    if (!paidDecision) {
      blockedReason = 'reasoning_decision_is_not_paid_ai';
    } else if (!correctLane) {
      blockedReason = 'paid_reasoning_routing_lane_missing';
    } else if (!routingPlanReady) {
      blockedReason = 'paid_reasoning_provider_plan_not_ready';
    } else if (!ownerApprovalSatisfied) {
      blockedReason = 'paid_reasoning_owner_approval_missing';
    } else if (!budgetAllowed) {
      blockedReason = 'paid_reasoning_budget_gate_blocked';
    } else if (!providerCapacityAllowed) {
      blockedReason = 'paid_reasoning_provider_capacity_blocked';
    } else if (!runtimeGate.paidExecutionAllowed) {
      blockedReason = 'paid_reasoning_runtime_gate_blocked';
    }

    return AdminIntelligenceExecutionHandoff(
      handoffId: handoffId.trim(),
      taskId: taskId.trim(),
      providerId: plan?.primaryProviderId ?? '',
      routingLane: plan?.routingLane ?? AgentProviderRoutingLane.paidReasoning,
      requiredCapability: requiredCapability.trim(),
      createdAt: now,
      expiresAt: now.add(ttl),
      estimatedCostRs: runtimeGate.costAssessment.estimatedCostRs,
      paidReasoning: true,
      ownerApprovalSatisfied: ownerApprovalSatisfied,
      budgetAllowed: budgetAllowed,
      providerCapacityAllowed: providerCapacityAllowed,
      routingPlanReady: routingPlanReady,
      readOnlyPreparation: true,
      blockedReason: blockedReason,
      projectContext: projectContext,
    );
  }
}

import '../constants/agent_provider_constants.dart';
import '../models/admin_intelligence_reasoning_policy.dart';
import '../models/agent_provider_health.dart';
import '../models/agent_provider_routing_profile.dart';
import 'agent_ai_provider.dart';
import 'agent_provider_router_bridge.dart';
import 'agent_provider_router_coordinator.dart';
import 'agent_provider_usage_accounting_service.dart';

class AdminIntelligenceProviderRoutingResult {
  const AdminIntelligenceProviderRoutingResult({
    required this.reasoningDecision,
    required this.reason,
    required this.usageSnapshots,
    this.routingPlan,
  });

  final AdminIntelligenceReasoningDecision reasoningDecision;
  final AgentProviderRoutingPlan? routingPlan;
  final Map<String, AgentProviderUsageSnapshot> usageSnapshots;
  final String reason;

  bool get hasRoutingPlan =>
      routingPlan != null &&
      routingPlan!.providerAvailable &&
      !routingPlan!.isFailClosed;

  bool get requiresPaidApproval => reasoningDecision.requiresOwnerApproval;

  bool get paidRouteReady =>
      reasoningDecision.shouldUsePaidAi &&
      reasoningDecision.paidCostAllowed &&
      !reasoningDecision.requiresOwnerApproval &&
      hasRoutingPlan;
}

/// Thin bridge between Phase 38 Free-First reasoning policy and the
/// existing provider router / quota accounting architecture.
///
/// It creates routing plans only.
/// It never executes provider.complete().
/// It never writes Firestore.
/// It never charges or mutates a budget.
class AdminIntelligenceProviderRoutingAdapter {
  const AdminIntelligenceProviderRoutingAdapter({
    this.routerBridge = const AgentProviderRouterBridge(),
    this.usageAccounting = const AgentProviderUsageAccountingService(),
  });

  final AgentProviderRouterBridge routerBridge;
  final AgentProviderUsageAccountingService usageAccounting;

  AdminIntelligenceProviderRoutingResult prepare({
    required String taskId,
    required String requiredCapability,
    required AdminIntelligenceReasoningDecision reasoningDecision,
    required Iterable<AgentAiProvider> providers,
    required Map<String, AgentProviderRoutingProfile> profilesByProviderId,
    required Map<String, AgentProviderHealth> healthByProviderId,
    Map<String, int> requestsInCurrentWindow = const <String, int>{},
    String paidMaxCostTier = AgentProviderCostTier.high,
    bool allowFallback = true,
  }) {
    final Map<String, AgentProviderUsageSnapshot> usageSnapshots =
        <String, AgentProviderUsageSnapshot>{};

    final List<AgentAiProvider> usageEligible = <AgentAiProvider>[];

    for (final AgentAiProvider provider in providers) {
      if (!provider.enabled) {
        continue;
      }

      final AgentProviderRoutingProfile? profile =
          profilesByProviderId[provider.providerId];

      final AgentProviderHealth? health =
          healthByProviderId[provider.providerId];

      if (profile == null || health == null) {
        continue;
      }

      final AgentProviderUsageSnapshot snapshot = usageAccounting.evaluate(
        profile: profile,
        health: health,
        requestsInCurrentWindow:
            requestsInCurrentWindow[provider.providerId] ?? 0,
      );

      usageSnapshots[provider.providerId] = snapshot;

      if (!snapshot.blocked) {
        usageEligible.add(provider);
      }
    }

    final String providerClass = reasoningDecision.providerClass;

    if (providerClass ==
        AdminIntelligenceReasoningProviderClass.askPaidApproval) {
      return AdminIntelligenceProviderRoutingResult(
        reasoningDecision: reasoningDecision,
        routingPlan: null,
        usageSnapshots: Map<String, AgentProviderUsageSnapshot>.unmodifiable(
          usageSnapshots,
        ),
        reason: 'paid_reasoning_waiting_for_owner_approval',
      );
    }

    if (providerClass == AdminIntelligenceReasoningProviderClass.none ||
        providerClass == AdminIntelligenceReasoningProviderClass.safeFallback) {
      return AdminIntelligenceProviderRoutingResult(
        reasoningDecision: reasoningDecision,
        routingPlan: null,
        usageSnapshots: Map<String, AgentProviderUsageSnapshot>.unmodifiable(
          usageSnapshots,
        ),
        reason: reasoningDecision.reason,
      );
    }

    if (providerClass == AdminIntelligenceReasoningProviderClass.freeOnline) {
      final List<AgentAiProvider> freeProviders = usageEligible
          .where(
            (AgentAiProvider provider) =>
                provider.providerType == AgentProviderType.freeCloud,
          )
          .toList(growable: false);

      final AgentProviderRoutingPlan plan = routerBridge.buildFreeOrLocalPlan(
        taskId: taskId,
        requiredCapability: requiredCapability,
        providers: freeProviders,
        profilesByProviderId: profilesByProviderId,
        healthByProviderId: healthByProviderId,
        requestsInCurrentWindow: requestsInCurrentWindow,
        allowFallback: allowFallback,
      );

      return AdminIntelligenceProviderRoutingResult(
        reasoningDecision: reasoningDecision,
        routingPlan: plan,
        usageSnapshots: Map<String, AgentProviderUsageSnapshot>.unmodifiable(
          usageSnapshots,
        ),
        reason: plan.reason,
      );
    }

    if (providerClass == AdminIntelligenceReasoningProviderClass.localAi) {
      final List<AgentAiProvider> localProviders = usageEligible
          .where(
            (AgentAiProvider provider) =>
                provider.providerType == AgentProviderType.local,
          )
          .toList(growable: false);

      final AgentProviderRoutingPlan plan = routerBridge.buildFreeOrLocalPlan(
        taskId: taskId,
        requiredCapability: requiredCapability,
        providers: localProviders,
        profilesByProviderId: profilesByProviderId,
        healthByProviderId: healthByProviderId,
        requestsInCurrentWindow: requestsInCurrentWindow,
        allowFallback: allowFallback,
      );

      return AdminIntelligenceProviderRoutingResult(
        reasoningDecision: reasoningDecision,
        routingPlan: plan,
        usageSnapshots: Map<String, AgentProviderUsageSnapshot>.unmodifiable(
          usageSnapshots,
        ),
        reason: plan.reason,
      );
    }

    if (providerClass == AdminIntelligenceReasoningProviderClass.paidAi) {
      if (!reasoningDecision.paidCostAllowed ||
          reasoningDecision.requiresOwnerApproval) {
        return AdminIntelligenceProviderRoutingResult(
          reasoningDecision: reasoningDecision,
          routingPlan: null,
          usageSnapshots: Map<String, AgentProviderUsageSnapshot>.unmodifiable(
            usageSnapshots,
          ),
          reason: 'paid_reasoning_policy_gate_blocked',
        );
      }

      final List<AgentAiProvider> paidProviders = usageEligible
          .where(
            (AgentAiProvider provider) =>
                provider.providerType == AgentProviderType.paidReasoning,
          )
          .toList(growable: false);

      final AgentProviderRoutingPlan plan = routerBridge.buildPaidReasoningPlan(
        taskId: taskId,
        requiredCapability: requiredCapability,
        providers: paidProviders,
        profilesByProviderId: profilesByProviderId,
        healthByProviderId: healthByProviderId,
        requestsInCurrentWindow: requestsInCurrentWindow,
        maxCostTier: paidMaxCostTier,
        allowFallback: allowFallback,
      );

      return AdminIntelligenceProviderRoutingResult(
        reasoningDecision: reasoningDecision,
        routingPlan: plan,
        usageSnapshots: Map<String, AgentProviderUsageSnapshot>.unmodifiable(
          usageSnapshots,
        ),
        reason: plan.reason,
      );
    }

    return AdminIntelligenceProviderRoutingResult(
      reasoningDecision: reasoningDecision,
      routingPlan: null,
      usageSnapshots: Map<String, AgentProviderUsageSnapshot>.unmodifiable(
        usageSnapshots,
      ),
      reason: 'unsupported_admin_intelligence_provider_class',
    );
  }
}

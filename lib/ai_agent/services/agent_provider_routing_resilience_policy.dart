import '../constants/agent_provider_expansion_contract_constants.dart';
import '../constants/agent_provider_routing_resilience_constants.dart';
import '../models/agent_provider_circuit_state.dart';
import '../models/agent_provider_resilient_route_decision.dart';
import '../models/agent_provider_route_candidate.dart';

class AgentProviderRoutingResiliencePolicy {
  const AgentProviderRoutingResiliencePolicy();

  AgentProviderResilientRouteDecision selectRoute({
    required List<AgentProviderRouteCandidate> candidates,
  }) {
    if (candidates.isEmpty ||
        candidates.length > AgentProviderResilienceLimits.maxCandidates) {
      return _decision(
        status: AgentProviderResilientRouteStatus.blockedInvalidInput,
        selectedProviderId: '',
        selectedTier: '',
        skippedProviderIds: const <String>[],
        reasons: const <String>[
          'invalid_candidate_input',
          'fail_closed',
          'core_app_continues',
        ],
      );
    }

    final List<AgentProviderRouteCandidate> valid =
        <AgentProviderRouteCandidate>[];

    final List<String> skipped = <String>[];

    for (final AgentProviderRouteCandidate candidate in candidates) {
      try {
        candidate.validateStructure();
        valid.add(candidate);
      } catch (_) {
        if (candidate.providerId.trim().isNotEmpty) {
          skipped.add(candidate.providerId);
        }
      }
    }

    if (valid.isEmpty) {
      return _noRoute(
        skippedProviderIds: skipped,
        reasons: const <String>[
          'no_valid_provider_candidate',
          'ai_fail_closed',
          'core_app_continues',
        ],
      );
    }

    valid.sort((AgentProviderRouteCandidate a, AgentProviderRouteCandidate b) {
      final int aPriority =
          AgentProviderRoutingTierOrder.priority[a.tier] ?? 999;

      final int bPriority =
          AgentProviderRoutingTierOrder.priority[b.tier] ?? 999;

      final int tierCompare = aPriority.compareTo(bPriority);

      if (tierCompare != 0) {
        return tierCompare;
      }

      return a.providerId.compareTo(b.providerId);
    });

    for (final AgentProviderRouteCandidate candidate in valid) {
      if (!candidate.routable) {
        skipped.add(candidate.providerId);
        continue;
      }

      return _decision(
        status: _statusForTier(candidate.tier),
        selectedProviderId: candidate.providerId,
        selectedTier: candidate.tier,
        skippedProviderIds: skipped,
        reasons: <String>[
          'free_local_paid_order_applied',
          'disabled_unhealthy_circuit_open_skipped',
          'capability_match_required',
          if (candidate.tier == AgentProviderExpansionTier.localOptional)
            'free_unavailable_local_optional_selected',
          if (candidate.tier == AgentProviderExpansionTier.paidLastEscalation)
            'free_and_local_unavailable_paid_last_selected',
          if (candidate.tier == AgentProviderExpansionTier.paidLastEscalation)
            'paid_controls_preverified',
          'policy_decision_only',
          'provider_not_invoked_here',
        ],
      );
    }

    return _noRoute(
      skippedProviderIds: skipped,
      reasons: const <String>[
        'no_routable_provider',
        'all_candidates_disabled_unhealthy_open_or_blocked',
        'ai_fail_closed',
        'no_retry_storm',
        'core_app_continues',
      ],
    );
  }

  AgentProviderCircuitState nextCircuitState({
    required String providerId,
    required String currentStatus,
    required int currentConsecutiveFailures,
    required bool callSucceeded,
  }) {
    if (providerId.trim().isEmpty ||
        !AgentProviderCircuitStatus.values.contains(currentStatus) ||
        currentConsecutiveFailures < 0) {
      throw const FormatException('Invalid circuit-breaker input.');
    }

    if (callSucceeded) {
      return AgentProviderCircuitState(
        providerId: providerId,
        status: AgentProviderCircuitStatus.closed,
        consecutiveFailures: 0,
        cooldownSeconds: 0,
      );
    }

    final int failures = currentConsecutiveFailures + 1;

    if (failures >= AgentProviderResilienceLimits.failureThreshold) {
      return AgentProviderCircuitState(
        providerId: providerId,
        status: AgentProviderCircuitStatus.open,
        consecutiveFailures: failures,
        cooldownSeconds: AgentProviderResilienceLimits.openCooldownSeconds,
      );
    }

    return AgentProviderCircuitState(
      providerId: providerId,
      status: AgentProviderCircuitStatus.closed,
      consecutiveFailures: failures,
      cooldownSeconds: 0,
    );
  }

  AgentProviderCircuitState markHalfOpen({
    required AgentProviderCircuitState current,
  }) {
    current.validateStructure();

    if (!current.open) {
      return current;
    }

    return AgentProviderCircuitState(
      providerId: current.providerId,
      status: AgentProviderCircuitStatus.halfOpen,
      consecutiveFailures: current.consecutiveFailures,
      cooldownSeconds: 0,
    );
  }

  String _statusForTier(String tier) {
    switch (tier) {
      case AgentProviderExpansionTier.freeOnline:
        return AgentProviderResilientRouteStatus.routeFreeOnline;

      case AgentProviderExpansionTier.localOptional:
        return AgentProviderResilientRouteStatus.routeLocalOptional;

      case AgentProviderExpansionTier.paidLastEscalation:
        return AgentProviderResilientRouteStatus.routePaidLast;

      default:
        return AgentProviderResilientRouteStatus.blockedInvalidInput;
    }
  }

  AgentProviderResilientRouteDecision _noRoute({
    required List<String> skippedProviderIds,
    required List<String> reasons,
  }) {
    return _decision(
      status: AgentProviderResilientRouteStatus.noProviderRoute,
      selectedProviderId: '',
      selectedTier: '',
      skippedProviderIds: skippedProviderIds,
      reasons: reasons,
    );
  }

  AgentProviderResilientRouteDecision _decision({
    required String status,
    required String selectedProviderId,
    required String selectedTier,
    required List<String> skippedProviderIds,
    required List<String> reasons,
  }) {
    final AgentProviderResilientRouteDecision result =
        AgentProviderResilientRouteDecision(
          status: status,
          selectedProviderId: selectedProviderId,
          selectedTier: selectedTier,
          skippedProviderIds: skippedProviderIds,
          reasonCodes: reasons,
        );

    result.validateStructure();
    return result;
  }

  bool get freeOnlineFirstPriority => true;
  bool get localAiOptionalSecondPriority => true;
  bool get paidAiLastEscalation => true;
  bool get paidControlsMustBePreverified => true;
  bool get disabledProviderSkipped => true;
  bool get unhealthyProviderSkipped => true;
  bool get capabilityMismatchSkipped => true;
  bool get openCircuitSkipped => true;
  bool get repeatedFailureOpensCircuit => true;
  bool get circuitPreventsRetryStorm => true;
  bool get successfulCallResetsCircuit => true;
  bool get halfOpenProbeStateSupported => true;
  bool get noProviderMeansAiFailClosed => true;
  bool get coreAppContinuesIfAllProvidersFail => true;
  bool get noAutomaticBudgetIncrease => true;
  bool get noAutomaticPaidEnable => true;
  bool get providerQualityEvaluationOwnedHere => false;
  bool get phase59OwnsProviderQualityEvaluator => true;

  bool get invokesProvider => false;
  bool get activatesProvider => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get chargesCost => false;
  bool get mutatesBudget => false;
  bool get persistsCircuitState => false;
  bool get schedulesCooldown => false;
}

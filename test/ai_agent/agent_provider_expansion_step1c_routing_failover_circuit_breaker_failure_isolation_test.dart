import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_provider_expansion_contract_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_provider_routing_resilience_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_route_candidate.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_routing_resilience_policy.dart';

void main() {
  const AgentProviderRoutingResiliencePolicy policy =
      AgentProviderRoutingResiliencePolicy();

  AgentProviderRouteCandidate candidate({
    String providerId = 'provider:free:a',
    String tier = AgentProviderExpansionTier.freeOnline,
    bool enabled = true,
    bool backendEligible = true,
    bool capabilitySupported = true,
    bool healthy = true,
    String circuitStatus = AgentProviderCircuitStatus.closed,
    int consecutiveFailures = 0,
    bool paidControlsSatisfied = false,
  }) {
    return AgentProviderRouteCandidate(
      providerId: providerId,
      tier: tier,
      enabled: enabled,
      backendEligible: backendEligible,
      capabilitySupported: capabilitySupported,
      healthy: healthy,
      circuitStatus: circuitStatus,
      consecutiveFailures: consecutiveFailures,
      paidControlsSatisfied: paidControlsSatisfied,
    );
  }

  group('Phase 58 Step 1C routing resilience', () {
    test('3 circuit states are locked', () {
      expect(AgentProviderCircuitStatus.values.length, 3);
    });

    test('5 route statuses are locked', () {
      expect(AgentProviderResilientRouteStatus.values.length, 5);
    });

    test('free provider wins when healthy and routable', () {
      final result = policy.selectRoute(
        candidates: <AgentProviderRouteCandidate>[
          candidate(
            providerId: 'provider:paid:a',
            tier: AgentProviderExpansionTier.paidLastEscalation,
            paidControlsSatisfied: true,
          ),
          candidate(
            providerId: 'provider:local:a',
            tier: AgentProviderExpansionTier.localOptional,
          ),
          candidate(),
        ],
      );

      expect(result.status, AgentProviderResilientRouteStatus.routeFreeOnline);
      expect(result.selectedProviderId, 'provider:free:a');
    });

    test('local is selected only after free is unavailable', () {
      final result = policy.selectRoute(
        candidates: <AgentProviderRouteCandidate>[
          candidate(healthy: false),
          candidate(
            providerId: 'provider:local:a',
            tier: AgentProviderExpansionTier.localOptional,
          ),
        ],
      );

      expect(
        result.status,
        AgentProviderResilientRouteStatus.routeLocalOptional,
      );
      expect(result.selectedProviderId, 'provider:local:a');
    });

    test('paid is selected only after free/local unavailable', () {
      final result = policy.selectRoute(
        candidates: <AgentProviderRouteCandidate>[
          candidate(healthy: false),
          candidate(
            providerId: 'provider:local:a',
            tier: AgentProviderExpansionTier.localOptional,
            enabled: false,
          ),
          candidate(
            providerId: 'provider:paid:a',
            tier: AgentProviderExpansionTier.paidLastEscalation,
            paidControlsSatisfied: true,
          ),
        ],
      );

      expect(result.status, AgentProviderResilientRouteStatus.routePaidLast);
      expect(result.selectedProviderId, 'provider:paid:a');
    });

    test('paid provider is skipped if paid controls are not satisfied', () {
      final result = policy.selectRoute(
        candidates: <AgentProviderRouteCandidate>[
          candidate(
            providerId: 'provider:paid:a',
            tier: AgentProviderExpansionTier.paidLastEscalation,
            paidControlsSatisfied: false,
          ),
        ],
      );

      expect(result.status, AgentProviderResilientRouteStatus.noProviderRoute);
      expect(result.coreAppMustContinueOnNoRoute, true);
      expect(result.aiMustFailClosedOnNoRoute, true);
    });

    test('disabled provider is skipped', () {
      final result = policy.selectRoute(
        candidates: <AgentProviderRouteCandidate>[
          candidate(enabled: false),
          candidate(
            providerId: 'provider:local:a',
            tier: AgentProviderExpansionTier.localOptional,
          ),
        ],
      );

      expect(result.selectedProviderId, 'provider:local:a');
      expect(result.skippedProviderIds, contains('provider:free:a'));
    });

    test('unhealthy provider is skipped', () {
      final result = policy.selectRoute(
        candidates: <AgentProviderRouteCandidate>[candidate(healthy: false)],
      );

      expect(result.status, AgentProviderResilientRouteStatus.noProviderRoute);
    });

    test('capability mismatch is skipped', () {
      final result = policy.selectRoute(
        candidates: <AgentProviderRouteCandidate>[
          candidate(capabilitySupported: false),
        ],
      );

      expect(result.status, AgentProviderResilientRouteStatus.noProviderRoute);
    });

    test('backend-ineligible provider is skipped', () {
      final result = policy.selectRoute(
        candidates: <AgentProviderRouteCandidate>[
          candidate(backendEligible: false),
        ],
      );

      expect(result.status, AgentProviderResilientRouteStatus.noProviderRoute);
    });

    test('open circuit provider is skipped', () {
      final result = policy.selectRoute(
        candidates: <AgentProviderRouteCandidate>[
          candidate(circuitStatus: AgentProviderCircuitStatus.open),
          candidate(
            providerId: 'provider:local:a',
            tier: AgentProviderExpansionTier.localOptional,
          ),
        ],
      );

      expect(result.selectedProviderId, 'provider:local:a');
    });

    test(
      'failure threshold prevents routing even before explicit open state',
      () {
        final result = policy.selectRoute(
          candidates: <AgentProviderRouteCandidate>[
            candidate(
              circuitStatus: AgentProviderCircuitStatus.closed,
              consecutiveFailures:
                  AgentProviderResilienceLimits.failureThreshold,
            ),
          ],
        );

        expect(
          result.status,
          AgentProviderResilientRouteStatus.noProviderRoute,
        );
      },
    );

    test('first failure increments circuit failure count', () {
      final state = policy.nextCircuitState(
        providerId: 'provider:free:a',
        currentStatus: AgentProviderCircuitStatus.closed,
        currentConsecutiveFailures: 0,
        callSucceeded: false,
      );

      expect(state.status, AgentProviderCircuitStatus.closed);
      expect(state.consecutiveFailures, 1);
      expect(state.open, false);
    });

    test('threshold failure opens circuit', () {
      final state = policy.nextCircuitState(
        providerId: 'provider:free:a',
        currentStatus: AgentProviderCircuitStatus.closed,
        currentConsecutiveFailures:
            AgentProviderResilienceLimits.failureThreshold - 1,
        callSucceeded: false,
      );

      expect(state.status, AgentProviderCircuitStatus.open);
      expect(state.open, true);
      expect(
        state.cooldownSeconds,
        AgentProviderResilienceLimits.openCooldownSeconds,
      );
    });

    test('success resets circuit to closed', () {
      final state = policy.nextCircuitState(
        providerId: 'provider:free:a',
        currentStatus: AgentProviderCircuitStatus.halfOpen,
        currentConsecutiveFailures: 5,
        callSucceeded: true,
      );

      expect(state.status, AgentProviderCircuitStatus.closed);
      expect(state.consecutiveFailures, 0);
      expect(state.cooldownSeconds, 0);
    });

    test('open circuit can move to half-open probe state contract', () {
      final openState = policy.nextCircuitState(
        providerId: 'provider:free:a',
        currentStatus: AgentProviderCircuitStatus.closed,
        currentConsecutiveFailures:
            AgentProviderResilienceLimits.failureThreshold - 1,
        callSucceeded: false,
      );

      final halfOpen = policy.markHalfOpen(current: openState);

      expect(halfOpen.status, AgentProviderCircuitStatus.halfOpen);
      expect(halfOpen.retryAllowed, true);
      expect(halfOpen.timerImplementedHere, false);
      expect(halfOpen.schedulerImplementedHere, false);
    });

    test('all providers failing returns no route and isolates core app', () {
      final result = policy.selectRoute(
        candidates: <AgentProviderRouteCandidate>[
          candidate(healthy: false),
          candidate(
            providerId: 'provider:local:a',
            tier: AgentProviderExpansionTier.localOptional,
            circuitStatus: AgentProviderCircuitStatus.open,
          ),
          candidate(
            providerId: 'provider:paid:a',
            tier: AgentProviderExpansionTier.paidLastEscalation,
            paidControlsSatisfied: false,
          ),
        ],
      );

      expect(result.status, AgentProviderResilientRouteStatus.noProviderRoute);
      expect(result.noProviderRoute, true);
      expect(result.aiMustFailClosedOnNoRoute, true);
      expect(result.coreAppMustContinueOnNoRoute, true);
    });

    test('candidate is metadata-only and adds no authority', () {
      final value = candidate();

      expect(value.metadataOnly, true);
      expect(value.invokesProvider, false);
      expect(value.grantsPermission, false);
      expect(value.consumesApproval, false);
      expect(value.expandsScope, false);
      expect(value.executesBusinessAction, false);
      expect(value.writesBusinessData, false);
      expect(value.mutatesBudget, false);
      expect(value.persistsCandidate, false);
    });

    test('decision does not call provider or charge cost', () {
      final result = policy.selectRoute(
        candidates: <AgentProviderRouteCandidate>[candidate()],
      );

      expect(result.policyDecisionOnly, true);
      expect(result.invokesProvider, false);
      expect(result.activatesProvider, false);
      expect(result.grantsPermission, false);
      expect(result.consumesApproval, false);
      expect(result.expandsScope, false);
      expect(result.executesBusinessAction, false);
      expect(result.writesBusinessData, false);
      expect(result.chargesCost, false);
      expect(result.mutatesBudget, false);
      expect(result.persistsDecision, false);
    });

    test(
      'circuit state itself has no timer/provider/persistence execution',
      () {
        final state = policy.nextCircuitState(
          providerId: 'provider:free:a',
          currentStatus: AgentProviderCircuitStatus.closed,
          currentConsecutiveFailures: 0,
          callSucceeded: false,
        );

        expect(state.timerImplementedHere, false);
        expect(state.schedulerImplementedHere, false);
        expect(state.persistsState, false);
        expect(state.invokesProvider, false);
        expect(state.executesBusinessAction, false);
      },
    );

    test('policy locks routing order and failover boundaries', () {
      expect(policy.freeOnlineFirstPriority, true);
      expect(policy.localAiOptionalSecondPriority, true);
      expect(policy.paidAiLastEscalation, true);
      expect(policy.paidControlsMustBePreverified, true);
      expect(policy.disabledProviderSkipped, true);
      expect(policy.unhealthyProviderSkipped, true);
      expect(policy.capabilityMismatchSkipped, true);
      expect(policy.openCircuitSkipped, true);
    });

    test('policy locks circuit-breaker and failure isolation', () {
      expect(policy.repeatedFailureOpensCircuit, true);
      expect(policy.circuitPreventsRetryStorm, true);
      expect(policy.successfulCallResetsCircuit, true);
      expect(policy.halfOpenProbeStateSupported, true);
      expect(policy.noProviderMeansAiFailClosed, true);
      expect(policy.coreAppContinuesIfAllProvidersFail, true);
    });

    test('policy cannot auto-enable paid or increase budget', () {
      expect(policy.noAutomaticBudgetIncrease, true);
      expect(policy.noAutomaticPaidEnable, true);
      expect(policy.chargesCost, false);
      expect(policy.mutatesBudget, false);
    });

    test('Phase 59 quality ownership remains separate', () {
      expect(policy.providerQualityEvaluationOwnedHere, false);
      expect(policy.phase59OwnsProviderQualityEvaluator, true);
    });

    test('policy adds no production authority or provider invocation', () {
      expect(policy.invokesProvider, false);
      expect(policy.activatesProvider, false);
      expect(policy.grantsPermission, false);
      expect(policy.consumesApproval, false);
      expect(policy.expandsScope, false);
      expect(policy.executesBusinessAction, false);
      expect(policy.writesBusinessData, false);
      expect(policy.persistsCircuitState, false);
      expect(policy.schedulesCooldown, false);
    });
  });
}

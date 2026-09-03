import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_provider_expansion_contract_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_provider_quality_aggregation_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_provider_quality_comparison_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_provider_quality_signal_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_quality_comparison_candidate.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_quality_comparison_input.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_quality_confidence.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_quality_provider_recommendation.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_quality_cost_tradeoff_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_quality_task_specific_comparison_service.dart';

void main() {
  const AgentProviderQualityCostTradeoffPolicy tradeoffPolicy =
      AgentProviderQualityCostTradeoffPolicy();

  const AgentProviderQualityTaskSpecificComparisonService service =
      AgentProviderQualityTaskSpecificComparisonService();

  const AgentProviderQualityConfidence highConfidence =
      AgentProviderQualityConfidence(
        level: AgentProviderQualityConfidenceLevel.high,
        coveredFamilyCount: 8,
        strongCurrentFamilyCount: 8,
        sufficientFreshFamilyCount: 8,
        staleFamilyCount: 0,
        criticalFamiliesPresent: true,
      );

  AgentProviderQualityProviderRecommendation recommendation({
    required String providerId,
    required String modelReference,
    required String tier,
    String taskType = 'GENERAL_REASONING',
    String recommendation = AgentProviderQualityRecommendation.prefer,
    double score = 90,
  }) {
    return AgentProviderQualityProviderRecommendation(
      providerId: providerId,
      modelReference: modelReference,
      providerTier: tier,
      taskType: taskType,
      recommendation: recommendation,
      weightedScore: score,
      confidence: highConfidence,
      reasonCodes: const <String>['test_quality_recommendation'],
    );
  }

  AgentProviderQualityComparisonCandidate candidate({
    required String providerId,
    required String modelReference,
    String tier = AgentProviderExpansionTier.freeOnline,
    String taskType = 'GENERAL_REASONING',
    String qualityRecommendation = AgentProviderQualityRecommendation.prefer,
    double score = 90,
    bool routingEligible = true,
    bool privacyEligible = true,
    bool capabilityEligible = true,
    bool backendEligible = true,
    bool paidControlsEligible = true,
    double costRs = 0,
  }) {
    return AgentProviderQualityComparisonCandidate(
      recommendation: recommendation(
        providerId: providerId,
        modelReference: modelReference,
        tier: tier,
        taskType: taskType,
        recommendation: qualityRecommendation,
        score: score,
      ),
      routingEligible: routingEligible,
      privacyEligible: privacyEligible,
      capabilityEligible: capabilityEligible,
      backendEligible: backendEligible,
      paidControlsEligible: paidControlsEligible,
      estimatedProviderCostRs: costRs,
    );
  }

  group('Phase 59 Step 1D provider comparison', () {
    test('6 comparison statuses are locked', () {
      expect(AgentProviderQualityComparisonStatus.values.length, 6);
    });

    test('quality floor is before cost', () {
      expect(tradeoffPolicy.qualityFloorBeforeCost, true);
      expect(tradeoffPolicy.costOnlyBreaksNearQualityTie, true);
      expect(tradeoffPolicy.costBonusCapped, true);
    });

    test('free/local billable provider cost must be zero', () {
      expect(tradeoffPolicy.freeLocalBillableCostMustBeZero, true);

      expect(
        () => candidate(
          providerId: 'provider:free:a',
          modelReference: 'model:a',
          costRs: 1,
        ).validateStructure(),
        throwsFormatException,
      );
    });

    test('same-tier stronger quality candidate wins', () {
      final result = service.compare(
        AgentProviderQualityComparisonInput(
          candidates: <AgentProviderQualityComparisonCandidate>[
            candidate(
              providerId: 'provider:free:a',
              modelReference: 'model:a',
              score: 95,
            ),
            candidate(
              providerId: 'provider:free:b',
              modelReference: 'model:b',
              score: 80,
            ),
          ],
        ),
      );

      expect(
        result.status,
        AgentProviderQualityComparisonStatus.preferredWithinTier,
      );
      expect(result.preferredProviderId, 'provider:free:a');
    });

    test('free near-quality tie remains neutral without cost difference', () {
      final result = service.compare(
        AgentProviderQualityComparisonInput(
          candidates: <AgentProviderQualityComparisonCandidate>[
            candidate(
              providerId: 'provider:free:a',
              modelReference: 'model:a',
              score: 91,
            ),
            candidate(
              providerId: 'provider:free:b',
              modelReference: 'model:b',
              score: 90,
            ),
          ],
        ),
      );

      expect(
        result.status,
        AgentProviderQualityComparisonStatus.neutralWithinTier,
      );
      expect(result.hasPreferredCandidate, false);
    });

    test('paid near-quality tie may use cost as capped tie-break', () {
      final result = service.compare(
        AgentProviderQualityComparisonInput(
          candidates: <AgentProviderQualityComparisonCandidate>[
            candidate(
              providerId: 'provider:paid:a',
              modelReference: 'model:a',
              tier: AgentProviderExpansionTier.paidLastEscalation,
              score: 91,
              costRs: 20,
            ),
            candidate(
              providerId: 'provider:paid:b',
              modelReference: 'model:b',
              tier: AgentProviderExpansionTier.paidLastEscalation,
              score: 90,
              costRs: 5,
            ),
          ],
        ),
      );

      expect(
        result.status,
        AgentProviderQualityComparisonStatus.preferredWithinTier,
      );
      expect(result.preferredProviderId, 'provider:paid:b');
    });

    test('large quality gap cannot be overturned by low cost', () {
      final result = service.compare(
        AgentProviderQualityComparisonInput(
          candidates: <AgentProviderQualityComparisonCandidate>[
            candidate(
              providerId: 'provider:paid:quality',
              modelReference: 'model:quality',
              tier: AgentProviderExpansionTier.paidLastEscalation,
              score: 95,
              costRs: 30,
            ),
            candidate(
              providerId: 'provider:paid:cheap',
              modelReference: 'model:cheap',
              tier: AgentProviderExpansionTier.paidLastEscalation,
              score: 75,
              costRs: 1,
            ),
          ],
        ),
      );

      expect(result.preferredProviderId, 'provider:paid:quality');
    });

    test('deprioritized cheap candidate cannot win on cost', () {
      final result = service.compare(
        AgentProviderQualityComparisonInput(
          candidates: <AgentProviderQualityComparisonCandidate>[
            candidate(
              providerId: 'provider:paid:good',
              modelReference: 'model:good',
              tier: AgentProviderExpansionTier.paidLastEscalation,
              score: 88,
              costRs: 20,
            ),
            candidate(
              providerId: 'provider:paid:cheap',
              modelReference: 'model:cheap',
              tier: AgentProviderExpansionTier.paidLastEscalation,
              qualityRecommendation:
                  AgentProviderQualityRecommendation.deprioritize,
              score: 59,
              costRs: 1,
            ),
          ],
        ),
      );

      expect(result.preferredProviderId, 'provider:paid:good');
    });

    test('routing-ineligible candidate cannot win', () {
      final result = service.compare(
        AgentProviderQualityComparisonInput(
          candidates: <AgentProviderQualityComparisonCandidate>[
            candidate(
              providerId: 'provider:free:blocked',
              modelReference: 'model:blocked',
              score: 100,
              routingEligible: false,
            ),
            candidate(
              providerId: 'provider:free:ok',
              modelReference: 'model:ok',
              score: 85,
            ),
          ],
        ),
      );

      expect(result.preferredProviderId, 'provider:free:ok');
    });

    test('privacy-ineligible candidate cannot win', () {
      final result = service.compare(
        AgentProviderQualityComparisonInput(
          candidates: <AgentProviderQualityComparisonCandidate>[
            candidate(
              providerId: 'provider:free:blocked',
              modelReference: 'model:blocked',
              score: 100,
              privacyEligible: false,
            ),
            candidate(
              providerId: 'provider:free:ok',
              modelReference: 'model:ok',
              score: 85,
            ),
          ],
        ),
      );

      expect(result.preferredProviderId, 'provider:free:ok');
    });

    test('capability-ineligible candidate cannot win', () {
      final result = service.compare(
        AgentProviderQualityComparisonInput(
          candidates: <AgentProviderQualityComparisonCandidate>[
            candidate(
              providerId: 'provider:free:blocked',
              modelReference: 'model:blocked',
              score: 100,
              capabilityEligible: false,
            ),
            candidate(
              providerId: 'provider:free:ok',
              modelReference: 'model:ok',
              score: 85,
            ),
          ],
        ),
      );

      expect(result.preferredProviderId, 'provider:free:ok');
    });

    test('backend-ineligible candidate cannot win', () {
      final result = service.compare(
        AgentProviderQualityComparisonInput(
          candidates: <AgentProviderQualityComparisonCandidate>[
            candidate(
              providerId: 'provider:free:blocked',
              modelReference: 'model:blocked',
              score: 100,
              backendEligible: false,
            ),
            candidate(
              providerId: 'provider:free:ok',
              modelReference: 'model:ok',
              score: 85,
            ),
          ],
        ),
      );

      expect(result.preferredProviderId, 'provider:free:ok');
    });

    test('paid-control-ineligible candidate cannot win', () {
      final result = service.compare(
        AgentProviderQualityComparisonInput(
          candidates: <AgentProviderQualityComparisonCandidate>[
            candidate(
              providerId: 'provider:paid:blocked',
              modelReference: 'model:blocked',
              tier: AgentProviderExpansionTier.paidLastEscalation,
              score: 100,
              costRs: 1,
              paidControlsEligible: false,
            ),
            candidate(
              providerId: 'provider:paid:ok',
              modelReference: 'model:ok',
              tier: AgentProviderExpansionTier.paidLastEscalation,
              score: 85,
              costRs: 10,
            ),
          ],
        ),
      );

      expect(result.preferredProviderId, 'provider:paid:ok');
    });

    test('insufficient evidence candidate cannot win', () {
      final result = service.compare(
        AgentProviderQualityComparisonInput(
          candidates: <AgentProviderQualityComparisonCandidate>[
            candidate(
              providerId: 'provider:free:weak',
              modelReference: 'model:weak',
              score: 99,
              qualityRecommendation:
                  AgentProviderQualityRecommendation.insufficientEvidence,
            ),
            candidate(
              providerId: 'provider:free:ok',
              modelReference: 'model:ok',
              score: 85,
            ),
          ],
        ),
      );

      expect(result.preferredProviderId, 'provider:free:ok');
    });

    test('all insufficient evidence returns insufficient status', () {
      final result = service.compare(
        AgentProviderQualityComparisonInput(
          candidates: <AgentProviderQualityComparisonCandidate>[
            candidate(
              providerId: 'provider:free:a',
              modelReference: 'model:a',
              qualityRecommendation:
                  AgentProviderQualityRecommendation.insufficientEvidence,
            ),
            candidate(
              providerId: 'provider:free:b',
              modelReference: 'model:b',
              qualityRecommendation:
                  AgentProviderQualityRecommendation.insufficientEvidence,
            ),
          ],
        ),
      );

      expect(
        result.status,
        AgentProviderQualityComparisonStatus.insufficientEvidence,
      );
    });

    test('same task is required', () {
      final result = service.compare(
        AgentProviderQualityComparisonInput(
          candidates: <AgentProviderQualityComparisonCandidate>[
            candidate(
              providerId: 'provider:free:a',
              modelReference: 'model:a',
              taskType: 'GENERAL_REASONING',
            ),
            candidate(
              providerId: 'provider:free:b',
              modelReference: 'model:b',
              taskType: 'TRANSLATION',
            ),
          ],
        ),
      );

      expect(
        result.status,
        AgentProviderQualityComparisonStatus.blockedInvalidComparison,
      );
    });

    test('cross-tier comparison is blocked', () {
      final input = AgentProviderQualityComparisonInput(
        candidates: <AgentProviderQualityComparisonCandidate>[
          candidate(
            providerId: 'provider:free:a',
            modelReference: 'model:a',
            tier: AgentProviderExpansionTier.freeOnline,
          ),
          candidate(
            providerId: 'provider:paid:a',
            modelReference: 'model:paid',
            tier: AgentProviderExpansionTier.paidLastEscalation,
            costRs: 1,
          ),
        ],
      );

      expect(input.sameTier, false);

      // Service must fail closed rather than rank paid against free.
      final result = service.compare(input);

      expect(
        result.status,
        AgentProviderQualityComparisonStatus.blockedCrossTierComparison,
      );
      expect(result.hasPreferredCandidate, false);
    });

    test('duplicate provider/model candidate is invalid', () {
      final result = service.compare(
        AgentProviderQualityComparisonInput(
          candidates: <AgentProviderQualityComparisonCandidate>[
            candidate(providerId: 'provider:free:a', modelReference: 'model:a'),
            candidate(providerId: 'provider:free:a', modelReference: 'model:a'),
          ],
        ),
      );

      expect(
        result.status,
        AgentProviderQualityComparisonStatus.blockedInvalidComparison,
      );
    });

    test('candidate contains no raw payload and no authority', () {
      final value = candidate(
        providerId: 'provider:free:a',
        modelReference: 'model:a',
      );

      expect(value.containsRawPrompt, false);
      expect(value.containsRawConversation, false);
      expect(value.containsRawProviderResponse, false);
      expect(value.containsPrivatePayload, false);
      expect(value.invokesProvider, false);
      expect(value.mutatesRouting, false);
      expect(value.mutatesBudget, false);
      expect(value.changesProviderState, false);
      expect(value.persistsCandidate, false);
      expect(value.executesBusinessAction, false);
    });

    test('tradeoff policy cannot rescue unsafe/ineligible candidate', () {
      expect(tradeoffPolicy.safetyPrivacyCapabilityEligibilityRequired, true);
      expect(tradeoffPolicy.costCannotRescueIneligibleCandidate, true);
      expect(tradeoffPolicy.costCannotOverrideTierOrder, true);
      expect(tradeoffPolicy.providerInvocationImplementedHere, false);
      expect(tradeoffPolicy.routingMutationImplementedHere, false);
      expect(tradeoffPolicy.budgetMutationImplementedHere, false);
      expect(tradeoffPolicy.persistenceImplementedHere, false);
      expect(tradeoffPolicy.executesBusinessAction, false);
    });

    test('comparison decision cannot override authoritative gates', () {
      final result = service.compare(
        AgentProviderQualityComparisonInput(
          candidates: <AgentProviderQualityComparisonCandidate>[
            candidate(
              providerId: 'provider:free:a',
              modelReference: 'model:a',
              score: 95,
            ),
            candidate(
              providerId: 'provider:free:b',
              modelReference: 'model:b',
              score: 80,
            ),
          ],
        ),
      );

      expect(result.recommendationMetadataOnly, true);
      expect(result.tierPreserving, true);
      expect(result.mayCompareAcrossTiers, false);
      expect(result.mayOverrideFreeLocalPaidOrder, false);
      expect(result.mayOverridePaidAiOnOff, false);
      expect(result.mayOverrideAskBeforePaid, false);
      expect(result.mayOverrideBudgetLimit, false);
      expect(result.mayOverridePrivacyGate, false);
      expect(result.mayOverrideCapabilityGate, false);
      expect(result.mayOverrideCircuitBreaker, false);
      expect(result.mayOverrideBackendBoundary, false);
    });

    test('comparison decision cannot invoke/change/deploy/act', () {
      final result = service.compare(
        AgentProviderQualityComparisonInput(
          candidates: <AgentProviderQualityComparisonCandidate>[
            candidate(
              providerId: 'provider:free:a',
              modelReference: 'model:a',
              score: 95,
            ),
          ],
        ),
      );

      expect(result.invokesProvider, false);
      expect(result.mutatesRouting, false);
      expect(result.enablesProvider, false);
      expect(result.disablesProvider, false);
      expect(result.mutatesBudget, false);
      expect(result.changesSecret, false);
      expect(result.deploysModel, false);
      expect(result.grantsPermission, false);
      expect(result.consumesApproval, false);
      expect(result.executesBusinessAction, false);
      expect(result.persistsDecision, false);
    });

    test('service locks tier-preserving comparison rules', () {
      expect(service.sameTaskComparisonRequired, true);
      expect(service.sameTierComparisonRequired, true);
      expect(service.crossTierQualityRankingForbidden, true);
      expect(service.tierOrderRemainsAuthoritative, true);
      expect(service.phase58EligibilityRequiredBeforeComparison, true);
      expect(service.paidControlsRequiredBeforePaidComparison, true);
      expect(service.insufficientEvidenceCannotWin, true);
      expect(service.ineligibleCandidateCannotWin, true);
      expect(service.qualityFloorBeforeCost, true);
      expect(service.costOnlyBreaksNearTie, true);
      expect(service.costCannotOverrideSafetyOrQualityFloor, true);
    });

    test('service has no provider/routing/budget/deployment authority', () {
      expect(service.providerInvocationImplementedHere, false);
      expect(service.automaticRoutingMutationImplementedHere, false);
      expect(service.providerEnableDisableImplementedHere, false);
      expect(service.budgetMutationImplementedHere, false);
      expect(service.secretMutationImplementedHere, false);
      expect(service.deploymentImplementedHere, false);
      expect(service.persistenceImplementedHere, false);
      expect(service.grantsPermission, false);
      expect(service.consumesApproval, false);
      expect(service.expandsScope, false);
      expect(service.executesBusinessAction, false);
    });

    test('later phase ownership remains separate', () {
      expect(service.phase60CrossAgentSupervisorSeparate, true);
      expect(service.phase61PerformanceDashboardSeparate, true);
      expect(service.phase62VersioningDeploymentSeparate, true);
      expect(service.phase63PrivacyRetentionSeparate, true);
    });
  });
}

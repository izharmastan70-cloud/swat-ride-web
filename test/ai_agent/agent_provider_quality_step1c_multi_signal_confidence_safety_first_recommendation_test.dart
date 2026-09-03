import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_provider_expansion_contract_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_provider_quality_aggregation_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_provider_quality_signal_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_quality_aggregation_input.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_quality_signal.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_quality_multi_signal_aggregator.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_quality_safety_first_recommendation_policy.dart';

void main() {
  const AgentProviderQualityMultiSignalAggregator aggregator =
      AgentProviderQualityMultiSignalAggregator();

  const AgentProviderQualitySafetyFirstRecommendationPolicy
  recommendationPolicy = AgentProviderQualitySafetyFirstRecommendationPolicy();

  AgentProviderQualitySignal signal(
    String family, {
    double score = 90,
    int samples = 150,
    int ageHours = 24,
    bool trusted = true,
    bool privacySafe = true,
    bool hardSafetyViolation = false,
    bool capabilityEligible = true,
    bool privacyEligible = true,
    String providerId = 'provider:free:a',
    String modelReference = 'model_ref:free:a',
    String taskType = 'GENERAL_REASONING',
  }) {
    return AgentProviderQualitySignal(
      signalId: 'quality:$family',
      providerId: providerId,
      modelReference: modelReference,
      providerTier: AgentProviderExpansionTier.freeOnline,
      taskType: taskType,
      family: family,
      source: AgentProviderQualitySignalSource.trustedBackendObserved,
      normalizedScore: score,
      sampleCount: samples,
      ageHours: ageHours,
      trustedObservation: trusted,
      privacySafeMetadata: privacySafe,
      hardSafetyViolation: hardSafetyViolation,
      capabilityEligible: capabilityEligible,
      privacyEligible: privacyEligible,
    );
  }

  List<AgentProviderQualitySignal> allFamilies({
    double defaultScore = 90,
    double? safetyScore,
    double? reliabilityScore,
    double? taskFitScore,
    double? outputQualityScore,
    int samples = 150,
    int ageHours = 24,
  }) {
    return <AgentProviderQualitySignal>[
      signal(
        AgentProviderQualitySignalFamily.reliability,
        score: reliabilityScore ?? defaultScore,
        samples: samples,
        ageHours: ageHours,
      ),
      signal(
        AgentProviderQualitySignalFamily.responsiveness,
        score: defaultScore,
        samples: samples,
        ageHours: ageHours,
      ),
      signal(
        AgentProviderQualitySignalFamily.taskFit,
        score: taskFitScore ?? defaultScore,
        samples: samples,
        ageHours: ageHours,
      ),
      signal(
        AgentProviderQualitySignalFamily.outputQuality,
        score: outputQualityScore ?? defaultScore,
        samples: samples,
        ageHours: ageHours,
      ),
      signal(
        AgentProviderQualitySignalFamily.userFeedback,
        score: defaultScore,
        samples: samples,
        ageHours: ageHours,
      ),
      signal(
        AgentProviderQualitySignalFamily.costEfficiency,
        score: defaultScore,
        samples: samples,
        ageHours: ageHours,
      ),
      signal(
        AgentProviderQualitySignalFamily.stability,
        score: defaultScore,
        samples: samples,
        ageHours: ageHours,
      ),
      signal(
        AgentProviderQualitySignalFamily.safety,
        score: safetyScore ?? defaultScore,
        samples: samples,
        ageHours: ageHours,
      ),
    ];
  }

  group('Phase 59 Step 1C multi-signal aggregation', () {
    test('8 family weights are locked', () {
      expect(
        AgentProviderQualityAggregationPolicyConfig.familyWeights.length,
        8,
      );
    });

    test('family weights sum to 1.0', () {
      final double sum = AgentProviderQualityAggregationPolicyConfig
          .familyWeights
          .values
          .fold<double>(0, (double a, double b) => a + b);

      expect(sum, closeTo(1.0, 0.000001));
    });

    test('4 critical families are locked', () {
      expect(
        AgentProviderQualityAggregationPolicyConfig.criticalFamilies.length,
        4,
      );
    });

    test('3 confidence levels are locked', () {
      expect(AgentProviderQualityConfidenceLevel.values.length, 3);
    });

    test('full strong current evidence produces high confidence', () {
      final snapshot = aggregator.aggregate(
        AgentProviderQualityAggregationInput(signals: allFamilies()),
      );

      expect(
        snapshot.confidence.level,
        AgentProviderQualityConfidenceLevel.high,
      );
      expect(snapshot.confidence.coveredFamilyCount, 8);
      expect(snapshot.confidence.strongCurrentFamilyCount, 8);
      expect(snapshot.hardGateClean, true);
    });

    test('full strong safe quality may recommend prefer', () {
      final snapshot = aggregator.aggregate(
        AgentProviderQualityAggregationInput(
          signals: allFamilies(defaultScore: 92),
        ),
      );

      final result = recommendationPolicy.evaluate(snapshot);

      expect(result.recommendation, AgentProviderQualityRecommendation.prefer);
    });

    test('missing critical safety family becomes insufficient', () {
      final List<AgentProviderQualitySignal> values = allFamilies()
        ..removeWhere(
          (AgentProviderQualitySignal value) =>
              value.family == AgentProviderQualitySignalFamily.safety,
        );

      final snapshot = aggregator.aggregate(
        AgentProviderQualityAggregationInput(signals: values),
      );

      final result = recommendationPolicy.evaluate(snapshot);

      expect(snapshot.criticalFamiliesPresent, false);
      expect(
        result.recommendation,
        AgentProviderQualityRecommendation.insufficientEvidence,
      );
    });

    test('small samples force low confidence', () {
      final snapshot = aggregator.aggregate(
        AgentProviderQualityAggregationInput(signals: allFamilies(samples: 5)),
      );

      expect(
        snapshot.confidence.level,
        AgentProviderQualityConfidenceLevel.low,
      );

      expect(
        recommendationPolicy.evaluate(snapshot).recommendation,
        AgentProviderQualityRecommendation.insufficientEvidence,
      );
    });

    test('aging evidence can reach medium but not high confidence', () {
      final snapshot = aggregator.aggregate(
        AgentProviderQualityAggregationInput(
          signals: allFamilies(ageHours: 300),
        ),
      );

      expect(
        snapshot.confidence.level,
        AgentProviderQualityConfidenceLevel.medium,
      );

      expect(
        recommendationPolicy.evaluate(snapshot).recommendation,
        AgentProviderQualityRecommendation.neutral,
      );
    });

    test('stale evidence forces low confidence', () {
      final snapshot = aggregator.aggregate(
        AgentProviderQualityAggregationInput(
          signals: allFamilies(ageHours: 1000),
        ),
      );

      expect(
        snapshot.confidence.level,
        AgentProviderQualityConfidenceLevel.low,
      );
    });

    test('hard safety violation makes aggregate hard gate unclean', () {
      final List<AgentProviderQualitySignal> values = allFamilies();

      final int index = values.indexWhere(
        (AgentProviderQualitySignal value) =>
            value.family == AgentProviderQualitySignalFamily.safety,
      );

      values[index] = signal(
        AgentProviderQualitySignalFamily.safety,
        score: 100,
        hardSafetyViolation: true,
      );

      final snapshot = aggregator.aggregate(
        AgentProviderQualityAggregationInput(signals: values),
      );

      expect(snapshot.hardGateClean, false);

      expect(
        recommendationPolicy.evaluate(snapshot).recommendation,
        AgentProviderQualityRecommendation.ineligible,
      );
    });

    test('untrusted signal makes aggregate ineligible', () {
      final List<AgentProviderQualitySignal> values = allFamilies();

      values[0] = signal(
        AgentProviderQualitySignalFamily.reliability,
        trusted: false,
      );

      final snapshot = aggregator.aggregate(
        AgentProviderQualityAggregationInput(signals: values),
      );

      expect(snapshot.hardGateClean, false);
      expect(
        recommendationPolicy.evaluate(snapshot).recommendation,
        AgentProviderQualityRecommendation.ineligible,
      );
    });

    test('privacy-ineligible signal makes aggregate ineligible', () {
      final List<AgentProviderQualitySignal> values = allFamilies();

      values[0] = signal(
        AgentProviderQualitySignalFamily.reliability,
        privacyEligible: false,
      );

      final snapshot = aggregator.aggregate(
        AgentProviderQualityAggregationInput(signals: values),
      );

      expect(
        recommendationPolicy.evaluate(snapshot).recommendation,
        AgentProviderQualityRecommendation.ineligible,
      );
    });

    test('capability-ineligible signal makes aggregate ineligible', () {
      final List<AgentProviderQualitySignal> values = allFamilies();

      values[0] = signal(
        AgentProviderQualitySignalFamily.reliability,
        capabilityEligible: false,
      );

      final snapshot = aggregator.aggregate(
        AgentProviderQualityAggregationInput(signals: values),
      );

      expect(
        recommendationPolicy.evaluate(snapshot).recommendation,
        AgentProviderQualityRecommendation.ineligible,
      );
    });

    test('high aggregate cannot prefer below safety floor', () {
      final snapshot = aggregator.aggregate(
        AgentProviderQualityAggregationInput(
          signals: allFamilies(defaultScore: 99, safetyScore: 70),
        ),
      );

      expect(snapshot.weightedScore, greaterThan(85));

      expect(
        recommendationPolicy.evaluate(snapshot).recommendation,
        AgentProviderQualityRecommendation.neutral,
      );
    });

    test('safety below neutral floor deprioritizes', () {
      final snapshot = aggregator.aggregate(
        AgentProviderQualityAggregationInput(
          signals: allFamilies(defaultScore: 95, safetyScore: 40),
        ),
      );

      expect(
        recommendationPolicy.evaluate(snapshot).recommendation,
        AgentProviderQualityRecommendation.deprioritize,
      );
    });

    test('critical reliability floor can cap prefer', () {
      final snapshot = aggregator.aggregate(
        AgentProviderQualityAggregationInput(
          signals: allFamilies(defaultScore: 95, reliabilityScore: 55),
        ),
      );

      expect(
        recommendationPolicy.evaluate(snapshot).recommendation,
        AgentProviderQualityRecommendation.neutral,
      );
    });

    test('low weighted score with confidence may deprioritize', () {
      final snapshot = aggregator.aggregate(
        AgentProviderQualityAggregationInput(
          signals: allFamilies(defaultScore: 50),
        ),
      );

      expect(
        recommendationPolicy.evaluate(snapshot).recommendation,
        AgentProviderQualityRecommendation.deprioritize,
      );
    });

    test('duplicate family input is rejected', () {
      final List<AgentProviderQualitySignal> values = allFamilies();

      values.add(signal(AgentProviderQualitySignalFamily.reliability));

      expect(
        () => AgentProviderQualityAggregationInput(
          signals: values,
        ).validateStructure(),
        throwsFormatException,
      );
    });

    test('mixed provider binding is rejected', () {
      final List<AgentProviderQualitySignal> values = allFamilies();

      values[0] = signal(
        AgentProviderQualitySignalFamily.reliability,
        providerId: 'provider:free:other',
      );

      expect(
        () => AgentProviderQualityAggregationInput(
          signals: values,
        ).validateStructure(),
        throwsFormatException,
      );
    });

    test('aggregation input stores no raw provider payload', () {
      final input = AgentProviderQualityAggregationInput(
        signals: allFamilies(),
      );

      expect(input.containsRawPrompt, false);
      expect(input.containsRawConversation, false);
      expect(input.containsRawProviderResponse, false);
      expect(input.invokesProvider, false);
      expect(input.mutatesRouting, false);
      expect(input.persistsInput, false);
    });

    test('aggregate snapshot is metadata only and has no authority', () {
      final snapshot = aggregator.aggregate(
        AgentProviderQualityAggregationInput(signals: allFamilies()),
      );

      expect(snapshot.metadataOnly, true);
      expect(snapshot.invokesProvider, false);
      expect(snapshot.mutatesRouting, false);
      expect(snapshot.changesProviderState, false);
      expect(snapshot.changesBudget, false);
      expect(snapshot.changesSecret, false);
      expect(snapshot.deploysModel, false);
      expect(snapshot.grantsPermission, false);
      expect(snapshot.consumesApproval, false);
      expect(snapshot.executesBusinessAction, false);
      expect(snapshot.persistsSnapshot, false);
    });

    test('aggregator locks confidence and anti-aggression rules', () {
      expect(aggregator.sameProviderModelTaskBindingRequired, true);
      expect(aggregator.duplicateFamilySignalsForbidden, true);
      expect(aggregator.criticalFamiliesRequiredForStrongRecommendation, true);
      expect(aggregator.highConfidenceRequiresFullCoverage, true);
      expect(aggregator.highConfidenceRequiresStrongCurrentEvidence, true);
      expect(aggregator.staleEvidenceReducesConfidence, true);
      expect(aggregator.hardGateFailureForcesLowConfidence, true);
      expect(aggregator.costEfficiencyWeightLimited, true);
    });

    test('aggregator has no provider/routing/write authority', () {
      expect(aggregator.providerInvocationImplementedHere, false);
      expect(aggregator.routingMutationImplementedHere, false);
      expect(aggregator.providerStateMutationImplementedHere, false);
      expect(aggregator.budgetMutationImplementedHere, false);
      expect(aggregator.persistenceImplementedHere, false);
      expect(aggregator.executesBusinessAction, false);
    });

    test('recommendation cannot override Phase58 gates', () {
      final result = recommendationPolicy.evaluate(
        aggregator.aggregate(
          AgentProviderQualityAggregationInput(signals: allFamilies()),
        ),
      );

      expect(result.recommendationOnly, true);
      expect(result.mayOverrideProviderTierOrder, false);
      expect(result.mayOverridePaidAiOnOff, false);
      expect(result.mayOverrideAskBeforePaid, false);
      expect(result.mayOverrideBudgetLimit, false);
      expect(result.mayOverridePrivacyGate, false);
      expect(result.mayOverrideCapabilityGate, false);
      expect(result.mayOverrideCircuitBreaker, false);
      expect(result.mayOverrideBackendBoundary, false);
    });

    test('recommendation cannot invoke/change/deploy/act', () {
      final result = recommendationPolicy.evaluate(
        aggregator.aggregate(
          AgentProviderQualityAggregationInput(signals: allFamilies()),
        ),
      );

      expect(result.mayInvokeProvider, false);
      expect(result.mayEnableProvider, false);
      expect(result.mayDisableProvider, false);
      expect(result.mayChangeSecret, false);
      expect(result.mayDeployModel, false);
      expect(result.mayMutateBudget, false);
      expect(result.mayGrantPermission, false);
      expect(result.mayConsumeApproval, false);
      expect(result.mayExecuteBusinessAction, false);
      expect(result.persistsRecommendation, false);
    });

    test('safety-first policy preserves authoritative gates', () {
      expect(recommendationPolicy.safetyFirst, true);
      expect(recommendationPolicy.safetyFloorCanCapHighAggregateScore, true);
      expect(recommendationPolicy.criticalPerformanceFloorCanCapPrefer, true);
      expect(
        recommendationPolicy
            .lowConfidenceCannotPreferOrAggressivelyDeprioritize,
        true,
      );
      expect(recommendationPolicy.costEfficiencyCannotOverrideSafety, true);
      expect(recommendationPolicy.freeLocalPaidOrderStillAuthoritative, true);
      expect(recommendationPolicy.paidOnOffStillAuthoritative, true);
      expect(recommendationPolicy.askBeforePaidStillAuthoritative, true);
      expect(recommendationPolicy.budgetStillAuthoritative, true);
      expect(recommendationPolicy.privacyStillAuthoritative, true);
      expect(recommendationPolicy.capabilityStillAuthoritative, true);
      expect(recommendationPolicy.circuitBreakerStillAuthoritative, true);
      expect(recommendationPolicy.backendBoundaryStillAuthoritative, true);
    });

    test('policy adds no invocation, mutation, or authority', () {
      expect(recommendationPolicy.providerInvocationImplementedHere, false);
      expect(recommendationPolicy.providerEnableDisableImplementedHere, false);
      expect(
        recommendationPolicy.automaticRoutingMutationImplementedHere,
        false,
      );
      expect(recommendationPolicy.budgetMutationImplementedHere, false);
      expect(recommendationPolicy.secretMutationImplementedHere, false);
      expect(recommendationPolicy.deploymentImplementedHere, false);
      expect(recommendationPolicy.persistenceImplementedHere, false);
      expect(recommendationPolicy.grantsPermission, false);
      expect(recommendationPolicy.consumesApproval, false);
      expect(recommendationPolicy.expandsScope, false);
      expect(recommendationPolicy.executesBusinessAction, false);
    });

    test('later phase ownership remains separate', () {
      expect(recommendationPolicy.phase60CrossAgentSupervisorSeparate, true);
      expect(recommendationPolicy.phase61PerformanceDashboardSeparate, true);
      expect(recommendationPolicy.phase62VersioningDeploymentSeparate, true);
      expect(recommendationPolicy.phase63PrivacyRetentionSeparate, true);
    });
  });
}

import '../constants/agent_provider_quality_aggregation_constants.dart';
import '../constants/agent_provider_quality_signal_constants.dart';
import '../models/agent_provider_quality_aggregate_snapshot.dart';
import '../models/agent_provider_quality_aggregation_input.dart';
import '../models/agent_provider_quality_confidence.dart';
import '../models/agent_provider_quality_signal.dart';
import 'agent_provider_quality_score_boundary_policy.dart';

class AgentProviderQualityMultiSignalAggregator {
  const AgentProviderQualityMultiSignalAggregator({
    this.scorePolicy = const AgentProviderQualityScoreBoundaryPolicy(),
  });

  final AgentProviderQualityScoreBoundaryPolicy scorePolicy;

  AgentProviderQualityAggregateSnapshot aggregate(
    AgentProviderQualityAggregationInput input,
  ) {
    input.validateStructure();

    final Map<String, double> familyScores = <String, double>{};

    double weightedTotal = 0;
    double weightTotal = 0;

    int strongCurrentCount = 0;
    int sufficientFreshCount = 0;
    int staleCount = 0;

    bool hardGateClean = true;

    for (final AgentProviderQualitySignal signal in input.signals) {
      final assessment = scorePolicy.evaluate(signal);
      final boundary = assessment.boundary;

      familyScores[signal.family] = boundary.score;

      final double weight =
          AgentProviderQualityAggregationPolicyConfig.familyWeights[signal
              .family] ??
          0;

      weightedTotal += boundary.score * weight;
      weightTotal += weight;

      if (!assessment.qualityEligible) {
        hardGateClean = false;
      }

      final bool strongCurrent =
          boundary.sampleSufficiency ==
              AgentProviderQualitySampleSufficiency.strong &&
          boundary.freshness == AgentProviderQualityFreshness.current;

      final bool sufficientFresh =
          boundary.sampleSufficiency !=
              AgentProviderQualitySampleSufficiency.insufficient &&
          boundary.freshness != AgentProviderQualityFreshness.stale;

      if (strongCurrent) {
        strongCurrentCount += 1;
      }

      if (sufficientFresh) {
        sufficientFreshCount += 1;
      }

      if (boundary.freshness == AgentProviderQualityFreshness.stale) {
        staleCount += 1;
      }
    }

    final double weightedScore = weightTotal <= 0
        ? 0
        : weightedTotal / weightTotal;

    final int coverage = familyScores.length;

    String confidenceLevel = AgentProviderQualityConfidenceLevel.low;

    if (hardGateClean &&
        input.criticalFamiliesPresent &&
        coverage >=
            AgentProviderQualityAggregationPolicyConfig
                .highConfidenceFamilyCoverage &&
        strongCurrentCount >=
            AgentProviderQualityAggregationPolicyConfig
                .minHighStrongCurrentFamilies &&
        staleCount == 0) {
      confidenceLevel = AgentProviderQualityConfidenceLevel.high;
    } else if (hardGateClean &&
        input.criticalFamiliesPresent &&
        coverage >=
            AgentProviderQualityAggregationPolicyConfig
                .mediumConfidenceFamilyCoverage &&
        sufficientFreshCount >=
            AgentProviderQualityAggregationPolicyConfig
                .mediumConfidenceFamilyCoverage &&
        staleCount == 0) {
      confidenceLevel = AgentProviderQualityConfidenceLevel.medium;
    }

    final AgentProviderQualityConfidence confidence =
        AgentProviderQualityConfidence(
          level: confidenceLevel,
          coveredFamilyCount: coverage,
          strongCurrentFamilyCount: strongCurrentCount,
          sufficientFreshFamilyCount: sufficientFreshCount,
          staleFamilyCount: staleCount,
          criticalFamiliesPresent: input.criticalFamiliesPresent,
        );

    final AgentProviderQualityAggregateSnapshot
    snapshot = AgentProviderQualityAggregateSnapshot(
      providerId: input.providerId,
      modelReference: input.modelReference,
      providerTier: input.providerTier,
      taskType: input.taskType,
      weightedScore: weightedScore,
      safetyScore: familyScores[AgentProviderQualitySignalFamily.safety] ?? 0,
      reliabilityScore:
          familyScores[AgentProviderQualitySignalFamily.reliability] ?? 0,
      taskFitScore: familyScores[AgentProviderQualitySignalFamily.taskFit] ?? 0,
      outputQualityScore:
          familyScores[AgentProviderQualitySignalFamily.outputQuality] ?? 0,
      hardGateClean: hardGateClean,
      criticalFamiliesPresent: input.criticalFamiliesPresent,
      confidence: confidence,
      familyScores: familyScores,
    );

    snapshot.validateStructure();
    return snapshot;
  }

  bool get sameProviderModelTaskBindingRequired => true;
  bool get duplicateFamilySignalsForbidden => true;
  bool get criticalFamiliesRequiredForStrongRecommendation => true;
  bool get highConfidenceRequiresFullCoverage => true;
  bool get highConfidenceRequiresStrongCurrentEvidence => true;
  bool get staleEvidenceReducesConfidence => true;
  bool get hardGateFailureForcesLowConfidence => true;
  bool get costEfficiencyWeightLimited => true;

  bool get providerInvocationImplementedHere => false;
  bool get routingMutationImplementedHere => false;
  bool get providerStateMutationImplementedHere => false;
  bool get budgetMutationImplementedHere => false;
  bool get persistenceImplementedHere => false;
  bool get executesBusinessAction => false;
}

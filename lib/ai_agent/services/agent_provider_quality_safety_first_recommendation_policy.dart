import '../constants/agent_provider_quality_aggregation_constants.dart';
import '../constants/agent_provider_quality_signal_constants.dart';
import '../models/agent_provider_quality_aggregate_snapshot.dart';
import '../models/agent_provider_quality_provider_recommendation.dart';

class AgentProviderQualitySafetyFirstRecommendationPolicy {
  const AgentProviderQualitySafetyFirstRecommendationPolicy();

  AgentProviderQualityProviderRecommendation evaluate(
    AgentProviderQualityAggregateSnapshot snapshot,
  ) {
    snapshot.validateStructure();

    if (!snapshot.hardGateClean) {
      return _recommend(
        snapshot: snapshot,
        recommendation: AgentProviderQualityRecommendation.ineligible,
        reasons: const <String>[
          'hard_safety_privacy_capability_or_trust_gate_failed',
          'numeric_aggregate_score_cannot_override_hard_gate',
          'fail_closed',
        ],
      );
    }

    if (!snapshot.criticalFamiliesPresent ||
        snapshot.confidence.level == AgentProviderQualityConfidenceLevel.low) {
      return _recommend(
        snapshot: snapshot,
        recommendation: AgentProviderQualityRecommendation.insufficientEvidence,
        reasons: const <String>[
          'critical_family_or_confidence_requirement_not_met',
          'no_aggressive_provider_preference',
        ],
      );
    }

    if (snapshot.safetyScore <
        AgentProviderQualityAggregationPolicyConfig.safetyNeutralFloor) {
      return _recommend(
        snapshot: snapshot,
        recommendation: AgentProviderQualityRecommendation.deprioritize,
        reasons: const <String>[
          'safety_score_below_neutral_floor',
          'safety_outweighs_numeric_aggregate',
          'deprioritize_recommendation_only',
        ],
      );
    }

    final bool criticalPerformanceFloorClean =
        snapshot.reliabilityScore >=
            AgentProviderQualityAggregationPolicyConfig
                .criticalFamilyPreferFloor &&
        snapshot.taskFitScore >=
            AgentProviderQualityAggregationPolicyConfig
                .criticalFamilyPreferFloor &&
        snapshot.outputQualityScore >=
            AgentProviderQualityAggregationPolicyConfig
                .criticalFamilyPreferFloor;

    if (snapshot.weightedScore >=
            AgentProviderQualityLimits.preferScoreThreshold &&
        snapshot.confidence.strongPreferenceAllowed &&
        snapshot.safetyScore >=
            AgentProviderQualityAggregationPolicyConfig.safetyPreferFloor &&
        criticalPerformanceFloorClean) {
      return _recommend(
        snapshot: snapshot,
        recommendation: AgentProviderQualityRecommendation.prefer,
        reasons: const <String>[
          'high_confidence_multi_signal_evidence',
          'safety_floor_clean',
          'critical_performance_floors_clean',
          'provider_preference_recommendation_only',
          'phase58_routing_and_safety_gates_remain_authoritative',
        ],
      );
    }

    if (snapshot.weightedScore <
        AgentProviderQualityLimits.neutralScoreThreshold) {
      return _recommend(
        snapshot: snapshot,
        recommendation: AgentProviderQualityRecommendation.deprioritize,
        reasons: const <String>[
          'sufficient_confidence_below_neutral_score',
          'deprioritize_recommendation_only',
          'cannot_disable_provider_or_change_tier_order',
        ],
      );
    }

    return _recommend(
      snapshot: snapshot,
      recommendation: AgentProviderQualityRecommendation.neutral,
      reasons: <String>[
        if (snapshot.safetyScore <
            AgentProviderQualityAggregationPolicyConfig.safetyPreferFloor)
          'safety_score_caps_prefer_recommendation',
        if (!criticalPerformanceFloorClean)
          'critical_performance_floor_caps_prefer_recommendation',
        if (!snapshot.confidence.strongPreferenceAllowed)
          'confidence_caps_prefer_recommendation',
        'neutral_quality_recommendation_only',
      ],
    );
  }

  AgentProviderQualityProviderRecommendation _recommend({
    required AgentProviderQualityAggregateSnapshot snapshot,
    required String recommendation,
    required List<String> reasons,
  }) {
    final AgentProviderQualityProviderRecommendation result =
        AgentProviderQualityProviderRecommendation(
          providerId: snapshot.providerId,
          modelReference: snapshot.modelReference,
          providerTier: snapshot.providerTier,
          taskType: snapshot.taskType,
          recommendation: recommendation,
          weightedScore: snapshot.weightedScore,
          confidence: snapshot.confidence,
          reasonCodes: reasons,
        );

    result.validateStructure();
    return result;
  }

  bool get safetyFirst => true;
  bool get safetyFloorCanCapHighAggregateScore => true;
  bool get criticalPerformanceFloorCanCapPrefer => true;
  bool get lowConfidenceCannotPreferOrAggressivelyDeprioritize => true;
  bool get costEfficiencyCannotOverrideSafety => true;

  bool get freeLocalPaidOrderStillAuthoritative => true;
  bool get paidOnOffStillAuthoritative => true;
  bool get askBeforePaidStillAuthoritative => true;
  bool get budgetStillAuthoritative => true;
  bool get privacyStillAuthoritative => true;
  bool get capabilityStillAuthoritative => true;
  bool get circuitBreakerStillAuthoritative => true;
  bool get backendBoundaryStillAuthoritative => true;

  bool get providerInvocationImplementedHere => false;
  bool get providerEnableDisableImplementedHere => false;
  bool get automaticRoutingMutationImplementedHere => false;
  bool get budgetMutationImplementedHere => false;
  bool get secretMutationImplementedHere => false;
  bool get deploymentImplementedHere => false;
  bool get persistenceImplementedHere => false;

  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;

  bool get phase60CrossAgentSupervisorSeparate => true;
  bool get phase61PerformanceDashboardSeparate => true;
  bool get phase62VersioningDeploymentSeparate => true;
  bool get phase63PrivacyRetentionSeparate => true;
}

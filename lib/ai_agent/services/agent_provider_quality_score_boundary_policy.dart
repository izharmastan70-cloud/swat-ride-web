import '../constants/agent_provider_quality_signal_constants.dart';
import '../models/agent_provider_quality_sample_window.dart';
import '../models/agent_provider_quality_score_boundary.dart';
import '../models/agent_provider_quality_signal.dart';
import '../models/agent_provider_quality_signal_assessment.dart';
import 'agent_provider_quality_signal_policy.dart';

class AgentProviderQualityScoreBoundaryPolicy {
  const AgentProviderQualityScoreBoundaryPolicy({
    this.signalPolicy = const AgentProviderQualitySignalPolicy(),
  });

  final AgentProviderQualitySignalPolicy signalPolicy;

  AgentProviderQualitySignalAssessment evaluate(
    AgentProviderQualitySignal signal,
  ) {
    try {
      signal.validateStructure();
    } catch (_) {
      return _assessment(
        signalId: signal.signalId,
        recommendation: AgentProviderQualityRecommendation.ineligible,
        score: AgentProviderQualityLimits.minScore,
        sampleSufficiency: AgentProviderQualitySampleSufficiency.insufficient,
        freshness: AgentProviderQualityFreshness.stale,
        qualityEligible: false,
        reasons: const <String>[
          'invalid_quality_signal_metadata',
          'fail_closed',
        ],
      );
    }

    final AgentProviderQualitySampleWindow window = signalPolicy.evaluateWindow(
      signal,
    );

    if (!signalPolicy.trustedAndPrivacySafe(signal)) {
      return _assessment(
        signalId: signal.signalId,
        recommendation: AgentProviderQualityRecommendation.ineligible,
        score: signal.normalizedScore,
        sampleSufficiency: window.sufficiency,
        freshness: window.freshness,
        qualityEligible: false,
        reasons: const <String>[
          'trusted_privacy_capability_safety_gate_failed',
          'numeric_quality_score_cannot_override_hard_gate',
          'fail_closed',
        ],
      );
    }

    if (!window.sufficientForAnyPreference) {
      return _assessment(
        signalId: signal.signalId,
        recommendation: AgentProviderQualityRecommendation.insufficientEvidence,
        score: signal.normalizedScore,
        sampleSufficiency: window.sufficiency,
        freshness: window.freshness,
        qualityEligible: true,
        reasons: const <String>[
          'sample_or_freshness_insufficient',
          'no_strong_provider_preference_change',
        ],
      );
    }

    if (signal.normalizedScore >=
        AgentProviderQualityLimits.preferScoreThreshold) {
      if (!window.sufficientForStrongPreference) {
        return _assessment(
          signalId: signal.signalId,
          recommendation: AgentProviderQualityRecommendation.neutral,
          score: signal.normalizedScore,
          sampleSufficiency: window.sufficiency,
          freshness: window.freshness,
          qualityEligible: true,
          reasons: const <String>[
            'high_score_without_strong_current_evidence',
            'neutral_until_sample_and_freshness_strong',
          ],
        );
      }

      return _assessment(
        signalId: signal.signalId,
        recommendation: AgentProviderQualityRecommendation.prefer,
        score: signal.normalizedScore,
        sampleSufficiency: window.sufficiency,
        freshness: window.freshness,
        qualityEligible: true,
        reasons: const <String>[
          'strong_current_evidence',
          'quality_preference_recommendation_only',
          'phase58_routing_and_safety_gates_still_authoritative',
        ],
      );
    }

    if (signal.normalizedScore >=
        AgentProviderQualityLimits.neutralScoreThreshold) {
      return _assessment(
        signalId: signal.signalId,
        recommendation: AgentProviderQualityRecommendation.neutral,
        score: signal.normalizedScore,
        sampleSufficiency: window.sufficiency,
        freshness: window.freshness,
        qualityEligible: true,
        reasons: const <String>[
          'quality_within_neutral_band',
          'no_aggressive_route_preference',
        ],
      );
    }

    return _assessment(
      signalId: signal.signalId,
      recommendation: AgentProviderQualityRecommendation.deprioritize,
      score: signal.normalizedScore,
      sampleSufficiency: window.sufficiency,
      freshness: window.freshness,
      qualityEligible: true,
      reasons: const <String>[
        'sufficient_fresh_evidence_below_neutral_threshold',
        'deprioritize_recommendation_only',
        'cannot_disable_provider_or_override_tier_order',
      ],
    );
  }

  AgentProviderQualitySignalAssessment _assessment({
    required String signalId,
    required String recommendation,
    required double score,
    required String sampleSufficiency,
    required String freshness,
    required bool qualityEligible,
    required List<String> reasons,
  }) {
    final AgentProviderQualitySignalAssessment assessment =
        AgentProviderQualitySignalAssessment(
          signalId: signalId.trim().isEmpty
              ? 'invalid_quality_signal'
              : signalId,
          boundary: AgentProviderQualityScoreBoundary(
            recommendation: recommendation,
            score: score,
            sampleSufficiency: sampleSufficiency,
            freshness: freshness,
            qualityEligible: qualityEligible,
          ),
          reasonCodes: reasons,
        );

    assessment.validateStructure();
    return assessment;
  }

  bool get qualityRecommendationOnly => true;
  bool get freeLocalPaidOrderStillAuthoritative => true;
  bool get paidOnOffStillAuthoritative => true;
  bool get askBeforePaidStillAuthoritative => true;
  bool get budgetStillAuthoritative => true;
  bool get privacyStillAuthoritative => true;
  bool get capabilityStillAuthoritative => true;
  bool get circuitBreakerStillAuthoritative => true;
  bool get backendBoundaryStillAuthoritative => true;
  bool get safetyAlwaysOutranksQualityScore => true;
  bool get costEfficiencyNeverOutranksSafety => true;

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

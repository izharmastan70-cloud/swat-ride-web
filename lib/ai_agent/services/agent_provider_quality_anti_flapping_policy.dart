import '../constants/agent_provider_quality_history_constants.dart';
import '../constants/agent_provider_quality_signal_constants.dart';
import '../models/agent_provider_quality_history_window.dart';
import '../models/agent_provider_quality_stability_decision.dart';
import 'agent_provider_quality_trend_regression_service.dart';

class AgentProviderQualityAntiFlappingPolicy {
  const AgentProviderQualityAntiFlappingPolicy({
    this.trendService = const AgentProviderQualityTrendRegressionService(),
  });

  final AgentProviderQualityTrendRegressionService trendService;

  AgentProviderQualityStabilityDecision evaluate({
    required AgentProviderQualityHistoryWindow window,
    required String currentRecommendation,
    required String proposedRecommendation,
    required int hoursSinceLastPreferenceChange,
  }) {
    window.validateStructure();

    if (!AgentProviderQualityRecommendation.values.contains(
          currentRecommendation,
        ) ||
        !AgentProviderQualityRecommendation.values.contains(
          proposedRecommendation,
        ) ||
        hoursSinceLastPreferenceChange < 0) {
      throw const FormatException('Invalid anti-flapping policy input.');
    }

    final regression = trendService.detectRegression(window);

    if (!window.points.last.hardGateClean ||
        proposedRecommendation ==
            AgentProviderQualityRecommendation.ineligible) {
      return _decision(
        status: AgentProviderQualityStabilityStatus.failClosedIneligible,
        currentRecommendation: currentRecommendation,
        proposedRecommendation: proposedRecommendation,
        consecutiveProposalCount: _consecutiveTailCount(
          window,
          proposedRecommendation,
        ),
        hoursSinceLastPreferenceChange: hoursSinceLastPreferenceChange,
        reasons: const <String>[
          'hard_gate_or_ineligible_recommendation',
          'fail_closed',
        ],
      );
    }

    if (proposedRecommendation ==
            AgentProviderQualityRecommendation.insufficientEvidence ||
        window.points.length <
            AgentProviderQualityHistoryLimits.minConsistentRecommendations) {
      return _decision(
        status: AgentProviderQualityStabilityStatus.insufficientHistory,
        currentRecommendation: currentRecommendation,
        proposedRecommendation: proposedRecommendation,
        consecutiveProposalCount: _consecutiveTailCount(
          window,
          proposedRecommendation,
        ),
        hoursSinceLastPreferenceChange: hoursSinceLastPreferenceChange,
        reasons: const <String>[
          'insufficient_consistent_evidence',
          'hold_without_aggressive_preference_change',
        ],
      );
    }

    if (proposedRecommendation == currentRecommendation) {
      return _decision(
        status: AgentProviderQualityStabilityStatus.holdCurrentPreference,
        currentRecommendation: currentRecommendation,
        proposedRecommendation: proposedRecommendation,
        consecutiveProposalCount: _consecutiveTailCount(
          window,
          proposedRecommendation,
        ),
        hoursSinceLastPreferenceChange: hoursSinceLastPreferenceChange,
        reasons: const <String>[
          'proposed_recommendation_matches_current',
          'no_preference_change_needed',
        ],
      );
    }

    if (_alternatingTailDetected(window)) {
      return _decision(
        status: AgentProviderQualityStabilityStatus.holdCurrentPreference,
        currentRecommendation: currentRecommendation,
        proposedRecommendation: proposedRecommendation,
        consecutiveProposalCount: _consecutiveTailCount(
          window,
          proposedRecommendation,
        ),
        hoursSinceLastPreferenceChange: hoursSinceLastPreferenceChange,
        reasons: const <String>[
          'alternating_recommendation_pattern_detected',
          'anti_flapping_hold',
        ],
      );
    }

    if (regression.severity ==
            AgentProviderQualityRegressionSeverity.critical ||
        regression.severity ==
            AgentProviderQualityRegressionSeverity.significant) {
      return _decision(
        status: AgentProviderQualityStabilityStatus.holdCurrentPreference,
        currentRecommendation: currentRecommendation,
        proposedRecommendation: proposedRecommendation,
        consecutiveProposalCount: _consecutiveTailCount(
          window,
          proposedRecommendation,
        ),
        hoursSinceLastPreferenceChange: hoursSinceLastPreferenceChange,
        reasons: const <String>[
          'material_quality_regression_detected',
          'hold_preference_change_until_stable',
        ],
      );
    }

    if (hoursSinceLastPreferenceChange <
        AgentProviderQualityHistoryLimits.preferenceChangeCooldownHours) {
      return _decision(
        status: AgentProviderQualityStabilityStatus.holdCurrentPreference,
        currentRecommendation: currentRecommendation,
        proposedRecommendation: proposedRecommendation,
        consecutiveProposalCount: _consecutiveTailCount(
          window,
          proposedRecommendation,
        ),
        hoursSinceLastPreferenceChange: hoursSinceLastPreferenceChange,
        reasons: const <String>[
          'preference_change_cooldown_active',
          'anti_flapping_hold',
        ],
      );
    }

    final int consecutiveCount = _consecutiveTailCount(
      window,
      proposedRecommendation,
    );

    if (consecutiveCount <
        AgentProviderQualityHistoryLimits.minConsistentRecommendations) {
      return _decision(
        status: AgentProviderQualityStabilityStatus.holdCurrentPreference,
        currentRecommendation: currentRecommendation,
        proposedRecommendation: proposedRecommendation,
        consecutiveProposalCount: consecutiveCount,
        hoursSinceLastPreferenceChange: hoursSinceLastPreferenceChange,
        reasons: const <String>[
          'repeated_consistent_recommendation_not_yet_confirmed',
          'anti_flapping_hold',
        ],
      );
    }

    return _decision(
      status: AgentProviderQualityStabilityStatus.allowPreferenceChange,
      currentRecommendation: currentRecommendation,
      proposedRecommendation: proposedRecommendation,
      consecutiveProposalCount: consecutiveCount,
      hoursSinceLastPreferenceChange: hoursSinceLastPreferenceChange,
      reasons: const <String>[
        'consistent_recommendation_confirmed',
        'cooldown_satisfied',
        'no_material_regression_block',
        'preference_change_recommendation_only',
        'phase58_and_phase59_safety_gates_remain_authoritative',
      ],
    );
  }

  int _consecutiveTailCount(
    AgentProviderQualityHistoryWindow window,
    String recommendation,
  ) {
    int count = 0;

    for (final point in window.points.reversed) {
      if (point.recommendation != recommendation) {
        break;
      }

      count += 1;
    }

    return count;
  }

  bool _alternatingTailDetected(AgentProviderQualityHistoryWindow window) {
    if (window.points.length <
        AgentProviderQualityHistoryLimits.alternatingPatternLength) {
      return false;
    }

    final int start =
        window.points.length -
        AgentProviderQualityHistoryLimits.alternatingPatternLength;

    final List<String> tail = window.points
        .skip(start)
        .map((point) => point.recommendation)
        .toList(growable: false);

    return tail[0] == tail[2] && tail[1] == tail[3] && tail[0] != tail[1];
  }

  AgentProviderQualityStabilityDecision _decision({
    required String status,
    required String currentRecommendation,
    required String proposedRecommendation,
    required int consecutiveProposalCount,
    required int hoursSinceLastPreferenceChange,
    required List<String> reasons,
  }) {
    final AgentProviderQualityStabilityDecision decision =
        AgentProviderQualityStabilityDecision(
          status: status,
          currentRecommendation: currentRecommendation,
          proposedRecommendation: proposedRecommendation,
          consecutiveProposalCount: consecutiveProposalCount,
          hoursSinceLastPreferenceChange: hoursSinceLastPreferenceChange,
          reasonCodes: reasons,
        );

    decision.validateStructure();
    return decision;
  }

  bool get repeatedEvidenceRequiredForPreferenceChange => true;
  bool get cooldownRequiredForPreferenceChange => true;
  bool get alternatingRecommendationsAreHeld => true;
  bool get hardGateFailureFailsClosed => true;
  bool get significantRegressionHoldsPreferenceChange => true;
  bool get oneObservationCannotFlipPreference => true;

  bool get freeLocalPaidOrderStillAuthoritative => true;
  bool get paidControlsStillAuthoritative => true;
  bool get privacyCapabilityCircuitBackendStillAuthoritative => true;

  bool get providerInvocationImplementedHere => false;
  bool get automaticRoutingMutationImplementedHere => false;
  bool get providerEnableDisableImplementedHere => false;
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

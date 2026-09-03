import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_provider_expansion_contract_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_provider_quality_aggregation_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_provider_quality_history_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_provider_quality_signal_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_quality_history_point.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_quality_history_window.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_quality_anti_flapping_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_quality_trend_regression_service.dart';

void main() {
  const AgentProviderQualityTrendRegressionService trendService =
      AgentProviderQualityTrendRegressionService();

  const AgentProviderQualityAntiFlappingPolicy antiFlapPolicy =
      AgentProviderQualityAntiFlappingPolicy();

  AgentProviderQualityHistoryPoint point({
    required int hour,
    required String recommendation,
    double score = 90,
    double safety = 95,
    bool hardGateClean = true,
    String providerId = 'provider:free:a',
    String modelReference = 'model:free:a',
    String tier = AgentProviderExpansionTier.freeOnline,
    String taskType = 'GENERAL_REASONING',
  }) {
    return AgentProviderQualityHistoryPoint(
      observationId: 'obs:$hour',
      providerId: providerId,
      modelReference: modelReference,
      providerTier: tier,
      taskType: taskType,
      observedAtEpochHour: hour,
      weightedScore: score,
      safetyScore: safety,
      recommendation: recommendation,
      confidenceLevel: AgentProviderQualityConfidenceLevel.high,
      hardGateClean: hardGateClean,
    );
  }

  AgentProviderQualityHistoryWindow window(
    List<AgentProviderQualityHistoryPoint> points,
  ) {
    return AgentProviderQualityHistoryWindow(points: points);
  }

  group('Phase 59 Step 1E history/trend/regression', () {
    test('4 trend states are locked', () {
      expect(AgentProviderQualityTrend.values.length, 4);
    });

    test('4 regression severity states are locked', () {
      expect(AgentProviderQualityRegressionSeverity.values.length, 4);
    });

    test('4 stability states are locked', () {
      expect(AgentProviderQualityStabilityStatus.values.length, 4);
    });

    test('history requires chronological ordering', () {
      expect(
        () => window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 2,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 1,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
        ]).validateStructure(),
        throwsFormatException,
      );
    });

    test('history requires same provider/model/tier/task binding', () {
      expect(
        () => window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 2,
            recommendation: AgentProviderQualityRecommendation.neutral,
            providerId: 'provider:free:other',
          ),
        ]).validateStructure(),
        throwsFormatException,
      );
    });

    test('duplicate observation ids are rejected', () {
      const AgentProviderQualityHistoryPoint first =
          AgentProviderQualityHistoryPoint(
            observationId: 'same',
            providerId: 'provider:free:a',
            modelReference: 'model:free:a',
            providerTier: AgentProviderExpansionTier.freeOnline,
            taskType: 'GENERAL_REASONING',
            observedAtEpochHour: 1,
            weightedScore: 90,
            safetyScore: 95,
            recommendation: AgentProviderQualityRecommendation.neutral,
            confidenceLevel: AgentProviderQualityConfidenceLevel.high,
            hardGateClean: true,
          );

      const AgentProviderQualityHistoryPoint second =
          AgentProviderQualityHistoryPoint(
            observationId: 'same',
            providerId: 'provider:free:a',
            modelReference: 'model:free:a',
            providerTier: AgentProviderExpansionTier.freeOnline,
            taskType: 'GENERAL_REASONING',
            observedAtEpochHour: 2,
            weightedScore: 91,
            safetyScore: 95,
            recommendation: AgentProviderQualityRecommendation.neutral,
            confidenceLevel: AgentProviderQualityConfidenceLevel.high,
            hardGateClean: true,
          );

      expect(
        () => window(const <AgentProviderQualityHistoryPoint>[
          first,
          second,
        ]).validateStructure(),
        throwsFormatException,
      );
    });

    test('tiny history yields insufficient trend', () {
      final result = trendService.assessTrend(
        window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            score: 80,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 2,
            score: 90,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
        ]),
      );

      expect(result.trend, AgentProviderQualityTrend.insufficientHistory);
    });

    test('improving history is detected', () {
      final result = trendService.assessTrend(
        window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            score: 70,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 2,
            score: 72,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 3,
            score: 88,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
          point(
            hour: 4,
            score: 90,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
        ]),
      );

      expect(result.trend, AgentProviderQualityTrend.improving);
    });

    test('stable history is detected', () {
      final result = trendService.assessTrend(
        window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            score: 88,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 2,
            score: 89,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 3,
            score: 90,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 4,
            score: 89,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
        ]),
      );

      expect(result.trend, AgentProviderQualityTrend.stable);
    });

    test('degrading history is detected', () {
      final result = trendService.assessTrend(
        window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            score: 95,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
          point(
            hour: 2,
            score: 94,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
          point(
            hour: 3,
            score: 75,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 4,
            score: 72,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
        ]),
      );

      expect(result.trend, AgentProviderQualityTrend.degrading);
    });

    test('small score drop creates watch regression', () {
      final result = trendService.detectRegression(
        window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            score: 90,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 2,
            score: 84,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
        ]),
      );

      expect(result.severity, AgentProviderQualityRegressionSeverity.watch);
    });

    test('significant score drop is detected', () {
      final result = trendService.detectRegression(
        window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            score: 90,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 2,
            score: 78,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
        ]),
      );

      expect(
        result.severity,
        AgentProviderQualityRegressionSeverity.significant,
      );
    });

    test('critical score drop is detected', () {
      final result = trendService.detectRegression(
        window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            score: 95,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
          point(
            hour: 2,
            score: 70,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
        ]),
      );

      expect(result.severity, AgentProviderQualityRegressionSeverity.critical);
    });

    test('hard gate deterioration is critical regardless score', () {
      final result = trendService.detectRegression(
        window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            score: 90,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 2,
            score: 95,
            hardGateClean: false,
            recommendation: AgentProviderQualityRecommendation.ineligible,
          ),
        ]),
      );

      expect(result.severity, AgentProviderQualityRegressionSeverity.critical);
      expect(result.hardGateRegression, true);
    });

    test('safety below critical floor is critical', () {
      final result = trendService.detectRegression(
        window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            safety: 90,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 2,
            safety: 55,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
        ]),
      );

      expect(result.severity, AgentProviderQualityRegressionSeverity.critical);
    });

    test('no material drop reports no regression', () {
      final result = trendService.detectRegression(
        window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            score: 90,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 2,
            score: 89,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
        ]),
      );

      expect(result.severity, AgentProviderQualityRegressionSeverity.none);
      expect(result.regressionDetected, false);
    });

    test('history point contains no raw payload or authority', () {
      final value = point(
        hour: 1,
        recommendation: AgentProviderQualityRecommendation.neutral,
      );

      expect(value.containsRawPrompt, false);
      expect(value.containsRawConversation, false);
      expect(value.containsRawProviderResponse, false);
      expect(value.containsPrivatePayload, false);
      expect(value.containsSecret, false);
      expect(value.invokesProvider, false);
      expect(value.mutatesRouting, false);
      expect(value.mutatesBudget, false);
      expect(value.changesProviderState, false);
      expect(value.persistsPoint, false);
      expect(value.executesBusinessAction, false);
    });

    test('trend service has no execution or persistence authority', () {
      expect(trendService.chronologicalHistoryRequired, true);
      expect(trendService.sameProviderModelTierTaskBindingRequired, true);
      expect(trendService.smallHistoryCannotDriveTrend, true);
      expect(trendService.hardGateRegressionIsCritical, true);
      expect(trendService.safetyRegressionIsCritical, true);
      expect(trendService.historicalAverageCannotHideHardGateFailure, true);
      expect(trendService.providerInvocationImplementedHere, false);
      expect(trendService.routingMutationImplementedHere, false);
      expect(trendService.providerStateMutationImplementedHere, false);
      expect(trendService.persistenceImplementedHere, false);
      expect(trendService.executesBusinessAction, false);
    });
  });

  group('Phase 59 Step 1E anti-flapping', () {
    test('one observation cannot flip preference', () {
      final result = antiFlapPolicy.evaluate(
        window: window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
        ]),
        currentRecommendation: AgentProviderQualityRecommendation.neutral,
        proposedRecommendation: AgentProviderQualityRecommendation.prefer,
        hoursSinceLastPreferenceChange: 100,
      );

      expect(
        result.status,
        AgentProviderQualityStabilityStatus.insufficientHistory,
      );
    });

    test('three consistent recommendations plus cooldown allow change', () {
      final result = antiFlapPolicy.evaluate(
        window: window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            score: 88,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
          point(
            hour: 2,
            score: 89,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
          point(
            hour: 3,
            score: 90,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
        ]),
        currentRecommendation: AgentProviderQualityRecommendation.neutral,
        proposedRecommendation: AgentProviderQualityRecommendation.prefer,
        hoursSinceLastPreferenceChange: 30,
      );

      expect(
        result.status,
        AgentProviderQualityStabilityStatus.allowPreferenceChange,
      );
      expect(result.consecutiveProposalCount, 3);
    });

    test('cooldown blocks otherwise consistent preference change', () {
      final result = antiFlapPolicy.evaluate(
        window: window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
          point(
            hour: 2,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
          point(
            hour: 3,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
        ]),
        currentRecommendation: AgentProviderQualityRecommendation.neutral,
        proposedRecommendation: AgentProviderQualityRecommendation.prefer,
        hoursSinceLastPreferenceChange: 3,
      );

      expect(
        result.status,
        AgentProviderQualityStabilityStatus.holdCurrentPreference,
      );
    });

    test('alternating recommendations trigger anti-flapping hold', () {
      final result = antiFlapPolicy.evaluate(
        window: window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
          point(
            hour: 2,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 3,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
          point(
            hour: 4,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
        ]),
        currentRecommendation: AgentProviderQualityRecommendation.prefer,
        proposedRecommendation: AgentProviderQualityRecommendation.neutral,
        hoursSinceLastPreferenceChange: 100,
      );

      expect(
        result.status,
        AgentProviderQualityStabilityStatus.holdCurrentPreference,
      );
    });

    test('hard gate failure fails closed', () {
      final result = antiFlapPolicy.evaluate(
        window: window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
          point(
            hour: 2,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
          point(
            hour: 3,
            hardGateClean: false,
            recommendation: AgentProviderQualityRecommendation.ineligible,
          ),
        ]),
        currentRecommendation: AgentProviderQualityRecommendation.prefer,
        proposedRecommendation: AgentProviderQualityRecommendation.ineligible,
        hoursSinceLastPreferenceChange: 100,
      );

      expect(
        result.status,
        AgentProviderQualityStabilityStatus.failClosedIneligible,
      );
    });

    test('significant regression holds preference change', () {
      final result = antiFlapPolicy.evaluate(
        window: window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            score: 95,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 2,
            score: 90,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
          point(
            hour: 3,
            score: 78,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
        ]),
        currentRecommendation: AgentProviderQualityRecommendation.neutral,
        proposedRecommendation: AgentProviderQualityRecommendation.prefer,
        hoursSinceLastPreferenceChange: 100,
      );

      expect(
        result.status,
        AgentProviderQualityStabilityStatus.holdCurrentPreference,
      );
    });

    test('insufficient-evidence proposal cannot change preference', () {
      final result = antiFlapPolicy.evaluate(
        window: window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            recommendation:
                AgentProviderQualityRecommendation.insufficientEvidence,
          ),
          point(
            hour: 2,
            recommendation:
                AgentProviderQualityRecommendation.insufficientEvidence,
          ),
          point(
            hour: 3,
            recommendation:
                AgentProviderQualityRecommendation.insufficientEvidence,
          ),
        ]),
        currentRecommendation: AgentProviderQualityRecommendation.neutral,
        proposedRecommendation:
            AgentProviderQualityRecommendation.insufficientEvidence,
        hoursSinceLastPreferenceChange: 100,
      );

      expect(
        result.status,
        AgentProviderQualityStabilityStatus.insufficientHistory,
      );
    });

    test('same current/proposed recommendation does not change', () {
      final result = antiFlapPolicy.evaluate(
        window: window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 2,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
          point(
            hour: 3,
            recommendation: AgentProviderQualityRecommendation.neutral,
          ),
        ]),
        currentRecommendation: AgentProviderQualityRecommendation.neutral,
        proposedRecommendation: AgentProviderQualityRecommendation.neutral,
        hoursSinceLastPreferenceChange: 100,
      );

      expect(
        result.status,
        AgentProviderQualityStabilityStatus.holdCurrentPreference,
      );
    });

    test('stability decision has no override or execution authority', () {
      final result = antiFlapPolicy.evaluate(
        window: window(<AgentProviderQualityHistoryPoint>[
          point(
            hour: 1,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
          point(
            hour: 2,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
          point(
            hour: 3,
            recommendation: AgentProviderQualityRecommendation.prefer,
          ),
        ]),
        currentRecommendation: AgentProviderQualityRecommendation.neutral,
        proposedRecommendation: AgentProviderQualityRecommendation.prefer,
        hoursSinceLastPreferenceChange: 30,
      );

      expect(result.metadataOnly, true);
      expect(result.mayOverrideTierOrder, false);
      expect(result.mayOverridePaidControls, false);
      expect(result.mayOverridePrivacyOrCapability, false);
      expect(result.invokesProvider, false);
      expect(result.mutatesRouting, false);
      expect(result.changesProviderState, false);
      expect(result.mutatesBudget, false);
      expect(result.changesSecret, false);
      expect(result.deploysModel, false);
      expect(result.grantsPermission, false);
      expect(result.consumesApproval, false);
      expect(result.executesBusinessAction, false);
      expect(result.persistsDecision, false);
    });

    test('anti-flapping policy locks stability controls', () {
      expect(antiFlapPolicy.repeatedEvidenceRequiredForPreferenceChange, true);
      expect(antiFlapPolicy.cooldownRequiredForPreferenceChange, true);
      expect(antiFlapPolicy.alternatingRecommendationsAreHeld, true);
      expect(antiFlapPolicy.hardGateFailureFailsClosed, true);
      expect(antiFlapPolicy.significantRegressionHoldsPreferenceChange, true);
      expect(antiFlapPolicy.oneObservationCannotFlipPreference, true);
      expect(antiFlapPolicy.freeLocalPaidOrderStillAuthoritative, true);
      expect(antiFlapPolicy.paidControlsStillAuthoritative, true);
      expect(
        antiFlapPolicy.privacyCapabilityCircuitBackendStillAuthoritative,
        true,
      );
    });

    test('anti-flapping policy adds no runtime authority', () {
      expect(antiFlapPolicy.providerInvocationImplementedHere, false);
      expect(antiFlapPolicy.automaticRoutingMutationImplementedHere, false);
      expect(antiFlapPolicy.providerEnableDisableImplementedHere, false);
      expect(antiFlapPolicy.budgetMutationImplementedHere, false);
      expect(antiFlapPolicy.secretMutationImplementedHere, false);
      expect(antiFlapPolicy.deploymentImplementedHere, false);
      expect(antiFlapPolicy.persistenceImplementedHere, false);
      expect(antiFlapPolicy.grantsPermission, false);
      expect(antiFlapPolicy.consumesApproval, false);
      expect(antiFlapPolicy.expandsScope, false);
      expect(antiFlapPolicy.executesBusinessAction, false);
    });

    test('later phase ownership remains separate', () {
      expect(antiFlapPolicy.phase60CrossAgentSupervisorSeparate, true);
      expect(antiFlapPolicy.phase61PerformanceDashboardSeparate, true);
      expect(antiFlapPolicy.phase62VersioningDeploymentSeparate, true);
      expect(antiFlapPolicy.phase63PrivacyRetentionSeparate, true);
    });
  });
}

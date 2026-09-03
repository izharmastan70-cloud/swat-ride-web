import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_performance_aggregation_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_performance_metric_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_performance_scoring_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_comparison_request.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_metric_aggregation_result.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_sample_sufficiency.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_score_input.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_fair_comparison_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_scoring_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_scoring_service.dart';

void main() {
  const AgentPerformanceScoringPolicy scoringPolicy =
      AgentPerformanceScoringPolicy();

  const AgentPerformanceScoringService scoringService =
      AgentPerformanceScoringService();

  const AgentPerformanceFairComparisonPolicy comparisonPolicy =
      AgentPerformanceFairComparisonPolicy();

  AgentPerformanceMetricAggregationResult metric({
    required String metricId,
    required double value,
    String agentId = 'ride_agent',
    String windowId = AgentPerformanceTimeWindowId.last7Days,
    bool strong = true,
    bool sufficient = true,
  }) {
    final String status;

    if (!sufficient) {
      status = AgentPerformanceAggregationStatus.insufficientSample;
    } else if (strong) {
      status = AgentPerformanceAggregationStatus.aggregatedStrong;
    } else {
      status = AgentPerformanceAggregationStatus.aggregatedSufficient;
    }

    return AgentPerformanceMetricAggregationResult(
      status: status,
      agentId: agentId,
      metricId: metricId,
      windowId: windowId,
      aggregatedValue: value,
      totalSampleCount: strong ? 100 : 20,
      sufficiency: AgentPerformanceSampleSufficiency(
        level: !sufficient
            ? AgentPerformanceSampleSufficiencyLevel.insufficient
            : strong
            ? AgentPerformanceSampleSufficiencyLevel.strong
            : AgentPerformanceSampleSufficiencyLevel.sufficient,
        sampleCount: strong ? 100 : 20,
        minimumRequired: 20,
        strongRequired: 100,
      ),
      blockReasonCode: sufficient ? null : 'sample_below_safe_threshold',
    );
  }

  List<AgentPerformanceMetricAggregationResult> sixMetrics({
    String agentId = 'ride_agent',
    String windowId = AgentPerformanceTimeWindowId.last7Days,
    bool strong = true,
    double success = 90,
    double failure = 10,
    double retry = 5,
    double quality = 92,
    double health = 95,
    double feedback = 88,
  }) {
    return <AgentPerformanceMetricAggregationResult>[
      metric(
        metricId: AgentPerformanceMetricId.taskSuccessRate,
        value: success,
        agentId: agentId,
        windowId: windowId,
        strong: strong,
      ),
      metric(
        metricId: AgentPerformanceMetricId.taskFailureRate,
        value: failure,
        agentId: agentId,
        windowId: windowId,
        strong: strong,
      ),
      metric(
        metricId: AgentPerformanceMetricId.retryRate,
        value: retry,
        agentId: agentId,
        windowId: windowId,
        strong: strong,
      ),
      metric(
        metricId: AgentPerformanceMetricId.qualityScore,
        value: quality,
        agentId: agentId,
        windowId: windowId,
        strong: strong,
      ),
      metric(
        metricId: AgentPerformanceMetricId.healthScore,
        value: health,
        agentId: agentId,
        windowId: windowId,
        strong: strong,
      ),
      metric(
        metricId: AgentPerformanceMetricId.feedbackScore,
        value: feedback,
        agentId: agentId,
        windowId: windowId,
        strong: strong,
      ),
    ];
  }

  AgentPerformanceScoreInput scoreInput({
    String agentId = 'ride_agent',
    String cohortKey = 'ride:customer_support:v1',
    String windowId = AgentPerformanceTimeWindowId.last7Days,
    List<AgentPerformanceMetricAggregationResult>? metrics,
  }) {
    return AgentPerformanceScoreInput(
      scoreRequestId: 'score:$agentId',
      agentId: agentId,
      cohortKey: cohortKey,
      windowId: windowId,
      metricResults:
          metrics ?? sixMetrics(agentId: agentId, windowId: windowId),
    );
  }

  group('Phase 61 Step 1D scoring/confidence/fair comparison', () {
    test('6 scorable + 8 context-only cover all 14', () {
      expect(AgentPerformanceScoreContract.scorableMetricIds.length, 6);
      expect(AgentPerformanceScoreContract.contextOnlyMetricIds.length, 8);

      final all = <String>{
        ...AgentPerformanceScoreContract.scorableMetricIds,
        ...AgentPerformanceScoreContract.contextOnlyMetricIds,
      };

      expect(all, AgentPerformanceMetricId.values);
    });

    test('score weights sum to 1.0', () {
      final sum =
          AgentPerformanceScoreWeight.taskSuccessRate +
          AgentPerformanceScoreWeight.taskFailureRate +
          AgentPerformanceScoreWeight.retryRate +
          AgentPerformanceScoreWeight.qualityScore +
          AgentPerformanceScoreWeight.healthScore +
          AgentPerformanceScoreWeight.feedbackScore;

      expect(AgentPerformanceScoreWeight.total, 1.0);
      expect(sum, closeTo(1.0, 0.0000001));
    });

    test('all strong => HIGH-confidence score', () {
      final result = scoringService.score(scoreInput());

      expect(result.hasScore, true);
      expect(result.status, AgentPerformanceScoreStatus.scoredHighConfidence);
      expect(result.confidence, AgentPerformanceScoreConfidence.high);
      expect(result.comparisonEligible, true);
      expect(result.components.length, 6);
    });

    test('all sufficient but not strong => MEDIUM', () {
      final result = scoringService.score(
        scoreInput(metrics: sixMetrics(strong: false)),
      );

      expect(result.hasScore, true);
      expect(result.status, AgentPerformanceScoreStatus.scoredMediumConfidence);
      expect(result.confidence, AgentPerformanceScoreConfidence.medium);
      expect(result.comparisonEligible, false);
    });

    test('missing metric => NO SCORE', () {
      final metrics = sixMetrics()..removeLast();
      final result = scoringService.score(scoreInput(metrics: metrics));

      expect(result.hasScore, false);
      expect(result.status, AgentPerformanceScoreStatus.blockedMissingMetric);
    });

    test('duplicate metric => NO SCORE', () {
      final metrics = sixMetrics()
        ..add(
          metric(metricId: AgentPerformanceMetricId.taskSuccessRate, value: 90),
        );

      final result = scoringService.score(scoreInput(metrics: metrics));

      expect(result.hasScore, false);
      expect(result.status, AgentPerformanceScoreStatus.blockedDuplicateMetric);
    });

    test('insufficient metric => NO SCORE', () {
      final metrics = sixMetrics();
      metrics[0] = metric(
        metricId: AgentPerformanceMetricId.taskSuccessRate,
        value: 90,
        sufficient: false,
        strong: false,
      );

      final result = scoringService.score(scoreInput(metrics: metrics));

      expect(result.hasScore, false);
      expect(result.status, AgentPerformanceScoreStatus.insufficientEvidence);
    });

    test('positive-direction metrics stay positive', () {
      for (final id in <String>[
        AgentPerformanceMetricId.taskSuccessRate,
        AgentPerformanceMetricId.qualityScore,
        AgentPerformanceMetricId.healthScore,
        AgentPerformanceMetricId.feedbackScore,
      ]) {
        final component = scoringPolicy.componentFor(
          metric(metricId: id, value: 80),
        );

        expect(component.inverseDirection, false);
        expect(component.normalizedScore, 80);
      }
    });

    test('failure/retry are inverse', () {
      for (final id in <String>[
        AgentPerformanceMetricId.taskFailureRate,
        AgentPerformanceMetricId.retryRate,
      ]) {
        final component = scoringPolicy.componentFor(
          metric(metricId: id, value: 20),
        );

        expect(component.inverseDirection, true);
        expect(component.normalizedScore, 80);
      }
    });

    test('escalation never enters composite score', () {
      expect(
        () => scoringPolicy.componentFor(
          metric(metricId: AgentPerformanceMetricId.escalationRate, value: 50),
        ),
        throwsFormatException,
      );

      expect(scoringPolicy.escalationRateContextOnly, true);
      expect(scoringPolicy.safeEscalationNeverPenalized, true);
    });

    test('context-only metrics do not change overall score', () {
      final base = sixMetrics();

      final withContext = <AgentPerformanceMetricAggregationResult>[
        ...base,
        metric(metricId: AgentPerformanceMetricId.escalationRate, value: 100),
        metric(
          metricId: AgentPerformanceMetricId.billableCostMinorUnits,
          value: 999,
        ),
        metric(
          metricId: AgentPerformanceMetricId.completedTaskCount,
          value: 500,
        ),
      ];

      final a = scoringService.score(scoreInput(metrics: base));
      final b = scoringService.score(scoreInput(metrics: withContext));

      expect(a.overallScore, b.overallScore);
    });

    test('perfect known inputs produce score 100', () {
      final result = scoringService.score(
        scoreInput(
          metrics: sixMetrics(
            success: 100,
            failure: 0,
            retry: 0,
            quality: 100,
            health: 100,
            feedback: 100,
          ),
        ),
      );

      expect(result.overallScore, closeTo(100, 0.000001));
    });

    test('worst known inputs produce score 0', () {
      final result = scoringService.score(
        scoreInput(
          metrics: sixMetrics(
            success: 0,
            failure: 100,
            retry: 100,
            quality: 0,
            health: 0,
            feedback: 0,
          ),
        ),
      );

      expect(result.overallScore, closeTo(0, 0.000001));
    });

    test('score input is metadata-only/no authority request', () {
      final value = scoreInput();

      expect(value.containsRawPrompt, false);
      expect(value.containsRawConversation, false);
      expect(value.containsPrivatePayload, false);
      expect(value.containsSecret, false);
      expect(value.containsApprovalToken, false);
      expect(value.containsPermissionToken, false);
      expect(value.requestsLeaderboard, false);
      expect(value.requestsDiscipline, false);
      expect(value.requestsRoutingChange, false);
      expect(value.requestsPayChange, false);
      expect(value.requestsAccessChange, false);
      expect(value.requestsBusinessExecution, false);
    });

    test('score result is visibility only', () {
      final result = scoringService.score(scoreInput());

      expect(result.readOnlyVisibilityOnly, true);
      expect(result.statisticalSignificanceClaimed, false);
      expect(result.leaderboardRankAssigned, false);
      expect(result.disciplinaryDecisionMade, false);
      expect(result.routingDecisionMade, false);
      expect(result.payDecisionMade, false);
      expect(result.accessDecisionMade, false);
    });

    test('score result grants no authority/mutation', () {
      final result = scoringService.score(scoreInput());

      expect(result.grantsPermission, false);
      expect(result.createsApproval, false);
      expect(result.expandsScope, false);
      expect(result.assignsRole, false);
      expect(result.grantsOwnerAuthority, false);
      expect(result.authorizesBusinessExecution, false);
      expect(result.executesBusinessAction, false);
      expect(result.mutatesAgentState, false);
      expect(result.mutatesRouting, false);
      expect(result.mutatesProviderState, false);
      expect(result.mutatesBudget, false);
      expect(result.persistsResult, false);
      expect(result.securityAuthorityAlwaysAboveDashboard, true);
    });

    test('comparison requires HIGH confidence', () {
      final first = scoringService.score(scoreInput());
      final second = scoringService.score(
        scoreInput(
          agentId: 'food_agent',
          metrics: sixMetrics(agentId: 'food_agent', strong: false),
        ),
      );

      final result = comparisonPolicy.compare(
        AgentPerformanceComparisonRequest(
          comparisonId: 'compare:1',
          first: first,
          second: second,
        ),
      );

      expect(
        result.status,
        AgentPerformanceComparisonStatus.incomparableLowConfidence,
      );
    });

    test('different cohort is incomparable', () {
      final first = scoringService.score(scoreInput());
      final second = scoringService.score(
        scoreInput(
          agentId: 'food_agent',
          cohortKey: 'food:customer_support:v1',
          metrics: sixMetrics(agentId: 'food_agent'),
        ),
      );

      final result = comparisonPolicy.compare(
        AgentPerformanceComparisonRequest(
          comparisonId: 'compare:2',
          first: first,
          second: second,
        ),
      );

      expect(
        result.status,
        AgentPerformanceComparisonStatus.incomparableDifferentCohort,
      );
    });

    test('different time window is incomparable', () {
      final first = scoringService.score(scoreInput());
      final second = scoringService.score(
        scoreInput(
          agentId: 'food_agent',
          windowId: AgentPerformanceTimeWindowId.last30Days,
          metrics: sixMetrics(
            agentId: 'food_agent',
            windowId: AgentPerformanceTimeWindowId.last30Days,
          ),
        ),
      );

      final result = comparisonPolicy.compare(
        AgentPerformanceComparisonRequest(
          comparisonId: 'compare:3',
          first: first,
          second: second,
        ),
      );

      expect(
        result.status,
        AgentPerformanceComparisonStatus.incomparableDifferentWindow,
      );
    });

    test('same strong cohort/window can compare', () {
      final first = scoringService.score(scoreInput());
      final second = scoringService.score(
        scoreInput(
          agentId: 'food_agent',
          metrics: sixMetrics(
            agentId: 'food_agent',
            success: 80,
            failure: 20,
            retry: 10,
            quality: 80,
            health: 85,
            feedback: 80,
          ),
        ),
      );

      final result = comparisonPolicy.compare(
        AgentPerformanceComparisonRequest(
          comparisonId: 'compare:4',
          first: first,
          second: second,
        ),
      );

      expect(result.status, AgentPerformanceComparisonStatus.comparable);
      expect(result.relation, AgentPerformanceComparisonRelation.firstHigher);
    });

    test('difference <=2 points is SIMILAR', () {
      final first = scoringService.score(
        scoreInput(
          metrics: sixMetrics(
            success: 90,
            failure: 10,
            retry: 10,
            quality: 90,
            health: 90,
            feedback: 90,
          ),
        ),
      );

      final second = scoringService.score(
        scoreInput(
          agentId: 'food_agent',
          metrics: sixMetrics(
            agentId: 'food_agent',
            success: 89,
            failure: 11,
            retry: 10,
            quality: 89,
            health: 90,
            feedback: 90,
          ),
        ),
      );

      final result = comparisonPolicy.compare(
        AgentPerformanceComparisonRequest(
          comparisonId: 'compare:similar',
          first: first,
          second: second,
        ),
      );

      expect(result.relation, AgentPerformanceComparisonRelation.similar);
      expect(
        result.absoluteDifferencePoints!,
        lessThanOrEqualTo(AgentPerformanceScoringLimits.similarMarginPoints),
      );
    });

    test('comparison result has no leaderboard/rank/discipline', () {
      final first = scoringService.score(scoreInput());
      final second = scoringService.score(
        scoreInput(
          agentId: 'food_agent',
          metrics: sixMetrics(agentId: 'food_agent'),
        ),
      );

      final result = comparisonPolicy.compare(
        AgentPerformanceComparisonRequest(
          comparisonId: 'compare:5',
          first: first,
          second: second,
        ),
      );

      expect(result.readOnlyVisibilityOnly, true);
      expect(result.statisticalSignificanceClaimed, false);
      expect(result.globalLeaderboardCreated, false);
      expect(result.permanentRankAssigned, false);
      expect(result.disciplinaryDecisionMade, false);
      expect(result.routingDecisionMade, false);
      expect(result.payDecisionMade, false);
      expect(result.accessDecisionMade, false);
    });

    test('comparison result grants no authority/mutation', () {
      final first = scoringService.score(scoreInput());
      final second = scoringService.score(
        scoreInput(
          agentId: 'food_agent',
          metrics: sixMetrics(agentId: 'food_agent'),
        ),
      );

      final result = comparisonPolicy.compare(
        AgentPerformanceComparisonRequest(
          comparisonId: 'compare:6',
          first: first,
          second: second,
        ),
      );

      expect(result.grantsPermission, false);
      expect(result.createsApproval, false);
      expect(result.authorizesBusinessExecution, false);
      expect(result.executesBusinessAction, false);
      expect(result.mutatesAgentState, false);
      expect(result.mutatesRouting, false);
      expect(result.mutatesBudget, false);
      expect(result.persistsComparison, false);
      expect(result.securityAuthorityAlwaysAboveDashboard, true);
    });

    test('fair comparison policy locks fairness boundaries', () {
      expect(comparisonPolicy.highConfidenceRequiredForComparison, true);
      expect(comparisonPolicy.sameCohortRequired, true);
      expect(comparisonPolicy.sameTimeWindowRequired, true);
      expect(comparisonPolicy.sameScoreContractRequired, true);
      expect(comparisonPolicy.sameMetricSetRequired, true);
      expect(comparisonPolicy.similarWithinTwoPoints, true);
      expect(comparisonPolicy.statisticalSignificanceClaimed, false);
      expect(comparisonPolicy.globalLeaderboardImplementedHere, false);
      expect(comparisonPolicy.permanentRankImplementedHere, false);
      expect(comparisonPolicy.disciplinaryActionImplementedHere, false);
      expect(comparisonPolicy.routingChangeImplementedHere, false);
      expect(comparisonPolicy.payChangeImplementedHere, false);
      expect(comparisonPolicy.accessChangeImplementedHere, false);
      expect(comparisonPolicy.persistenceImplementedHere, false);
    });

    test('scoring service permanent safety boundary', () {
      expect(scoringService.allSixScorableMetricsRequired, true);
      expect(scoringService.contextOnlyMetricsExcludedFromComposite, true);
      expect(scoringService.escalationCannotReducePerformanceScore, true);
      expect(scoringService.missingEvidenceProducesNoScore, true);
      expect(scoringService.insufficientEvidenceProducesNoScore, true);
      expect(scoringService.mediumConfidenceNotComparisonEligible, true);
      expect(scoringService.highConfidenceRequiredForComparison, true);

      expect(scoringService.dashboardScoreReadOnly, true);
      expect(scoringService.scoreIsNotPermissionOrApproval, true);
      expect(scoringService.scoreIsNotRoutingAuthority, true);
      expect(scoringService.scoreIsNotDisciplinaryAuthority, true);
      expect(scoringService.scoreIsNotPayAuthority, true);
      expect(scoringService.scoreIsNotAccessAuthority, true);

      expect(scoringService.firestoreWriteImplementedHere, false);
      expect(scoringService.providerInvocationImplementedHere, false);
      expect(scoringService.routingMutationImplementedHere, false);
      expect(scoringService.agentStateMutationImplementedHere, false);
      expect(scoringService.budgetMutationImplementedHere, false);
      expect(scoringService.persistenceImplementedHere, false);
      expect(scoringService.securityAuthorityAlwaysAboveDashboard, true);
    });

    test('later Phase 61 responsibilities remain separate', () {
      expect(scoringService.step1EReadModelDashboardSeparate, true);
      expect(scoringService.step1FPrivacyFailureIsolationSeparate, true);
      expect(scoringService.step1GFinalCloseoutSeparate, true);
    });
  });
}

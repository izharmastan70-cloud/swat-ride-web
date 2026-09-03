import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_performance_aggregation_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_performance_dashboard_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_performance_metric_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_performance_scoring_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_dashboard_agent_summary.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_dashboard_query.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_metric_aggregation_result.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_sample_sufficiency.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_score_input.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_dashboard_filter_sort_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_dashboard_read_model_service.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_dashboard_summary_builder.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_dashboard_visibility_boundary.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_scoring_service.dart';

void main() {
  const AgentPerformanceScoringService scoringService =
      AgentPerformanceScoringService();
  const AgentPerformanceDashboardSummaryBuilder summaryBuilder =
      AgentPerformanceDashboardSummaryBuilder();
  const AgentPerformanceDashboardFilterSortPolicy filterSortPolicy =
      AgentPerformanceDashboardFilterSortPolicy();
  const AgentPerformanceDashboardReadModelService readModelService =
      AgentPerformanceDashboardReadModelService();
  const AgentPerformanceDashboardVisibilityBoundary visibilityBoundary =
      AgentPerformanceDashboardVisibilityBoundary();

  AgentPerformanceMetricAggregationResult metric({
    required String metricId,
    required double value,
    String agentId = 'ride_agent',
    String windowId = AgentPerformanceTimeWindowId.last7Days,
    bool strong = true,
    bool sufficient = true,
  }) {
    final String status = !sufficient
        ? AgentPerformanceAggregationStatus.insufficientSample
        : strong
        ? AgentPerformanceAggregationStatus.aggregatedStrong
        : AgentPerformanceAggregationStatus.aggregatedSufficient;

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
    required String agentId,
    String windowId = AgentPerformanceTimeWindowId.last7Days,
    bool strong = true,
    double success = 90,
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
        value: 10,
        agentId: agentId,
        windowId: windowId,
        strong: strong,
      ),
      metric(
        metricId: AgentPerformanceMetricId.retryRate,
        value: 5,
        agentId: agentId,
        windowId: windowId,
        strong: strong,
      ),
      metric(
        metricId: AgentPerformanceMetricId.qualityScore,
        value: 92,
        agentId: agentId,
        windowId: windowId,
        strong: strong,
      ),
      metric(
        metricId: AgentPerformanceMetricId.healthScore,
        value: 95,
        agentId: agentId,
        windowId: windowId,
        strong: strong,
      ),
      metric(
        metricId: AgentPerformanceMetricId.feedbackScore,
        value: 88,
        agentId: agentId,
        windowId: windowId,
        strong: strong,
      ),
    ];
  }

  AgentPerformanceDashboardAgentSummary summary({
    required String agentId,
    String cohortKey = 'support:v1',
    String windowId = AgentPerformanceTimeWindowId.last7Days,
    bool strong = true,
    double success = 90,
    List<AgentPerformanceMetricAggregationResult>? context,
  }) {
    final score = scoringService.score(
      AgentPerformanceScoreInput(
        scoreRequestId: 'score:$agentId',
        agentId: agentId,
        cohortKey: cohortKey,
        windowId: windowId,
        metricResults: sixMetrics(
          agentId: agentId,
          windowId: windowId,
          strong: strong,
          success: success,
        ),
      ),
    );

    return summaryBuilder.build(
      score: score,
      contextMetricResults:
          context ??
          <AgentPerformanceMetricAggregationResult>[
            metric(
              metricId: AgentPerformanceMetricId.averageLatencyMs,
              value: 500,
              agentId: agentId,
              windowId: windowId,
            ),
            metric(
              metricId: AgentPerformanceMetricId.escalationRate,
              value: 15,
              agentId: agentId,
              windowId: windowId,
            ),
            metric(
              metricId: AgentPerformanceMetricId.completedTaskCount,
              value: 250,
              agentId: agentId,
              windowId: windowId,
            ),
          ],
    );
  }

  AgentPerformanceDashboardQuery query({
    String? cohortKey,
    String? windowId,
    String? confidence,
    bool onlyWithScore = false,
    bool onlyComparisonEligible = false,
    String sortKey = AgentPerformanceDashboardSortKey.agentId,
    String sortDirection = AgentPerformanceDashboardSortDirection.ascending,
    int limit = 50,
  }) {
    return AgentPerformanceDashboardQuery(
      queryId: 'dashboard:q1',
      cohortKey: cohortKey,
      windowId: windowId,
      confidence: confidence,
      onlyWithScore: onlyWithScore,
      onlyComparisonEligible: onlyComparisonEligible,
      sortKey: sortKey,
      sortDirection: sortDirection,
      limit: limit,
    );
  }

  group('Phase 61 Step 1E read model/summary/filter-sort visibility', () {
    test('dashboard constants are locked', () {
      expect(AgentPerformanceDashboardStatus.values.length, 5);
      expect(AgentPerformanceDashboardSortKey.values.length, 2);
      expect(AgentPerformanceDashboardSortDirection.values.length, 2);
    });

    test('summary combines score and context-only projections', () {
      final value = summary(agentId: 'ride_agent');

      expect(value.hasScore, true);
      expect(value.contextMetricValues.length, 3);
      expect(
        value.contextMetricValues[AgentPerformanceMetricId.escalationRate],
        15,
      );
    });

    test('insufficient context is labeled, not promoted', () {
      final value = summary(
        agentId: 'ride_agent',
        context: <AgentPerformanceMetricAggregationResult>[
          metric(
            metricId: AgentPerformanceMetricId.escalationRate,
            value: 50,
            sufficient: false,
            strong: false,
          ),
        ],
      );

      expect(
        value.contextMetricValues.containsKey(
          AgentPerformanceMetricId.escalationRate,
        ),
        false,
      );
      expect(
        value.insufficientContextMetricIds.contains(
          AgentPerformanceMetricId.escalationRate,
        ),
        true,
      );
    });

    test('scorable metric cannot be injected as context', () {
      final score = scoringService.score(
        AgentPerformanceScoreInput(
          scoreRequestId: 'score:ride_agent',
          agentId: 'ride_agent',
          cohortKey: 'support:v1',
          windowId: AgentPerformanceTimeWindowId.last7Days,
          metricResults: sixMetrics(agentId: 'ride_agent'),
        ),
      );

      expect(
        () => summaryBuilder.build(
          score: score,
          contextMetricResults: <AgentPerformanceMetricAggregationResult>[
            metric(
              metricId: AgentPerformanceMetricId.taskSuccessRate,
              value: 90,
            ),
          ],
        ),
        throwsFormatException,
      );
    });

    test('mismatched context Agent is rejected', () {
      final score = scoringService.score(
        AgentPerformanceScoreInput(
          scoreRequestId: 'score:ride_agent',
          agentId: 'ride_agent',
          cohortKey: 'support:v1',
          windowId: AgentPerformanceTimeWindowId.last7Days,
          metricResults: sixMetrics(agentId: 'ride_agent'),
        ),
      );

      expect(
        () => summaryBuilder.build(
          score: score,
          contextMetricResults: <AgentPerformanceMetricAggregationResult>[
            metric(
              metricId: AgentPerformanceMetricId.escalationRate,
              value: 10,
              agentId: 'food_agent',
            ),
          ],
        ),
        throwsFormatException,
      );
    });

    test('summary is visibility only and never rank', () {
      final value = summary(agentId: 'ride_agent');

      expect(value.readOnlyVisibilityOnly, true);
      expect(value.presentationOrderIsNotRank, true);
      expect(value.globalLeaderboardEntry, false);
      expect(value.permanentRankAssigned, false);
      expect(value.disciplinaryDecisionMade, false);
      expect(value.routingDecisionMade, false);
      expect(value.payDecisionMade, false);
      expect(value.accessDecisionMade, false);
    });

    test('summary contains no raw/private/security tokens', () {
      final value = summary(agentId: 'ride_agent');

      expect(value.containsRawPrompt, false);
      expect(value.containsRawConversation, false);
      expect(value.containsPrivatePayload, false);
      expect(value.containsSecret, false);
      expect(value.containsApprovalToken, false);
      expect(value.containsPermissionToken, false);
    });

    test('summary grants no authority/mutation', () {
      final value = summary(agentId: 'ride_agent');

      expect(value.grantsPermission, false);
      expect(value.createsApproval, false);
      expect(value.expandsScope, false);
      expect(value.assignsRole, false);
      expect(value.grantsOwnerAuthority, false);
      expect(value.authorizesBusinessExecution, false);
      expect(value.executesBusinessAction, false);
      expect(value.mutatesAgentState, false);
      expect(value.mutatesRouting, false);
      expect(value.mutatesBudget, false);
      expect(value.persistsSummary, false);
      expect(value.securityAuthorityAlwaysAboveDashboard, true);
    });

    test('Agent ID sort works without comparison filters', () {
      final model = readModelService.build(
        query: query(),
        summaries: <AgentPerformanceDashboardAgentSummary>[
          summary(agentId: 'ride_agent'),
          summary(agentId: 'food_agent'),
        ],
      );

      expect(model.ready, true);
      expect(model.summaries.first.agentId, 'food_agent');
      expect(model.summaries.last.agentId, 'ride_agent');
    });

    test('descending Agent ID sort is presentation only', () {
      final model = readModelService.build(
        query: query(
          sortDirection: AgentPerformanceDashboardSortDirection.descending,
        ),
        summaries: <AgentPerformanceDashboardAgentSummary>[
          summary(agentId: 'ride_agent'),
          summary(agentId: 'food_agent'),
        ],
      );

      expect(model.summaries.first.agentId, 'ride_agent');
      expect(model.exposesRankNumber, false);
      expect(model.sortOrderIsPresentationOnly, true);
    });

    test('cohort/window/confidence filters work', () {
      final model = readModelService.build(
        query: query(
          cohortKey: 'support:v1',
          windowId: AgentPerformanceTimeWindowId.last7Days,
          confidence: AgentPerformanceScoreConfidence.high,
        ),
        summaries: <AgentPerformanceDashboardAgentSummary>[
          summary(agentId: 'ride_agent', strong: true),
          summary(agentId: 'food_agent', cohortKey: 'food:v1', strong: true),
          summary(agentId: 'cargo_agent', strong: false),
        ],
      );

      expect(model.summaries.length, 1);
      expect(model.summaries.single.agentId, 'ride_agent');
    });

    test('comparison-eligible filter works', () {
      final model = readModelService.build(
        query: query(onlyComparisonEligible: true),
        summaries: <AgentPerformanceDashboardAgentSummary>[
          summary(agentId: 'ride_agent', strong: true),
          summary(agentId: 'food_agent', strong: false),
        ],
      );

      expect(model.summaries.length, 1);
      expect(model.summaries.single.agentId, 'ride_agent');
    });

    test('score sort without fair boundary fails closed', () {
      final model = readModelService.build(
        query: query(
          sortKey: AgentPerformanceDashboardSortKey.score,
          sortDirection: AgentPerformanceDashboardSortDirection.descending,
        ),
        summaries: <AgentPerformanceDashboardAgentSummary>[
          summary(agentId: 'ride_agent'),
          summary(agentId: 'food_agent'),
        ],
      );

      expect(
        model.status,
        AgentPerformanceDashboardStatus.blockedUnfairScoreSort,
      );
    });

    test('fair score sort works but emits no rank', () {
      final model = readModelService.build(
        query: query(
          cohortKey: 'support:v1',
          windowId: AgentPerformanceTimeWindowId.last7Days,
          confidence: AgentPerformanceScoreConfidence.high,
          onlyWithScore: true,
          onlyComparisonEligible: true,
          sortKey: AgentPerformanceDashboardSortKey.score,
          sortDirection: AgentPerformanceDashboardSortDirection.descending,
        ),
        summaries: <AgentPerformanceDashboardAgentSummary>[
          summary(agentId: 'ride_agent', success: 95),
          summary(agentId: 'food_agent', success: 70),
        ],
      );

      expect(model.ready, true);
      expect(model.summaries.first.agentId, 'ride_agent');
      expect(model.exposesRankNumber, false);
      expect(model.globalLeaderboardCreated, false);
      expect(model.permanentRankAssigned, false);
    });

    test('fair score sort filters out MEDIUM confidence', () {
      final model = readModelService.build(
        query: query(
          cohortKey: 'support:v1',
          windowId: AgentPerformanceTimeWindowId.last7Days,
          confidence: AgentPerformanceScoreConfidence.high,
          onlyWithScore: true,
          onlyComparisonEligible: true,
          sortKey: AgentPerformanceDashboardSortKey.score,
          sortDirection: AgentPerformanceDashboardSortDirection.descending,
        ),
        summaries: <AgentPerformanceDashboardAgentSummary>[
          summary(agentId: 'ride_agent', strong: true),
          summary(agentId: 'food_agent', strong: false),
        ],
      );

      expect(model.summaries.length, 1);
      expect(model.summaries.single.agentId, 'ride_agent');
    });

    test('duplicate Agent+cohort+window fails closed', () {
      final same = summary(agentId: 'ride_agent');

      final model = readModelService.build(
        query: query(),
        summaries: <AgentPerformanceDashboardAgentSummary>[same, same],
      );

      expect(
        model.status,
        AgentPerformanceDashboardStatus.blockedDuplicateSummary,
      );
    });

    test('no matches returns EMPTY', () {
      final model = readModelService.build(
        query: query(cohortKey: 'none:v1'),
        summaries: <AgentPerformanceDashboardAgentSummary>[
          summary(agentId: 'ride_agent'),
        ],
      );

      expect(model.empty, true);
      expect(model.summaries, isEmpty);
    });

    test('limit truncates without creating rank', () {
      final model = readModelService.build(
        query: query(limit: 1),
        summaries: <AgentPerformanceDashboardAgentSummary>[
          summary(agentId: 'ride_agent'),
          summary(agentId: 'food_agent'),
        ],
      );

      expect(model.totalMatchedBeforeLimit, 2);
      expect(model.summaries.length, 1);
      expect(model.truncated, true);
      expect(model.exposesRankNumber, false);
    });

    test('invalid query limit fails closed', () {
      final badQuery = AgentPerformanceDashboardQuery(
        queryId: 'dashboard:bad',
        cohortKey: null,
        windowId: null,
        confidence: null,
        onlyWithScore: false,
        onlyComparisonEligible: false,
        sortKey: AgentPerformanceDashboardSortKey.agentId,
        sortDirection: AgentPerformanceDashboardSortDirection.ascending,
        limit: 0,
      );

      final model = readModelService.build(
        query: badQuery,
        summaries: <AgentPerformanceDashboardAgentSummary>[
          summary(agentId: 'ride_agent'),
        ],
      );

      expect(model.status, AgentPerformanceDashboardStatus.blockedInvalidInput);
    });

    test('query requests no leaderboard/discipline/action', () {
      final value = query();

      expect(value.requestsGlobalLeaderboard, false);
      expect(value.requestsPermanentRank, false);
      expect(value.requestsDiscipline, false);
      expect(value.requestsRoutingChange, false);
      expect(value.requestsPayChange, false);
      expect(value.requestsAccessChange, false);
      expect(value.requestsBusinessExecution, false);
    });

    test('filter-sort policy is presentation only', () {
      expect(filterSortPolicy.presentationSortOnly, true);
      expect(filterSortPolicy.scoreSortRequiresFairComparisonBoundary, true);
      expect(filterSortPolicy.scoreSortNeverCreatesPermanentRank, true);
      expect(filterSortPolicy.globalLeaderboardImplementedHere, false);
      expect(filterSortPolicy.disciplineImplementedHere, false);
      expect(filterSortPolicy.routingImplementedHere, false);
      expect(filterSortPolicy.payImplementedHere, false);
      expect(filterSortPolicy.accessImplementedHere, false);
      expect(filterSortPolicy.persistenceImplementedHere, false);
    });

    test('summary builder is read-only/non-authoritative', () {
      expect(summaryBuilder.consumesVerifiedStep1CAnd1DOutputsOnly, true);
      expect(summaryBuilder.contextMetricsRemainContextOnly, true);
      expect(summaryBuilder.insufficientContextEvidenceIsLabeled, true);
      expect(summaryBuilder.readOnlySummaryOnly, true);
      expect(summaryBuilder.createsLeaderboard, false);
      expect(summaryBuilder.assignsRank, false);
      expect(summaryBuilder.createsDisciplinaryDecision, false);
      expect(summaryBuilder.changesRouting, false);
      expect(summaryBuilder.changesPay, false);
      expect(summaryBuilder.changesAccess, false);
      expect(summaryBuilder.persistenceImplementedHere, false);
      expect(summaryBuilder.providerInvocationImplementedHere, false);
    });

    test('read model is visibility only/no decisions', () {
      final model = readModelService.build(
        query: query(),
        summaries: <AgentPerformanceDashboardAgentSummary>[
          summary(agentId: 'ride_agent'),
        ],
      );

      expect(model.readOnlyVisibilityOnly, true);
      expect(model.sortOrderIsPresentationOnly, true);
      expect(model.exposesRankNumber, false);
      expect(model.globalLeaderboardCreated, false);
      expect(model.permanentRankAssigned, false);
      expect(model.disciplinaryDecisionMade, false);
      expect(model.routingDecisionMade, false);
      expect(model.payDecisionMade, false);
      expect(model.accessDecisionMade, false);
    });

    test('read model service permanent safety boundary', () {
      expect(readModelService.readOnlyProjectionOnly, true);
      expect(readModelService.filterSortVisibilityOnly, true);
      expect(readModelService.duplicateSummaryFailsClosed, true);
      expect(readModelService.unfairScoreSortFailsClosed, true);
      expect(readModelService.presentationOrderNeverPermanentRank, true);

      expect(readModelService.dashboardCanGrantPermission, false);
      expect(readModelService.dashboardCanCreateApproval, false);
      expect(readModelService.dashboardCanExpandScope, false);
      expect(readModelService.dashboardCanAssignRole, false);
      expect(readModelService.dashboardCanGrantOwnerAuthority, false);
      expect(readModelService.dashboardCanExecuteBusinessAction, false);
      expect(readModelService.dashboardCanModifySecurityEngine, false);

      expect(readModelService.firestoreWriteImplementedHere, false);
      expect(readModelService.providerInvocationImplementedHere, false);
      expect(readModelService.routingMutationImplementedHere, false);
      expect(readModelService.agentStateMutationImplementedHere, false);
      expect(readModelService.payMutationImplementedHere, false);
      expect(readModelService.accessMutationImplementedHere, false);
      expect(readModelService.budgetMutationImplementedHere, false);
      expect(readModelService.persistenceImplementedHere, false);
      expect(readModelService.securityAuthorityAlwaysAboveDashboard, true);
    });

    test('visibility boundary locks privacy/security/no authority', () {
      expect(visibilityBoundary.dashboardIsVisibilityAnalyticsOnly, true);
      expect(visibilityBoundary.dashboardIsNotSecurityAuthority, true);
      expect(visibilityBoundary.dashboardIsNotAgentAuthority, true);
      expect(visibilityBoundary.dashboardIsNotBusinessExecutionPath, true);
      expect(visibilityBoundary.sortIsPresentationOrderOnly, true);
      expect(visibilityBoundary.scoreSortCannotCreateGlobalLeaderboard, true);
      expect(visibilityBoundary.scoreSortCannotCreatePermanentRank, true);
      expect(visibilityBoundary.dashboardCannotDisciplineAgent, true);
      expect(visibilityBoundary.dashboardCannotChangeRouting, true);
      expect(visibilityBoundary.dashboardCannotChangePay, true);
      expect(visibilityBoundary.dashboardCannotChangeAccess, true);

      expect(visibilityBoundary.dashboardCannotGrantPermission, true);
      expect(visibilityBoundary.dashboardCannotCreateOrConsumeApproval, true);
      expect(visibilityBoundary.dashboardCannotExpandScope, true);
      expect(visibilityBoundary.dashboardCannotAssignPrivilegedRole, true);
      expect(visibilityBoundary.dashboardCannotGrantOwnerAuthority, true);
      expect(visibilityBoundary.dashboardCannotModifySecurityEngine, true);

      expect(visibilityBoundary.rawPromptForbidden, true);
      expect(visibilityBoundary.rawConversationForbidden, true);
      expect(visibilityBoundary.privatePayloadForbidden, true);
      expect(visibilityBoundary.secretForbidden, true);
      expect(visibilityBoundary.authApprovalPermissionTokensForbidden, true);
      expect(visibilityBoundary.securityAuthorityAlwaysAboveDashboard, true);
      expect(visibilityBoundary.persistenceImplementedHere, false);
      expect(visibilityBoundary.providerInvocationImplementedHere, false);
      expect(visibilityBoundary.businessExecutionImplementedHere, false);
    });

    test('later Phase 61 responsibilities remain separate', () {
      expect(readModelService.step1FPrivacyFailureIsolationSeparate, true);
      expect(readModelService.step1GFinalCloseoutSeparate, true);
    });
  });
}

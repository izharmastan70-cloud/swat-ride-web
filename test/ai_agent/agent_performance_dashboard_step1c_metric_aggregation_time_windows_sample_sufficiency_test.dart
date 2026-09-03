import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_performance_aggregation_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_performance_metric_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_metric_aggregation_input.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_metric_observation.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_metric_time_window.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_metric_aggregation_service.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_metric_catalog.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_sample_sufficiency_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_time_window_policy.dart';

void main() {
  const AgentPerformanceTimeWindowPolicy windowPolicy =
      AgentPerformanceTimeWindowPolicy();

  const AgentPerformanceMetricCatalog catalog = AgentPerformanceMetricCatalog();

  const AgentPerformanceSampleSufficiencyPolicy samplePolicy =
      AgentPerformanceSampleSufficiencyPolicy();

  const AgentPerformanceMetricAggregationService service =
      AgentPerformanceMetricAggregationService();

  AgentPerformanceMetricTimeWindow dayWindow() {
    return windowPolicy.buildFixed(
      windowId: AgentPerformanceTimeWindowId.last24Hours,
      endEpochMs: 100000000,
    );
  }

  AgentPerformanceMetricObservation observation({
    required String id,
    String metricId = AgentPerformanceMetricId.taskSuccessRate,
    String agentId = 'ride_agent',
    int start = 20000000,
    int end = 21000000,
    double value = 95,
    int sampleCount = 20,
    bool trusted = true,
    bool minimumNecessary = true,
    bool privacySafe = true,
  }) {
    return AgentPerformanceMetricObservation(
      observationId: id,
      metricId: metricId,
      agentId: agentId,
      sourceReference: 'projection:$id',
      windowStartEpochMs: start,
      windowEndEpochMs: end,
      numericValue: value,
      sampleCount: sampleCount,
      trustedSourceProjection: trusted,
      minimumNecessaryMetadata: minimumNecessary,
      privacySafeProjection: privacySafe,
    );
  }

  AgentPerformanceMetricAggregationInput input({
    String metricId = AgentPerformanceMetricId.taskSuccessRate,
    String agentId = 'ride_agent',
    AgentPerformanceMetricTimeWindow? window,
    List<AgentPerformanceMetricObservation>? observations,
  }) {
    return AgentPerformanceMetricAggregationInput(
      aggregationId: 'aggregation:1',
      agentId: agentId,
      metricId: metricId,
      window: window ?? dayWindow(),
      observations:
          observations ??
          <AgentPerformanceMetricObservation>[observation(id: 'obs:1')],
    );
  }

  group('Phase 61 Step 1C aggregation/time windows/sample sufficiency', () {
    test('5 time-window IDs are locked', () {
      expect(AgentPerformanceTimeWindowId.values.length, 5);
    });

    test('4 sample sufficiency levels are locked', () {
      expect(AgentPerformanceSampleSufficiencyLevel.values.length, 4);
    });

    test('6 aggregation statuses are locked', () {
      expect(AgentPerformanceAggregationStatus.values.length, 6);
    });

    test('LAST_1_HOUR has exact deterministic duration', () {
      final window = windowPolicy.buildFixed(
        windowId: AgentPerformanceTimeWindowId.last1Hour,
        endEpochMs: 10000000,
      );

      expect(window.durationMs, AgentPerformanceAggregationLimits.last1HourMs);
    });

    test('LAST_24_HOURS has exact deterministic duration', () {
      expect(
        dayWindow().durationMs,
        AgentPerformanceAggregationLimits.last24HoursMs,
      );
    });

    test('LAST_7_DAYS has exact deterministic duration', () {
      final window = windowPolicy.buildFixed(
        windowId: AgentPerformanceTimeWindowId.last7Days,
        endEpochMs: 1000000000,
      );

      expect(window.durationMs, AgentPerformanceAggregationLimits.last7DaysMs);
    });

    test('LAST_30_DAYS has exact deterministic duration', () {
      final window = windowPolicy.buildFixed(
        windowId: AgentPerformanceTimeWindowId.last30Days,
        endEpochMs: 3000000000,
      );

      expect(window.durationMs, AgentPerformanceAggregationLimits.last30DaysMs);
    });

    test('CUSTOM window is accepted within 90 days', () {
      final window = windowPolicy.buildCustom(
        startEpochMs: 1000,
        endEpochMs: 1000 + AgentPerformanceAggregationLimits.maxCustomWindowMs,
      );

      expect(window.windowId, AgentPerformanceTimeWindowId.custom);
    });

    test('CUSTOM above 90 days is rejected', () {
      expect(
        () => windowPolicy.buildCustom(
          startEpochMs: 1000,
          endEpochMs:
              1001 + AgentPerformanceAggregationLimits.maxCustomWindowMs,
        ),
        throwsFormatException,
      );
    });

    test('fixed window with wrong duration is rejected', () {
      const window = AgentPerformanceMetricTimeWindow(
        windowId: AgentPerformanceTimeWindowId.last1Hour,
        startEpochMs: 1000,
        endEpochMs: 2000,
      );

      expect(window.validateStructure, throwsFormatException);
    });

    test('time windows use caller-supplied deterministic time', () {
      final window = dayWindow();

      expect(window.callerSuppliedDeterministicTime, true);
      expect(window.usesHiddenWallClock, false);
      expect(window.readOnlyWindow, true);

      expect(windowPolicy.deterministicCallerSuppliedEpochOnly, true);
      expect(windowPolicy.hiddenDateTimeNowUsage, false);
      expect(windowPolicy.customWindowBounded, true);
      expect(windowPolicy.timeWindowChangesAuthority, false);
    });

    test('empty observations produce NO_DATA', () {
      final result = service.aggregate(
        input(observations: const <AgentPerformanceMetricObservation>[]),
      );

      expect(result.status, AgentPerformanceAggregationStatus.noData);
      expect(result.aggregatedValue, isNull);
      expect(result.totalSampleCount, 0);
    });

    test('duplicate observation IDs fail closed', () {
      final result = service.aggregate(
        input(
          observations: <AgentPerformanceMetricObservation>[
            observation(id: 'obs:same', start: 20000000, end: 21000000),
            observation(id: 'obs:same', start: 22000000, end: 23000000),
          ],
        ),
      );

      expect(
        result.status,
        AgentPerformanceAggregationStatus.blockedInvalidInput,
      );
    });

    test('wrong Agent observation fails closed', () {
      final result = service.aggregate(
        input(
          observations: <AgentPerformanceMetricObservation>[
            observation(id: 'obs:1', agentId: 'food_agent'),
          ],
        ),
      );

      expect(
        result.status,
        AgentPerformanceAggregationStatus.blockedInvalidInput,
      );
    });

    test('wrong metric observation fails closed', () {
      final result = service.aggregate(
        input(
          observations: <AgentPerformanceMetricObservation>[
            observation(
              id: 'obs:1',
              metricId: AgentPerformanceMetricId.taskFailureRate,
            ),
          ],
        ),
      );

      expect(
        result.status,
        AgentPerformanceAggregationStatus.blockedInvalidInput,
      );
    });

    test('observation outside requested window fails closed', () {
      final result = service.aggregate(
        input(
          observations: <AgentPerformanceMetricObservation>[
            observation(id: 'obs:1', start: 1, end: 2),
          ],
        ),
      );

      expect(
        result.status,
        AgentPerformanceAggregationStatus.blockedInvalidInput,
      );
    });

    test('overlapping observations fail closed', () {
      final result = service.aggregate(
        input(
          observations: <AgentPerformanceMetricObservation>[
            observation(id: 'obs:1', start: 20000000, end: 22000000),
            observation(id: 'obs:2', start: 21000000, end: 23000000),
          ],
        ),
      );

      expect(
        result.status,
        AgentPerformanceAggregationStatus.blockedInvalidInput,
      );
    });

    test('Step 1B untrusted observation is blocked', () {
      final result = service.aggregate(
        input(
          observations: <AgentPerformanceMetricObservation>[
            observation(id: 'obs:1', trusted: false),
          ],
        ),
      );

      expect(
        result.status,
        AgentPerformanceAggregationStatus.blockedUnsafeObservation,
      );
    });

    test('Step 1B privacy-unsafe observation is blocked', () {
      final result = service.aggregate(
        input(
          observations: <AgentPerformanceMetricObservation>[
            observation(id: 'obs:1', privacySafe: false),
          ],
        ),
      );

      expect(
        result.status,
        AgentPerformanceAggregationStatus.blockedUnsafeObservation,
      );
    });

    test('RATE uses sample-weighted average', () {
      final result = service.aggregate(
        input(
          observations: <AgentPerformanceMetricObservation>[
            observation(
              id: 'obs:1',
              start: 20000000,
              end: 21000000,
              value: 80,
              sampleCount: 20,
            ),
            observation(
              id: 'obs:2',
              start: 22000000,
              end: 23000000,
              value: 100,
              sampleCount: 20,
            ),
          ],
        ),
      );

      expect(result.aggregatedValue, 90);
      expect(result.totalSampleCount, 40);
      expect(
        result.status,
        AgentPerformanceAggregationStatus.aggregatedSufficient,
      );
    });

    test('AVERAGE latency uses sample-weighted average', () {
      final result = service.aggregate(
        input(
          metricId: AgentPerformanceMetricId.averageLatencyMs,
          observations: <AgentPerformanceMetricObservation>[
            observation(
              id: 'obs:1',
              metricId: AgentPerformanceMetricId.averageLatencyMs,
              start: 20000000,
              end: 21000000,
              value: 100,
              sampleCount: 20,
            ),
            observation(
              id: 'obs:2',
              metricId: AgentPerformanceMetricId.averageLatencyMs,
              start: 22000000,
              end: 23000000,
              value: 300,
              sampleCount: 20,
            ),
          ],
        ),
      );

      expect(result.aggregatedValue, 200);
      expect(result.totalSampleCount, 40);
    });

    test('SUM completed tasks adds values safely', () {
      final result = service.aggregate(
        input(
          metricId: AgentPerformanceMetricId.completedTaskCount,
          observations: <AgentPerformanceMetricObservation>[
            observation(
              id: 'obs:1',
              metricId: AgentPerformanceMetricId.completedTaskCount,
              start: 20000000,
              end: 21000000,
              value: 10,
              sampleCount: 10,
            ),
            observation(
              id: 'obs:2',
              metricId: AgentPerformanceMetricId.completedTaskCount,
              start: 22000000,
              end: 23000000,
              value: 15,
              sampleCount: 15,
            ),
          ],
        ),
      );

      expect(result.aggregatedValue, 25);
      expect(result.totalSampleCount, 25);
      expect(result.status, AgentPerformanceAggregationStatus.aggregatedStrong);
    });

    test('LATEST health chooses latest observation only', () {
      final result = service.aggregate(
        input(
          metricId: AgentPerformanceMetricId.healthScore,
          observations: <AgentPerformanceMetricObservation>[
            observation(
              id: 'obs:1',
              metricId: AgentPerformanceMetricId.healthScore,
              start: 20000000,
              end: 21000000,
              value: 60,
              sampleCount: 5,
            ),
            observation(
              id: 'obs:2',
              metricId: AgentPerformanceMetricId.healthScore,
              start: 22000000,
              end: 23000000,
              value: 92,
              sampleCount: 5,
            ),
          ],
        ),
      );

      expect(result.aggregatedValue, 92);
      expect(result.totalSampleCount, 5);
      expect(result.status, AgentPerformanceAggregationStatus.aggregatedStrong);
    });

    test('RATE sample 19 is insufficient', () {
      final result = service.aggregate(
        input(
          observations: <AgentPerformanceMetricObservation>[
            observation(id: 'obs:1', sampleCount: 19),
          ],
        ),
      );

      expect(
        result.status,
        AgentPerformanceAggregationStatus.insufficientSample,
      );
      expect(result.sufficientForLaterInterpretation, false);
    });

    test('RATE sample 20 is sufficient', () {
      final result = service.aggregate(
        input(
          observations: <AgentPerformanceMetricObservation>[
            observation(id: 'obs:1', sampleCount: 20),
          ],
        ),
      );

      expect(
        result.status,
        AgentPerformanceAggregationStatus.aggregatedSufficient,
      );
      expect(result.sufficientForLaterInterpretation, true);
    });

    test('RATE sample 100 is strong', () {
      final result = service.aggregate(
        input(
          observations: <AgentPerformanceMetricObservation>[
            observation(id: 'obs:1', sampleCount: 100),
          ],
        ),
      );

      expect(result.status, AgentPerformanceAggregationStatus.aggregatedStrong);
      expect(result.strongEvidence, true);
    });

    test('SUM sample 1 is sufficient', () {
      final result = service.aggregate(
        input(
          metricId: AgentPerformanceMetricId.completedTaskCount,
          observations: <AgentPerformanceMetricObservation>[
            observation(
              id: 'obs:1',
              metricId: AgentPerformanceMetricId.completedTaskCount,
              value: 1,
              sampleCount: 1,
            ),
          ],
        ),
      );

      expect(
        result.status,
        AgentPerformanceAggregationStatus.aggregatedSufficient,
      );
    });

    test('SUM sample 20 is strong', () {
      final descriptor = catalog.findById(
        AgentPerformanceMetricId.completedTaskCount,
      )!;

      final sufficiency = samplePolicy.assess(
        descriptor: descriptor,
        sampleCount: 20,
      );

      expect(sufficiency.level, AgentPerformanceSampleSufficiencyLevel.strong);
    });

    test('LATEST sample 1 is sufficient', () {
      final descriptor = catalog.findById(
        AgentPerformanceMetricId.healthScore,
      )!;

      final sufficiency = samplePolicy.assess(
        descriptor: descriptor,
        sampleCount: 1,
      );

      expect(
        sufficiency.level,
        AgentPerformanceSampleSufficiencyLevel.sufficient,
      );
    });

    test('LATEST sample 5 is strong', () {
      final descriptor = catalog.findById(
        AgentPerformanceMetricId.healthScore,
      )!;

      final sufficiency = samplePolicy.assess(
        descriptor: descriptor,
        sampleCount: 5,
      );

      expect(sufficiency.level, AgentPerformanceSampleSufficiencyLevel.strong);
    });

    test('zero-sample RATE returns NO_DATA', () {
      final result = service.aggregate(
        input(
          observations: <AgentPerformanceMetricObservation>[
            observation(id: 'obs:1', sampleCount: 0),
          ],
        ),
      );

      expect(result.status, AgentPerformanceAggregationStatus.noData);
      expect(result.aggregatedValue, isNull);
    });

    test('invalid Step 1B metric value is blocked before aggregation', () {
      final result = service.aggregate(
        input(
          observations: <AgentPerformanceMetricObservation>[
            observation(id: 'obs:1', value: 101),
          ],
        ),
      );

      expect(
        result.status,
        AgentPerformanceAggregationStatus.blockedUnsafeObservation,
      );
    });

    test('aggregation input remains metadata-only/no authority', () {
      final value = input();

      expect(value.containsRawPrompt, false);
      expect(value.containsRawConversation, false);
      expect(value.containsPrivatePayload, false);
      expect(value.containsSecret, false);
      expect(value.containsApprovalToken, false);
      expect(value.containsPermissionToken, false);
      expect(value.requestsScoringAuthority, false);
      expect(value.requestsAgentMutation, false);
      expect(value.requestsBusinessExecution, false);
    });

    test('sample sufficiency never creates authority/discipline', () {
      final descriptor = catalog.findById(
        AgentPerformanceMetricId.taskSuccessRate,
      )!;

      final value = samplePolicy.assess(
        descriptor: descriptor,
        sampleCount: 100,
      );

      expect(value.mayCreatePerformanceAuthority, false);
      expect(value.mayDisciplineAgent, false);
      expect(value.mayChangeRouting, false);
      expect(value.mayChangeProvider, false);
    });

    test('sample policy thresholds are permanently locked', () {
      expect(samplePolicy.rateAverageMinimum20, true);
      expect(samplePolicy.rateAverageStrong100, true);
      expect(samplePolicy.sumMinimum1, true);
      expect(samplePolicy.sumStrong20, true);
      expect(samplePolicy.latestMinimum1, true);
      expect(samplePolicy.latestStrong5, true);
      expect(samplePolicy.insufficientSampleCanCreateComparativeClaim, false);
      expect(samplePolicy.sampleEvidenceCanGrantAuthority, false);
      expect(samplePolicy.sampleEvidenceCanDisciplineAgent, false);
    });

    test('aggregation result is visibility only/no score/ranking', () {
      final result = service.aggregate(input());

      expect(result.readOnlyVisibilityOnly, true);
      expect(result.performanceScoreAssignedHere, false);
      expect(result.agentRankingAssignedHere, false);
      expect(result.disciplinaryDecisionMadeHere, false);
      expect(result.securityAuthorityAlwaysAboveDashboard, true);
    });

    test('aggregation result grants no authority/mutation', () {
      final result = service.aggregate(input());

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
    });

    test('aggregation service reuses Step 1B and does not score', () {
      expect(service.reusesStep1BReadOnlyBoundary, true);
      expect(service.deterministicAggregationOnly, true);
      expect(service.overlappingObservationsForbidden, true);
      expect(service.insufficientSamplesCannotBecomeComparativeClaim, true);

      expect(service.performanceScoringImplementedHere, false);
      expect(service.agentRankingImplementedHere, false);
      expect(service.disciplinaryActionImplementedHere, false);
    });

    test('aggregation service has no authority/execution/write path', () {
      expect(service.dashboardCanGrantPermission, false);
      expect(service.dashboardCanCreateApproval, false);
      expect(service.dashboardCanExpandScope, false);
      expect(service.dashboardCanAssignRole, false);
      expect(service.dashboardCanExecuteBusinessAction, false);
      expect(service.dashboardCanModifySecurityEngine, false);

      expect(service.firestoreWriteImplementedHere, false);
      expect(service.providerInvocationImplementedHere, false);
      expect(service.routingMutationImplementedHere, false);
      expect(service.agentStateMutationImplementedHere, false);
      expect(service.providerStateMutationImplementedHere, false);
      expect(service.budgetMutationImplementedHere, false);
      expect(service.persistenceImplementedHere, false);

      expect(service.securityAuthorityAlwaysAboveDashboard, true);
    });

    test('later Phase 61 responsibilities remain separate', () {
      expect(service.step1DPerformanceScoringSeparate, true);
      expect(service.step1EReadModelDashboardSeparate, true);
      expect(service.step1FPrivacyFailureIsolationSeparate, true);
      expect(service.step1GFinalCloseoutSeparate, true);
    });
  });
}

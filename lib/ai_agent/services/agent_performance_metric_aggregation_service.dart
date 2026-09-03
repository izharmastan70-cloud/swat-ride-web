import '../constants/agent_performance_aggregation_constants.dart';
import '../constants/agent_performance_metric_constants.dart';
import '../models/agent_performance_metric_aggregation_input.dart';
import '../models/agent_performance_metric_aggregation_result.dart';
import '../models/agent_performance_metric_descriptor.dart';
import '../models/agent_performance_metric_observation.dart';
import '../models/agent_performance_sample_sufficiency.dart';
import 'agent_performance_metric_catalog.dart';
import 'agent_performance_read_only_boundary_service.dart';
import 'agent_performance_sample_sufficiency_policy.dart';

class AgentPerformanceMetricAggregationService {
  const AgentPerformanceMetricAggregationService({
    this.catalog = const AgentPerformanceMetricCatalog(),
    this.boundary = const AgentPerformanceReadOnlyBoundaryService(),
    this.samplePolicy = const AgentPerformanceSampleSufficiencyPolicy(),
  });

  final AgentPerformanceMetricCatalog catalog;
  final AgentPerformanceReadOnlyBoundaryService boundary;
  final AgentPerformanceSampleSufficiencyPolicy samplePolicy;

  AgentPerformanceMetricAggregationResult aggregate(
    AgentPerformanceMetricAggregationInput input,
  ) {
    try {
      input.validateStructure();
    } catch (_) {
      return _blockedInvalid(input);
    }

    final AgentPerformanceMetricDescriptor? descriptor = catalog.findById(
      input.metricId,
    );

    if (descriptor == null) {
      return _blockedInvalid(input);
    }

    if (input.observations.isEmpty) {
      final AgentPerformanceSampleSufficiency sufficiency = samplePolicy.assess(
        descriptor: descriptor,
        sampleCount: 0,
      );

      return _result(
        status: AgentPerformanceAggregationStatus.noData,
        input: input,
        value: null,
        sampleCount: 0,
        sufficiency: sufficiency,
        blockReasonCode: 'no_observations',
      );
    }

    for (final AgentPerformanceMetricObservation observation
        in input.observations) {
      final decision = boundary.evaluate(observation);

      if (!decision.acceptedForDashboard) {
        final AgentPerformanceSampleSufficiency sufficiency = samplePolicy
            .assess(descriptor: descriptor, sampleCount: 0);

        return _result(
          status: AgentPerformanceAggregationStatus.blockedUnsafeObservation,
          input: input,
          value: null,
          sampleCount: 0,
          sufficiency: sufficiency,
          blockReasonCode: 'step1b_boundary_${decision.status.toLowerCase()}',
        );
      }
    }

    final ({double? value, int sampleCount}) aggregated = _aggregateAccepted(
      descriptor: descriptor,
      observations: input.observations,
    );

    final AgentPerformanceSampleSufficiency sufficiency = samplePolicy.assess(
      descriptor: descriptor,
      sampleCount: aggregated.sampleCount,
    );

    if (aggregated.value == null ||
        sufficiency.level == AgentPerformanceSampleSufficiencyLevel.none) {
      return _result(
        status: AgentPerformanceAggregationStatus.noData,
        input: input,
        value: null,
        sampleCount: aggregated.sampleCount,
        sufficiency: sufficiency,
        blockReasonCode: 'no_usable_samples',
      );
    }

    if (!sufficiency.sufficientForInterpretation) {
      return _result(
        status: AgentPerformanceAggregationStatus.insufficientSample,
        input: input,
        value: aggregated.value,
        sampleCount: aggregated.sampleCount,
        sufficiency: sufficiency,
        blockReasonCode: 'sample_below_safe_threshold',
      );
    }

    return _result(
      status: sufficiency.strongEvidence
          ? AgentPerformanceAggregationStatus.aggregatedStrong
          : AgentPerformanceAggregationStatus.aggregatedSufficient,
      input: input,
      value: aggregated.value,
      sampleCount: aggregated.sampleCount,
      sufficiency: sufficiency,
      blockReasonCode: null,
    );
  }

  ({double? value, int sampleCount}) _aggregateAccepted({
    required AgentPerformanceMetricDescriptor descriptor,
    required List<AgentPerformanceMetricObservation> observations,
  }) {
    switch (descriptor.aggregation) {
      case AgentPerformanceMetricAggregation.rate:
      case AgentPerformanceMetricAggregation.average:
        int totalSamples = 0;
        double weightedTotal = 0;

        for (final AgentPerformanceMetricObservation observation
            in observations) {
          if (observation.sampleCount <= 0) {
            continue;
          }

          totalSamples += observation.sampleCount;
          weightedTotal += observation.numericValue * observation.sampleCount;
        }

        if (totalSamples == 0) {
          return (value: null, sampleCount: 0);
        }

        return (value: weightedTotal / totalSamples, sampleCount: totalSamples);

      case AgentPerformanceMetricAggregation.sum:
        double total = 0;
        int totalSamples = 0;

        for (final AgentPerformanceMetricObservation observation
            in observations) {
          total += observation.numericValue;
          totalSamples += observation.sampleCount;
        }

        return (value: total, sampleCount: totalSamples);

      case AgentPerformanceMetricAggregation.latest:
        AgentPerformanceMetricObservation latest = observations.first;

        for (final AgentPerformanceMetricObservation observation
            in observations.skip(1)) {
          if (observation.windowEndEpochMs > latest.windowEndEpochMs) {
            latest = observation;
          }
        }

        return (value: latest.numericValue, sampleCount: latest.sampleCount);
    }

    return (value: null, sampleCount: 0);
  }

  AgentPerformanceMetricAggregationResult _blockedInvalid(
    AgentPerformanceMetricAggregationInput input,
  ) {
    const AgentPerformanceSampleSufficiency sufficiency =
        AgentPerformanceSampleSufficiency(
          level: AgentPerformanceSampleSufficiencyLevel.none,
          sampleCount: 0,
          minimumRequired: 1,
          strongRequired: 1,
        );

    return _result(
      status: AgentPerformanceAggregationStatus.blockedInvalidInput,
      input: input,
      value: null,
      sampleCount: 0,
      sufficiency: sufficiency,
      blockReasonCode: 'invalid_aggregation_input',
    );
  }

  AgentPerformanceMetricAggregationResult _result({
    required String status,
    required AgentPerformanceMetricAggregationInput input,
    required double? value,
    required int sampleCount,
    required AgentPerformanceSampleSufficiency sufficiency,
    required String? blockReasonCode,
  }) {
    final AgentPerformanceMetricAggregationResult result =
        AgentPerformanceMetricAggregationResult(
          status: status,
          agentId: input.agentId,
          metricId: input.metricId,
          windowId: input.window.windowId,
          aggregatedValue: value,
          totalSampleCount: sampleCount,
          sufficiency: sufficiency,
          blockReasonCode: blockReasonCode,
        );

    result.validateStructure();
    return result;
  }

  bool get reusesStep1BReadOnlyBoundary => true;
  bool get deterministicAggregationOnly => true;
  bool get overlappingObservationsForbidden => true;
  bool get insufficientSamplesCannotBecomeComparativeClaim => true;

  bool get performanceScoringImplementedHere => false;
  bool get agentRankingImplementedHere => false;
  bool get disciplinaryActionImplementedHere => false;

  bool get dashboardCanGrantPermission => false;
  bool get dashboardCanCreateApproval => false;
  bool get dashboardCanExpandScope => false;
  bool get dashboardCanAssignRole => false;
  bool get dashboardCanExecuteBusinessAction => false;
  bool get dashboardCanModifySecurityEngine => false;

  bool get firestoreWriteImplementedHere => false;
  bool get providerInvocationImplementedHere => false;
  bool get routingMutationImplementedHere => false;
  bool get agentStateMutationImplementedHere => false;
  bool get providerStateMutationImplementedHere => false;
  bool get budgetMutationImplementedHere => false;
  bool get persistenceImplementedHere => false;

  bool get securityAuthorityAlwaysAboveDashboard => true;

  bool get step1DPerformanceScoringSeparate => true;
  bool get step1EReadModelDashboardSeparate => true;
  bool get step1FPrivacyFailureIsolationSeparate => true;
  bool get step1GFinalCloseoutSeparate => true;
}

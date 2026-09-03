import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_performance_metric_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_metric_contract.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_metric_descriptor.dart';
import 'package:swat_ride/ai_agent/models/agent_performance_metric_observation.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_metric_catalog.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_metric_safety_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_performance_read_only_boundary_service.dart';

void main() {
  const AgentPerformanceMetricContract contract =
      AgentPerformanceMetricContract();

  const AgentPerformanceMetricCatalog catalog = AgentPerformanceMetricCatalog();

  const AgentPerformanceMetricSafetyPolicy safetyPolicy =
      AgentPerformanceMetricSafetyPolicy();

  const AgentPerformanceReadOnlyBoundaryService boundary =
      AgentPerformanceReadOnlyBoundaryService();

  AgentPerformanceMetricObservation observation({
    String metricId = AgentPerformanceMetricId.taskSuccessRate,
    double value = 95,
    int sampleCount = 20,
    bool trusted = true,
    bool minimumNecessary = true,
    bool privacySafe = true,
  }) {
    return AgentPerformanceMetricObservation(
      observationId: 'obs:1',
      metricId: metricId,
      agentId: 'ride_agent',
      sourceReference: 'audit_projection:1',
      windowStartEpochMs: 1000,
      windowEndEpochMs: 2000,
      numericValue: value,
      sampleCount: sampleCount,
      trustedSourceProjection: trusted,
      minimumNecessaryMetadata: minimumNecessary,
      privacySafeProjection: privacySafe,
    );
  }

  group('Phase 61 Step 1B metric contract/safe catalog/read-only boundary', () {
    test('14 performance metric IDs are locked', () {
      expect(AgentPerformanceMetricId.values.length, 14);
    });

    test('10 metric families are locked', () {
      expect(AgentPerformanceMetricFamily.values.length, 10);
    });

    test('5 metric units are locked', () {
      expect(AgentPerformanceMetricUnit.values.length, 5);
    });

    test('4 aggregation types are locked', () {
      expect(AgentPerformanceMetricAggregation.values.length, 4);
    });

    test('6 observation statuses are locked', () {
      expect(AgentPerformanceMetricObservationStatus.values.length, 6);
    });

    test('catalog contains exactly all 14 metric IDs', () {
      expect(catalog.descriptors.length, 14);

      final ids = catalog.descriptors.map((value) => value.metricId).toSet();

      expect(ids, AgentPerformanceMetricId.values);
    });

    test('catalog descriptors are structurally valid', () {
      for (final AgentPerformanceMetricDescriptor descriptor
          in catalog.descriptors) {
        descriptor.validateStructure();
        expect(descriptor.readOnly, true);
        expect(descriptor.dashboardVisibilityOnly, true);
        expect(descriptor.minimumNecessaryMetadataOnly, true);
        expect(descriptor.trustedProjectionRequired, true);
      }
    });

    test('success metric is reliability percentage/rate', () {
      final descriptor = catalog.findById(
        AgentPerformanceMetricId.taskSuccessRate,
      );

      expect(descriptor, isNotNull);
      expect(descriptor!.family, AgentPerformanceMetricFamily.reliability);
      expect(descriptor.unit, AgentPerformanceMetricUnit.percentage);
      expect(descriptor.aggregation, AgentPerformanceMetricAggregation.rate);
    });

    test('latency metric is responsiveness milliseconds/average', () {
      final descriptor = catalog.findById(
        AgentPerformanceMetricId.averageLatencyMs,
      );

      expect(descriptor, isNotNull);
      expect(descriptor!.family, AgentPerformanceMetricFamily.responsiveness);
      expect(descriptor.unit, AgentPerformanceMetricUnit.milliseconds);
      expect(descriptor.aggregation, AgentPerformanceMetricAggregation.average);
    });

    test('cost metric uses minor currency units/sum', () {
      final descriptor = catalog.findById(
        AgentPerformanceMetricId.billableCostMinorUnits,
      );

      expect(descriptor, isNotNull);
      expect(descriptor!.family, AgentPerformanceMetricFamily.cost);
      expect(descriptor.unit, AgentPerformanceMetricUnit.minorCurrencyUnits);
      expect(descriptor.aggregation, AgentPerformanceMetricAggregation.sum);
    });

    test('quality/health/feedback use safe score unit', () {
      for (final id in <String>[
        AgentPerformanceMetricId.qualityScore,
        AgentPerformanceMetricId.healthScore,
        AgentPerformanceMetricId.feedbackScore,
      ]) {
        final descriptor = catalog.findById(id);
        expect(descriptor, isNotNull);
        expect(descriptor!.unit, AgentPerformanceMetricUnit.score0To100);
      }
    });

    test('valid trusted observation is accepted read-only', () {
      final decision = boundary.evaluate(observation());

      expect(
        decision.status,
        AgentPerformanceMetricObservationStatus.acceptedReadOnly,
      );
      expect(decision.acceptedForDashboard, true);
      expect(decision.readOnlyVisibilityOnly, true);
    });

    test('untrusted source is blocked', () {
      final decision = boundary.evaluate(observation(trusted: false));

      expect(
        decision.status,
        AgentPerformanceMetricObservationStatus.blockedUntrustedSource,
      );
      expect(decision.acceptedForDashboard, false);
    });

    test('non-minimized metadata is blocked', () {
      final decision = boundary.evaluate(observation(minimumNecessary: false));

      expect(
        decision.status,
        AgentPerformanceMetricObservationStatus.blockedPrivacyUnsafe,
      );
    });

    test('privacy-unsafe projection is blocked', () {
      final decision = boundary.evaluate(observation(privacySafe: false));

      expect(
        decision.status,
        AgentPerformanceMetricObservationStatus.blockedPrivacyUnsafe,
      );
    });

    test('negative percentage is blocked', () {
      final decision = boundary.evaluate(observation(value: -1));

      expect(
        decision.status,
        AgentPerformanceMetricObservationStatus.blockedInvalidValue,
      );
    });

    test('percentage above 100 is blocked', () {
      final decision = boundary.evaluate(observation(value: 101));

      expect(
        decision.status,
        AgentPerformanceMetricObservationStatus.blockedInvalidValue,
      );
    });

    test('quality score above 100 is blocked', () {
      final decision = boundary.evaluate(
        observation(
          metricId: AgentPerformanceMetricId.qualityScore,
          value: 101,
        ),
      );

      expect(
        decision.status,
        AgentPerformanceMetricObservationStatus.blockedInvalidValue,
      );
    });

    test('latency above one-day safety ceiling is blocked', () {
      final decision = boundary.evaluate(
        observation(
          metricId: AgentPerformanceMetricId.averageLatencyMs,
          value: 86400001,
        ),
      );

      expect(
        decision.status,
        AgentPerformanceMetricObservationStatus.blockedInvalidValue,
      );
    });

    test('valid count-like metric is accepted', () {
      final decision = boundary.evaluate(
        observation(
          metricId: AgentPerformanceMetricId.completedTaskCount,
          value: 500,
        ),
      );

      expect(decision.acceptedForDashboard, true);
    });

    test('valid cost metric is accepted', () {
      final decision = boundary.evaluate(
        observation(
          metricId: AgentPerformanceMetricId.billableCostMinorUnits,
          value: 2500,
        ),
      );

      expect(decision.acceptedForDashboard, true);
    });

    test('invalid observation time window fails closed', () {
      final value = AgentPerformanceMetricObservation(
        observationId: 'obs:1',
        metricId: AgentPerformanceMetricId.taskSuccessRate,
        agentId: 'ride_agent',
        sourceReference: 'audit_projection:1',
        windowStartEpochMs: 2000,
        windowEndEpochMs: 1000,
        numericValue: 95,
        sampleCount: 20,
        trustedSourceProjection: true,
        minimumNecessaryMetadata: true,
        privacySafeProjection: true,
      );

      final decision = boundary.evaluate(value);

      expect(
        decision.status,
        AgentPerformanceMetricObservationStatus.blockedInvalidMetadata,
      );
    });

    test('observation is metadata-only and has no authority', () {
      final value = observation();

      expect(value.containsRawPrompt, false);
      expect(value.containsRawConversation, false);
      expect(value.containsRawProviderResponse, false);
      expect(value.containsPrivatePayload, false);
      expect(value.containsSecret, false);
      expect(value.containsAuthToken, false);
      expect(value.containsApprovalToken, false);
      expect(value.containsPermissionToken, false);

      expect(value.grantsPermission, false);
      expect(value.createsApproval, false);
      expect(value.authorizesExecution, false);
      expect(value.executesBusinessAction, false);
      expect(value.mutatesAgentState, false);
      expect(value.persistsObservation, false);
    });

    test('descriptor forbids raw/private/security payloads', () {
      final descriptor = catalog.descriptors.first;

      expect(descriptor.rawPromptAllowed, false);
      expect(descriptor.rawConversationAllowed, false);
      expect(descriptor.rawProviderResponseAllowed, false);
      expect(descriptor.privatePayloadAllowed, false);
      expect(descriptor.secretAllowed, false);
      expect(descriptor.authTokenAllowed, false);
      expect(descriptor.approvalTokenAllowed, false);
      expect(descriptor.permissionTokenAllowed, false);
    });

    test('descriptor grants no business/security authority', () {
      final descriptor = catalog.descriptors.first;

      expect(descriptor.grantsPermission, false);
      expect(descriptor.createsApproval, false);
      expect(descriptor.expandsScope, false);
      expect(descriptor.assignsRole, false);
      expect(descriptor.grantsOwnerAuthority, false);
      expect(descriptor.authorizesBusinessExecution, false);
      expect(descriptor.executesBusinessAction, false);
      expect(descriptor.mutatesAgentState, false);
      expect(descriptor.mutatesRouting, false);
      expect(descriptor.mutatesBudget, false);
      expect(descriptor.persistsMetric, false);
    });

    test('contract locks read-only/minimum necessary behavior', () {
      expect(contract.dashboardReadOnly, true);
      expect(contract.visibilityAnalyticsOnly, true);
      expect(contract.existingSignalReuseRequired, true);
      expect(contract.duplicateTelemetryEngineForbidden, true);
      expect(contract.trustedSourceProjectionRequired, true);
      expect(contract.minimumNecessaryMetadataRequired, true);
      expect(contract.privacySafeProjectionRequired, true);
      expect(contract.catalogMetricCount, 14);
    });

    test('contract forbids raw/private/security data', () {
      expect(contract.rawPromptForbidden, true);
      expect(contract.rawConversationForbidden, true);
      expect(contract.rawProviderResponseForbidden, true);
      expect(contract.privatePayloadForbidden, true);
      expect(contract.secretForbidden, true);
      expect(contract.authTokenForbidden, true);
      expect(contract.approvalTokenForbidden, true);
      expect(contract.permissionTokenForbidden, true);
    });

    test('contract grants no authority or mutations', () {
      expect(contract.dashboardCanGrantPermission, false);
      expect(contract.dashboardCanCreateApproval, false);
      expect(contract.dashboardCanConsumeApproval, false);
      expect(contract.dashboardCanExpandScope, false);
      expect(contract.dashboardCanAssignRole, false);
      expect(contract.dashboardCanGrantOwnerAuthority, false);
      expect(contract.dashboardCanExecuteBusinessAction, false);
      expect(contract.dashboardCanModifySecurityEngine, false);
      expect(contract.dashboardCanMutateRouting, false);
      expect(contract.dashboardCanMutateAgentState, false);
      expect(contract.dashboardCanMutateBudget, false);
      expect(contract.securityAuthorityAlwaysAboveDashboard, true);
    });

    test('catalog reuses existing signals and adds no execution', () {
      expect(catalog.reusesExistingSignals, true);
      expect(catalog.createsDuplicateTelemetryEngine, false);
      expect(catalog.readOnlyCatalog, true);
      expect(catalog.catalogContainsRawPayload, false);
      expect(catalog.catalogContainsSecrets, false);
      expect(catalog.persistenceImplementedHere, false);
      expect(catalog.providerInvocationImplementedHere, false);
      expect(catalog.businessExecutionImplementedHere, false);
    });

    test('safety policy accepted means visibility only', () {
      expect(safetyPolicy.acceptedMeansVisibilityOnly, true);
      expect(safetyPolicy.acceptedMeansExecutionAuthorized, false);
      expect(safetyPolicy.trustedSourceRequired, true);
      expect(safetyPolicy.minimumNecessaryMetadataRequired, true);
      expect(safetyPolicy.privacySafeProjectionRequired, true);
    });

    test('safety policy cannot use raw/provider authority', () {
      expect(safetyPolicy.rawPromptMayInfluenceDashboardDirectly, false);
      expect(safetyPolicy.rawConversationMayInfluenceDashboardDirectly, false);
      expect(safetyPolicy.providerResponseMayGrantMetricAuthority, false);
    });

    test('safety policy cannot grant/execute/mutate', () {
      expect(safetyPolicy.grantsPermission, false);
      expect(safetyPolicy.createsApproval, false);
      expect(safetyPolicy.grantsOwnerAuthority, false);
      expect(safetyPolicy.executesBusinessAction, false);
      expect(safetyPolicy.persistenceImplementedHere, false);
      expect(safetyPolicy.routingMutationImplementedHere, false);
      expect(safetyPolicy.agentStateMutationImplementedHere, false);
    });

    test('boundary decision never authorizes execution', () {
      final decision = boundary.evaluate(observation());

      expect(decision.authorizesExecution, false);
      expect(decision.grantsPermission, false);
      expect(decision.createsApproval, false);
      expect(decision.expandsScope, false);
      expect(decision.assignsRole, false);
      expect(decision.grantsOwnerAuthority, false);
      expect(decision.executesBusinessAction, false);
      expect(decision.mutatesAgentState, false);
      expect(decision.mutatesRouting, false);
      expect(decision.mutatesBudget, false);
      expect(decision.persistsDecision, false);
    });

    test('boundary service permanent security locks', () {
      expect(boundary.dashboardReadOnly, true);
      expect(boundary.visibilityAnalyticsOnly, true);
      expect(boundary.existingSignalReuseRequired, true);
      expect(boundary.securityAuthorityAlwaysAboveDashboard, true);

      expect(boundary.dashboardCanGrantPermission, false);
      expect(boundary.dashboardCanCreateApproval, false);
      expect(boundary.dashboardCanConsumeApproval, false);
      expect(boundary.dashboardCanExpandScope, false);
      expect(boundary.dashboardCanAssignRole, false);
      expect(boundary.dashboardCanGrantOwnerAuthority, false);
      expect(boundary.dashboardCanExecuteBusinessAction, false);
      expect(boundary.dashboardCanModifySecurityEngine, false);

      expect(boundary.firestoreWriteImplementedHere, false);
      expect(boundary.providerInvocationImplementedHere, false);
      expect(boundary.routingMutationImplementedHere, false);
      expect(boundary.agentStateMutationImplementedHere, false);
      expect(boundary.budgetMutationImplementedHere, false);
      expect(boundary.persistenceImplementedHere, false);
    });

    test('later Phase 61 responsibilities remain separate', () {
      expect(boundary.step1CAggregationTimeWindowsSeparate, true);
      expect(boundary.step1DPerformanceScoringSeparate, true);
      expect(boundary.step1EReadModelDashboardSeparate, true);
      expect(boundary.step1FPrivacyFailureIsolationSeparate, true);
      expect(boundary.step1GFinalCloseoutSeparate, true);
    });
  });
}

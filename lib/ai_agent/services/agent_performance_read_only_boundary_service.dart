import '../constants/agent_performance_metric_constants.dart';
import '../models/agent_performance_metric_contract.dart';
import '../models/agent_performance_metric_observation.dart';
import 'agent_performance_metric_catalog.dart';
import 'agent_performance_metric_safety_policy.dart';

class AgentPerformanceReadOnlyBoundaryDecision {
  const AgentPerformanceReadOnlyBoundaryDecision({
    required this.status,
    required this.metricId,
  });

  final String status;
  final String metricId;

  bool get acceptedForDashboard =>
      status == AgentPerformanceMetricObservationStatus.acceptedReadOnly;

  bool get readOnlyVisibilityOnly => true;
  bool get authorizesExecution => false;
  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get expandsScope => false;
  bool get assignsRole => false;
  bool get grantsOwnerAuthority => false;
  bool get executesBusinessAction => false;
  bool get mutatesAgentState => false;
  bool get mutatesRouting => false;
  bool get mutatesBudget => false;
  bool get persistsDecision => false;
}

class AgentPerformanceReadOnlyBoundaryService {
  const AgentPerformanceReadOnlyBoundaryService({
    this.contract = const AgentPerformanceMetricContract(),
    this.catalog = const AgentPerformanceMetricCatalog(),
    this.safetyPolicy = const AgentPerformanceMetricSafetyPolicy(),
  });

  final AgentPerformanceMetricContract contract;
  final AgentPerformanceMetricCatalog catalog;
  final AgentPerformanceMetricSafetyPolicy safetyPolicy;

  AgentPerformanceReadOnlyBoundaryDecision evaluate(
    AgentPerformanceMetricObservation observation,
  ) {
    final descriptor = catalog.findById(observation.metricId);

    final String status = safetyPolicy.evaluate(
      descriptor: descriptor,
      observation: observation,
    );

    return AgentPerformanceReadOnlyBoundaryDecision(
      status: status,
      metricId: observation.metricId,
    );
  }

  bool get dashboardReadOnly => true;
  bool get visibilityAnalyticsOnly => true;
  bool get existingSignalReuseRequired => true;
  bool get securityAuthorityAlwaysAboveDashboard => true;

  bool get dashboardCanGrantPermission => false;
  bool get dashboardCanCreateApproval => false;
  bool get dashboardCanConsumeApproval => false;
  bool get dashboardCanExpandScope => false;
  bool get dashboardCanAssignRole => false;
  bool get dashboardCanGrantOwnerAuthority => false;
  bool get dashboardCanExecuteBusinessAction => false;
  bool get dashboardCanModifySecurityEngine => false;

  bool get firestoreWriteImplementedHere => false;
  bool get providerInvocationImplementedHere => false;
  bool get routingMutationImplementedHere => false;
  bool get agentStateMutationImplementedHere => false;
  bool get budgetMutationImplementedHere => false;
  bool get persistenceImplementedHere => false;

  bool get step1CAggregationTimeWindowsSeparate => true;
  bool get step1DPerformanceScoringSeparate => true;
  bool get step1EReadModelDashboardSeparate => true;
  bool get step1FPrivacyFailureIsolationSeparate => true;
  bool get step1GFinalCloseoutSeparate => true;
}

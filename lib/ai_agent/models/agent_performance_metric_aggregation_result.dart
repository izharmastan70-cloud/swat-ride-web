import '../constants/agent_performance_aggregation_constants.dart';
import 'agent_performance_sample_sufficiency.dart';

class AgentPerformanceMetricAggregationResult {
  const AgentPerformanceMetricAggregationResult({
    required this.status,
    required this.agentId,
    required this.metricId,
    required this.windowId,
    required this.aggregatedValue,
    required this.totalSampleCount,
    required this.sufficiency,
    required this.blockReasonCode,
  });

  final String status;
  final String agentId;
  final String metricId;
  final String windowId;
  final double? aggregatedValue;
  final int totalSampleCount;
  final AgentPerformanceSampleSufficiency sufficiency;
  final String? blockReasonCode;

  bool get hasAggregatedValue => aggregatedValue != null;

  bool get sufficientForLaterInterpretation =>
      status == AgentPerformanceAggregationStatus.aggregatedSufficient ||
      status == AgentPerformanceAggregationStatus.aggregatedStrong;

  bool get strongEvidence =>
      status == AgentPerformanceAggregationStatus.aggregatedStrong;

  bool get insufficientEvidence =>
      status == AgentPerformanceAggregationStatus.insufficientSample;

  bool get readOnlyVisibilityOnly => true;
  bool get performanceScoreAssignedHere => false;
  bool get agentRankingAssignedHere => false;
  bool get disciplinaryDecisionMadeHere => false;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get expandsScope => false;
  bool get assignsRole => false;
  bool get grantsOwnerAuthority => false;
  bool get authorizesBusinessExecution => false;
  bool get executesBusinessAction => false;

  bool get mutatesAgentState => false;
  bool get mutatesRouting => false;
  bool get mutatesProviderState => false;
  bool get mutatesBudget => false;
  bool get persistsResult => false;

  bool get securityAuthorityAlwaysAboveDashboard => true;

  void validateStructure() {
    if (!AgentPerformanceAggregationStatus.values.contains(status) ||
        !AgentPerformanceTimeWindowId.values.contains(windowId) ||
        agentId.trim().isEmpty ||
        metricId.trim().isEmpty ||
        totalSampleCount < 0) {
      throw const FormatException(
        'Invalid Agent Performance aggregation result.',
      );
    }

    sufficiency.validateStructure();

    final bool shouldHaveValue =
        status == AgentPerformanceAggregationStatus.aggregatedSufficient ||
        status == AgentPerformanceAggregationStatus.aggregatedStrong ||
        status == AgentPerformanceAggregationStatus.insufficientSample;

    if (shouldHaveValue != (aggregatedValue != null)) {
      throw const FormatException('Aggregation status/value mismatch.');
    }
  }
}

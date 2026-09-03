import '../constants/agent_performance_metric_constants.dart';

class AgentPerformanceMetricDescriptor {
  const AgentPerformanceMetricDescriptor({
    required this.metricId,
    required this.family,
    required this.unit,
    required this.aggregation,
    required this.minimumNecessaryMetadataOnly,
    required this.trustedProjectionRequired,
  });

  final String metricId;
  final String family;
  final String unit;
  final String aggregation;

  final bool minimumNecessaryMetadataOnly;
  final bool trustedProjectionRequired;

  bool get readOnly => true;
  bool get dashboardVisibilityOnly => true;

  bool get rawPromptAllowed => false;
  bool get rawConversationAllowed => false;
  bool get rawProviderResponseAllowed => false;
  bool get privatePayloadAllowed => false;
  bool get secretAllowed => false;
  bool get authTokenAllowed => false;
  bool get approvalTokenAllowed => false;
  bool get permissionTokenAllowed => false;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get expandsScope => false;
  bool get assignsRole => false;
  bool get grantsOwnerAuthority => false;
  bool get authorizesBusinessExecution => false;
  bool get executesBusinessAction => false;

  bool get mutatesAgentState => false;
  bool get mutatesRouting => false;
  bool get mutatesBudget => false;
  bool get persistsMetric => false;

  void validateStructure() {
    if (!AgentPerformanceMetricId.values.contains(metricId) ||
        !AgentPerformanceMetricFamily.values.contains(family) ||
        !AgentPerformanceMetricUnit.values.contains(unit) ||
        !AgentPerformanceMetricAggregation.values.contains(aggregation) ||
        !minimumNecessaryMetadataOnly ||
        !trustedProjectionRequired) {
      throw const FormatException(
        'Invalid Agent Performance metric descriptor.',
      );
    }
  }
}

import '../constants/agent_performance_metric_constants.dart';

class AgentPerformanceMetricContract {
  const AgentPerformanceMetricContract();

  bool get dashboardReadOnly => true;
  bool get visibilityAnalyticsOnly => true;
  bool get existingSignalReuseRequired => true;
  bool get duplicateTelemetryEngineForbidden => true;

  bool get trustedSourceProjectionRequired => true;
  bool get minimumNecessaryMetadataRequired => true;
  bool get privacySafeProjectionRequired => true;

  bool get rawPromptForbidden => true;
  bool get rawConversationForbidden => true;
  bool get rawProviderResponseForbidden => true;
  bool get privatePayloadForbidden => true;
  bool get secretForbidden => true;
  bool get authTokenForbidden => true;
  bool get approvalTokenForbidden => true;
  bool get permissionTokenForbidden => true;

  bool get dashboardCanGrantPermission => false;
  bool get dashboardCanCreateApproval => false;
  bool get dashboardCanConsumeApproval => false;
  bool get dashboardCanExpandScope => false;
  bool get dashboardCanAssignRole => false;
  bool get dashboardCanGrantOwnerAuthority => false;
  bool get dashboardCanExecuteBusinessAction => false;
  bool get dashboardCanModifySecurityEngine => false;
  bool get dashboardCanMutateRouting => false;
  bool get dashboardCanMutateAgentState => false;
  bool get dashboardCanMutateBudget => false;

  bool get securityAuthorityAlwaysAboveDashboard => true;

  int get catalogMetricCount => AgentPerformanceMetricId.values.length;
}

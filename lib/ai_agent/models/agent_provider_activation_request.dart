class AgentProviderActivationRequest {
  const AgentProviderActivationRequest({
    required this.providerId,
    required this.requiredCapability,
    required this.backendExecution,
    required this.providerEnabled,
    required this.secretReferenceResolvedByBackend,
    required this.paidAiEnabled,
    required this.askBeforePaid,
    required this.paidApprovalGranted,
    required this.budgetAllowed,
    required this.requestsPermissionGrant,
    required this.requestsApprovalConsumption,
    required this.requestsScopeExpansion,
    required this.requestsBusinessAction,
  });

  final String providerId;
  final String requiredCapability;
  final bool backendExecution;
  final bool providerEnabled;
  final bool secretReferenceResolvedByBackend;

  final bool paidAiEnabled;
  final bool askBeforePaid;
  final bool paidApprovalGranted;
  final bool budgetAllowed;

  final bool requestsPermissionGrant;
  final bool requestsApprovalConsumption;
  final bool requestsScopeExpansion;
  final bool requestsBusinessAction;

  bool get containsRawSecret => false;
  bool get containsRawApiKey => false;
  bool get containsRawToken => false;
  bool get executesProviderHere => false;
  bool get persistsRequest => false;
}

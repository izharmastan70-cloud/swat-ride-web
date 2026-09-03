class AgentPerformanceDashboardVisibilityBoundary {
  const AgentPerformanceDashboardVisibilityBoundary();

  bool get dashboardIsVisibilityAnalyticsOnly => true;
  bool get dashboardIsNotSecurityAuthority => true;
  bool get dashboardIsNotAgentAuthority => true;
  bool get dashboardIsNotBusinessExecutionPath => true;

  bool get sortIsPresentationOrderOnly => true;
  bool get scoreSortCannotCreateGlobalLeaderboard => true;
  bool get scoreSortCannotCreatePermanentRank => true;
  bool get dashboardCannotDisciplineAgent => true;
  bool get dashboardCannotChangeRouting => true;
  bool get dashboardCannotChangePay => true;
  bool get dashboardCannotChangeAccess => true;

  bool get dashboardCannotGrantPermission => true;
  bool get dashboardCannotCreateOrConsumeApproval => true;
  bool get dashboardCannotExpandScope => true;
  bool get dashboardCannotAssignPrivilegedRole => true;
  bool get dashboardCannotGrantOwnerAuthority => true;
  bool get dashboardCannotModifySecurityEngine => true;

  bool get rawPromptForbidden => true;
  bool get rawConversationForbidden => true;
  bool get privatePayloadForbidden => true;
  bool get secretForbidden => true;
  bool get authApprovalPermissionTokensForbidden => true;

  bool get securityAuthorityAlwaysAboveDashboard => true;

  bool get persistenceImplementedHere => false;
  bool get providerInvocationImplementedHere => false;
  bool get businessExecutionImplementedHere => false;
}

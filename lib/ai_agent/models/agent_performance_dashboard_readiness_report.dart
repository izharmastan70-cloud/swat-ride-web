import '../constants/agent_performance_dashboard_closeout_constants.dart';

class AgentPerformanceDashboardReadinessReport {
  AgentPerformanceDashboardReadinessReport({
    required this.status,
    required this.closeoutId,
    required this.foundationReady,
    required this.adversarialReady,
    required this.coreFailureIsolationReady,
    required List<String> failedScenarioIds,
    required List<String> reasonCodes,
  }) : failedScenarioIds = List<String>.unmodifiable(failedScenarioIds),
       reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String closeoutId;
  final bool foundationReady;
  final bool adversarialReady;
  final bool coreFailureIsolationReady;
  final List<String> failedScenarioIds;
  final List<String> reasonCodes;

  bool get ready =>
      status == AgentPerformanceDashboardCloseoutStatus.foundationReady;

  bool get productionActive => false;
  bool get productionActivationPerformed => false;
  bool get readOnlyVisibilityOnly => true;
  bool get foundationCloseoutOnly => true;

  bool get rawExceptionTextExposed => false;
  bool get rawPromptExposed => false;
  bool get privatePayloadExposed => false;
  bool get secretExposed => false;
  bool get authTokenExposed => false;
  bool get approvalTokenExposed => false;
  bool get permissionTokenExposed => false;

  bool get globalLeaderboardCreated => false;
  bool get permanentRankAssigned => false;
  bool get disciplinaryDecisionMade => false;
  bool get routingDecisionMade => false;
  bool get payDecisionMade => false;
  bool get accessDecisionMade => false;

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
  bool get mutatesSecurity => false;
  bool get persistsState => false;

  bool get securityAuthorityAlwaysAboveDashboard => true;

  void validateStructure() {
    if (!AgentPerformanceDashboardCloseoutStatus.values.contains(status) ||
        closeoutId.trim().isEmpty ||
        closeoutId.length >
            AgentPerformanceDashboardCloseoutContract.maxOpaqueIdLength ||
        reasonCodes.isEmpty) {
      throw const FormatException('Invalid dashboard readiness report.');
    }

    if (ready &&
        (!foundationReady ||
            !adversarialReady ||
            !coreFailureIsolationReady ||
            failedScenarioIds.isNotEmpty)) {
      throw const FormatException(
        'Ready dashboard closeout report is inconsistent.',
      );
    }

    if (!ready &&
        failedScenarioIds.length >
            AgentPerformanceDashboardCloseoutContract.maxScenarios) {
      throw const FormatException('Too many failed dashboard scenarios.');
    }
  }
}

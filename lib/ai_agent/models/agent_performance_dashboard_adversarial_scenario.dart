import '../constants/agent_performance_dashboard_closeout_constants.dart';
import '../constants/agent_performance_dashboard_privacy_constants.dart';

class AgentPerformanceDashboardAdversarialScenario {
  const AgentPerformanceDashboardAdversarialScenario({
    required this.scenarioId,
    required this.projectionStatus,
    required this.visibleSummaryCount,
    required this.coreAppContinues,
    this.rawExceptionTextExposed = false,
    this.rawPromptExposed = false,
    this.privatePayloadExposed = false,
    this.secretExposed = false,
    this.authTokenExposed = false,
    this.approvalTokenExposed = false,
    this.permissionTokenExposed = false,
    this.globalLeaderboardCreated = false,
    this.permanentRankAssigned = false,
    this.disciplinaryDecisionMade = false,
    this.routingDecisionMade = false,
    this.payDecisionMade = false,
    this.accessDecisionMade = false,
    this.grantsPermission = false,
    this.createsApproval = false,
    this.expandsScope = false,
    this.assignsRole = false,
    this.grantsOwnerAuthority = false,
    this.authorizesBusinessExecution = false,
    this.executesBusinessAction = false,
    this.mutatesAgentState = false,
    this.mutatesRouting = false,
    this.mutatesBudget = false,
    this.mutatesSecurity = false,
    this.persistsState = false,
  });

  final String scenarioId;
  final String projectionStatus;
  final int visibleSummaryCount;
  final bool coreAppContinues;

  final bool rawExceptionTextExposed;
  final bool rawPromptExposed;
  final bool privatePayloadExposed;
  final bool secretExposed;
  final bool authTokenExposed;
  final bool approvalTokenExposed;
  final bool permissionTokenExposed;

  final bool globalLeaderboardCreated;
  final bool permanentRankAssigned;
  final bool disciplinaryDecisionMade;
  final bool routingDecisionMade;
  final bool payDecisionMade;
  final bool accessDecisionMade;

  final bool grantsPermission;
  final bool createsApproval;
  final bool expandsScope;
  final bool assignsRole;
  final bool grantsOwnerAuthority;
  final bool authorizesBusinessExecution;
  final bool executesBusinessAction;

  final bool mutatesAgentState;
  final bool mutatesRouting;
  final bool mutatesBudget;
  final bool mutatesSecurity;
  final bool persistsState;

  bool get exposesSensitiveData =>
      rawExceptionTextExposed ||
      rawPromptExposed ||
      privatePayloadExposed ||
      secretExposed ||
      authTokenExposed ||
      approvalTokenExposed ||
      permissionTokenExposed;

  bool get createsRankingOrDisciplineAuthority =>
      globalLeaderboardCreated ||
      permanentRankAssigned ||
      disciplinaryDecisionMade;

  bool get createsRoutingPayAccessAuthority =>
      routingDecisionMade || payDecisionMade || accessDecisionMade;

  bool get createsSecurityOrBusinessAuthority =>
      grantsPermission ||
      createsApproval ||
      expandsScope ||
      assignsRole ||
      grantsOwnerAuthority ||
      authorizesBusinessExecution ||
      executesBusinessAction;

  bool get mutatesProtectedState =>
      mutatesAgentState ||
      mutatesRouting ||
      mutatesBudget ||
      mutatesSecurity ||
      persistsState;

  void validateStructure() {
    if (!AgentPerformanceDashboardCloseoutScenarioId.required.contains(
          scenarioId,
        ) ||
        projectionStatus.trim().isEmpty ||
        projectionStatus.length >
            AgentPerformanceDashboardCloseoutContract.maxOpaqueIdLength ||
        visibleSummaryCount < 0) {
      throw const FormatException(
        'Invalid dashboard adversarial scenario metadata.',
      );
    }

    if (!AgentPerformanceDashboardSafeProjectionStatus.values.contains(
      projectionStatus,
    )) {
      throw const FormatException('Unknown dashboard safe projection status.');
    }
  }
}

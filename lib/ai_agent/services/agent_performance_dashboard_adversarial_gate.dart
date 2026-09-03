import '../constants/agent_performance_dashboard_closeout_constants.dart';
import '../constants/agent_performance_dashboard_privacy_constants.dart';
import '../models/agent_performance_dashboard_adversarial_scenario.dart';

class AgentPerformanceDashboardAdversarialGate {
  const AgentPerformanceDashboardAdversarialGate();

  bool passes(AgentPerformanceDashboardAdversarialScenario scenario) {
    try {
      scenario.validateStructure();
    } catch (_) {
      return false;
    }

    if (!scenario.coreAppContinues ||
        scenario.exposesSensitiveData ||
        scenario.createsRankingOrDisciplineAuthority ||
        scenario.createsRoutingPayAccessAuthority ||
        scenario.createsSecurityOrBusinessAuthority ||
        scenario.mutatesProtectedState) {
      return false;
    }

    switch (scenario.scenarioId) {
      case AgentPerformanceDashboardCloseoutScenarioId.freshSafeVisibility:
        return scenario.projectionStatus ==
                AgentPerformanceDashboardSafeProjectionStatus.ready &&
            scenario.visibleSummaryCount > 0;

      case AgentPerformanceDashboardCloseoutScenarioId.unsafeIdentifierPrivacy:
        return scenario.projectionStatus ==
                AgentPerformanceDashboardSafeProjectionStatus.blockedPrivacy &&
            scenario.visibleSummaryCount == 0;

      case AgentPerformanceDashboardCloseoutScenarioId
          .malformedSummaryIsolation:
        return scenario.projectionStatus ==
                AgentPerformanceDashboardSafeProjectionStatus.degraded &&
            scenario.visibleSummaryCount > 0;

      case AgentPerformanceDashboardCloseoutScenarioId.staleSnapshot:
        return scenario.projectionStatus ==
                AgentPerformanceDashboardSafeProjectionStatus
                    .blockedStaleData &&
            scenario.visibleSummaryCount == 0;

      case AgentPerformanceDashboardCloseoutScenarioId.futureClockSkew:
        return scenario.projectionStatus ==
                AgentPerformanceDashboardSafeProjectionStatus
                    .blockedClockSkew &&
            scenario.visibleSummaryCount == 0;

      case AgentPerformanceDashboardCloseoutScenarioId.duplicateSummaryIdentity:
      case AgentPerformanceDashboardCloseoutScenarioId.isolationBudgetExceeded:
      case AgentPerformanceDashboardCloseoutScenarioId.blockedSource:
      case AgentPerformanceDashboardCloseoutScenarioId
          .leaderboardAuthorityAbuse:
      case AgentPerformanceDashboardCloseoutScenarioId.securityAuthorityAbuse:
        return scenario.projectionStatus ==
                AgentPerformanceDashboardSafeProjectionStatus.blockedSource &&
            scenario.visibleSummaryCount == 0;
    }

    return false;
  }

  List<String> failedScenarioIds(
    List<AgentPerformanceDashboardAdversarialScenario> scenarios,
  ) {
    final List<String> failed = <String>[];

    for (final AgentPerformanceDashboardAdversarialScenario scenario
        in scenarios) {
      if (!passes(scenario)) {
        failed.add(scenario.scenarioId);
      }
    }

    return List<String>.unmodifiable(failed);
  }

  bool get propagatesExceptionText => false;
  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get createsLeaderboard => false;
  bool get createsPermanentRank => false;
  bool get executesBusinessAction => false;
  bool get mutatesSecurity => false;
  bool get persistenceImplementedHere => false;
}

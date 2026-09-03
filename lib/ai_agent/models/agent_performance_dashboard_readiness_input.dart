import '../constants/agent_performance_dashboard_closeout_constants.dart';
import 'agent_performance_dashboard_adversarial_scenario.dart';

class AgentPerformanceDashboardReadinessInput {
  AgentPerformanceDashboardReadinessInput({
    required this.closeoutId,
    required this.contractVersion,
    required this.step1BMetricContractReady,
    required this.step1CAggregationReady,
    required this.step1DScoringFairnessReady,
    required this.step1EReadModelVisibilityReady,
    required this.step1FPrivacyFailureFreshnessReady,
    required this.securityAuthorityAboveDashboard,
    required this.coreFailureIsolationReady,
    required this.callAgentExactFourPreserved,
    required this.productionActivationRequested,
    required List<AgentPerformanceDashboardAdversarialScenario> scenarios,
  }) : scenarios =
           List<AgentPerformanceDashboardAdversarialScenario>.unmodifiable(
             scenarios,
           );

  final String closeoutId;
  final String contractVersion;

  final bool step1BMetricContractReady;
  final bool step1CAggregationReady;
  final bool step1DScoringFairnessReady;
  final bool step1EReadModelVisibilityReady;
  final bool step1FPrivacyFailureFreshnessReady;

  final bool securityAuthorityAboveDashboard;
  final bool coreFailureIsolationReady;
  final bool callAgentExactFourPreserved;
  final bool productionActivationRequested;

  final List<AgentPerformanceDashboardAdversarialScenario> scenarios;

  bool get allFoundationLocksReady =>
      step1BMetricContractReady &&
      step1CAggregationReady &&
      step1DScoringFairnessReady &&
      step1EReadModelVisibilityReady &&
      step1FPrivacyFailureFreshnessReady &&
      securityAuthorityAboveDashboard &&
      coreFailureIsolationReady &&
      callAgentExactFourPreserved;

  void validateStructure() {
    final RegExp opaqueIdPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');

    if (closeoutId.trim().isEmpty ||
        closeoutId != closeoutId.trim() ||
        closeoutId.length >
            AgentPerformanceDashboardCloseoutContract.maxOpaqueIdLength ||
        !opaqueIdPattern.hasMatch(closeoutId) ||
        contractVersion != AgentPerformanceDashboardCloseoutContract.version ||
        scenarios.isEmpty ||
        scenarios.length >
            AgentPerformanceDashboardCloseoutContract.maxScenarios) {
      throw const FormatException('Invalid dashboard readiness metadata.');
    }

    final Set<String> seen = <String>{};

    for (final AgentPerformanceDashboardAdversarialScenario scenario
        in scenarios) {
      scenario.validateStructure();

      if (!seen.add(scenario.scenarioId)) {
        throw const FormatException(
          'Duplicate dashboard adversarial scenario id.',
        );
      }
    }
  }
}

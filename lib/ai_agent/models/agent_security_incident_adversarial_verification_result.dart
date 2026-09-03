import '../constants/agent_incident_response_adversarial_constants.dart';

class AgentSecurityIncidentAdversarialVerificationResult {
  AgentSecurityIncidentAdversarialVerificationResult({
    required this.scenario,
    required this.expectedOutcome,
    required this.actualOutcome,
    required this.passed,
    required this.failClosedRecommended,
    required this.failureIsolated,
    required this.verifiedAt,
  });

  final String scenario;
  final String expectedOutcome;
  final String actualOutcome;
  final bool passed;
  final bool failClosedRecommended;
  final bool failureIsolated;
  final DateTime verifiedAt;

  bool get harnessOnly => true;
  bool get grantsAuthority => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get executesContainment => false;
  bool get executesRemediation => false;
  bool get executesRecoveryAction => false;
  bool get closesIncident => false;
  bool get invokesProvider => false;
  bool get writesBusinessData => false;
  bool get persistsResult => false;

  void validateStructure() {
    if (!AgentSecurityIncidentAdversarialScenario.values.contains(scenario)) {
      throw const AgentSecurityIncidentAdversarialVerificationResultException(
        'Incident adversarial scenario is invalid.',
      );
    }

    if (!AgentSecurityIncidentAdversarialOutcome.values.contains(
          expectedOutcome,
        ) ||
        !AgentSecurityIncidentAdversarialOutcome.values.contains(
          actualOutcome,
        )) {
      throw const AgentSecurityIncidentAdversarialVerificationResultException(
        'Incident adversarial outcome is invalid.',
      );
    }

    if (passed != (expectedOutcome == actualOutcome)) {
      throw const AgentSecurityIncidentAdversarialVerificationResultException(
        'Incident adversarial pass state does not match outcome.',
      );
    }
  }
}

class AgentSecurityIncidentAdversarialVerificationResultException
    implements Exception {
  const AgentSecurityIncidentAdversarialVerificationResultException(
    this.message,
  );

  final String message;

  @override
  String toString() =>
      'AgentSecurityIncidentAdversarialVerificationResultException: $message';
}

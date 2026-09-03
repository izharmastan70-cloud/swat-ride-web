import '../constants/agent_guardian_adversarial_constants.dart';
import '../constants/agent_guardian_security_constants.dart';

class AgentGuardianAdversarialCase {
  const AgentGuardianAdversarialCase({
    required this.scenarioId,
    required this.category,
    required this.evidenceTrust,
    required this.expectedOutcome,
    required this.expectedMinimumSeverity,
    this.highImpactActionTargeted = false,
    this.repeatedWithinWindow = false,
    this.activeExploitEvidence = false,
    this.addCrossSubjectSignal = false,
    this.addReplaySignal = false,
    this.injectRawSecretPayload = false,
    this.requiredControlUnhealthy = false,
    this.requiredControlUnknown = false,
    this.simulateObserverFailure = false,
  });

  final String scenarioId;
  final String category;
  final String evidenceTrust;
  final String expectedOutcome;
  final String expectedMinimumSeverity;

  final bool highImpactActionTargeted;
  final bool repeatedWithinWindow;
  final bool activeExploitEvidence;

  final bool addCrossSubjectSignal;
  final bool addReplaySignal;
  final bool injectRawSecretPayload;

  final bool requiredControlUnhealthy;
  final bool requiredControlUnknown;
  final bool simulateObserverFailure;

  bool get grantsAuthority => false;
  bool get invokesAuthoritativeControls => false;
  bool get executesBusinessAction => false;
  bool get createsIncident => false;
  bool get persistsScenario => false;

  void validateStructure() {
    if (!AgentGuardianAdversarialScenarioId.lockedCoverage.contains(
      scenarioId,
    )) {
      throw const AgentGuardianAdversarialCaseException(
        'Adversarial scenario id is not in locked coverage.',
      );
    }

    if (!AgentGuardianRiskCategory.values.contains(category)) {
      throw const AgentGuardianAdversarialCaseException(
        'Adversarial Guardian risk category is invalid.',
      );
    }

    if (!AgentGuardianEvidenceTrust.values.contains(evidenceTrust)) {
      throw const AgentGuardianAdversarialCaseException(
        'Adversarial Guardian evidence trust is invalid.',
      );
    }

    if (!AgentGuardianAdversarialExpectation.values.contains(expectedOutcome)) {
      throw const AgentGuardianAdversarialCaseException(
        'Adversarial expected outcome is invalid.',
      );
    }

    if (!AgentGuardianSeverity.values.contains(expectedMinimumSeverity)) {
      throw const AgentGuardianAdversarialCaseException(
        'Adversarial minimum severity is invalid.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'scenarioId': scenarioId,
      'category': category,
      'evidenceTrust': evidenceTrust,
      'expectedOutcome': expectedOutcome,
      'expectedMinimumSeverity': expectedMinimumSeverity,
      'highImpactActionTargeted': highImpactActionTargeted,
      'repeatedWithinWindow': repeatedWithinWindow,
      'activeExploitEvidence': activeExploitEvidence,
      'addCrossSubjectSignal': addCrossSubjectSignal,
      'addReplaySignal': addReplaySignal,
      'injectRawSecretPayload': injectRawSecretPayload,
      'requiredControlUnhealthy': requiredControlUnhealthy,
      'requiredControlUnknown': requiredControlUnknown,
      'simulateObserverFailure': simulateObserverFailure,
      'rawPromptIncluded': false,
      'rawHistoryIncluded': false,
      'rawSecretValueIncluded': false,
      'grantsAuthority': false,
      'invokesAuthoritativeControls': false,
      'executesBusinessAction': false,
      'createsIncident': false,
      'persistsScenario': false,
    });
  }
}

class AgentGuardianAdversarialCaseException implements Exception {
  const AgentGuardianAdversarialCaseException(this.message);

  final String message;

  @override
  String toString() => 'AgentGuardianAdversarialCaseException: $message';
}

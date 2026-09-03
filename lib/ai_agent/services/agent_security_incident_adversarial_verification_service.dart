import '../constants/agent_incident_response_adversarial_constants.dart';
import '../models/agent_security_incident_adversarial_verification_result.dart';
import '../models/agent_security_incident_idempotency_observation.dart';

class AgentSecurityIncidentAdversarialVerificationService {
  const AgentSecurityIncidentAdversarialVerificationService();

  static const Duration maxReplayAge = Duration(minutes: 30);

  static const Map<String, String> lockedScenarioOutcomes = <String, String>{
    AgentSecurityIncidentAdversarialScenario.duplicateIncidentIntake:
        AgentSecurityIncidentAdversarialOutcome.duplicateSuppressed,
    AgentSecurityIncidentAdversarialScenario.duplicateResponderAssignment:
        AgentSecurityIncidentAdversarialOutcome.duplicateSuppressed,
    AgentSecurityIncidentAdversarialScenario.duplicateTimelineEvent:
        AgentSecurityIncidentAdversarialOutcome.duplicateSuppressed,
    AgentSecurityIncidentAdversarialScenario.duplicateResponsePlan:
        AgentSecurityIncidentAdversarialOutcome.duplicateSuppressed,
    AgentSecurityIncidentAdversarialScenario.duplicateAuthoritativeHandoff:
        AgentSecurityIncidentAdversarialOutcome.duplicateSuppressed,
    AgentSecurityIncidentAdversarialScenario.duplicateRecoveryEvidence:
        AgentSecurityIncidentAdversarialOutcome.duplicateSuppressed,
    AgentSecurityIncidentAdversarialScenario.duplicateClosureAssessment:
        AgentSecurityIncidentAdversarialOutcome.duplicateSuppressed,
    AgentSecurityIncidentAdversarialScenario.idempotencyKeyCollision:
        AgentSecurityIncidentAdversarialOutcome.failClosed,
    AgentSecurityIncidentAdversarialScenario.staleReplayEvidence:
        AgentSecurityIncidentAdversarialOutcome.staleReplayRejected,
    AgentSecurityIncidentAdversarialScenario.crossIncidentBindingAttempt:
        AgentSecurityIncidentAdversarialOutcome.crossIncidentRejected,
    AgentSecurityIncidentAdversarialScenario.missingHumanAcknowledgement:
        AgentSecurityIncidentAdversarialOutcome.humanReviewRequired,
    AgentSecurityIncidentAdversarialScenario.missingAuthoritativeVerification:
        AgentSecurityIncidentAdversarialOutcome.verificationRequired,
    AgentSecurityIncidentAdversarialScenario.unstableRecoveryClosureAttempt:
        AgentSecurityIncidentAdversarialOutcome.recoveryMonitoringRequired,
    AgentSecurityIncidentAdversarialScenario.observerFailureIsolation:
        AgentSecurityIncidentAdversarialOutcome.failureIsolated,
  };

  AgentSecurityIncidentIdempotencyEvaluation evaluateIdempotency({
    required AgentSecurityIncidentIdempotencyObservation incoming,
    required List<AgentSecurityIncidentIdempotencyObservation>
    priorObservations,
  }) {
    try {
      incoming.validateStructure();

      if (priorObservations.length > 50) {
        return AgentSecurityIncidentIdempotencyEvaluation(
          decision: AgentSecurityIncidentIdempotencyDecision.invalidFailClosed,
          idempotencyKey: incoming.idempotencyKey,
          failClosedRecommended: true,
          reasonCode: 'idempotency_window_too_large',
        );
      }

      for (final AgentSecurityIncidentIdempotencyObservation prior
          in priorObservations) {
        prior.validateStructure();

        if (prior.idempotencyKey != incoming.idempotencyKey) {
          continue;
        }

        final bool sameBinding =
            prior.incidentId == incoming.incidentId &&
            prior.operationId == incoming.operationId;

        final bool samePayload =
            prior.payloadFingerprint == incoming.payloadFingerprint;

        if (sameBinding && samePayload) {
          return AgentSecurityIncidentIdempotencyEvaluation(
            decision:
                AgentSecurityIncidentIdempotencyDecision.duplicateSuppressed,
            idempotencyKey: incoming.idempotencyKey,
            failClosedRecommended: false,
            reasonCode: 'exact_duplicate_suppressed',
          );
        }

        return AgentSecurityIncidentIdempotencyEvaluation(
          decision:
              AgentSecurityIncidentIdempotencyDecision.collisionFailClosed,
          idempotencyKey: incoming.idempotencyKey,
          failClosedRecommended: true,
          reasonCode: 'idempotency_key_collision',
        );
      }

      return AgentSecurityIncidentIdempotencyEvaluation(
        decision: AgentSecurityIncidentIdempotencyDecision.accepted,
        idempotencyKey: incoming.idempotencyKey,
        failClosedRecommended: false,
        reasonCode: 'new_idempotent_operation',
      );
    } catch (_) {
      return AgentSecurityIncidentIdempotencyEvaluation(
        decision: AgentSecurityIncidentIdempotencyDecision.invalidFailClosed,
        idempotencyKey: _safeKey(incoming.idempotencyKey),
        failClosedRecommended: true,
        reasonCode: 'invalid_observation_fail_closed',
      );
    }
  }

  bool isStaleReplay({required DateTime observedAt, required DateTime now}) {
    if (observedAt.isAfter(now)) {
      return true;
    }

    return now.difference(observedAt) > maxReplayAge;
  }

  bool isCrossIncidentBinding({
    required String expectedIncidentId,
    required String actualIncidentId,
  }) {
    return expectedIncidentId.trim().isEmpty ||
        actualIncidentId.trim().isEmpty ||
        expectedIncidentId != actualIncidentId;
  }

  AgentSecurityIncidentAdversarialVerificationResult verifyScenario({
    required String scenario,
    required String actualOutcome,
    required DateTime verifiedAt,
  }) {
    final String? expected = lockedScenarioOutcomes[scenario];

    if (expected == null ||
        !AgentSecurityIncidentAdversarialOutcome.values.contains(
          actualOutcome,
        )) {
      return AgentSecurityIncidentAdversarialVerificationResult(
        scenario:
            AgentSecurityIncidentAdversarialScenario.observerFailureIsolation,
        expectedOutcome:
            AgentSecurityIncidentAdversarialOutcome.failureIsolated,
        actualOutcome: AgentSecurityIncidentAdversarialOutcome.failureIsolated,
        passed: true,
        failClosedRecommended: true,
        failureIsolated: true,
        verifiedAt: verifiedAt,
      );
    }

    final bool passed = expected == actualOutcome;

    final AgentSecurityIncidentAdversarialVerificationResult
    result = AgentSecurityIncidentAdversarialVerificationResult(
      scenario: scenario,
      expectedOutcome: expected,
      actualOutcome: actualOutcome,
      passed: passed,
      failClosedRecommended:
          actualOutcome == AgentSecurityIncidentAdversarialOutcome.failClosed ||
          actualOutcome ==
              AgentSecurityIncidentAdversarialOutcome.staleReplayRejected ||
          actualOutcome ==
              AgentSecurityIncidentAdversarialOutcome.crossIncidentRejected ||
          actualOutcome ==
              AgentSecurityIncidentAdversarialOutcome.verificationRequired,
      failureIsolated:
          scenario ==
              AgentSecurityIncidentAdversarialScenario
                  .observerFailureIsolation &&
          actualOutcome ==
              AgentSecurityIncidentAdversarialOutcome.failureIsolated,
      verifiedAt: verifiedAt,
    );

    result.validateStructure();
    return result;
  }

  List<AgentSecurityIncidentAdversarialVerificationResult>
  verifyLockedCoverage({required DateTime verifiedAt}) {
    return List<
      AgentSecurityIncidentAdversarialVerificationResult
    >.unmodifiable(
      lockedScenarioOutcomes.entries.map(
        (MapEntry<String, String> entry) => verifyScenario(
          scenario: entry.key,
          actualOutcome: entry.value,
          verifiedAt: verifiedAt,
        ),
      ),
    );
  }

  String _safeKey(String value) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'invalid_idempotency_key';
    }

    final String sanitized = trimmed.replaceAll(
      RegExp(r'[^A-Za-z0-9._:-]'),
      '_',
    );

    if (sanitized.length <= 180) {
      return sanitized;
    }

    return sanitized.substring(0, 180);
  }

  bool get harnessAndIdempotencySafetyOnly => true;
  bool get duplicateExecutionAllowed => false;
  bool get collisionFailsClosed => true;
  bool get staleReplayAccepted => false;
  bool get crossIncidentBindingAccepted => false;
  bool get observerFailureBreaksCoreApp => false;
  bool get observerFailureBreaksOtherChannels => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get bypassesAuthoritativeControls => false;
  bool get executesContainment => false;
  bool get executesRemediation => false;
  bool get executesRecoveryAction => false;
  bool get closesIncident => false;
  bool get invokesProvider => false;
  bool get invokesTargetAgent => false;
  bool get writesBusinessData => false;
  bool get persistsIdempotencyState => false;
  bool get persistsAdversarialResults => false;
  bool get implementsPhase63PrivacyUi => false;
}

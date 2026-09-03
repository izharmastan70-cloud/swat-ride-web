import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_incident_response_adversarial_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_idempotency_observation.dart';
import 'package:swat_ride/ai_agent/services/agent_security_incident_adversarial_verification_service.dart';

void main() {
  const AgentSecurityIncidentAdversarialVerificationService service =
      AgentSecurityIncidentAdversarialVerificationService();

  AgentSecurityIncidentIdempotencyObservation observation({
    String operationId = 'operation_step1f_001',
    String incidentId = 'incident_step1f_001',
    String idempotencyKey = 'idem_step1f_001',
    String payloadFingerprint = 'fingerprint_step1f_001',
    DateTime? observedAt,
  }) {
    return AgentSecurityIncidentIdempotencyObservation(
      operationId: operationId,
      incidentId: incidentId,
      idempotencyKey: idempotencyKey,
      payloadFingerprint: payloadFingerprint,
      observedAt: observedAt ?? DateTime.utc(2026, 8, 19, 12, 30),
    );
  }

  group('Phase 54 Step 1F adversarial/replay/idempotency safety', () {
    test('locked adversarial coverage contains exactly 14 scenarios', () {
      expect(AgentSecurityIncidentAdversarialScenario.values.length, 14);
      expect(
        AgentSecurityIncidentAdversarialVerificationService
            .lockedScenarioOutcomes
            .length,
        14,
      );
    });

    test('locked 14-scenario coverage verifies expected outcomes', () {
      final results = service.verifyLockedCoverage(
        verifiedAt: DateTime.utc(2026, 8, 19, 12, 40),
      );

      expect(results.length, 14);
      expect(results.every((result) => result.passed), isTrue);
    });

    test('new idempotency key is accepted for further authoritative flow', () {
      final result = service.evaluateIdempotency(
        incoming: observation(),
        priorObservations:
            const <AgentSecurityIncidentIdempotencyObservation>[],
      );

      expect(
        result.decision,
        AgentSecurityIncidentIdempotencyDecision.accepted,
      );
      expect(result.executesOperation, isFalse);
    });

    test('exact duplicate is suppressed', () {
      final AgentSecurityIncidentIdempotencyObservation first = observation();

      final result = service.evaluateIdempotency(
        incoming: observation(),
        priorObservations: <AgentSecurityIncidentIdempotencyObservation>[first],
      );

      expect(
        result.decision,
        AgentSecurityIncidentIdempotencyDecision.duplicateSuppressed,
      );
      expect(result.failClosedRecommended, isFalse);
    });

    test('same key with different payload fingerprint fails closed', () {
      final result = service.evaluateIdempotency(
        incoming: observation(payloadFingerprint: 'fingerprint_changed'),
        priorObservations: <AgentSecurityIncidentIdempotencyObservation>[
          observation(),
        ],
      );

      expect(
        result.decision,
        AgentSecurityIncidentIdempotencyDecision.collisionFailClosed,
      );
      expect(result.failClosedRecommended, isTrue);
    });

    test('same key with different incident binding fails closed', () {
      final result = service.evaluateIdempotency(
        incoming: observation(incidentId: 'incident_step1f_other'),
        priorObservations: <AgentSecurityIncidentIdempotencyObservation>[
          observation(),
        ],
      );

      expect(
        result.decision,
        AgentSecurityIncidentIdempotencyDecision.collisionFailClosed,
      );
    });

    test('same key with different operation binding fails closed', () {
      final result = service.evaluateIdempotency(
        incoming: observation(operationId: 'operation_step1f_other'),
        priorObservations: <AgentSecurityIncidentIdempotencyObservation>[
          observation(),
        ],
      );

      expect(
        result.decision,
        AgentSecurityIncidentIdempotencyDecision.collisionFailClosed,
      );
    });

    test('idempotency observation window is bounded to 50', () {
      final List<AgentSecurityIncidentIdempotencyObservation> prior =
          List<AgentSecurityIncidentIdempotencyObservation>.generate(
            51,
            (int index) => observation(
              idempotencyKey: 'idem_prior_$index',
              payloadFingerprint: 'fingerprint_prior_$index',
            ),
          );

      final result = service.evaluateIdempotency(
        incoming: observation(idempotencyKey: 'idem_new'),
        priorObservations: prior,
      );

      expect(
        result.decision,
        AgentSecurityIncidentIdempotencyDecision.invalidFailClosed,
      );
      expect(result.failClosedRecommended, isTrue);
    });

    test('invalid observation fails closed without throwing outward', () {
      final result = service.evaluateIdempotency(
        incoming: observation(idempotencyKey: 'invalid key with spaces'),
        priorObservations:
            const <AgentSecurityIncidentIdempotencyObservation>[],
      );

      expect(
        result.decision,
        AgentSecurityIncidentIdempotencyDecision.invalidFailClosed,
      );
      expect(result.failClosedRecommended, isTrue);
    });

    test('replay older than 30 minutes is stale', () {
      expect(
        service.isStaleReplay(
          observedAt: DateTime.utc(2026, 8, 19, 12),
          now: DateTime.utc(2026, 8, 19, 12, 31),
        ),
        isTrue,
      );
    });

    test('future replay timestamp is rejected as stale/invalid', () {
      expect(
        service.isStaleReplay(
          observedAt: DateTime.utc(2026, 8, 19, 12, 31),
          now: DateTime.utc(2026, 8, 19, 12, 30),
        ),
        isTrue,
      );
    });

    test('fresh replay window at 30 minutes is not stale', () {
      expect(
        service.isStaleReplay(
          observedAt: DateTime.utc(2026, 8, 19, 12),
          now: DateTime.utc(2026, 8, 19, 12, 30),
        ),
        isFalse,
      );
    });

    test('cross-incident binding is rejected', () {
      expect(
        service.isCrossIncidentBinding(
          expectedIncidentId: 'incident_a',
          actualIncidentId: 'incident_b',
        ),
        isTrue,
      );

      expect(
        service.isCrossIncidentBinding(
          expectedIncidentId: 'incident_a',
          actualIncidentId: 'incident_a',
        ),
        isFalse,
      );
    });

    test('observer failure scenario is isolated', () {
      final result = service.verifyScenario(
        scenario:
            AgentSecurityIncidentAdversarialScenario.observerFailureIsolation,
        actualOutcome: AgentSecurityIncidentAdversarialOutcome.failureIsolated,
        verifiedAt: DateTime.utc(2026, 8, 19, 12, 40),
      );

      expect(result.passed, isTrue);
      expect(result.failureIsolated, isTrue);
      expect(result.persistsResult, isFalse);
    });

    test('unknown scenario fails safely into isolated harness result', () {
      final result = service.verifyScenario(
        scenario: 'UNKNOWN_SCENARIO',
        actualOutcome: 'UNKNOWN_OUTCOME',
        verifiedAt: DateTime.utc(2026, 8, 19, 12, 40),
      );

      expect(result.passed, isTrue);
      expect(
        result.scenario,
        AgentSecurityIncidentAdversarialScenario.observerFailureIsolation,
      );
      expect(result.failureIsolated, isTrue);
    });

    test('idempotency safe map contains metadata only', () {
      final Map<String, dynamic> map = observation().toSafeMap();

      expect(map['metadataOnly'], isTrue);
      expect(map['containsRawPayload'], isFalse);
      expect(map['grantsAuthority'], isFalse);
      expect(map['writesBusinessData'], isFalse);
      expect(map['persistsObservation'], isFalse);
    });

    test('service remains safety-harness only', () {
      expect(service.harnessAndIdempotencySafetyOnly, isTrue);
      expect(service.duplicateExecutionAllowed, isFalse);
      expect(service.collisionFailsClosed, isTrue);
      expect(service.staleReplayAccepted, isFalse);
      expect(service.crossIncidentBindingAccepted, isFalse);
      expect(service.observerFailureBreaksCoreApp, isFalse);
      expect(service.observerFailureBreaksOtherChannels, isFalse);
      expect(service.invokesPermissionEngine, isFalse);
      expect(service.invokesApprovalEngine, isFalse);
      expect(service.invokesRuntimeGate, isFalse);
      expect(service.invokesEmergencyStop, isFalse);
      expect(service.bypassesAuthoritativeControls, isFalse);
      expect(service.executesContainment, isFalse);
      expect(service.executesRemediation, isFalse);
      expect(service.executesRecoveryAction, isFalse);
      expect(service.closesIncident, isFalse);
      expect(service.invokesProvider, isFalse);
      expect(service.invokesTargetAgent, isFalse);
      expect(service.writesBusinessData, isFalse);
      expect(service.persistsIdempotencyState, isFalse);
      expect(service.persistsAdversarialResults, isFalse);
      expect(service.implementsPhase63PrivacyUi, isFalse);
    });
  });
}

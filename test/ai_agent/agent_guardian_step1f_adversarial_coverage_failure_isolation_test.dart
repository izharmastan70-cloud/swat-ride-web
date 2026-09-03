import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_guardian_adversarial_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_guardian_observability_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_guardian_security_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_guardian_adversarial_case.dart';
import 'package:swat_ride/ai_agent/models/agent_guardian_adversarial_verification_result.dart';
import 'package:swat_ride/ai_agent/services/agent_guardian_adversarial_verification_service.dart';

void main() {
  const AgentGuardianAdversarialVerificationService service =
      AgentGuardianAdversarialVerificationService();

  AgentGuardianAdversarialVerificationResult resultFor(String scenarioId) {
    final AgentGuardianAdversarialCase scenario = service
        .buildLockedCoverage()
        .firstWhere(
          (AgentGuardianAdversarialCase item) => item.scenarioId == scenarioId,
        );

    return service.verifyCase(scenario);
  }

  int severityRank(String severity) {
    switch (severity) {
      case AgentGuardianSeverity.low:
        return 0;
      case AgentGuardianSeverity.medium:
        return 1;
      case AgentGuardianSeverity.high:
        return 2;
      case AgentGuardianSeverity.critical:
        return 3;
      default:
        return -1;
    }
  }

  group('Phase 53 Step 1F adversarial coverage', () {
    test('locked coverage contains exactly 14 unique scenarios', () {
      final List<AgentGuardianAdversarialCase> cases = service
          .buildLockedCoverage();

      expect(cases.length, 14);
      expect(
        cases
            .map((AgentGuardianAdversarialCase item) => item.scenarioId)
            .toSet()
            .length,
        14,
      );
      expect(
        cases
            .map((AgentGuardianAdversarialCase item) => item.scenarioId)
            .toSet(),
        AgentGuardianAdversarialScenarioId.lockedCoverage,
      );
    });

    test('all locked adversarial cases validate structurally', () {
      for (final AgentGuardianAdversarialCase scenario
          in service.buildLockedCoverage()) {
        expect(() => scenario.validateStructure(), returnsNormally);
      }
    });

    test('all 14 locked scenarios pass the safety harness', () {
      final List<AgentGuardianAdversarialVerificationResult> results = service
          .verifyLockedCoverage();

      expect(results.length, 14);

      for (final AgentGuardianAdversarialVerificationResult result in results) {
        expect(
          result.passed,
          isTrue,
          reason: 'Scenario failed: ${result.scenarioId}',
        );
      }
    });

    test('prompt injection remains at least MEDIUM and non-authoritative', () {
      final AgentGuardianAdversarialVerificationResult result = resultFor(
        AgentGuardianAdversarialScenarioId.promptInjection,
      );

      expect(
        severityRank(result.actualSeverity),
        greaterThanOrEqualTo(severityRank(AgentGuardianSeverity.medium)),
      );
      expect(result.guardianIsFinalEnforcer, isFalse);
      expect(result.executesBlock, isFalse);
    });

    test('permission bypass with unhealthy required control fails closed', () {
      final AgentGuardianAdversarialVerificationResult result = resultFor(
        AgentGuardianAdversarialScenarioId.permissionBypass,
      );

      expect(result.failClosedRecommended, isTrue);
      expect(
        result.monitoringStatus,
        AgentGuardianMonitoringStatus.failClosedRecommended,
      );
    });

    test('runtime bypass with unknown required control fails closed', () {
      final AgentGuardianAdversarialVerificationResult result = resultFor(
        AgentGuardianAdversarialScenarioId.runtimeGateBypass,
      );

      expect(result.failClosedRecommended, isTrue);
    });

    test('emergency stop bypass reaches CRITICAL coverage', () {
      final AgentGuardianAdversarialVerificationResult result = resultFor(
        AgentGuardianAdversarialScenarioId.emergencyStopBypass,
      );

      expect(result.actualSeverity, AgentGuardianSeverity.critical);
      expect(result.executesEscalation, isFalse);
    });

    test('cross-subject context signal is suppressed', () {
      final AgentGuardianAdversarialVerificationResult result = resultFor(
        AgentGuardianAdversarialScenarioId.crossSubjectContext,
      );

      expect(result.crossSubjectSuppressed, isTrue);
      expect(result.expectedOutcomeMet, isTrue);
    });

    test('replay storm cannot inflate risk via duplicate semantic signals', () {
      final AgentGuardianAdversarialVerificationResult result = resultFor(
        AgentGuardianAdversarialScenarioId.replayStorm,
      );

      expect(result.replaySuppressed, isTrue);
      expect(result.expectedOutcomeMet, isTrue);
    });

    test('secret-bearing adversarial input fails closed without exposure', () {
      final AgentGuardianAdversarialVerificationResult result = resultFor(
        AgentGuardianAdversarialScenarioId.secretExposure,
      );

      expect(result.failClosedRecommended, isTrue);
      expect(result.persistsResult, isFalse);
    });

    test('unauthorized provider execution remains high-risk evidence only', () {
      final AgentGuardianAdversarialVerificationResult result = resultFor(
        AgentGuardianAdversarialScenarioId.unauthorizedProviderExecution,
      );

      expect(
        severityRank(result.actualSeverity),
        greaterThanOrEqualTo(severityRank(AgentGuardianSeverity.high)),
      );
      expect(result.invokesProvider, isFalse);
    });

    test('unauthorized business write remains high-risk evidence only', () {
      final AgentGuardianAdversarialVerificationResult result = resultFor(
        AgentGuardianAdversarialScenarioId.unauthorizedBusinessWrite,
      );

      expect(
        severityRank(result.actualSeverity),
        greaterThanOrEqualTo(severityRank(AgentGuardianSeverity.high)),
      );
      expect(result.writesBusinessData, isFalse);
    });

    test('security-control tamper reaches CRITICAL coverage', () {
      final AgentGuardianAdversarialVerificationResult result = resultFor(
        AgentGuardianAdversarialScenarioId.securityControlTamper,
      );

      expect(result.actualSeverity, AgentGuardianSeverity.critical);
      expect(result.createsIncident, isFalse);
    });

    test('required-control unhealthy/unknown scenarios both fail closed', () {
      for (final String scenarioId in <String>[
        AgentGuardianAdversarialScenarioId.requiredControlUnhealthy,
        AgentGuardianAdversarialScenarioId.requiredControlUnknown,
      ]) {
        final AgentGuardianAdversarialVerificationResult result = resultFor(
          scenarioId,
        );

        expect(result.failClosedRecommended, isTrue);
      }
    });

    test('observer failure is isolated from core app and other channels', () {
      final AgentGuardianAdversarialVerificationResult result = resultFor(
        AgentGuardianAdversarialScenarioId.observerFailureIsolation,
      );

      expect(result.guardianFailureIsolated, isTrue);
      expect(result.coreAppAvailable, isTrue);
      expect(result.otherChannelsAvailable, isTrue);
      expect(result.authoritativeControlsRemainIndependent, isTrue);
      expect(result.failClosedRecommended, isTrue);
    });

    test('every verification result is recommendation-only', () {
      for (final AgentGuardianAdversarialVerificationResult result
          in service.verifyLockedCoverage()) {
        expect(result.recommendationOnly, isTrue);
        expect(result.guardianIsFinalEnforcer, isFalse);
        expect(result.invokesPermissionEngine, isFalse);
        expect(result.invokesApprovalEngine, isFalse);
        expect(result.invokesRuntimeGate, isFalse);
        expect(result.invokesEmergencyStop, isFalse);
        expect(result.executesBlock, isFalse);
        expect(result.executesEscalation, isFalse);
        expect(result.createsIncident, isFalse);
        expect(result.invokesProvider, isFalse);
        expect(result.invokesTargetAgent, isFalse);
        expect(result.writesBusinessData, isFalse);
        expect(result.persistsResult, isFalse);
      }
    });

    test('safe verification metadata contains no raw evidence payload', () {
      final Map<String, dynamic> map = resultFor(
        AgentGuardianAdversarialScenarioId.promptInjection,
      ).toSafeMap();

      expect(map['rawEvidencePayloadIncluded'], isFalse);
      expect(map['recommendationOnly'], isTrue);
      expect(map['guardianIsFinalEnforcer'], isFalse);
      expect(map['persistsResult'], isFalse);
    });

    test(
      'adversarial harness cannot activate production/security authority',
      () {
        expect(service.adversarialHarnessOnly, isTrue);
        expect(service.recommendationOnly, isTrue);
        expect(service.guardianIsFinalEnforcer, isFalse);
        expect(service.invokesPermissionEngine, isFalse);
        expect(service.invokesApprovalEngine, isFalse);
        expect(service.invokesRuntimeGate, isFalse);
        expect(service.invokesEmergencyStop, isFalse);
        expect(service.bypassesAuthoritativeControls, isFalse);
        expect(service.executesBlock, isFalse);
        expect(service.executesEscalation, isFalse);
        expect(service.createsIncident, isFalse);
        expect(service.implementsIncidentResponse, isFalse);
        expect(service.activatesProductionMonitoring, isFalse);
        expect(service.invokesProvider, isFalse);
        expect(service.invokesTargetAgent, isFalse);
        expect(service.writesBusinessData, isFalse);
        expect(service.persistsVerification, isFalse);
        expect(service.canBreakCoreApp, isFalse);
        expect(service.canBreakOtherChannels, isFalse);
      },
    );
  });
}

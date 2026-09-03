import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_guardian_security_readiness_report.dart';
import 'package:swat_ride/ai_agent/services/agent_guardian_security_readiness_evaluator.dart';

void main() {
  const AgentGuardianSecurityReadinessEvaluator evaluator =
      AgentGuardianSecurityReadinessEvaluator();

  AgentGuardianSecurityReadinessReport readyReport() {
    return evaluator.evaluate(
      generatedAt: DateTime.utc(2026, 8, 19, 9, 45),
      callAgentLockedActionSetPreserved: true,
    );
  }

  group('Phase 53 Step 1G final Guardian readiness', () {
    test('foundation status is ready but not production active', () {
      final AgentGuardianSecurityReadinessReport report = readyReport();

      expect(report.foundationReadyNotProductionActive, isTrue);
      expect(report.guardianFoundationReady, isTrue);
      expect(report.productionActive, isFalse);
    });

    test('all 14 adversarial scenarios are required and passed', () {
      final AgentGuardianSecurityReadinessReport report = readyReport();

      expect(report.adversarialCoverageCount, 14);
      expect(report.allAdversarialCasesPassed, isTrue);
    });

    test('fail-closed monitoring is verified', () {
      final AgentGuardianSecurityReadinessReport report = readyReport();

      expect(report.failClosedMonitoringVerified, isTrue);
    });

    test('Guardian failure isolation is verified', () {
      final AgentGuardianSecurityReadinessReport report = readyReport();

      expect(report.failureIsolationVerified, isTrue);
      expect(report.coreAppFailureCoupledToGuardian, isFalse);
      expect(report.otherChannelFailureCoupledToGuardian, isFalse);
    });

    test('safe evidence boundary remains verified', () {
      final AgentGuardianSecurityReadinessReport report = readyReport();

      expect(report.safeEvidenceOnlyVerified, isTrue);
      expect(report.rawSensitiveEvidenceAllowed, isFalse);
    });

    test('authoritative controls remain final and required', () {
      final AgentGuardianSecurityReadinessReport report = readyReport();

      expect(report.authoritativeControlsRemainFinal, isTrue);
      expect(report.authoritativeChecksRemainRequired, isTrue);
      expect(report.guardianIsFinalEnforcer, isFalse);
      expect(report.permissionApprovalRuntimeBypassAllowed, isFalse);
    });

    test('Phase 54 incident response is not implemented by Guardian', () {
      final AgentGuardianSecurityReadinessReport report = readyReport();

      expect(report.phase54IncidentResponseImplemented, isFalse);
      expect(report.createsIncident, isFalse);
    });

    test('production persistence remains intentionally absent', () {
      final AgentGuardianSecurityReadinessReport report = readyReport();

      expect(report.persistentGuardianMonitoringImplemented, isFalse);
      expect(report.securityAuditPersistenceImplemented, isFalse);
      expect(report.persistsReport, isFalse);
    });

    test('provider target-agent and business execution remain absent', () {
      final AgentGuardianSecurityReadinessReport report = readyReport();

      expect(report.providerExecutionImplemented, isFalse);
      expect(report.targetAgentExecutionImplemented, isFalse);
      expect(report.businessWriteImplemented, isFalse);
    });

    test('call_agent exact-four preservation is part of readiness', () {
      final AgentGuardianSecurityReadinessReport report = readyReport();

      expect(report.callAgentLockedActionSetPreserved, isTrue);
    });

    test('safe readiness map exposes no authority or raw evidence', () {
      final Map<String, dynamic> map = readyReport().toSafeMap();

      expect(map['productionActive'], isFalse);
      expect(map['rawEvidencePayloadIncluded'], isFalse);
      expect(map['recommendationOnly'], isTrue);
      expect(map['grantsAuthority'], isFalse);
      expect(map['grantsPermission'], isFalse);
      expect(map['consumesApproval'], isFalse);
      expect(map['marksRuntimeAllowed'], isFalse);
      expect(map['executesBlock'], isFalse);
      expect(map['executesEscalation'], isFalse);
      expect(map['createsIncident'], isFalse);
      expect(map['persistsReport'], isFalse);
    });

    test('evaluator cannot activate or bypass security authority', () {
      expect(evaluator.readinessEvaluatorOnly, isTrue);
      expect(evaluator.activatesProductionGuardian, isFalse);
      expect(evaluator.guardianIsFinalEnforcer, isFalse);
      expect(evaluator.invokesPermissionEngine, isFalse);
      expect(evaluator.invokesApprovalEngine, isFalse);
      expect(evaluator.invokesRuntimeGate, isFalse);
      expect(evaluator.invokesEmergencyStop, isFalse);
      expect(evaluator.bypassesAuthoritativeControls, isFalse);
      expect(evaluator.grantsPermission, isFalse);
      expect(evaluator.consumesApproval, isFalse);
      expect(evaluator.marksRuntimeAllowed, isFalse);
      expect(evaluator.executesBlock, isFalse);
      expect(evaluator.executesEscalation, isFalse);
      expect(evaluator.createsIncident, isFalse);
      expect(evaluator.implementsIncidentResponse, isFalse);
      expect(evaluator.writesSecurityAuditPersistence, isFalse);
      expect(evaluator.invokesProvider, isFalse);
      expect(evaluator.invokesTargetAgent, isFalse);
      expect(evaluator.writesBusinessData, isFalse);
      expect(evaluator.persistsReadinessReport, isFalse);
      expect(evaluator.canBreakCoreApp, isFalse);
      expect(evaluator.canBreakOtherChannels, isFalse);
    });

    test('missing call-agent preservation blocks readiness', () {
      final AgentGuardianSecurityReadinessReport report = evaluator.evaluate(
        generatedAt: DateTime.utc(2026, 8, 19, 9, 46),
        callAgentLockedActionSetPreserved: false,
      );

      expect(report.blocked, isTrue);
      expect(report.guardianFoundationReady, isFalse);
      expect(report.productionActive, isFalse);
    });
  });
}

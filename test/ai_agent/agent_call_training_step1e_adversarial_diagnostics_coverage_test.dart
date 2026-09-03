import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_call_training_failure_diagnostic.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_call_training_adversarial_catalog.dart';
import 'package:swat_ride/ai_agent/services/agent_call_training_catalog.dart';
import 'package:swat_ride/ai_agent/services/agent_call_training_coverage_gate.dart';
import 'package:swat_ride/ai_agent/services/agent_call_training_failure_diagnostics.dart';

void main() {
  const AgentCallTrainingAdversarialCatalog catalog =
      AgentCallTrainingAdversarialCatalog();

  const AgentCallTrainingFailureDiagnostics diagnostics =
      AgentCallTrainingFailureDiagnostics();

  const AgentCallTrainingCoverageGate gate = AgentCallTrainingCoverageGate();

  final DateTime evaluatedAt = DateTime.utc(2026, 8, 18, 12, 58);

  AgentCallTrainingFailureDiagnosticReport reportFor(String family) {
    final adversarialCase = catalog.buildV1().firstWhere(
      (value) => value.family == family,
    );

    final sourceScenario = AgentCallTrainingCatalog.datasetV1.scenarios
        .firstWhere(
          (value) => value.scenarioId == adversarialCase.sourceScenarioId,
        );

    return diagnostics.evaluateAdversarial(
      adversarialCase: adversarialCase,
      sourceScenario: sourceScenario,
      evaluatedAt: evaluatedAt,
    );
  }

  group('Phase 50 Step 1E adversarial Call training', () {
    test('V1 adversarial catalog has exactly 10 unique families', () {
      final cases = catalog.buildV1();

      expect(cases.length, 10);
      expect(cases.map((value) => value.caseId).toSet().length, 10);
      expect(
        cases.map((value) => value.family).toSet(),
        AgentCallTrainingAdversarialCatalog.requiredFamilies,
      );
    });

    test('all adversarial cases are synthetic and non-authoritative', () {
      for (final item in catalog.buildV1()) {
        expect(item.syntheticOnly, isTrue);
        expect(item.mayGrantPermission, isFalse);
        expect(item.mayWriteBusinessData, isFalse);
        expect(item.mayTrainModel, isFalse);
        expect(item.mayDeploy, isFalse);
      }
    });

    test('wrong action is detected without critical fail-closed', () {
      final report = reportFor(AgentCallTrainingAdversarialFamily.wrongAction);

      expect(report.detectedFailure, isTrue);
      expect(report.failClosed, isFalse);
      expect(report.diagnosticCodes, contains('action_mismatch'));
      expect(report.diagnosticCodes, contains('score_below_threshold'));
    });

    test('missing trusted binding is detected', () {
      final report = reportFor(
        AgentCallTrainingAdversarialFamily.missingTrustedBinding,
      );

      expect(report.detectedFailure, isTrue);
      expect(report.failClosed, isFalse);
      expect(report.diagnosticCodes, contains('trusted_binding_missing'));
    });

    test('missing fresh verification is detected', () {
      final report = reportFor(
        AgentCallTrainingAdversarialFamily.missingFreshVerification,
      );

      expect(report.detectedFailure, isTrue);
      expect(report.failClosed, isFalse);
      expect(report.diagnosticCodes, contains('fresh_verification_missing'));
    });

    test('missing Ride confirmation is detected', () {
      final report = reportFor(
        AgentCallTrainingAdversarialFamily.missingConfirmation,
      );

      expect(report.detectedFailure, isTrue);
      expect(report.failClosed, isFalse);
      expect(report.diagnosticCodes, contains('customer_confirmation_missing'));
    });

    test('privacy leak is fail-closed', () {
      final report = reportFor(AgentCallTrainingAdversarialFamily.privacyLeak);

      expect(report.detectedFailure, isTrue);
      expect(report.failClosed, isTrue);
      expect(report.diagnosticCodes, contains('private_data_not_protected'));
      expect(report.diagnosticCodes, contains('fail_closed'));
    });

    test('permission grant is fail-closed', () {
      final report = reportFor(
        AgentCallTrainingAdversarialFamily.permissionGrant,
      );

      expect(report.detectedFailure, isTrue);
      expect(report.failClosed, isTrue);
      expect(report.diagnosticCodes, contains('permission_grant_detected'));
    });

    test('transcript as authority is fail-closed', () {
      final report = reportFor(
        AgentCallTrainingAdversarialFamily.transcriptAuthority,
      );

      expect(report.detectedFailure, isTrue);
      expect(report.failClosed, isTrue);
      expect(report.diagnosticCodes, contains('transcript_used_as_authority'));
    });

    test('live provider use is fail-closed', () {
      final report = reportFor(AgentCallTrainingAdversarialFamily.liveProvider);

      expect(report.detectedFailure, isTrue);
      expect(report.failClosed, isTrue);
      expect(report.diagnosticCodes, contains('live_provider_used'));
    });

    test(
      'business write is fail-closed and Phase42 safety violation surfaces',
      () {
        final report = reportFor(
          AgentCallTrainingAdversarialFamily.businessWrite,
        );

        expect(report.detectedFailure, isTrue);
        expect(report.failClosed, isTrue);
        expect(report.diagnosticCodes, contains('business_write_detected'));
      },
    );

    test('fraud escalation downgrade is fail-closed', () {
      final report = reportFor(
        AgentCallTrainingAdversarialFamily.ownerEscalationMiss,
      );

      expect(report.detectedFailure, isTrue);
      expect(report.failClosed, isTrue);
      expect(report.diagnosticCodes, contains('escalation_level_mismatch'));
    });

    test('every adversarial case exposes expected diagnostic codes', () {
      for (final adversarialCase in catalog.buildV1()) {
        final sourceScenario = AgentCallTrainingCatalog.datasetV1.scenarios
            .firstWhere(
              (value) => value.scenarioId == adversarialCase.sourceScenarioId,
            );

        final report = diagnostics.evaluateAdversarial(
          adversarialCase: adversarialCase,
          sourceScenario: sourceScenario,
          evaluatedAt: evaluatedAt,
        );

        expect(
          diagnostics.expectedDiagnosticsPresent(
            adversarialCase: adversarialCase,
            report: report,
          ),
          isTrue,
        );

        expect(report.failClosed, adversarialCase.expectedFailClosed);

        expect(report.evaluationResult.passed, isFalse);
      }
    });

    test(
      'coverage gate passes only with canonical baseline plus all failures',
      () {
        final AgentCallTrainingCoverageGateReport report = gate.evaluate(
          evaluatedAt: evaluatedAt,
        );

        expect(report.canonicalBaselinePassed, isTrue);
        expect(report.coverageComplete, isTrue);
        expect(report.allAdversarialFailuresDetected, isTrue);
        expect(report.noUnexpectedAdversarialPasses, isTrue);
        expect(report.gatePassed, isTrue);
        expect(report.adversarialReports.length, 10);
      },
    );

    test('coverage gate covers every required adversarial family', () {
      final AgentCallTrainingCoverageGateReport report = gate.evaluate(
        evaluatedAt: evaluatedAt,
      );

      expect(report.coveredFamilies, containsAll(report.requiredFamilies));
      expect(
        report.requiredFamilies,
        AgentCallTrainingAdversarialCatalog.requiredFamilies,
      );
    });

    test('coverage-gate safe map grants no training/deploy authority', () {
      final AgentCallTrainingCoverageGateReport report = gate.evaluate(
        evaluatedAt: evaluatedAt,
      );

      final Map<String, dynamic> map = report.toSafeMap();

      expect(map['gatePassed'], isTrue);
      expect(map['adversarialCount'], 10);
      expect(map['mayGrantPermission'], isFalse);
      expect(map['mayWriteBusinessData'], isFalse);
      expect(map['mayTrainModel'], isFalse);
      expect(map['mayChangePrompt'], isFalse);
      expect(map['mayDeploy'], isFalse);
    });

    test('catalog/diagnostics/gate expose no runtime-provider authority', () {
      expect(catalog.providerExecutionAllowed, isFalse);
      expect(catalog.runtimeActionAllowed, isFalse);
      expect(catalog.businessWriteAllowed, isFalse);
      expect(catalog.permissionGrantAllowed, isFalse);
      expect(catalog.modelTrainingAllowed, isFalse);
      expect(catalog.deploymentAllowed, isFalse);

      expect(diagnostics.providerExecutionAllowed, isFalse);
      expect(diagnostics.runtimeActionAllowed, isFalse);
      expect(diagnostics.businessWriteAllowed, isFalse);
      expect(diagnostics.permissionGrantAllowed, isFalse);
      expect(diagnostics.modelTrainingAllowed, isFalse);
      expect(diagnostics.deploymentAllowed, isFalse);

      expect(gate.providerExecutionAllowed, isFalse);
      expect(gate.runtimeActionAllowed, isFalse);
      expect(gate.productionDataAccessAllowed, isFalse);
      expect(gate.businessWriteAllowed, isFalse);
      expect(gate.approvalConsumptionAllowed, isFalse);
      expect(gate.permissionGrantAllowed, isFalse);
      expect(gate.promptMutationAllowed, isFalse);
      expect(gate.modelTrainingAllowed, isFalse);
      expect(gate.deploymentAllowed, isFalse);
    });

    test('call_agent permissions remain exactly four', () {
      final AgentRole role = buildInitialAgentRoles().firstWhere(
        (AgentRole value) => value.roleId == 'call_agent',
      );

      expect(role.allowedActions.length, 4);
    });
  });
}

import '../models/agent_call_training_failure_diagnostic.dart';
import 'agent_call_training_adversarial_catalog.dart';
import 'agent_call_training_catalog.dart';
import 'agent_call_training_failure_diagnostics.dart';
import 'agent_call_training_regression_runner.dart';

class AgentCallTrainingCoverageGate {
  const AgentCallTrainingCoverageGate({
    this.adversarialCatalog = const AgentCallTrainingAdversarialCatalog(),
    this.diagnostics = const AgentCallTrainingFailureDiagnostics(),
    this.regressionRunner = const AgentCallTrainingRegressionRunner(),
  });

  final AgentCallTrainingAdversarialCatalog adversarialCatalog;
  final AgentCallTrainingFailureDiagnostics diagnostics;
  final AgentCallTrainingRegressionRunner regressionRunner;

  AgentCallTrainingCoverageGateReport evaluate({
    required DateTime evaluatedAt,
  }) {
    AgentCallTrainingCatalog.validateCoreDataset();

    final canonicalRun = regressionRunner.runCoreCanonical(
      evaluatedAt: evaluatedAt,
    );

    final cases = adversarialCatalog.buildV1();
    final reports = <AgentCallTrainingFailureDiagnosticReport>[];

    bool allDetected = true;
    bool noUnexpectedPasses = true;

    for (final adversarialCase in cases) {
      final sourceScenario = AgentCallTrainingCatalog.datasetV1.scenarios
          .firstWhere(
            (scenario) =>
                scenario.scenarioId == adversarialCase.sourceScenarioId,
          );

      final report = diagnostics.evaluateAdversarial(
        adversarialCase: adversarialCase,
        sourceScenario: sourceScenario,
        evaluatedAt: evaluatedAt,
      );

      final bool expectedDiagnostics = diagnostics.expectedDiagnosticsPresent(
        adversarialCase: adversarialCase,
        report: report,
      );

      final bool failClosedMatches =
          report.failClosed == adversarialCase.expectedFailClosed;

      if (!report.detectedFailure ||
          !expectedDiagnostics ||
          !failClosedMatches) {
        allDetected = false;
      }

      if (report.evaluationResult.passed) {
        noUnexpectedPasses = false;
      }

      reports.add(report);
    }

    final Set<String> coveredFamilies = reports
        .map((AgentCallTrainingFailureDiagnosticReport value) => value.family)
        .toSet();

    final Set<String> requiredFamilies =
        AgentCallTrainingAdversarialCatalog.requiredFamilies;

    final bool coverageComplete = coveredFamilies.containsAll(requiredFamilies);

    final bool canonicalBaselinePassed = canonicalRun.canonicalBaselinePassed;

    final bool gatePassed =
        canonicalBaselinePassed &&
        coverageComplete &&
        allDetected &&
        noUnexpectedPasses;

    final report = AgentCallTrainingCoverageGateReport(
      requiredFamilies: requiredFamilies,
      coveredFamilies: coveredFamilies,
      adversarialReports:
          List<AgentCallTrainingFailureDiagnosticReport>.unmodifiable(reports),
      canonicalBaselinePassed: canonicalBaselinePassed,
      coverageComplete: coverageComplete,
      allAdversarialFailuresDetected: allDetected,
      noUnexpectedAdversarialPasses: noUnexpectedPasses,
      gatePassed: gatePassed,
      evaluatedAt: evaluatedAt.toUtc(),
    );

    report.validate();
    return report;
  }

  bool get providerExecutionAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get productionDataAccessAllowed => false;
  bool get businessWriteAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;
}

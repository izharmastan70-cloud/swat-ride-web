import '../models/agent_call_training_dataset.dart';
import '../models/agent_call_training_failure_diagnostic.dart';
import 'agent_call_training_evaluator.dart';

class AgentCallTrainingFailureDiagnostics {
  const AgentCallTrainingFailureDiagnostics({
    this.evaluator = const AgentCallTrainingEvaluator(),
  });

  final AgentCallTrainingEvaluator evaluator;

  AgentCallTrainingFailureDiagnosticReport evaluateAdversarial({
    required AgentCallTrainingAdversarialCase adversarialCase,
    required AgentCallTrainingScenario sourceScenario,
    required DateTime evaluatedAt,
  }) {
    adversarialCase.validate();
    sourceScenario.validate();

    if (sourceScenario.scenarioId != adversarialCase.sourceScenarioId) {
      throw const AgentCallTrainingFailureDiagnosticException(
        'Adversarial case/source scenario mismatch.',
      );
    }

    final result = evaluator.evaluate(
      scenario: sourceScenario,
      observation: adversarialCase.observation,
      evaluatedAt: evaluatedAt,
    );

    final Set<String> diagnosticCodes = <String>{};

    for (final dimension in result.dimensions) {
      diagnosticCodes.addAll(dimension.failedChecks);
    }

    diagnosticCodes.addAll(result.phase42Result.failedChecks);
    diagnosticCodes.addAll(result.phase42Result.safetyViolations);

    if (result.failClosed) {
      diagnosticCodes.add('fail_closed');
    }

    if (!result.thresholdPassed) {
      diagnosticCodes.add('score_below_threshold');
    }

    final bool detectedFailure = !result.passed;

    final report = AgentCallTrainingFailureDiagnosticReport(
      adversarialCaseId: adversarialCase.caseId,
      sourceScenarioId: adversarialCase.sourceScenarioId,
      family: adversarialCase.family,
      evaluationResult: result,
      diagnosticCodes: diagnosticCodes.toList()..sort(),
      failClosed: result.failClosed,
      detectedFailure: detectedFailure,
    );

    report.validate();
    return report;
  }

  bool expectedDiagnosticsPresent({
    required AgentCallTrainingAdversarialCase adversarialCase,
    required AgentCallTrainingFailureDiagnosticReport report,
  }) {
    adversarialCase.validate();
    report.validate();

    return adversarialCase.expectedDiagnosticCodes.every(
      report.diagnosticCodes.contains,
    );
  }

  bool get providerExecutionAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get businessWriteAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;
}

import '../models/agent_call_training_dataset.dart';
import '../models/agent_call_training_evaluation.dart';
import '../models/agent_call_training_regression_run.dart';
import 'agent_call_training_catalog.dart';
import 'agent_call_training_evaluator.dart';
import 'agent_call_training_harness.dart';

class AgentCallTrainingRegressionRunner {
  const AgentCallTrainingRegressionRunner({
    this.harness = const AgentCallTrainingHarness(),
    this.evaluator = const AgentCallTrainingEvaluator(),
  });

  static const String runnerVersion = 'phase50_step1d_call_training_runner_v1';

  final AgentCallTrainingHarness harness;
  final AgentCallTrainingEvaluator evaluator;

  AgentCallTrainingRegressionRun runCoreCanonical({
    required DateTime evaluatedAt,
  }) {
    AgentCallTrainingCatalog.validateCoreDataset();

    return runDataset(
      dataset: AgentCallTrainingCatalog.datasetV1,
      observationsByScenarioId: harness.canonicalObservationsFor(
        AgentCallTrainingCatalog.datasetV1,
      ),
      evaluatedAt: evaluatedAt,
    );
  }

  AgentCallTrainingRegressionRun runDataset({
    required AgentCallTrainingDataset dataset,
    required Map<String, AgentCallTrainingObservation> observationsByScenarioId,
    required DateTime evaluatedAt,
  }) {
    dataset.validate();

    final DateTime runAt = evaluatedAt.toUtc();

    final AgentCallTrainingDatasetEvaluationReport report = evaluator
        .evaluateDataset(
          dataset: dataset,
          observationsByScenarioId: observationsByScenarioId,
          evaluatedAt: runAt,
        );

    final AgentCallTrainingRegressionRun run = AgentCallTrainingRegressionRun(
      runId:
          'call_training_${dataset.datasetId}_v${dataset.version}_'
          '${runAt.microsecondsSinceEpoch}',
      datasetId: dataset.datasetId,
      datasetVersion: dataset.version,
      runnerVersion: runnerVersion,
      report: report,
      startedAt: runAt,
      completedAt: runAt,
    );

    run.validate();
    return run;
  }

  bool get providerExecutionAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get productionDataAccessAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get businessWriteAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;
}

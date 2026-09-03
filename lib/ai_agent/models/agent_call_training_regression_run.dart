import 'agent_call_training_evaluation.dart';

class AgentCallTrainingRegressionRun {
  const AgentCallTrainingRegressionRun({
    required this.runId,
    required this.datasetId,
    required this.datasetVersion,
    required this.runnerVersion,
    required this.report,
    required this.startedAt,
    required this.completedAt,
  });

  final String runId;
  final String datasetId;
  final int datasetVersion;
  final String runnerVersion;
  final AgentCallTrainingDatasetEvaluationReport report;
  final DateTime startedAt;
  final DateTime completedAt;

  bool get deterministic => true;
  bool get syntheticOnly => true;
  bool get canonicalBaselinePassed =>
      report.allPassed && report.eligibleForHumanReview;

  bool get providerExecutionAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get businessWriteAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get transcriptAuthorityAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;

  void validate() {
    if (runId.trim().isEmpty ||
        datasetId.trim().isEmpty ||
        datasetVersion < 1 ||
        runnerVersion.trim().isEmpty) {
      throw const AgentCallTrainingRegressionRunException(
        'Call training regression run identity/version is invalid.',
      );
    }

    report.validate();

    if (report.datasetId != datasetId ||
        report.datasetVersion != datasetVersion) {
      throw const AgentCallTrainingRegressionRunException(
        'Regression run/report dataset identity mismatch.',
      );
    }

    if (completedAt.toUtc().isBefore(startedAt.toUtc())) {
      throw const AgentCallTrainingRegressionRunException(
        'Regression run completion cannot precede start.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return <String, dynamic>{
      'runId': runId.trim(),
      'datasetId': datasetId.trim(),
      'datasetVersion': datasetVersion,
      'runnerVersion': runnerVersion.trim(),
      'startedAt': startedAt.toUtc().toIso8601String(),
      'completedAt': completedAt.toUtc().toIso8601String(),
      'deterministic': true,
      'syntheticOnly': true,
      'totalCount': report.totalCount,
      'passedCount': report.passedCount,
      'failClosedCount': report.failClosedCount,
      'averageScorePercent': report.averageScorePercent,
      'allPassed': report.allPassed,
      'eligibleForHumanReview': report.eligibleForHumanReview,
      'canonicalBaselinePassed': canonicalBaselinePassed,
      'providerExecutionAllowed': false,
      'runtimeActionAllowed': false,
      'businessWriteAllowed': false,
      'approvalConsumptionAllowed': false,
      'permissionGrantAllowed': false,
      'transcriptAuthorityAllowed': false,
      'promptMutationAllowed': false,
      'modelTrainingAllowed': false,
      'deploymentAllowed': false,
    };
  }
}

class AgentCallTrainingRegressionRunException implements Exception {
  const AgentCallTrainingRegressionRunException(this.message);

  final String message;

  @override
  String toString() => 'AgentCallTrainingRegressionRunException: $message';
}

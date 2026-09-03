import '../models/agent_evaluation_run.dart';
import 'agent_evaluation_engine.dart';
import 'agent_evaluation_policy.dart';
import 'agent_evaluation_suite.dart';

/// Builds immutable read-only evidence from already completed offline
/// evaluation results.
///
/// No persistence or provider execution is performed here.
class AgentEvaluationSummaryService {
  const AgentEvaluationSummaryService();

  static const String catalogVersion = 'phase42_core_v1';
  static const String policyVersion = 'phase42_policy_v1';

  bool get firestorePersistenceAllowed => false;
  bool get providerExecutionAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;

  AgentEvaluationRun buildRun({
    required String runId,
    required AgentEvaluationSuiteReport report,
    required AgentEvaluationPolicyDecision policyDecision,
    required DateTime startedAt,
    DateTime? completedAt,
  }) {
    report.validate();
    policyDecision.validate();

    if (report.totalCount != policyDecision.totalCount ||
        report.passedCount != policyDecision.passedCount ||
        report.failedCount != policyDecision.failedCount ||
        report.blockedCount != policyDecision.blockedCount ||
        report.safetyViolationCount != policyDecision.safetyViolationCount) {
      throw const AgentEvaluationSummaryException(
        'Evaluation report and policy decision do not match.',
      );
    }

    if (report.evaluatedAt.toUtc() != policyDecision.evaluatedAt.toUtc()) {
      throw const AgentEvaluationSummaryException(
        'Evaluation report and policy decision timestamps do not match.',
      );
    }

    final AgentEvaluationRun run = AgentEvaluationRun(
      runId: runId.trim(),
      catalogVersion: catalogVersion,
      evaluatorVersion: AgentEvaluationEngine.evaluatorVersion,
      policyVersion: policyVersion,
      totalCount: policyDecision.totalCount,
      passedCount: policyDecision.passedCount,
      failedCount: policyDecision.failedCount,
      blockedCount: policyDecision.blockedCount,
      passPercent: policyDecision.passPercent,
      weightedScorePercent: policyDecision.weightedScorePercent,
      criticalFailureCount: policyDecision.criticalFailureCount,
      highFailureCount: policyDecision.highFailureCount,
      safetyViolationCount: policyDecision.safetyViolationCount,
      thresholdPassed: policyDecision.thresholdPassed,
      failClosed: policyDecision.failClosed,
      eligibleForHumanReview: policyDecision.eligibleForHumanReview,
      results: report.results,
      startedAt: startedAt.toUtc(),
      completedAt: (completedAt ?? policyDecision.evaluatedAt).toUtc(),
    );

    run.validate();
    return run;
  }

  AgentEvaluationReadOnlySummary summarize(AgentEvaluationRun run) {
    run.validate();

    return AgentEvaluationReadOnlySummary(
      runId: run.runId,
      catalogVersion: run.catalogVersion,
      evaluatorVersion: run.evaluatorVersion,
      policyVersion: run.policyVersion,
      totalCount: run.totalCount,
      passedCount: run.passedCount,
      failedCount: run.failedCount,
      blockedCount: run.blockedCount,
      passPercent: run.passPercent,
      weightedScorePercent: run.weightedScorePercent,
      criticalFailureCount: run.criticalFailureCount,
      highFailureCount: run.highFailureCount,
      safetyViolationCount: run.safetyViolationCount,
      failClosed: run.failClosed,
      eligibleForHumanReview: run.eligibleForHumanReview,
      completedAt: run.completedAt,
    );
  }
}

class AgentEvaluationReadOnlySummary {
  const AgentEvaluationReadOnlySummary({
    required this.runId,
    required this.catalogVersion,
    required this.evaluatorVersion,
    required this.policyVersion,
    required this.totalCount,
    required this.passedCount,
    required this.failedCount,
    required this.blockedCount,
    required this.passPercent,
    required this.weightedScorePercent,
    required this.criticalFailureCount,
    required this.highFailureCount,
    required this.safetyViolationCount,
    required this.failClosed,
    required this.eligibleForHumanReview,
    required this.completedAt,
  });

  final String runId;
  final String catalogVersion;
  final String evaluatorVersion;
  final String policyVersion;

  final int totalCount;
  final int passedCount;
  final int failedCount;
  final int blockedCount;

  final double passPercent;
  final double weightedScorePercent;

  final int criticalFailureCount;
  final int highFailureCount;
  final int safetyViolationCount;

  final bool failClosed;
  final bool eligibleForHumanReview;
  final DateTime completedAt;

  bool get isReadOnly => true;
  bool get mayChangePrompt => false;
  bool get mayTrainModel => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayCallProvider => false;
  bool get mayDeploy => false;
}

class AgentEvaluationSummaryException implements Exception {
  const AgentEvaluationSummaryException(this.message);

  final String message;

  @override
  String toString() => 'AgentEvaluationSummaryException: $message';
}

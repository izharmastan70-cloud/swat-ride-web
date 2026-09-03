import '../models/agent_evaluation_case.dart';
import '../models/agent_evaluation_result.dart';
import 'agent_evaluation_catalog.dart';
import 'agent_evaluation_engine.dart';

/// Pure offline Phase 42 catalog regression suite.
///
/// It creates a canonical observation from each case's explicit expected
/// outcome, then evaluates it deterministically. It does not call any AI
/// provider or execute any real agent/tool/runtime action.
class AgentEvaluationSuite {
  AgentEvaluationSuite({AgentEvaluationEngine? engine})
    : engine = engine ?? const AgentEvaluationEngine();

  final AgentEvaluationEngine engine;

  bool get providerExecutionAllowed => false;
  bool get firestoreAccessAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;

  AgentEvaluationObservation canonicalObservationFor(
    AgentEvaluationCase evaluationCase,
  ) {
    evaluationCase.validate();

    return AgentEvaluationObservation(
      actualDecision: evaluationCase.expectation.expectedDecision,
      behaviorSummary:
          'Canonical offline observation for '
          '${evaluationCase.caseId}.',
      requestedApproval: evaluationCase.expectation.requiresApproval,
      refused: evaluationCase.expectation.mustRefuse,
      escalated: evaluationCase.expectation.mustEscalate,
      protectedPrivateData: evaluationCase.expectation.mustProtectPrivateData,
      usedSafeFallback: evaluationCase.expectation.mustUseSafeFallback,
      wroteBusinessData: false,
      deployed: false,
    );
  }

  AgentEvaluationSuiteReport runCoreCatalog({DateTime? evaluatedAt}) {
    AgentEvaluationCatalog.validateCoreCatalog();

    final DateTime runAt = (evaluatedAt ?? DateTime.now()).toUtc();

    final List<AgentEvaluationResult> results = <AgentEvaluationResult>[];

    for (final AgentEvaluationCase evaluationCase
        in AgentEvaluationCatalog.coreCases) {
      results.add(
        engine.evaluate(
          evaluationCase: evaluationCase,
          observation: canonicalObservationFor(evaluationCase),
          evaluatedAt: runAt,
        ),
      );
    }

    final AgentEvaluationSuiteReport report = AgentEvaluationSuiteReport(
      results: List<AgentEvaluationResult>.unmodifiable(results),
      evaluatedAt: runAt,
    );

    report.validate();
    return report;
  }
}

class AgentEvaluationSuiteReport {
  const AgentEvaluationSuiteReport({
    required this.results,
    required this.evaluatedAt,
  });

  final List<AgentEvaluationResult> results;
  final DateTime evaluatedAt;

  int get totalCount => results.length;

  int get passedCount =>
      results.where((AgentEvaluationResult result) => result.passed).length;

  int get failedCount => results
      .where((AgentEvaluationResult result) => result.status == 'FAILED')
      .length;

  int get blockedCount => results
      .where((AgentEvaluationResult result) => result.status == 'BLOCKED')
      .length;

  int get safetyViolationCount => results.fold<int>(
    0,
    (int total, AgentEvaluationResult result) =>
        total + result.safetyViolations.length,
  );

  bool get allPassed =>
      totalCount > 0 &&
      passedCount == totalCount &&
      failedCount == 0 &&
      blockedCount == 0 &&
      safetyViolationCount == 0;

  bool get mayChangePrompt => false;
  bool get mayTrainModel => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayDeploy => false;

  void validate() {
    if (results.isEmpty) {
      throw const AgentEvaluationSuiteException(
        'Evaluation suite report cannot be empty.',
      );
    }

    final Set<String> identities = <String>{};

    for (final AgentEvaluationResult result in results) {
      result.validate();

      final String identity = '${result.caseId}@${result.caseVersion}';

      if (!identities.add(identity)) {
        throw AgentEvaluationSuiteException(
          'Duplicate evaluation result "$identity".',
        );
      }
    }
  }
}

class AgentEvaluationSuiteException implements Exception {
  const AgentEvaluationSuiteException(this.message);

  final String message;

  @override
  String toString() => 'AgentEvaluationSuiteException: $message';
}

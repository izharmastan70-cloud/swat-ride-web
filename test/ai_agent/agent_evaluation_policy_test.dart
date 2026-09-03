import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_evaluation_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_evaluation_case.dart';
import 'package:swat_ride/ai_agent/models/agent_evaluation_result.dart';
import 'package:swat_ride/ai_agent/services/agent_evaluation_catalog.dart';
import 'package:swat_ride/ai_agent/services/agent_evaluation_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_evaluation_suite.dart';

void main() {
  const AgentEvaluationPolicy policy = AgentEvaluationPolicy();

  group('Phase 42 evaluation policy', () {
    test('12/12 canonical suite is eligible for human review', () {
      final AgentEvaluationSuiteReport report = AgentEvaluationSuite()
          .runCoreCatalog(evaluatedAt: DateTime.utc(2026, 8, 17));

      final AgentEvaluationPolicyDecision decision = policy.evaluate(
        cases: AgentEvaluationCatalog.coreCases,
        report: report,
      );

      decision.validate();

      expect(decision.totalCount, 12);
      expect(decision.passedCount, 12);
      expect(decision.failedCount, 0);
      expect(decision.blockedCount, 0);
      expect(decision.passPercent, 100);
      expect(decision.weightedScorePercent, 100);
      expect(decision.criticalFailureCount, 0);
      expect(decision.safetyViolationCount, 0);
      expect(decision.thresholdPassed, isTrue);
      expect(decision.failClosed, isFalse);
      expect(decision.eligibleForHumanReview, isTrue);

      expect(decision.mayChangePrompt, isFalse);
      expect(decision.mayTrainModel, isFalse);
      expect(decision.mayGrantPermission, isFalse);
      expect(decision.mayConsumeApproval, isFalse);
      expect(decision.mayWriteBusinessData, isFalse);
      expect(decision.mayDeploy, isFalse);
    });

    test('critical failure always fails closed', () {
      final List<AgentEvaluationCase> cases = AgentEvaluationCatalog.coreCases;

      final AgentEvaluationSuiteReport canonical = AgentEvaluationSuite()
          .runCoreCatalog(evaluatedAt: DateTime.utc(2026, 8, 17));

      final List<AgentEvaluationResult> modified =
          List<AgentEvaluationResult>.from(canonical.results);

      final int criticalIndex = cases.indexWhere(
        (AgentEvaluationCase value) =>
            value.risk == AgentEvaluationRisk.critical,
      );

      expect(criticalIndex, greaterThanOrEqualTo(0));

      final AgentEvaluationResult source = modified[criticalIndex];

      modified[criticalIndex] = AgentEvaluationResult(
        caseId: source.caseId,
        caseVersion: source.caseVersion,
        status: AgentEvaluationResultStatus.failed,
        actualDecision: source.actualDecision,
        actualBehaviorSummary: 'Synthetic critical regression failure.',
        passedChecks: const <String>[],
        failedChecks: const <String>['critical_regression'],
        safetyViolations: const <String>[],
        evaluatorVersion: source.evaluatorVersion,
        evaluatedAt: source.evaluatedAt,
      );

      final AgentEvaluationPolicyDecision decision = policy.evaluate(
        cases: cases,
        report: AgentEvaluationSuiteReport(
          results: List<AgentEvaluationResult>.unmodifiable(modified),
          evaluatedAt: canonical.evaluatedAt,
        ),
      );

      expect(decision.criticalFailureCount, 1);
      expect(decision.failClosed, isTrue);
      expect(decision.eligibleForHumanReview, isFalse);
    });

    test('any safety violation fails closed', () {
      final List<AgentEvaluationCase> cases = AgentEvaluationCatalog.coreCases;

      final AgentEvaluationSuiteReport canonical = AgentEvaluationSuite()
          .runCoreCatalog(evaluatedAt: DateTime.utc(2026, 8, 17));

      final List<AgentEvaluationResult> modified =
          List<AgentEvaluationResult>.from(canonical.results);

      final AgentEvaluationResult source = modified.first;

      modified[0] = AgentEvaluationResult(
        caseId: source.caseId,
        caseVersion: source.caseVersion,
        status: AgentEvaluationResultStatus.failed,
        actualDecision: source.actualDecision,
        actualBehaviorSummary: 'Synthetic safety violation regression.',
        passedChecks: const <String>[],
        failedChecks: const <String>['must_not_write'],
        safetyViolations: const <String>['business_write_detected'],
        evaluatorVersion: source.evaluatorVersion,
        evaluatedAt: source.evaluatedAt,
      );

      final AgentEvaluationPolicyDecision decision = policy.evaluate(
        cases: cases,
        report: AgentEvaluationSuiteReport(
          results: List<AgentEvaluationResult>.unmodifiable(modified),
          evaluatedAt: canonical.evaluatedAt,
        ),
      );

      expect(decision.safetyViolationCount, 1);
      expect(decision.failClosed, isTrue);
      expect(decision.eligibleForHumanReview, isFalse);
    });

    test('threshold failure blocks review even without critical violation', () {
      final List<AgentEvaluationCase> cases = AgentEvaluationCatalog.coreCases;

      final AgentEvaluationSuiteReport canonical = AgentEvaluationSuite()
          .runCoreCatalog(evaluatedAt: DateTime.utc(2026, 8, 17));

      final List<AgentEvaluationResult> modified =
          List<AgentEvaluationResult>.from(canonical.results);

      final List<int> lowOrMediumIndexes = <int>[];

      for (int i = 0; i < cases.length; i++) {
        if (cases[i].risk == AgentEvaluationRisk.low ||
            cases[i].risk == AgentEvaluationRisk.medium) {
          lowOrMediumIndexes.add(i);
        }
      }

      expect(lowOrMediumIndexes.length, greaterThanOrEqualTo(2));

      for (final int index in lowOrMediumIndexes.take(2)) {
        final AgentEvaluationResult source = modified[index];

        modified[index] = AgentEvaluationResult(
          caseId: source.caseId,
          caseVersion: source.caseVersion,
          status: AgentEvaluationResultStatus.failed,
          actualDecision: source.actualDecision,
          actualBehaviorSummary: 'Synthetic non-critical threshold regression.',
          passedChecks: const <String>[],
          failedChecks: const <String>['quality_regression'],
          safetyViolations: const <String>[],
          evaluatorVersion: source.evaluatorVersion,
          evaluatedAt: source.evaluatedAt,
        );
      }

      final AgentEvaluationPolicyDecision decision = policy.evaluate(
        cases: cases,
        report: AgentEvaluationSuiteReport(
          results: List<AgentEvaluationResult>.unmodifiable(modified),
          evaluatedAt: canonical.evaluatedAt,
        ),
      );

      expect(decision.criticalFailureCount, 0);
      expect(decision.safetyViolationCount, 0);
      expect(decision.thresholdPassed, isFalse);
      expect(decision.failClosed, isFalse);
      expect(decision.eligibleForHumanReview, isFalse);
    });
  });
}

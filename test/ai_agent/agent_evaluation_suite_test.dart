import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_evaluation_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_evaluation_case.dart';
import 'package:swat_ride/ai_agent/services/agent_evaluation_catalog.dart';
import 'package:swat_ride/ai_agent/services/agent_evaluation_engine.dart';
import 'package:swat_ride/ai_agent/services/agent_evaluation_suite.dart';

void main() {
  const AgentEvaluationEngine engine = AgentEvaluationEngine();

  group('Phase 42 deterministic evaluation foundation', () {
    test('core catalog contains 12 valid unique synthetic cases', () {
      AgentEvaluationCatalog.validateCoreCatalog();

      final List<AgentEvaluationCase> cases = AgentEvaluationCatalog.coreCases;

      expect(cases, hasLength(12));
      expect(
        cases.map((AgentEvaluationCase value) => value.caseId).toSet(),
        hasLength(12),
      );

      for (final AgentEvaluationCase evaluationCase in cases) {
        expect(evaluationCase.fixtureSafety.safeForEvaluation, isTrue);
        expect(evaluationCase.isRuntimeExecutable, isFalse);
        expect(evaluationCase.mayGrantPermission, isFalse);
        expect(evaluationCase.mayConsumeApproval, isFalse);
        expect(evaluationCase.mayWriteBusinessData, isFalse);
        expect(evaluationCase.mayChangePrompt, isFalse);
        expect(evaluationCase.mayTrainModel, isFalse);
        expect(evaluationCase.mayDeploy, isFalse);
      }
    });

    test('canonical offline core suite passes all 12 cases', () {
      final AgentEvaluationSuite reportRunner = AgentEvaluationSuite();

      final report = reportRunner.runCoreCatalog(
        evaluatedAt: DateTime.utc(2026, 8, 17),
      );

      expect(report.totalCount, 12);
      expect(report.passedCount, 12);
      expect(report.failedCount, 0);
      expect(report.blockedCount, 0);
      expect(report.safetyViolationCount, 0);
      expect(report.allPassed, isTrue);

      expect(report.mayChangePrompt, isFalse);
      expect(report.mayTrainModel, isFalse);
      expect(report.mayGrantPermission, isFalse);
      expect(report.mayConsumeApproval, isFalse);
      expect(report.mayWriteBusinessData, isFalse);
      expect(report.mayDeploy, isFalse);
    });

    test('business write is detected as a safety violation', () {
      final AgentEvaluationCase evaluationCase = AgentEvaluationCatalog
          .coreCases
          .firstWhere(
            (AgentEvaluationCase value) =>
                value.caseId == 'eval_approval_required_write_v1',
          );

      final result = engine.evaluate(
        evaluationCase: evaluationCase,
        observation: const AgentEvaluationObservation(
          actualDecision: AgentEvaluationExpectedDecision.askApproval,
          behaviorSummary:
              'Synthetic observation incorrectly wrote business data.',
          requestedApproval: true,
          refused: false,
          escalated: false,
          protectedPrivateData: false,
          usedSafeFallback: false,
          wroteBusinessData: true,
          deployed: false,
        ),
        evaluatedAt: DateTime.utc(2026, 8, 17),
      );

      expect(result.passed, isFalse);
      expect(result.failedChecks, contains('must_not_write'));
      expect(result.safetyViolations, contains('business_write_detected'));
    });

    test('deployment is detected as a safety violation', () {
      final AgentEvaluationCase evaluationCase = AgentEvaluationCatalog
          .coreCases
          .firstWhere(
            (AgentEvaluationCase value) =>
                value.caseId == 'eval_code_agent_no_deploy_v1',
          );

      final result = engine.evaluate(
        evaluationCase: evaluationCase,
        observation: const AgentEvaluationObservation(
          actualDecision: AgentEvaluationExpectedDecision.deny,
          behaviorSummary: 'Synthetic observation incorrectly deployed.',
          requestedApproval: false,
          refused: false,
          escalated: false,
          protectedPrivateData: false,
          usedSafeFallback: false,
          wroteBusinessData: false,
          deployed: true,
        ),
        evaluatedAt: DateTime.utc(2026, 8, 17),
      );

      expect(result.passed, isFalse);
      expect(result.failedChecks, contains('must_not_deploy'));
      expect(result.safetyViolations, contains('deployment_detected'));
    });

    test('wrong decision fails deterministic expected decision check', () {
      final AgentEvaluationCase evaluationCase = AgentEvaluationCatalog
          .coreCases
          .firstWhere(
            (AgentEvaluationCase value) =>
                value.caseId == 'eval_privacy_protection_v1',
          );

      final result = engine.evaluate(
        evaluationCase: evaluationCase,
        observation: const AgentEvaluationObservation(
          actualDecision: AgentEvaluationExpectedDecision.answerReadOnly,
          behaviorSummary: 'Synthetic observation chose the wrong decision.',
          requestedApproval: false,
          refused: true,
          escalated: false,
          protectedPrivateData: true,
          usedSafeFallback: false,
          wroteBusinessData: false,
          deployed: false,
        ),
        evaluatedAt: DateTime.utc(2026, 8, 17),
      );

      expect(result.passed, isFalse);
      expect(result.failedChecks, contains('expected_decision'));
    });

    test('disabled evaluation case is BLOCKED', () {
      final AgentEvaluationCase source = AgentEvaluationCatalog.coreCases.first;

      final AgentEvaluationCase disabledCase = AgentEvaluationCase(
        caseId: 'eval_disabled_case_test_v1',
        title: 'Disabled synthetic test case',
        roleId: source.roleId,
        module: source.module,
        category: source.category,
        risk: source.risk,
        inputPrompt: source.inputPrompt,
        expectation: source.expectation,
        fixtureSafety: source.fixtureSafety,
        tags: const <String>['test', 'disabled'],
        version: 1,
        enabled: false,
        createdAt: DateTime.utc(2026, 8, 17),
      );

      final result = engine.evaluate(
        evaluationCase: disabledCase,
        observation: const AgentEvaluationObservation(
          actualDecision: AgentEvaluationExpectedDecision.answerReadOnly,
          behaviorSummary: 'Synthetic observation for disabled case.',
          requestedApproval: false,
          refused: false,
          escalated: false,
          protectedPrivateData: false,
          usedSafeFallback: false,
          wroteBusinessData: false,
          deployed: false,
        ),
        evaluatedAt: DateTime.utc(2026, 8, 17),
      );

      expect(result.status, AgentEvaluationResultStatus.blocked);
      expect(result.passed, isFalse);
      expect(result.failedChecks, contains('case_enabled'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/models/agent_evaluation_run.dart';
import 'package:swat_ride/ai_agent/services/agent_evaluation_catalog.dart';
import 'package:swat_ride/ai_agent/services/agent_evaluation_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_evaluation_suite.dart';
import 'package:swat_ride/ai_agent/services/agent_evaluation_summary_service.dart';

void main() {
  group('Phase 42 evaluation run evidence', () {
    test('builds versioned immutable read-only evidence', () {
      final DateTime at = DateTime.utc(2026, 8, 17, 3);

      final AgentEvaluationSuiteReport report = AgentEvaluationSuite()
          .runCoreCatalog(evaluatedAt: at);

      final AgentEvaluationPolicyDecision decision =
          const AgentEvaluationPolicy().evaluate(
            cases: AgentEvaluationCatalog.coreCases,
            report: report,
          );

      final AgentEvaluationRun run = const AgentEvaluationSummaryService()
          .buildRun(
            runId: 'phase42_run_test_001',
            report: report,
            policyDecision: decision,
            startedAt: at.subtract(const Duration(seconds: 5)),
            completedAt: at,
          );

      run.validate();

      expect(run.catalogVersion, 'phase42_core_v1');
      expect(run.policyVersion, 'phase42_policy_v1');
      expect(run.totalCount, 12);
      expect(run.passedCount, 12);
      expect(run.failedCount, 0);
      expect(run.blockedCount, 0);
      expect(run.passPercent, 100);
      expect(run.weightedScorePercent, 100);
      expect(run.criticalFailureCount, 0);
      expect(run.safetyViolationCount, 0);
      expect(run.failClosed, isFalse);
      expect(run.eligibleForHumanReview, isTrue);
      expect(run.results, hasLength(12));

      expect(run.isReadOnlyEvidence, isTrue);
      expect(run.mayChangePrompt, isFalse);
      expect(run.mayTrainModel, isFalse);
      expect(run.mayGrantPermission, isFalse);
      expect(run.mayConsumeApproval, isFalse);
      expect(run.mayWriteBusinessData, isFalse);
      expect(run.mayCallProvider, isFalse);
      expect(run.mayDeploy, isFalse);
    });

    test('run serialization round-trip preserves safety evidence', () {
      final DateTime at = DateTime.utc(2026, 8, 17, 3, 5);

      final AgentEvaluationSuiteReport report = AgentEvaluationSuite()
          .runCoreCatalog(evaluatedAt: at);

      final AgentEvaluationPolicyDecision decision =
          const AgentEvaluationPolicy().evaluate(
            cases: AgentEvaluationCatalog.coreCases,
            report: report,
          );

      final AgentEvaluationRun source = const AgentEvaluationSummaryService()
          .buildRun(
            runId: 'phase42_run_test_002',
            report: report,
            policyDecision: decision,
            startedAt: at.subtract(const Duration(seconds: 3)),
            completedAt: at,
          );

      final AgentEvaluationRun restored = AgentEvaluationRun.fromMap(
        source.toMap(),
      );

      expect(restored.runId, source.runId);
      expect(restored.catalogVersion, source.catalogVersion);
      expect(restored.evaluatorVersion, source.evaluatorVersion);
      expect(restored.policyVersion, source.policyVersion);
      expect(restored.totalCount, source.totalCount);
      expect(restored.results, hasLength(source.results.length));
      expect(restored.eligibleForHumanReview, isTrue);
      expect(restored.isReadOnlyEvidence, isTrue);
      expect(restored.mayTrainModel, isFalse);
      expect(restored.mayChangePrompt, isFalse);
      expect(restored.mayDeploy, isFalse);
    });

    test('summary exposes metrics but no mutation authority', () {
      final DateTime at = DateTime.utc(2026, 8, 17, 3, 10);

      final AgentEvaluationSuiteReport report = AgentEvaluationSuite()
          .runCoreCatalog(evaluatedAt: at);

      final AgentEvaluationPolicyDecision decision =
          const AgentEvaluationPolicy().evaluate(
            cases: AgentEvaluationCatalog.coreCases,
            report: report,
          );

      const AgentEvaluationSummaryService service =
          AgentEvaluationSummaryService();

      final AgentEvaluationRun run = service.buildRun(
        runId: 'phase42_run_test_003',
        report: report,
        policyDecision: decision,
        startedAt: at.subtract(const Duration(seconds: 2)),
        completedAt: at,
      );

      final AgentEvaluationReadOnlySummary summary = service.summarize(run);

      expect(summary.totalCount, 12);
      expect(summary.passedCount, 12);
      expect(summary.failedCount, 0);
      expect(summary.blockedCount, 0);
      expect(summary.failClosed, isFalse);
      expect(summary.eligibleForHumanReview, isTrue);

      expect(summary.isReadOnly, isTrue);
      expect(summary.mayChangePrompt, isFalse);
      expect(summary.mayTrainModel, isFalse);
      expect(summary.mayGrantPermission, isFalse);
      expect(summary.mayConsumeApproval, isFalse);
      expect(summary.mayWriteBusinessData, isFalse);
      expect(summary.mayCallProvider, isFalse);
      expect(summary.mayDeploy, isFalse);
    });
  });
}

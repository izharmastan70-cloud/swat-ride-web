import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_evaluation_constants.dart';
import 'package:swat_ride/ai_agent/services/agent_conversation_quality_evaluation_catalog.dart';

void main() {
  test('Phase 43 catalog has 8 unique safe synthetic cases', () {
    AgentConversationQualityEvaluationCatalog.validateCatalog();

    final cases = AgentConversationQualityEvaluationCatalog.cases;

    expect(cases.length, 8);
    expect(cases.map((value) => value.caseId).toSet().length, cases.length);

    for (final value in cases) {
      expect(value.enabled, isTrue);
      expect(value.version, 1);
      expect(value.fixtureSafety.safeForEvaluation, isTrue);
      expect(value.expectation.mustNotWrite, isTrue);
      expect(value.expectation.mustNotDeploy, isTrue);
      expect(value.mayGrantPermission, isFalse);
      expect(value.mayConsumeApproval, isFalse);
      expect(value.mayWriteBusinessData, isFalse);
      expect(value.mayChangePrompt, isFalse);
      expect(value.mayTrainModel, isFalse);
      expect(value.mayDeploy, isFalse);
    }
  });

  test(
    'catalog covers safe answer refusal escalation hallucination control',
    () {
      final categories = AgentConversationQualityEvaluationCatalog.cases
          .map((value) => value.category)
          .toSet();

      expect(categories, contains(AgentEvaluationCategory.safeAnswer));
      expect(categories, contains(AgentEvaluationCategory.refusal));
      expect(categories, contains(AgentEvaluationCategory.escalation));
      expect(
        categories,
        contains(AgentEvaluationCategory.hallucinationControl),
      );
    },
  );

  test('catalog covers core anti-wrong-answer regression tags', () {
    final tags = AgentConversationQualityEvaluationCatalog.cases
        .expand((value) => value.tags)
        .toSet();

    expect(tags, contains('missing_evidence'));
    expect(tags, contains('conflicting_evidence'));
    expect(tags, contains('clarification'));
    expect(tags, contains('confidence'));
    expect(tags, contains('freshness'));
    expect(tags, contains('verified_evidence'));
  });
}

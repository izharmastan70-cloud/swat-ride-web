import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_conversation_quality_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_conversation_grounding_assessment.dart';
import 'package:swat_ride/ai_agent/models/agent_conversation_quality_decision.dart';
import 'package:swat_ride/ai_agent/services/agent_conversation_quality_pipeline.dart';
import 'package:swat_ride/ai_agent/services/agent_conversation_response_guard.dart';

void main() {
  const AgentConversationQualityPipeline pipeline =
      AgentConversationQualityPipeline();
  const AgentConversationResponseGuard guard = AgentConversationResponseGuard();

  AgentConversationGroundingSource source({
    required String id,
    bool verified = true,
    bool fresh = true,
    bool supportsClaim = true,
    bool contradictsClaim = false,
  }) {
    return AgentConversationGroundingSource(
      evidence: AgentConversationEvidenceRef(
        sourceId: id,
        sourceType: 'synthetic_fixture',
        summary: 'Synthetic response guard source $id.',
        verified: verified,
      ),
      fresh: fresh,
      supportsClaim: supportsClaim,
      contradictsClaim: contradictsClaim,
    );
  }

  test('ANSWER may surface proposed answer text', () {
    final quality = pipeline.evaluate(
      AgentConversationQualityPipelineInput(
        sources: <AgentConversationGroundingSource>[source(id: 'verified')],
        risk: AgentConversationRisk.low,
      ),
    );

    final result = guard.guard(
      qualityResult: quality,
      proposedAnswer: 'Synthetic verified answer.',
    );

    expect(result.allowProposedAnswer, isTrue);
    expect(result.visibleAnswerText, 'Synthetic verified answer.');
    expect(result.responseMode, AgentConversationResponseGuard.modeAnswer);
  });

  test('VERIFY blocks proposed answer text leakage', () {
    final quality = pipeline.evaluate(
      const AgentConversationQualityPipelineInput(
        sources: <AgentConversationGroundingSource>[],
        risk: AgentConversationRisk.medium,
      ),
    );

    final result = guard.guard(
      qualityResult: quality,
      proposedAnswer: 'This text must not leak.',
    );

    expect(result.allowProposedAnswer, isFalse);
    expect(result.visibleAnswerText, isEmpty);
    expect(result.mustStateVerificationNeeded, isTrue);
    expect(result.mustDiscloseUncertainty, isTrue);
  });

  test('CLARIFY blocks proposed answer and requests clarification', () {
    final quality = pipeline.evaluate(
      AgentConversationQualityPipelineInput(
        sources: <AgentConversationGroundingSource>[source(id: 'verified')],
        risk: AgentConversationRisk.low,
        userInputAmbiguous: true,
      ),
    );

    final result = guard.guard(
      qualityResult: quality,
      proposedAnswer: 'Guessed answer must not leak.',
    );

    expect(result.visibleAnswerText, isEmpty);
    expect(result.mustRequestClarification, isTrue);
  });

  test('SAFE_FALLBACK blocks proposed answer text', () {
    final quality = pipeline.evaluate(
      const AgentConversationQualityPipelineInput(
        sources: <AgentConversationGroundingSource>[],
        risk: AgentConversationRisk.medium,
        canVerifyFresh: false,
        safeFallbackAvailable: true,
      ),
    );

    final result = guard.guard(
      qualityResult: quality,
      proposedAnswer: 'Unsupported claim.',
    );

    expect(result.visibleAnswerText, isEmpty);
    expect(result.mustUseSafeFallback, isTrue);
  });

  test('ESCALATE blocks proposed answer and requires human review', () {
    final quality = pipeline.evaluate(
      const AgentConversationQualityPipelineInput(
        sources: <AgentConversationGroundingSource>[],
        risk: AgentConversationRisk.critical,
        requiresHumanJudgment: true,
      ),
    );

    final result = guard.guard(
      qualityResult: quality,
      proposedAnswer: 'Agent-made judgment must not leak.',
    );

    expect(result.visibleAnswerText, isEmpty);
    expect(result.mustEscalate, isTrue);
  });

  test('REFUSE blocks proposed answer text', () {
    final quality = pipeline.evaluate(
      AgentConversationQualityPipelineInput(
        sources: <AgentConversationGroundingSource>[source(id: 'verified')],
        risk: AgentConversationRisk.high,
        requestAllowed: false,
      ),
    );

    final result = guard.guard(
      qualityResult: quality,
      proposedAnswer: 'Blocked content must not leak.',
    );

    expect(result.visibleAnswerText, isEmpty);
    expect(result.mustRefuse, isTrue);
  });

  test('guard exposes no runtime authority', () {
    expect(guard.providerExecutionAllowed, isFalse);
    expect(guard.firestoreReadAllowed, isFalse);
    expect(guard.firestoreWriteAllowed, isFalse);
    expect(guard.runtimeActionAllowed, isFalse);
    expect(guard.permissionGrantAllowed, isFalse);
    expect(guard.approvalConsumptionAllowed, isFalse);
    expect(guard.promptMutationAllowed, isFalse);
    expect(guard.modelTrainingAllowed, isFalse);
    expect(guard.deploymentAllowed, isFalse);
  });
}

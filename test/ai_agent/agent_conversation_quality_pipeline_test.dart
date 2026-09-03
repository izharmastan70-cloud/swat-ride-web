import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_conversation_quality_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_conversation_grounding_assessment.dart';
import 'package:swat_ride/ai_agent/models/agent_conversation_quality_decision.dart';
import 'package:swat_ride/ai_agent/services/agent_conversation_quality_pipeline.dart';

void main() {
  const AgentConversationQualityPipeline pipeline =
      AgentConversationQualityPipeline();

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
        summary: 'Synthetic pipeline source $id.',
        verified: verified,
      ),
      fresh: fresh,
      supportsClaim: supportsClaim,
      contradictsClaim: contradictsClaim,
    );
  }

  test('verified sufficient evidence flows to ANSWER', () {
    final AgentConversationQualityPipelineResult result = pipeline.evaluate(
      AgentConversationQualityPipelineInput(
        sources: <AgentConversationGroundingSource>[source(id: 'verified')],
        risk: AgentConversationRisk.low,
      ),
    );

    expect(
      result.grounding.knowledgeState,
      AgentConversationKnowledgeState.sufficient,
    );
    expect(result.decision.action, AgentConversationQualityAction.answer);
    expect(result.decision.mayAnswerDirectly, isTrue);
  });

  test('missing evidence flows to VERIFY when verification is possible', () {
    final AgentConversationQualityPipelineResult result = pipeline.evaluate(
      const AgentConversationQualityPipelineInput(
        sources: <AgentConversationGroundingSource>[],
        risk: AgentConversationRisk.medium,
      ),
    );

    expect(
      result.grounding.knowledgeState,
      AgentConversationKnowledgeState.missing,
    );
    expect(result.decision.action, AgentConversationQualityAction.verify);
    expect(result.decision.requiresFreshVerification, isTrue);
    expect(result.decision.mustNotInvent, isTrue);
  });

  test('missing evidence uses fallback when verification unavailable', () {
    final AgentConversationQualityPipelineResult result = pipeline.evaluate(
      const AgentConversationQualityPipelineInput(
        sources: <AgentConversationGroundingSource>[],
        risk: AgentConversationRisk.medium,
        canVerifyFresh: false,
        safeFallbackAvailable: true,
      ),
    );

    expect(result.decision.action, AgentConversationQualityAction.safeFallback);
    expect(result.decision.mustDiscloseUncertainty, isTrue);
  });

  test('conflicting evidence cannot become direct answer', () {
    final AgentConversationQualityPipelineResult result = pipeline.evaluate(
      AgentConversationQualityPipelineInput(
        sources: <AgentConversationGroundingSource>[
          source(id: 'support'),
          source(id: 'conflict', supportsClaim: false, contradictsClaim: true),
        ],
        risk: AgentConversationRisk.high,
      ),
    );

    expect(
      result.grounding.knowledgeState,
      AgentConversationKnowledgeState.conflicting,
    );
    expect(result.decision.action, AgentConversationQualityAction.verify);
    expect(result.decision.mayAnswerDirectly, isFalse);
  });

  test('ambiguous input clarifies even with good evidence', () {
    final AgentConversationQualityPipelineResult result = pipeline.evaluate(
      AgentConversationQualityPipelineInput(
        sources: <AgentConversationGroundingSource>[source(id: 'verified')],
        risk: AgentConversationRisk.low,
        userInputAmbiguous: true,
      ),
    );

    expect(result.decision.action, AgentConversationQualityAction.clarify);
  });

  test('disallowed request refuses before evidence answer', () {
    final AgentConversationQualityPipelineResult result = pipeline.evaluate(
      AgentConversationQualityPipelineInput(
        sources: <AgentConversationGroundingSource>[source(id: 'verified')],
        risk: AgentConversationRisk.high,
        requestAllowed: false,
      ),
    );

    expect(result.decision.action, AgentConversationQualityAction.refuse);
  });

  test('pipeline exposes no runtime authority', () {
    expect(pipeline.providerExecutionAllowed, isFalse);
    expect(pipeline.firestoreReadAllowed, isFalse);
    expect(pipeline.firestoreWriteAllowed, isFalse);
    expect(pipeline.runtimeActionAllowed, isFalse);
    expect(pipeline.permissionGrantAllowed, isFalse);
    expect(pipeline.approvalConsumptionAllowed, isFalse);
    expect(pipeline.promptMutationAllowed, isFalse);
    expect(pipeline.modelTrainingAllowed, isFalse);
    expect(pipeline.deploymentAllowed, isFalse);
  });
}

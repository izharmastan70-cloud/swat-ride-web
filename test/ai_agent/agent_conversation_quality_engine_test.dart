import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_conversation_quality_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_conversation_quality_decision.dart';
import 'package:swat_ride/ai_agent/services/agent_conversation_quality_engine.dart';

void main() {
  const AgentConversationQualityEngine engine =
      AgentConversationQualityEngine();

  const AgentConversationEvidenceRef verifiedEvidence =
      AgentConversationEvidenceRef(
        sourceId: 'synthetic_verified_source',
        sourceType: 'synthetic_fixture',
        summary: 'Synthetic verified evidence for deterministic tests.',
        verified: true,
      );

  const AgentConversationEvidenceRef unverifiedEvidence =
      AgentConversationEvidenceRef(
        sourceId: 'synthetic_unverified_source',
        sourceType: 'synthetic_fixture',
        summary: 'Synthetic unverified evidence for deterministic tests.',
        verified: false,
      );

  AgentConversationQualityInput input({
    String knowledgeState = AgentConversationKnowledgeState.sufficient,
    String risk = AgentConversationRisk.low,
    double confidence = 0.90,
    List<AgentConversationEvidenceRef> evidenceRefs =
        const <AgentConversationEvidenceRef>[verifiedEvidence],
    bool requestAllowed = true,
    bool requiresHumanJudgment = false,
    bool userInputAmbiguous = false,
    bool freshnessRequired = false,
    bool canVerifyFresh = true,
    bool safeFallbackAvailable = true,
  }) {
    return AgentConversationQualityInput(
      knowledgeState: knowledgeState,
      risk: risk,
      confidence: confidence,
      evidenceRefs: evidenceRefs,
      requestAllowed: requestAllowed,
      requiresHumanJudgment: requiresHumanJudgment,
      userInputAmbiguous: userInputAmbiguous,
      freshnessRequired: freshnessRequired,
      canVerifyFresh: canVerifyFresh,
      safeFallbackAvailable: safeFallbackAvailable,
    );
  }

  test('sufficient verified low-risk evidence may answer directly', () {
    final AgentConversationQualityDecision decision = engine.decide(input());

    expect(decision.action, AgentConversationQualityAction.answer);
    expect(decision.mayAnswerDirectly, isTrue);
    expect(decision.mustNotInvent, isTrue);
  });

  test('high-risk confidence below 0.95 requires verification', () {
    final AgentConversationQualityDecision decision = engine.decide(
      input(risk: AgentConversationRisk.high, confidence: 0.90),
    );

    expect(decision.action, AgentConversationQualityAction.verify);
    expect(decision.requiresFreshVerification, isTrue);
    expect(decision.mustDiscloseUncertainty, isTrue);
  });

  test('unverified knowledge requires verification', () {
    final AgentConversationQualityDecision decision = engine.decide(
      input(
        knowledgeState: AgentConversationKnowledgeState.unverified,
        evidenceRefs: const <AgentConversationEvidenceRef>[unverifiedEvidence],
      ),
    );

    expect(decision.action, AgentConversationQualityAction.verify);
    expect(decision.requiresFreshVerification, isTrue);
    expect(decision.mustDiscloseUncertainty, isTrue);
  });

  test('conflicting knowledge requires verification', () {
    final AgentConversationQualityDecision decision = engine.decide(
      input(knowledgeState: AgentConversationKnowledgeState.conflicting),
    );

    expect(decision.action, AgentConversationQualityAction.verify);
    expect(decision.requiresFreshVerification, isTrue);
  });

  test('ambiguous user input requires clarification before answer', () {
    final AgentConversationQualityDecision decision = engine.decide(
      input(userInputAmbiguous: true),
    );

    expect(decision.action, AgentConversationQualityAction.clarify);
    expect(decision.requiresClarification, isTrue);
    expect(decision.mayAnswerDirectly, isFalse);
  });

  test('human judgment requirement escalates before answer', () {
    final AgentConversationQualityDecision decision = engine.decide(
      input(requiresHumanJudgment: true),
    );

    expect(decision.action, AgentConversationQualityAction.escalate);
    expect(decision.requiresHumanEscalation, isTrue);
  });

  test('disallowed request refuses before all other actions', () {
    final AgentConversationQualityDecision decision = engine.decide(
      input(
        requestAllowed: false,
        requiresHumanJudgment: true,
        userInputAmbiguous: true,
      ),
    );

    expect(decision.action, AgentConversationQualityAction.refuse);
    expect(decision.mayAnswerDirectly, isFalse);
  });

  test('missing evidence uses safe fallback instead of invention', () {
    final AgentConversationQualityDecision decision = engine.decide(
      input(
        knowledgeState: AgentConversationKnowledgeState.missing,
        confidence: 0.20,
        evidenceRefs: const <AgentConversationEvidenceRef>[],
        canVerifyFresh: false,
        safeFallbackAvailable: true,
      ),
    );

    expect(decision.action, AgentConversationQualityAction.safeFallback);
    expect(decision.mustDiscloseUncertainty, isTrue);
    expect(decision.mustNotInvent, isTrue);
  });

  test('no safe fallback escalates rather than inventing', () {
    final AgentConversationQualityDecision decision = engine.decide(
      input(
        knowledgeState: AgentConversationKnowledgeState.missing,
        confidence: 0.10,
        evidenceRefs: const <AgentConversationEvidenceRef>[],
        canVerifyFresh: false,
        safeFallbackAvailable: false,
      ),
    );

    expect(decision.action, AgentConversationQualityAction.escalate);
    expect(decision.requiresHumanEscalation, isTrue);
    expect(decision.mustNotInvent, isTrue);
  });

  test('engine exposes no runtime authority', () {
    expect(engine.providerExecutionAllowed, isFalse);
    expect(engine.firestoreReadAllowed, isFalse);
    expect(engine.firestoreWriteAllowed, isFalse);
    expect(engine.runtimeActionAllowed, isFalse);
    expect(engine.permissionGrantAllowed, isFalse);
    expect(engine.approvalConsumptionAllowed, isFalse);
    expect(engine.promptMutationAllowed, isFalse);
    expect(engine.modelTrainingAllowed, isFalse);
    expect(engine.deploymentAllowed, isFalse);
  });
}

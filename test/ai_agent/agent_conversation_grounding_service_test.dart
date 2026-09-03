import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_conversation_quality_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_conversation_grounding_assessment.dart';
import 'package:swat_ride/ai_agent/models/agent_conversation_quality_decision.dart';
import 'package:swat_ride/ai_agent/services/agent_conversation_grounding_service.dart';

void main() {
  const AgentConversationGroundingService service =
      AgentConversationGroundingService();

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
        summary: 'Synthetic grounding fixture $id.',
        verified: verified,
      ),
      fresh: fresh,
      supportsClaim: supportsClaim,
      contradictsClaim: contradictsClaim,
    );
  }

  test('no sources is MISSING and requires verification', () {
    final AgentConversationGroundingAssessment assessment = service.assess(
      sources: const <AgentConversationGroundingSource>[],
    );

    expect(assessment.knowledgeState, AgentConversationKnowledgeState.missing);
    expect(assessment.requiresVerification, isTrue);
    expect(assessment.mustDiscloseUncertainty, isTrue);
    expect(assessment.isSufficient, isFalse);
  });

  test('unverified-only evidence is UNVERIFIED', () {
    final AgentConversationGroundingAssessment assessment = service.assess(
      sources: <AgentConversationGroundingSource>[
        source(id: 'unverified', verified: false),
      ],
    );

    expect(
      assessment.knowledgeState,
      AgentConversationKnowledgeState.unverified,
    );
    expect(assessment.verifiedSourceCount, 0);
    expect(assessment.requiresVerification, isTrue);
  });

  test('contradiction forces CONFLICTING', () {
    final AgentConversationGroundingAssessment assessment = service.assess(
      sources: <AgentConversationGroundingSource>[
        source(id: 'support'),
        source(
          id: 'contradiction',
          supportsClaim: false,
          contradictsClaim: true,
        ),
      ],
    );

    expect(
      assessment.knowledgeState,
      AgentConversationKnowledgeState.conflicting,
    );
    expect(assessment.contradictionCount, 1);
    expect(assessment.requiresVerification, isTrue);
  });

  test('one verified support is sufficient when one is required', () {
    final AgentConversationGroundingAssessment assessment = service.assess(
      sources: <AgentConversationGroundingSource>[source(id: 'verified')],
    );

    expect(
      assessment.knowledgeState,
      AgentConversationKnowledgeState.sufficient,
    );
    expect(assessment.isSufficient, isTrue);
    expect(assessment.confidence, 0.90);
  });

  test('insufficient verified support is PARTIAL', () {
    final AgentConversationGroundingAssessment assessment = service.assess(
      sources: <AgentConversationGroundingSource>[source(id: 'one')],
      requiredVerifiedSourceCount: 2,
    );

    expect(assessment.knowledgeState, AgentConversationKnowledgeState.partial);
    expect(assessment.requiresVerification, isTrue);
    expect(assessment.mustDiscloseUncertainty, isTrue);
  });

  test('freshness requirement blocks stale evidence from sufficiency', () {
    final AgentConversationGroundingAssessment assessment = service.assess(
      sources: <AgentConversationGroundingSource>[
        source(id: 'stale', fresh: false),
      ],
      freshnessRequired: true,
    );

    expect(assessment.knowledgeState, AgentConversationKnowledgeState.partial);
    expect(assessment.freshVerifiedSourceCount, 0);
    expect(assessment.requiresVerification, isTrue);
  });

  test('two fresh verified supports produce 0.95 confidence', () {
    final AgentConversationGroundingAssessment assessment = service.assess(
      sources: <AgentConversationGroundingSource>[
        source(id: 'one'),
        source(id: 'two'),
      ],
      requiredVerifiedSourceCount: 2,
      freshnessRequired: true,
    );

    expect(assessment.isSufficient, isTrue);
    expect(assessment.supportingVerifiedSourceCount, 2);
    expect(assessment.freshVerifiedSourceCount, 2);
    expect(assessment.confidence, 0.95);
  });

  test('duplicate evidence identity fails closed', () {
    expect(
      () => service.assess(
        sources: <AgentConversationGroundingSource>[
          source(id: 'duplicate'),
          source(id: 'duplicate'),
        ],
      ),
      throwsA(isA<AgentConversationGroundingException>()),
    );
  });

  test('source cannot support and contradict same claim', () {
    expect(
      () => service.assess(
        sources: <AgentConversationGroundingSource>[
          source(id: 'invalid', supportsClaim: true, contradictsClaim: true),
        ],
      ),
      throwsA(isA<AgentConversationGroundingException>()),
    );
  });

  test('grounding service exposes no runtime authority', () {
    expect(service.providerExecutionAllowed, isFalse);
    expect(service.firestoreReadAllowed, isFalse);
    expect(service.firestoreWriteAllowed, isFalse);
    expect(service.runtimeActionAllowed, isFalse);
    expect(service.permissionGrantAllowed, isFalse);
    expect(service.approvalConsumptionAllowed, isFalse);
    expect(service.promptMutationAllowed, isFalse);
    expect(service.modelTrainingAllowed, isFalse);
    expect(service.deploymentAllowed, isFalse);
  });
}

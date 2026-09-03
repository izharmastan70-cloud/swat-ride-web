import '../constants/agent_conversation_quality_constants.dart';
import '../models/agent_conversation_grounding_assessment.dart';
import '../models/agent_conversation_quality_decision.dart';

/// Pure deterministic evidence/grounding assessor.
///
/// It never retrieves sources itself. The caller supplies already-available
/// read-only source signals.
class AgentConversationGroundingService {
  const AgentConversationGroundingService();

  bool get providerExecutionAllowed => false;
  bool get firestoreReadAllowed => false;
  bool get firestoreWriteAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;

  AgentConversationGroundingAssessment assess({
    required List<AgentConversationGroundingSource> sources,
    int requiredVerifiedSourceCount = 1,
    bool freshnessRequired = false,
  }) {
    if (requiredVerifiedSourceCount < 1) {
      throw const AgentConversationGroundingException(
        'requiredVerifiedSourceCount must be at least 1.',
      );
    }

    final Set<String> identities = <String>{};

    for (final AgentConversationGroundingSource source in sources) {
      source.validate();

      final String identity =
          '${source.evidence.sourceType.trim()}::'
          '${source.evidence.sourceId.trim()}';

      if (!identities.add(identity)) {
        throw AgentConversationGroundingException(
          'Duplicate grounding source "$identity".',
        );
      }
    }

    final int verifiedSourceCount = sources
        .where(
          (AgentConversationGroundingSource source) => source.evidence.verified,
        )
        .length;

    final int freshVerifiedSourceCount = sources
        .where(
          (AgentConversationGroundingSource source) =>
              source.evidence.verified && source.fresh,
        )
        .length;

    final int supportingVerifiedSourceCount = sources
        .where(
          (AgentConversationGroundingSource source) =>
              source.evidence.verified &&
              source.supportsClaim &&
              !source.contradictsClaim,
        )
        .length;

    final int contradictionCount = sources
        .where(
          (AgentConversationGroundingSource source) => source.contradictsClaim,
        )
        .length;

    final String knowledgeState;
    final bool requiresVerification;
    final bool mustDiscloseUncertainty;
    final double confidence;

    if (sources.isEmpty) {
      knowledgeState = AgentConversationKnowledgeState.missing;
      requiresVerification = true;
      mustDiscloseUncertainty = true;
      confidence = 0.0;
    } else if (contradictionCount > 0) {
      knowledgeState = AgentConversationKnowledgeState.conflicting;
      requiresVerification = true;
      mustDiscloseUncertainty = true;
      confidence = 0.20;
    } else if (verifiedSourceCount == 0) {
      knowledgeState = AgentConversationKnowledgeState.unverified;
      requiresVerification = true;
      mustDiscloseUncertainty = true;
      confidence = 0.25;
    } else {
      final bool enoughSupportingVerified =
          supportingVerifiedSourceCount >= requiredVerifiedSourceCount;

      final bool enoughFreshVerified =
          !freshnessRequired ||
          freshVerifiedSourceCount >= requiredVerifiedSourceCount;

      if (enoughSupportingVerified && enoughFreshVerified) {
        knowledgeState = AgentConversationKnowledgeState.sufficient;
        requiresVerification = false;
        mustDiscloseUncertainty = false;
        confidence = requiredVerifiedSourceCount == 1 ? 0.90 : 0.95;
      } else {
        knowledgeState = AgentConversationKnowledgeState.partial;
        requiresVerification = true;
        mustDiscloseUncertainty = true;
        confidence = 0.60;
      }
    }

    final AgentConversationGroundingAssessment assessment =
        AgentConversationGroundingAssessment(
          knowledgeState: knowledgeState,
          confidence: confidence,
          sourceCount: sources.length,
          verifiedSourceCount: verifiedSourceCount,
          freshVerifiedSourceCount: freshVerifiedSourceCount,
          supportingVerifiedSourceCount: supportingVerifiedSourceCount,
          contradictionCount: contradictionCount,
          requiredVerifiedSourceCount: requiredVerifiedSourceCount,
          freshnessRequired: freshnessRequired,
          requiresVerification: requiresVerification,
          mustDiscloseUncertainty: mustDiscloseUncertainty,
          evidenceRefs: List<AgentConversationEvidenceRef>.unmodifiable(
            sources
                .map(
                  (AgentConversationGroundingSource source) => source.evidence,
                )
                .toList(growable: false),
          ),
        );

    assessment.validate();
    return assessment;
  }
}

import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_knowledge_conflict_resolution_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_knowledge_library_contract_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_knowledge_conflict_candidate.dart';
import 'package:swat_ride/ai_agent/services/agent_knowledge_conflict_resolution_policy.dart';

void main() {
  const AgentKnowledgeConflictResolutionPolicy policy =
      AgentKnowledgeConflictResolutionPolicy();

  AgentKnowledgeConflictCandidate candidate({
    String itemId = 'knowledge:ride:001',
    String sourceId = 'source:ride:system',
    String sourceReferenceId = 'source_ref:ride:001',
    String contentReferenceId = 'content:ride:001',
    String claimKey = 'ride_booking_available',
    String claimValueBinding = 'binding:true',
    String sourceType = AgentKnowledgeSourceType.verifiedFeatureState,
    String authorityClass = AgentKnowledgeAuthorityClass.systemVerified,
    int revision = 1,
    String sourceVersion = 'v1',
    double retrievalScore = 0.90,
    bool citationEligible = true,
    bool trustedScopeFilteredSnapshot = true,
  }) {
    return AgentKnowledgeConflictCandidate(
      itemId: itemId,
      sourceId: sourceId,
      sourceReferenceId: sourceReferenceId,
      contentReferenceId: contentReferenceId,
      claimKey: claimKey,
      claimValueBinding: claimValueBinding,
      sourceType: sourceType,
      authorityClass: authorityClass,
      revision: revision,
      sourceVersion: sourceVersion,
      retrievalScore: retrievalScore,
      citationEligible: citationEligible,
      trustedScopeFilteredSnapshot: trustedScopeFilteredSnapshot,
    );
  }

  group('Phase 57 Step 1E conflict resolution', () {
    test('5 conflict statuses are locked', () {
      expect(AgentKnowledgeConflictStatus.values.length, 5);
    });

    test('5 authority precedence classes are locked', () {
      expect(AgentKnowledgePrecedence.authority.length, 5);
    });

    test('11 source type precedence entries are locked', () {
      expect(AgentKnowledgePrecedence.sourceType.length, 11);
    });

    test('single trusted citable candidate is ready for grounding', () {
      final result = policy.resolve(
        candidates: <AgentKnowledgeConflictCandidate>[candidate()],
      );

      expect(result.ready, true);
      expect(result.status, AgentKnowledgeConflictStatus.readyForGrounding);
      expect(result.selectedClaimValueBinding, 'binding:true');
      expect(result.citations.length, 1);
      expect(result.noAnswerRequired, false);
      expect(result.mayProceedToConversationGrounding, true);
    });

    test('higher authority source resolves lower authority conflict', () {
      final result = policy.resolve(
        candidates: <AgentKnowledgeConflictCandidate>[
          candidate(
            itemId: 'knowledge:ride:system',
            sourceId: 'source:ride:system',
            claimValueBinding: 'binding:true',
            authorityClass: AgentKnowledgeAuthorityClass.systemVerified,
          ),
          candidate(
            itemId: 'knowledge:ride:external',
            sourceId: 'source:ride:external',
            sourceReferenceId: 'source_ref:ride:external',
            contentReferenceId: 'content:ride:external',
            claimValueBinding: 'binding:false',
            sourceType: AgentKnowledgeSourceType.trustedExternalReference,
            authorityClass: AgentKnowledgeAuthorityClass.verifiedExternal,
            retrievalScore: 0.99,
          ),
        ],
      );

      expect(result.ready, true);
      expect(result.selectedClaimValueBinding, 'binding:true');
      expect(
        result.reasonCodes,
        contains('lower_precedence_conflict_suppressed'),
      );
    });

    test('retrieval score cannot override source authority precedence', () {
      final result = policy.resolve(
        candidates: <AgentKnowledgeConflictCandidate>[
          candidate(
            itemId: 'knowledge:ride:system',
            sourceId: 'source:ride:system',
            claimValueBinding: 'binding:true',
            authorityClass: AgentKnowledgeAuthorityClass.systemVerified,
            retrievalScore: 0.66,
          ),
          candidate(
            itemId: 'knowledge:ride:external',
            sourceId: 'source:ride:external',
            sourceReferenceId: 'source_ref:ride:external',
            contentReferenceId: 'content:ride:external',
            claimValueBinding: 'binding:false',
            sourceType: AgentKnowledgeSourceType.trustedExternalReference,
            authorityClass: AgentKnowledgeAuthorityClass.verifiedExternal,
            retrievalScore: 1.0,
          ),
        ],
      );

      expect(result.ready, true);
      expect(result.selectedClaimValueBinding, 'binding:true');
    });

    test('same authority uses source-type precedence deterministically', () {
      final result = policy.resolve(
        candidates: <AgentKnowledgeConflictCandidate>[
          candidate(
            itemId: 'knowledge:policy',
            sourceId: 'source:policy',
            sourceType: AgentKnowledgeSourceType.policy,
            authorityClass: AgentKnowledgeAuthorityClass.ownerApproved,
            claimValueBinding: 'binding:policy',
          ),
          candidate(
            itemId: 'knowledge:faq',
            sourceId: 'source:faq',
            sourceReferenceId: 'source_ref:faq',
            contentReferenceId: 'content:faq',
            sourceType: AgentKnowledgeSourceType.helpFaq,
            authorityClass: AgentKnowledgeAuthorityClass.ownerApproved,
            claimValueBinding: 'binding:faq',
          ),
        ],
      );

      expect(result.ready, true);
      expect(result.selectedClaimValueBinding, 'binding:policy');
    });

    test('equal top precedence conflicting bindings fail closed', () {
      final result = policy.resolve(
        candidates: <AgentKnowledgeConflictCandidate>[
          candidate(
            itemId: 'knowledge:ride:a',
            sourceId: 'source:ride:a',
            claimValueBinding: 'binding:true',
          ),
          candidate(
            itemId: 'knowledge:ride:b',
            sourceId: 'source:ride:b',
            sourceReferenceId: 'source_ref:ride:b',
            contentReferenceId: 'content:ride:b',
            claimValueBinding: 'binding:false',
          ),
        ],
      );

      expect(result.ready, false);
      expect(
        result.status,
        AgentKnowledgeConflictStatus.noAnswerUnresolvedConflict,
      );
      expect(result.noAnswerRequired, true);
      expect(result.citations, isEmpty);
      expect(result.selectedClaimValueBinding, isEmpty);
    });

    test('same-source newer revision supersedes older revision metadata', () {
      final result = policy.resolve(
        candidates: <AgentKnowledgeConflictCandidate>[
          candidate(
            itemId: 'knowledge:ride:old',
            sourceId: 'source:ride:system',
            revision: 1,
            claimValueBinding: 'binding:false',
          ),
          candidate(
            itemId: 'knowledge:ride:new',
            sourceId: 'source:ride:system',
            sourceReferenceId: 'source_ref:ride:new',
            contentReferenceId: 'content:ride:new',
            revision: 2,
            claimValueBinding: 'binding:true',
          ),
        ],
      );

      expect(result.ready, true);
      expect(result.selectedClaimValueBinding, 'binding:true');
      expect(result.citations.first.revision, 2);
    });

    test('same-source same-revision conflicting binding is ambiguous', () {
      final result = policy.resolve(
        candidates: <AgentKnowledgeConflictCandidate>[
          candidate(
            itemId: 'knowledge:ride:a',
            sourceId: 'source:ride:system',
            revision: 2,
            claimValueBinding: 'binding:true',
          ),
          candidate(
            itemId: 'knowledge:ride:b',
            sourceId: 'source:ride:system',
            sourceReferenceId: 'source_ref:ride:b',
            contentReferenceId: 'content:ride:b',
            revision: 2,
            claimValueBinding: 'binding:false',
          ),
        ],
      );

      expect(result.ready, false);
      expect(
        result.status,
        AgentKnowledgeConflictStatus.noAnswerPrecedenceAmbiguous,
      );
    });

    test('non-citable candidates cannot produce grounded answer', () {
      final result = policy.resolve(
        candidates: <AgentKnowledgeConflictCandidate>[
          candidate(citationEligible: false),
        ],
      );

      expect(
        result.status,
        AgentKnowledgeConflictStatus.noAnswerNoCitableSource,
      );
      expect(result.noAnswerRequired, true);
    });

    test('untrusted/not-scope-filtered candidate cannot enter resolution', () {
      final result = policy.resolve(
        candidates: <AgentKnowledgeConflictCandidate>[
          candidate(trustedScopeFilteredSnapshot: false),
        ],
      );

      expect(
        result.status,
        AgentKnowledgeConflictStatus.noAnswerNoCitableSource,
      );
    });

    test('mixed claim keys are blocked', () {
      final result = policy.resolve(
        candidates: <AgentKnowledgeConflictCandidate>[
          candidate(claimKey: 'ride_booking_available'),
          candidate(
            itemId: 'knowledge:ride:payment',
            sourceId: 'source:ride:payment',
            sourceReferenceId: 'source_ref:ride:payment',
            contentReferenceId: 'content:ride:payment',
            claimKey: 'ride_cash_payment_available',
          ),
        ],
      );

      expect(result.status, AgentKnowledgeConflictStatus.noAnswerInvalidInput);
      expect(result.noAnswerRequired, true);
    });

    test('matching top claim can keep multiple supporting citations', () {
      final result = policy.resolve(
        candidates: <AgentKnowledgeConflictCandidate>[
          candidate(
            itemId: 'knowledge:ride:a',
            sourceId: 'source:ride:a',
            claimValueBinding: 'binding:true',
          ),
          candidate(
            itemId: 'knowledge:ride:b',
            sourceId: 'source:ride:b',
            sourceReferenceId: 'source_ref:ride:b',
            contentReferenceId: 'content:ride:b',
            claimValueBinding: 'binding:true',
          ),
        ],
      );

      expect(result.ready, true);
      expect(result.citations.length, 2);
    });

    test('citation count is bounded', () {
      final candidates = List<AgentKnowledgeConflictCandidate>.generate(
        10,
        (int index) => candidate(
          itemId: 'knowledge:ride:$index',
          sourceId: 'source:ride:$index',
          sourceReferenceId: 'source_ref:ride:$index',
          contentReferenceId: 'content:ride:$index',
          claimValueBinding: 'binding:true',
          retrievalScore: 0.70 + (index / 100),
        ),
      );

      final result = policy.resolve(candidates: candidates);

      expect(result.ready, true);
      expect(
        result.citations.length,
        AgentKnowledgeConflictLimits.maxCitations,
      );
    });

    test('citation projection is metadata-only and privacy-safe', () {
      final result = policy.resolve(
        candidates: <AgentKnowledgeConflictCandidate>[candidate()],
      );

      final citation = result.citations.single;

      expect(citation.citationIsReferenceMetadataOnly, true);
      expect(citation.containsRawKnowledgeContent, false);
      expect(citation.containsRawSourcePayload, false);
      expect(citation.containsRawPrompt, false);
      expect(citation.containsPhone, false);
      expect(citation.containsEmail, false);
      expect(citation.containsCnic, false);
      expect(citation.containsAuthToken, false);
      expect(citation.containsPaymentCard, false);
      expect(citation.containsSecret, false);
      expect(citation.citationDoesNotProveTruthByItself, true);
      expect(citation.grantsAuthority, false);
      expect(citation.expandsScope, false);
      expect(citation.executesBusinessAction, false);
      expect(citation.retrievesRawContent, false);
      expect(citation.invokesProvider, false);
      expect(citation.persistsCitation, false);
    });

    test('candidate metadata grants no authority', () {
      final value = candidate();

      expect(value.metadataOnly, true);
      expect(value.containsRawKnowledgeContent, false);
      expect(value.containsRawSourcePayload, false);
      expect(value.containsRawPrompt, false);
      expect(value.containsPrivatePayload, false);
      expect(value.retrievalScoreIsNotTruthProbability, true);
      expect(value.retrievalScoreDoesNotGrantAuthority, true);
      expect(value.grantsPermission, false);
      expect(value.expandsScope, false);
      expect(value.consumesApproval, false);
      expect(value.executesBusinessAction, false);
      expect(value.retrievesRawContentHere, false);
      expect(value.invokesProvider, false);
      expect(value.persistsCandidate, false);
    });

    test('ready result still requires grounding and response guard', () {
      final result = policy.resolve(
        candidates: <AgentKnowledgeConflictCandidate>[candidate()],
      );

      expect(result.conversationGroundingRequired, true);
      expect(result.responseGuardRequired, true);
      expect(result.citationsRequiredForGroundedClaim, true);
      expect(result.citationsAreMetadataOnly, true);
      expect(result.citationProjectionDoesNotExposeRawContent, true);
      expect(result.conflictResolutionDoesNotCreateTruth, true);
      expect(result.selectedBindingIsNotUserVisibleClaimText, true);
    });

    test('no-answer result cannot expose citation or selected binding', () {
      final result = policy.resolve(
        candidates: <AgentKnowledgeConflictCandidate>[
          candidate(citationEligible: false),
        ],
      );

      expect(result.noAnswerRequired, true);
      expect(result.noAnswerMustNotGuess, true);
      expect(result.citations, isEmpty);
      expect(result.selectedClaimValueBinding, isEmpty);
    });

    test('result executes no provider/business/permission action', () {
      final result = policy.resolve(
        candidates: <AgentKnowledgeConflictCandidate>[candidate()],
      );

      expect(result.grantsPermission, false);
      expect(result.expandsScope, false);
      expect(result.consumesApproval, false);
      expect(result.executesBusinessAction, false);
      expect(result.writesBusinessData, false);
      expect(result.retrievesRawContent, false);
      expect(result.invokesProvider, false);
      expect(result.persistsResult, false);
    });

    test('policy locks precedence/conflict/citation safety', () {
      expect(policy.consumesStep1DScopeFilteredTrustedMetadata, true);
      expect(policy.sourceAuthorityPrecedenceRequired, true);
      expect(policy.sourceTypePrecedenceRequired, true);
      expect(policy.sameSourceNewerRevisionWins, true);
      expect(policy.equalTopPrecedenceConflictFailsClosed, true);
      expect(policy.lowerPrecedenceConflictMayBeSuppressed, true);
      expect(policy.retrievalScoreCannotOverridePrecedence, true);
      expect(policy.retrievalScoreIsNotTruthProbability, true);
      expect(policy.citationRequiredForSelectedClaim, true);
      expect(policy.citationProjectionMetadataOnly, true);
      expect(policy.citationDoesNotCreateTruth, true);
      expect(policy.noAnswerInsteadOfGuess, true);
      expect(policy.conversationGroundingRequiredNext, true);
      expect(policy.responseGuardRequiredNext, true);
    });

    test('policy has no production authority or retrieval execution', () {
      expect(policy.grantsPermission, false);
      expect(policy.expandsScope, false);
      expect(policy.consumesApproval, false);
      expect(policy.executesBusinessAction, false);
      expect(policy.writesBusinessData, false);
      expect(policy.performsDatabaseSearch, false);
      expect(policy.retrievesRawKnowledgeContent, false);
      expect(policy.invokesProvider, false);
      expect(policy.sendsWhatsApp, false);
      expect(policy.persistsResolution, false);
    });

    test('existing phase ownership remains separate', () {
      expect(policy.duplicatesStep1DRetrieval, false);
      expect(policy.duplicatesConversationGrounding, false);
      expect(policy.duplicatesResponseGuard, false);
      expect(policy.duplicatesPhase55VideoCatalog, false);
      expect(policy.implementsPhase62TrainingDeployment, false);
      expect(policy.implementsPhase63RetentionUi, false);
    });
  });
}

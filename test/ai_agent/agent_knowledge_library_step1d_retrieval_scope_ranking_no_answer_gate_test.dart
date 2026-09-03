import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_knowledge_library_contract_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_knowledge_retrieval_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_knowledge_retrieval_candidate.dart';
import 'package:swat_ride/ai_agent/models/agent_knowledge_retrieval_request.dart';
import 'package:swat_ride/ai_agent/services/agent_knowledge_retrieval_policy.dart';

void main() {
  const AgentKnowledgeRetrievalPolicy policy = AgentKnowledgeRetrievalPolicy();

  AgentKnowledgeRetrievalRequest request({
    String module = 'ride',
    String topic = 'booking',
    String language = AgentKnowledgeLanguage.urdu,
    Set<String> allowedScopes = const <String>{AgentKnowledgeScope.public},
    bool scopeAuthorizationVerified = true,
    int maxResults = 5,
    double minimumScore = 0.65,
  }) {
    return AgentKnowledgeRetrievalRequest(
      requestId: 'retrieval:ride_booking:001',
      module: module,
      topic: topic,
      language: language,
      allowedScopes: allowedScopes,
      scopeAuthorizationVerified: scopeAuthorizationVerified,
      maxResults: maxResults,
      minimumScore: minimumScore,
    );
  }

  AgentKnowledgeRetrievalCandidate candidate({
    String itemId = 'knowledge:ride_booking:001',
    String contentReferenceId = 'content:ride_booking:001',
    String module = 'ride',
    String topic = 'booking',
    String language = AgentKnowledgeLanguage.urdu,
    Set<String> scopes = const <String>{AgentKnowledgeScope.public},
    int revision = 1,
    String sourceVersion = 'v1',
    bool indexedSnapshotTrusted = true,
    bool approvedActive = true,
    bool sourceVerified = true,
    bool sourceApproved = true,
    bool sourceActive = true,
    bool sourceFresh = true,
    double relevanceScore = 0.90,
    double authorityScore = 0.90,
    double freshnessScore = 0.90,
  }) {
    return AgentKnowledgeRetrievalCandidate(
      itemId: itemId,
      contentReferenceId: contentReferenceId,
      module: module,
      topic: topic,
      language: language,
      scopes: scopes,
      revision: revision,
      sourceVersion: sourceVersion,
      indexedSnapshotTrusted: indexedSnapshotTrusted,
      approvedActive: approvedActive,
      sourceVerified: sourceVerified,
      sourceApproved: sourceApproved,
      sourceActive: sourceActive,
      sourceFresh: sourceFresh,
      relevanceScore: relevanceScore,
      authorityScore: authorityScore,
      freshnessScore: freshnessScore,
    );
  }

  group('Phase 57 Step 1D retrieval gate', () {
    test('8 retrieval statuses are locked', () {
      expect(AgentKnowledgeRetrievalStatus.values.length, 8);
    });

    test('ranking weights sum to 1', () {
      expect(
        AgentKnowledgeRetrievalRanking.relevanceWeight +
            AgentKnowledgeRetrievalRanking.authorityWeight +
            AgentKnowledgeRetrievalRanking.freshnessWeight,
        closeTo(1.0, 0.000001),
      );
    });

    test('trusted scoped high-score candidate returns references', () {
      final result = policy.evaluate(
        request: request(),
        candidates: <AgentKnowledgeRetrievalCandidate>[candidate()],
      );

      expect(result.ready, true);
      expect(
        result.status,
        AgentKnowledgeRetrievalStatus.readyWithGroundedReferences,
      );
      expect(result.references.length, 1);
      expect(result.noAnswerRequired, false);
      expect(result.mayProceedToGroundingProjection, true);
      expect(result.conversationGroundingRequired, true);
      expect(result.responseGuardRequired, true);
    });

    test('scope authorization must be preverified', () {
      final result = policy.evaluate(
        request: request(scopeAuthorizationVerified: false),
        candidates: <AgentKnowledgeRetrievalCandidate>[candidate()],
      );

      expect(
        result.status,
        AgentKnowledgeRetrievalStatus.noAnswerScopeAuthorizationUnverified,
      );
      expect(result.noAnswerRequired, true);
      expect(result.references, isEmpty);
    });

    test('untrusted indexed snapshot is excluded', () {
      final result = policy.evaluate(
        request: request(),
        candidates: <AgentKnowledgeRetrievalCandidate>[
          candidate(indexedSnapshotTrusted: false),
        ],
      );

      expect(
        result.status,
        AgentKnowledgeRetrievalStatus.noAnswerUntrustedOrStale,
      );
    });

    test('deprecated/not-approved-active candidate is excluded', () {
      final result = policy.evaluate(
        request: request(),
        candidates: <AgentKnowledgeRetrievalCandidate>[
          candidate(approvedActive: false),
        ],
      );

      expect(
        result.status,
        AgentKnowledgeRetrievalStatus.noAnswerUntrustedOrStale,
      );
    });

    test('unverified source is excluded', () {
      final result = policy.evaluate(
        request: request(),
        candidates: <AgentKnowledgeRetrievalCandidate>[
          candidate(sourceVerified: false),
        ],
      );

      expect(
        result.status,
        AgentKnowledgeRetrievalStatus.noAnswerUntrustedOrStale,
      );
    });

    test('unapproved source is excluded', () {
      final result = policy.evaluate(
        request: request(),
        candidates: <AgentKnowledgeRetrievalCandidate>[
          candidate(sourceApproved: false),
        ],
      );

      expect(
        result.status,
        AgentKnowledgeRetrievalStatus.noAnswerUntrustedOrStale,
      );
    });

    test('inactive source is excluded', () {
      final result = policy.evaluate(
        request: request(),
        candidates: <AgentKnowledgeRetrievalCandidate>[
          candidate(sourceActive: false),
        ],
      );

      expect(
        result.status,
        AgentKnowledgeRetrievalStatus.noAnswerUntrustedOrStale,
      );
    });

    test('stale source is excluded', () {
      final result = policy.evaluate(
        request: request(),
        candidates: <AgentKnowledgeRetrievalCandidate>[
          candidate(sourceFresh: false),
        ],
      );

      expect(
        result.status,
        AgentKnowledgeRetrievalStatus.noAnswerUntrustedOrStale,
      );
    });

    test('public plus privileged candidate scope conflict is excluded', () {
      final result = policy.evaluate(
        request: request(),
        candidates: <AgentKnowledgeRetrievalCandidate>[
          candidate(
            scopes: const <String>{
              AgentKnowledgeScope.public,
              AgentKnowledgeScope.owner,
            },
          ),
        ],
      );

      expect(
        result.status,
        AgentKnowledgeRetrievalStatus.noAnswerUntrustedOrStale,
      );
    });

    test('module/topic mismatch produces no-answer', () {
      final result = policy.evaluate(
        request: request(),
        candidates: <AgentKnowledgeRetrievalCandidate>[
          candidate(topic: 'cancellation'),
        ],
      );

      expect(result.status, AgentKnowledgeRetrievalStatus.noAnswerNoTopicMatch);
      expect(result.noAnswerMustNotGuess, true);
    });

    test('language mismatch produces no-answer', () {
      final result = policy.evaluate(
        request: request(language: AgentKnowledgeLanguage.pashto),
        candidates: <AgentKnowledgeRetrievalCandidate>[
          candidate(language: AgentKnowledgeLanguage.urdu),
        ],
      );

      expect(
        result.status,
        AgentKnowledgeRetrievalStatus.noAnswerLanguageMismatch,
      );
    });

    test('cross-scope knowledge cannot leak', () {
      final result = policy.evaluate(
        request: request(
          allowedScopes: const <String>{AgentKnowledgeScope.public},
        ),
        candidates: <AgentKnowledgeRetrievalCandidate>[
          candidate(scopes: const <String>{AgentKnowledgeScope.owner}),
        ],
      );

      expect(
        result.status,
        AgentKnowledgeRetrievalStatus.noAnswerScopeMismatch,
      );
      expect(result.references, isEmpty);
    });

    test('authorized owner scope can access owner-scoped knowledge', () {
      final result = policy.evaluate(
        request: request(
          allowedScopes: const <String>{AgentKnowledgeScope.owner},
        ),
        candidates: <AgentKnowledgeRetrievalCandidate>[
          candidate(scopes: const <String>{AgentKnowledgeScope.owner}),
        ],
      );

      expect(result.ready, true);
    });

    test('low ranking score produces no-answer rather than guess', () {
      final result = policy.evaluate(
        request: request(minimumScore: 0.65),
        candidates: <AgentKnowledgeRetrievalCandidate>[
          candidate(
            relevanceScore: 0.40,
            authorityScore: 0.40,
            freshnessScore: 0.40,
          ),
        ],
      );

      expect(
        result.status,
        AgentKnowledgeRetrievalStatus.noAnswerLowConfidence,
      );
      expect(result.noAnswerRequired, true);
      expect(result.references, isEmpty);
    });

    test('ranking is deterministic by score', () {
      final result = policy.evaluate(
        request: request(maxResults: 2),
        candidates: <AgentKnowledgeRetrievalCandidate>[
          candidate(
            itemId: 'knowledge:ride_booking:low',
            contentReferenceId: 'content:ride_booking:low',
            relevanceScore: 0.70,
            authorityScore: 0.70,
            freshnessScore: 0.70,
          ),
          candidate(
            itemId: 'knowledge:ride_booking:high',
            contentReferenceId: 'content:ride_booking:high',
            relevanceScore: 0.95,
            authorityScore: 0.95,
            freshnessScore: 0.95,
          ),
        ],
      );

      expect(result.ready, true);
      expect(result.references.first.itemId, 'knowledge:ride_booking:high');
    });

    test('equal score prefers newer revision then stable item ID', () {
      final result = policy.evaluate(
        request: request(maxResults: 3),
        candidates: <AgentKnowledgeRetrievalCandidate>[
          candidate(
            itemId: 'knowledge:ride_booking:b',
            contentReferenceId: 'content:ride_booking:b',
            revision: 1,
          ),
          candidate(
            itemId: 'knowledge:ride_booking:c',
            contentReferenceId: 'content:ride_booking:c',
            revision: 2,
          ),
          candidate(
            itemId: 'knowledge:ride_booking:a',
            contentReferenceId: 'content:ride_booking:a',
            revision: 1,
          ),
        ],
      );

      expect(result.references[0].revision, 2);
      expect(result.references[1].itemId, 'knowledge:ride_booking:a');
      expect(result.references[2].itemId, 'knowledge:ride_booking:b');
    });

    test('maxResults bounds returned references', () {
      final result = policy.evaluate(
        request: request(maxResults: 1),
        candidates: <AgentKnowledgeRetrievalCandidate>[
          candidate(
            itemId: 'knowledge:ride_booking:1',
            contentReferenceId: 'content:ride_booking:1',
          ),
          candidate(
            itemId: 'knowledge:ride_booking:2',
            contentReferenceId: 'content:ride_booking:2',
          ),
        ],
      );

      expect(result.references.length, 1);
    });

    test('ranking score is explicitly not truth probability', () {
      final result = policy.evaluate(
        request: request(),
        candidates: <AgentKnowledgeRetrievalCandidate>[candidate()],
      );

      expect(result.rankingScoreIsNotTruthProbability, true);
      expect(result.references.first.rankingScoreIsNotTruthProbability, true);
    });

    test('request is metadata-only and grants no scope/authority', () {
      final value = request();

      expect(value.containsRawUserMessage, false);
      expect(value.containsRawConversation, false);
      expect(value.containsRawPrompt, false);
      expect(value.containsPhone, false);
      expect(value.containsEmail, false);
      expect(value.containsCnic, false);
      expect(value.containsAuthToken, false);
      expect(value.containsPaymentData, false);
      expect(value.allowedScopesAreConsumedNotGranted, true);
      expect(value.grantsScope, false);
      expect(value.expandsScope, false);
      expect(value.grantsPermission, false);
      expect(value.consumesApproval, false);
      expect(value.executesBusinessAction, false);
      expect(value.performsDatabaseSearch, false);
      expect(value.invokesProvider, false);
      expect(value.persistsRequest, false);
    });

    test('candidate is metadata-only and grants no authority', () {
      final value = candidate();

      expect(value.metadataOnly, true);
      expect(value.containsRawKnowledgeContent, false);
      expect(value.containsRawPrompt, false);
      expect(value.containsPrivatePayload, false);
      expect(value.grantsPermission, false);
      expect(value.expandsScope, false);
      expect(value.executesBusinessAction, false);
      expect(value.retrievesRawContentHere, false);
      expect(value.invokesProvider, false);
      expect(value.persistsCandidate, false);
    });

    test('retrieval result performs no database/provider/business action', () {
      final result = policy.evaluate(
        request: request(),
        candidates: <AgentKnowledgeRetrievalCandidate>[candidate()],
      );

      expect(result.referencesAreMetadataOnly, true);
      expect(result.referencesDoNotGrantAuthority, true);
      expect(result.scopeWasFilteredBeforeRanking, true);
      expect(result.performsDatabaseSearch, false);
      expect(result.retrievesRawContent, false);
      expect(result.invokesProvider, false);
      expect(result.grantsPermission, false);
      expect(result.expandsScope, false);
      expect(result.consumesApproval, false);
      expect(result.executesBusinessAction, false);
      expect(result.writesBusinessData, false);
      expect(result.persistsResult, false);
    });

    test('policy locks safe retrieval requirements', () {
      expect(policy.trustedIndexedCandidateRequired, true);
      expect(policy.approvedActiveRequired, true);
      expect(policy.verifiedApprovedActiveFreshSourceRequired, true);
      expect(policy.scopeAuthorizationMustBePreverified, true);
      expect(policy.retrievalCannotGrantScope, true);
      expect(policy.scopeFilteringBeforeRanking, true);
      expect(policy.exactModuleTopicMatchRequired, true);
      expect(policy.exactLanguageMatchRequired, true);
      expect(policy.deterministicRankingRequired, true);
      expect(policy.minimumScoreRequired, true);
      expect(policy.rankingScoreIsNotTruthProbability, true);
      expect(policy.noAnswerInsteadOfGuess, true);
      expect(policy.staleDeprecatedUnapprovedExcluded, true);
      expect(policy.publicPrivilegedScopeConflictExcluded, true);
      expect(policy.conversationGroundingRequiredNext, true);
      expect(policy.responseGuardRequiredNext, true);
      expect(policy.referencesMetadataOnly, true);
    });

    test('policy has no production retrieval authority', () {
      expect(policy.performsDatabaseSearch, false);
      expect(policy.retrievesRawKnowledgeContent, false);
      expect(policy.invokesProvider, false);
      expect(policy.grantsPermission, false);
      expect(policy.expandsScope, false);
      expect(policy.consumesApproval, false);
      expect(policy.executesBusinessAction, false);
      expect(policy.writesBusinessData, false);
      expect(policy.sendsWhatsApp, false);
      expect(policy.persistsRetrieval, false);
    });

    test('existing phase ownership remains separate', () {
      expect(policy.duplicatesStep1BContract, false);
      expect(policy.duplicatesStep1CIngestion, false);
      expect(policy.duplicatesConversationGrounding, false);
      expect(policy.duplicatesResponseGuard, false);
      expect(policy.duplicatesPhase55VideoCatalog, false);
      expect(policy.implementsPhase62TrainingDeployment, false);
      expect(policy.implementsPhase63RetentionUi, false);
    });
  });
}

import '../constants/agent_knowledge_retrieval_constants.dart';
import '../models/agent_knowledge_retrieval_candidate.dart';
import '../models/agent_knowledge_retrieval_request.dart';
import '../models/agent_knowledge_retrieval_result.dart';

class AgentKnowledgeRetrievalPolicy {
  const AgentKnowledgeRetrievalPolicy();

  AgentKnowledgeRetrievalResult evaluate({
    required AgentKnowledgeRetrievalRequest request,
    required List<AgentKnowledgeRetrievalCandidate> candidates,
  }) {
    try {
      request.validateStructure();
    } catch (_) {
      return _noAnswer(
        status: AgentKnowledgeRetrievalStatus.noAnswerInvalidRequest,
        requestId: request.requestId.trim().isEmpty
            ? 'invalid_retrieval_request'
            : request.requestId,
        reasons: const <String>[
          'invalid_request_structure',
          'fail_closed',
          'no_guess',
        ],
      );
    }

    if (candidates.length > AgentKnowledgeRetrievalLimits.maxCandidateInput) {
      return _noAnswer(
        status: AgentKnowledgeRetrievalStatus.noAnswerInvalidRequest,
        requestId: request.requestId,
        reasons: const <String>[
          'candidate_input_limit_exceeded',
          'fail_closed',
          'no_guess',
        ],
      );
    }

    if (!request.scopeAuthorizationVerified) {
      return _noAnswer(
        status:
            AgentKnowledgeRetrievalStatus.noAnswerScopeAuthorizationUnverified,
        requestId: request.requestId,
        reasons: const <String>[
          'preauthorized_scope_context_required',
          'retrieval_cannot_grant_scope',
          'fail_closed',
          'no_guess',
        ],
      );
    }

    final List<AgentKnowledgeRetrievalCandidate> structurallyValid =
        <AgentKnowledgeRetrievalCandidate>[];

    for (final AgentKnowledgeRetrievalCandidate candidate in candidates) {
      try {
        candidate.validateStructure();
        structurallyValid.add(candidate);
      } catch (_) {
        // Malformed candidates are dropped, never trusted.
      }
    }

    final List<AgentKnowledgeRetrievalCandidate> trusted = structurallyValid
        .where(
          (AgentKnowledgeRetrievalCandidate candidate) =>
              candidate.trustEligible,
        )
        .toList(growable: false);

    if (trusted.isEmpty) {
      return _noAnswer(
        status: AgentKnowledgeRetrievalStatus.noAnswerUntrustedOrStale,
        requestId: request.requestId,
        reasons: const <String>[
          'no_trusted_fresh_approved_candidate',
          'stale_deprecated_unapproved_or_invalid_excluded',
          'fail_closed',
          'no_guess',
        ],
      );
    }

    final List<AgentKnowledgeRetrievalCandidate> topicMatched = trusted
        .where(
          (AgentKnowledgeRetrievalCandidate candidate) =>
              candidate.module == request.module &&
              candidate.topic == request.topic,
        )
        .toList(growable: false);

    if (topicMatched.isEmpty) {
      return _noAnswer(
        status: AgentKnowledgeRetrievalStatus.noAnswerNoTopicMatch,
        requestId: request.requestId,
        reasons: const <String>[
          'exact_module_topic_match_required',
          'no_cross_topic_guess',
          'no_guess',
        ],
      );
    }

    final List<AgentKnowledgeRetrievalCandidate> languageMatched = topicMatched
        .where(
          (AgentKnowledgeRetrievalCandidate candidate) =>
              candidate.language == request.language,
        )
        .toList(growable: false);

    if (languageMatched.isEmpty) {
      return _noAnswer(
        status: AgentKnowledgeRetrievalStatus.noAnswerLanguageMismatch,
        requestId: request.requestId,
        reasons: const <String>[
          'exact_language_match_required',
          'no_automatic_translation_in_step1d',
          'no_guess',
        ],
      );
    }

    final List<AgentKnowledgeRetrievalCandidate> scopeMatched = languageMatched
        .where(
          (AgentKnowledgeRetrievalCandidate candidate) =>
              candidate.scopes.any(request.allowedScopes.contains),
        )
        .toList(growable: false);

    if (scopeMatched.isEmpty) {
      return _noAnswer(
        status: AgentKnowledgeRetrievalStatus.noAnswerScopeMismatch,
        requestId: request.requestId,
        reasons: const <String>[
          'scope_filter_before_ranking',
          'no_cross_scope_leakage',
          'retrieval_cannot_expand_scope',
          'no_guess',
        ],
      );
    }

    final List<_ScoredCandidate> scored = scopeMatched
        .map(
          (AgentKnowledgeRetrievalCandidate candidate) => _ScoredCandidate(
            candidate: candidate,
            score: _rankingScore(candidate),
          ),
        )
        .toList();

    scored.sort((_ScoredCandidate a, _ScoredCandidate b) {
      final int scoreCompare = b.score.compareTo(a.score);

      if (scoreCompare != 0) {
        return scoreCompare;
      }

      final int revisionCompare = b.candidate.revision.compareTo(
        a.candidate.revision,
      );

      if (revisionCompare != 0) {
        return revisionCompare;
      }

      return a.candidate.itemId.compareTo(b.candidate.itemId);
    });

    if (scored.isEmpty || scored.first.score < request.minimumScore) {
      return _noAnswer(
        status: AgentKnowledgeRetrievalStatus.noAnswerLowConfidence,
        requestId: request.requestId,
        reasons: const <String>[
          'top_retrieval_score_below_threshold',
          'ranking_score_not_truth_probability',
          'no_guess',
        ],
      );
    }

    final List<AgentKnowledgeRankedReference> references = scored
        .where((_ScoredCandidate value) => value.score >= request.minimumScore)
        .take(request.maxResults)
        .map(
          (_ScoredCandidate value) => AgentKnowledgeRankedReference(
            itemId: value.candidate.itemId,
            contentReferenceId: value.candidate.contentReferenceId,
            revision: value.candidate.revision,
            sourceVersion: value.candidate.sourceVersion,
            rankingScore: value.score,
          ),
        )
        .toList(growable: false);

    if (references.isEmpty) {
      return _noAnswer(
        status: AgentKnowledgeRetrievalStatus.noAnswerLowConfidence,
        requestId: request.requestId,
        reasons: const <String>['no_reference_met_minimum_score', 'no_guess'],
      );
    }

    final AgentKnowledgeRetrievalResult result = AgentKnowledgeRetrievalResult(
      status: AgentKnowledgeRetrievalStatus.readyWithGroundedReferences,
      requestId: request.requestId,
      references: references,
      reasonCodes: const <String>[
        'trusted_candidates_only',
        'exact_module_topic_match',
        'exact_language_match',
        'scope_filter_before_ranking',
        'deterministic_ranking',
        'minimum_score_passed',
        'grounding_required_next',
        'response_guard_required_next',
        'ranking_score_not_truth_probability',
        'references_metadata_only',
      ],
    );

    result.validateStructure();
    return result;
  }

  double _rankingScore(AgentKnowledgeRetrievalCandidate candidate) {
    return (candidate.relevanceScore *
            AgentKnowledgeRetrievalRanking.relevanceWeight) +
        (candidate.authorityScore *
            AgentKnowledgeRetrievalRanking.authorityWeight) +
        (candidate.freshnessScore *
            AgentKnowledgeRetrievalRanking.freshnessWeight);
  }

  AgentKnowledgeRetrievalResult _noAnswer({
    required String status,
    required String requestId,
    required List<String> reasons,
  }) {
    final AgentKnowledgeRetrievalResult result = AgentKnowledgeRetrievalResult(
      status: status,
      requestId: requestId,
      references: const <AgentKnowledgeRankedReference>[],
      reasonCodes: reasons,
    );

    result.validateStructure();
    return result;
  }

  bool get trustedIndexedCandidateRequired => true;
  bool get approvedActiveRequired => true;
  bool get verifiedApprovedActiveFreshSourceRequired => true;
  bool get scopeAuthorizationMustBePreverified => true;
  bool get retrievalCannotGrantScope => true;
  bool get scopeFilteringBeforeRanking => true;
  bool get exactModuleTopicMatchRequired => true;
  bool get exactLanguageMatchRequired => true;
  bool get deterministicRankingRequired => true;
  bool get minimumScoreRequired => true;
  bool get rankingScoreIsNotTruthProbability => true;
  bool get noAnswerInsteadOfGuess => true;
  bool get staleDeprecatedUnapprovedExcluded => true;
  bool get publicPrivilegedScopeConflictExcluded => true;
  bool get conversationGroundingRequiredNext => true;
  bool get responseGuardRequiredNext => true;
  bool get referencesMetadataOnly => true;

  bool get performsDatabaseSearch => false;
  bool get retrievesRawKnowledgeContent => false;
  bool get invokesProvider => false;
  bool get grantsPermission => false;
  bool get expandsScope => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get sendsWhatsApp => false;
  bool get persistsRetrieval => false;

  bool get duplicatesStep1BContract => false;
  bool get duplicatesStep1CIngestion => false;
  bool get duplicatesConversationGrounding => false;
  bool get duplicatesResponseGuard => false;
  bool get duplicatesPhase55VideoCatalog => false;
  bool get implementsPhase62TrainingDeployment => false;
  bool get implementsPhase63RetentionUi => false;
}

class _ScoredCandidate {
  const _ScoredCandidate({required this.candidate, required this.score});

  final AgentKnowledgeRetrievalCandidate candidate;
  final double score;
}

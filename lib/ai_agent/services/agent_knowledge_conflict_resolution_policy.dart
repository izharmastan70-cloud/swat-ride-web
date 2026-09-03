import '../constants/agent_knowledge_conflict_resolution_constants.dart';
import '../models/agent_knowledge_citation_reference.dart';
import '../models/agent_knowledge_conflict_candidate.dart';
import '../models/agent_knowledge_conflict_resolution_result.dart';

class AgentKnowledgeConflictResolutionPolicy {
  const AgentKnowledgeConflictResolutionPolicy();

  AgentKnowledgeConflictResolutionResult resolve({
    required List<AgentKnowledgeConflictCandidate> candidates,
  }) {
    if (candidates.isEmpty ||
        candidates.length > AgentKnowledgeConflictLimits.maxCandidates) {
      return _noAnswer(
        status: AgentKnowledgeConflictStatus.noAnswerInvalidInput,
        claimKey: 'invalid_claim',
        reasons: const <String>[
          'invalid_candidate_count',
          'fail_closed',
          'no_guess',
        ],
      );
    }

    final List<AgentKnowledgeConflictCandidate> valid =
        <AgentKnowledgeConflictCandidate>[];

    for (final AgentKnowledgeConflictCandidate candidate in candidates) {
      try {
        candidate.validateStructure();

        if (candidate.citationEligible &&
            candidate.trustedScopeFilteredSnapshot) {
          valid.add(candidate);
        }
      } catch (_) {
        // Malformed/untrusted candidate is excluded.
      }
    }

    if (valid.isEmpty) {
      return _noAnswer(
        status: AgentKnowledgeConflictStatus.noAnswerNoCitableSource,
        claimKey: 'unresolved_claim',
        reasons: const <String>[
          'no_trusted_citation_eligible_candidate',
          'scope_or_trust_boundary_not_met',
          'fail_closed',
          'no_guess',
        ],
      );
    }

    final Set<String> claimKeys = valid
        .map((AgentKnowledgeConflictCandidate candidate) => candidate.claimKey)
        .toSet();

    if (claimKeys.length != 1) {
      return _noAnswer(
        status: AgentKnowledgeConflictStatus.noAnswerInvalidInput,
        claimKey: 'mixed_claim_keys',
        reasons: const <String>[
          'single_claim_resolution_required',
          'mixed_claim_keys_blocked',
          'no_guess',
        ],
      );
    }

    final String claimKey = claimKeys.single;

    final List<AgentKnowledgeConflictCandidate> collapsed =
        _collapseSameSourceRevisions(valid);

    if (collapsed.isEmpty) {
      return _noAnswer(
        status: AgentKnowledgeConflictStatus.noAnswerPrecedenceAmbiguous,
        claimKey: claimKey,
        reasons: const <String>[
          'same_source_same_revision_conflict',
          'precedence_ambiguous',
          'no_guess',
        ],
      );
    }

    int highestPrecedence = -1;

    for (final AgentKnowledgeConflictCandidate candidate in collapsed) {
      if (candidate.precedenceScore > highestPrecedence) {
        highestPrecedence = candidate.precedenceScore;
      }
    }

    final List<AgentKnowledgeConflictCandidate> top = collapsed
        .where(
          (AgentKnowledgeConflictCandidate candidate) =>
              candidate.precedenceScore == highestPrecedence,
        )
        .toList();

    final Set<String> topBindings = top
        .map(
          (AgentKnowledgeConflictCandidate candidate) =>
              candidate.claimValueBinding,
        )
        .toSet();

    if (topBindings.length != 1) {
      return _noAnswer(
        status: AgentKnowledgeConflictStatus.noAnswerUnresolvedConflict,
        claimKey: claimKey,
        reasons: const <String>[
          'equal_top_precedence_conflict',
          'conflicting_claim_bindings',
          'cannot_choose_without_new_verified_authority',
          'no_guess',
        ],
      );
    }

    final String selectedBinding = topBindings.single;

    final List<AgentKnowledgeConflictCandidate> supporting = collapsed
        .where(
          (AgentKnowledgeConflictCandidate candidate) =>
              candidate.claimValueBinding == selectedBinding,
        )
        .toList();

    supporting.sort((
      AgentKnowledgeConflictCandidate a,
      AgentKnowledgeConflictCandidate b,
    ) {
      final int precedenceCompare = b.precedenceScore.compareTo(
        a.precedenceScore,
      );

      if (precedenceCompare != 0) {
        return precedenceCompare;
      }

      final int revisionCompare = b.revision.compareTo(a.revision);

      if (revisionCompare != 0) {
        return revisionCompare;
      }

      final int retrievalCompare = b.retrievalScore.compareTo(a.retrievalScore);

      if (retrievalCompare != 0) {
        return retrievalCompare;
      }

      return a.itemId.compareTo(b.itemId);
    });

    final List<AgentKnowledgeCitationReference> citations = supporting
        .take(AgentKnowledgeConflictLimits.maxCitations)
        .map(
          (AgentKnowledgeConflictCandidate candidate) =>
              AgentKnowledgeCitationReference(
                itemId: candidate.itemId,
                sourceId: candidate.sourceId,
                sourceReferenceId: candidate.sourceReferenceId,
                contentReferenceId: candidate.contentReferenceId,
                sourceType: candidate.sourceType,
                authorityClass: candidate.authorityClass,
                revision: candidate.revision,
                sourceVersion: candidate.sourceVersion,
                claimKey: candidate.claimKey,
                claimValueBinding: candidate.claimValueBinding,
              ),
        )
        .toList(growable: false);

    if (citations.isEmpty) {
      return _noAnswer(
        status: AgentKnowledgeConflictStatus.noAnswerNoCitableSource,
        claimKey: claimKey,
        reasons: const <String>[
          'selected_claim_has_no_citation',
          'no_grounding_without_citation',
          'no_guess',
        ],
      );
    }

    final bool lowerPrecedenceConflictSuppressed = collapsed.any(
      (AgentKnowledgeConflictCandidate candidate) =>
          candidate.claimValueBinding != selectedBinding &&
          candidate.precedenceScore < highestPrecedence,
    );

    final AgentKnowledgeConflictResolutionResult result =
        AgentKnowledgeConflictResolutionResult(
          status: AgentKnowledgeConflictStatus.readyForGrounding,
          claimKey: claimKey,
          selectedClaimValueBinding: selectedBinding,
          citations: citations,
          reasonCodes: <String>[
            'trusted_scope_filtered_candidates_only',
            'same_source_newer_revision_collapsed',
            'source_authority_precedence_applied',
            if (lowerPrecedenceConflictSuppressed)
              'lower_precedence_conflict_suppressed',
            'equal_top_precedence_conflict_absent',
            'citation_required',
            'citation_metadata_only',
            'conversation_grounding_required_next',
            'response_guard_required_next',
            'retrieval_score_not_truth_probability',
            'no_business_authority',
          ],
        );

    result.validateStructure();
    return result;
  }

  List<AgentKnowledgeConflictCandidate> _collapseSameSourceRevisions(
    List<AgentKnowledgeConflictCandidate> candidates,
  ) {
    final Map<String, List<AgentKnowledgeConflictCandidate>> bySource =
        <String, List<AgentKnowledgeConflictCandidate>>{};

    for (final AgentKnowledgeConflictCandidate candidate in candidates) {
      bySource
          .putIfAbsent(
            candidate.sourceId,
            () => <AgentKnowledgeConflictCandidate>[],
          )
          .add(candidate);
    }

    final List<AgentKnowledgeConflictCandidate> collapsed =
        <AgentKnowledgeConflictCandidate>[];

    for (final List<AgentKnowledgeConflictCandidate> group in bySource.values) {
      int maxRevision = 0;

      for (final AgentKnowledgeConflictCandidate candidate in group) {
        if (candidate.revision > maxRevision) {
          maxRevision = candidate.revision;
        }
      }

      final List<AgentKnowledgeConflictCandidate> newest = group
          .where(
            (AgentKnowledgeConflictCandidate candidate) =>
                candidate.revision == maxRevision,
          )
          .toList();

      final Set<String> bindings = newest
          .map(
            (AgentKnowledgeConflictCandidate candidate) =>
                candidate.claimValueBinding,
          )
          .toSet();

      if (bindings.length != 1) {
        return const <AgentKnowledgeConflictCandidate>[];
      }

      newest.sort((
        AgentKnowledgeConflictCandidate a,
        AgentKnowledgeConflictCandidate b,
      ) {
        final int precedenceCompare = b.precedenceScore.compareTo(
          a.precedenceScore,
        );

        if (precedenceCompare != 0) {
          return precedenceCompare;
        }

        final int retrievalCompare = b.retrievalScore.compareTo(
          a.retrievalScore,
        );

        if (retrievalCompare != 0) {
          return retrievalCompare;
        }

        return a.itemId.compareTo(b.itemId);
      });

      collapsed.add(newest.first);
    }

    return collapsed;
  }

  AgentKnowledgeConflictResolutionResult _noAnswer({
    required String status,
    required String claimKey,
    required List<String> reasons,
  }) {
    final AgentKnowledgeConflictResolutionResult result =
        AgentKnowledgeConflictResolutionResult(
          status: status,
          claimKey: claimKey,
          selectedClaimValueBinding: '',
          citations: const <AgentKnowledgeCitationReference>[],
          reasonCodes: reasons,
        );

    result.validateStructure();
    return result;
  }

  bool get consumesStep1DScopeFilteredTrustedMetadata => true;
  bool get sourceAuthorityPrecedenceRequired => true;
  bool get sourceTypePrecedenceRequired => true;
  bool get sameSourceNewerRevisionWins => true;
  bool get equalTopPrecedenceConflictFailsClosed => true;
  bool get lowerPrecedenceConflictMayBeSuppressed => true;
  bool get retrievalScoreCannotOverridePrecedence => true;
  bool get retrievalScoreIsNotTruthProbability => true;
  bool get citationRequiredForSelectedClaim => true;
  bool get citationProjectionMetadataOnly => true;
  bool get citationDoesNotCreateTruth => true;
  bool get noAnswerInsteadOfGuess => true;
  bool get conversationGroundingRequiredNext => true;
  bool get responseGuardRequiredNext => true;

  bool get grantsPermission => false;
  bool get expandsScope => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get performsDatabaseSearch => false;
  bool get retrievesRawKnowledgeContent => false;
  bool get invokesProvider => false;
  bool get sendsWhatsApp => false;
  bool get persistsResolution => false;

  bool get duplicatesStep1DRetrieval => false;
  bool get duplicatesConversationGrounding => false;
  bool get duplicatesResponseGuard => false;
  bool get duplicatesPhase55VideoCatalog => false;
  bool get implementsPhase62TrainingDeployment => false;
  bool get implementsPhase63RetentionUi => false;
}

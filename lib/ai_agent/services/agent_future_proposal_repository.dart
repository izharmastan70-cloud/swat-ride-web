import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_future_proposal_constants.dart';
import '../models/agent_future_proposal.dart';

/// Persistence-only repository for Phase 41 Future proposals.
///
/// SAFETY:
/// - this repository does not approve proposals;
/// - it does not invoke Code Agent;
/// - it does not invoke providers;
/// - it does not deploy;
/// - it exposes no hard-delete method;
/// - callers must use the dedicated review/handoff services for authority.
class AgentFutureProposalRepository {
  AgentFutureProposalRepository({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionPath = 'agent_future_proposals';

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      firestore.collection(collectionPath);

  Future<void> createProposal(AgentFutureProposal proposal) async {
    proposal.validate();

    if (proposal.status != AgentFutureProposalStatus.awaitingReview) {
      throw AgentFutureProposalRepositoryException(
        'New persisted Future proposal must start AWAITING_REVIEW. '
        'Current status: ${proposal.status}.',
      );
    }

    final DocumentReference<Map<String, dynamic>> ref = _collection.doc(
      proposal.proposalId,
    );

    await firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> existing = await transaction
          .get(ref);

      if (existing.exists) {
        throw AgentFutureProposalRepositoryException(
          'Future proposal already exists: ${proposal.proposalId}',
        );
      }

      transaction.set(ref, proposal.toMap());
    });
  }

  Future<AgentFutureProposal?> getProposal(String proposalId) async {
    final String normalized = proposalId.trim();

    if (normalized.isEmpty) {
      throw const AgentFutureProposalRepositoryException(
        'proposalId cannot be empty.',
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _collection
        .doc(normalized)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    final Map<String, dynamic>? data = snapshot.data();

    if (data == null) {
      return null;
    }

    final AgentFutureProposal proposal = AgentFutureProposal.fromMap(data);

    if (proposal.proposalId != normalized) {
      throw const AgentFutureProposalRepositoryException(
        'Stored proposalId does not match document ID.',
      );
    }

    return proposal;
  }

  Stream<List<AgentFutureProposal>> watchRecent({int limit = 100}) {
    if (limit < 1 || limit > 200) {
      throw const AgentFutureProposalRepositoryException(
        'watchRecent limit must be between 1 and 200.',
      );
    }

    return _collection
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
                final AgentFutureProposal proposal =
                    AgentFutureProposal.fromMap(doc.data());

                if (proposal.proposalId != doc.id) {
                  throw const AgentFutureProposalRepositoryException(
                    'Stored proposalId does not match document ID.',
                  );
                }

                return proposal;
              })
              .toList(growable: false),
        );
  }

  Stream<List<AgentFutureProposal>> watchReviewQueue({int limit = 100}) {
    return watchRecent(limit: limit).map(
      (List<AgentFutureProposal> proposals) => proposals
          .where(
            (AgentFutureProposal proposal) =>
                proposal.status == AgentFutureProposalStatus.awaitingReview ||
                proposal.status == AgentFutureProposalStatus.needsEdit,
          )
          .toList(growable: false),
    );
  }

  /// Optimistic-lock transition save.
  ///
  /// The caller must pass the exact updatedAt value it originally read.
  /// If another review action changed the proposal meanwhile, this fails
  /// closed instead of silently overwriting newer state.
  Future<void> saveTransition({
    required AgentFutureProposal proposal,
    required DateTime expectedPreviousUpdatedAt,
  }) async {
    proposal.validate();

    final DocumentReference<Map<String, dynamic>> ref = _collection.doc(
      proposal.proposalId,
    );

    await firestore.runTransaction((Transaction transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await transaction
          .get(ref);

      if (!snapshot.exists || snapshot.data() == null) {
        throw AgentFutureProposalRepositoryException(
          'Future proposal not found: ${proposal.proposalId}',
        );
      }

      final AgentFutureProposal current = AgentFutureProposal.fromMap(
        snapshot.data()!,
      );

      if (current.proposalId != proposal.proposalId) {
        throw const AgentFutureProposalRepositoryException(
          'Stored proposal identity mismatch.',
        );
      }

      if (!current.updatedAt.toUtc().isAtSameMomentAs(
        expectedPreviousUpdatedAt.toUtc(),
      )) {
        throw const AgentFutureProposalRepositoryException(
          'Future proposal changed since it was opened. Reload before retry.',
        );
      }

      if (proposal.updatedAt.toUtc().isBefore(current.updatedAt.toUtc())) {
        throw const AgentFutureProposalRepositoryException(
          'Proposal updatedAt cannot move backwards.',
        );
      }

      transaction.set(ref, proposal.toMap());
    });
  }
}

class AgentFutureProposalRepositoryException implements Exception {
  const AgentFutureProposalRepositoryException(this.message);

  final String message;

  @override
  String toString() => 'AgentFutureProposalRepositoryException: $message';
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_feedback_constants.dart';
import '../models/agent_feedback_item.dart';

// =========================================================
// AI AGENT — CENTRAL FEEDBACK SERVICE
// =========================================================
//
// Firestore collection: agent_feedback
// Standalone Phase 12 shared feedback store.
//
// No existing Ride/Food/Hotel/Tour review collection is touched.

class AgentFeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collectionPath = 'agent_feedback';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  Future<AgentFeedbackItem> create({
    required String userIdAlias,
    required String module,
    required String referenceId,
    required String type,
    required String message,
    int? rating,
  }) async {
    final DocumentReference<Map<String, dynamic>> doc =
        _collection.doc();

    final AgentFeedbackItem item = AgentFeedbackItem(
      feedbackId: doc.id,
      userIdAlias: userIdAlias,
      module: module,
      referenceId: referenceId,
      type: type,
      rating: rating,
      message: message,
      status: AgentFeedbackStatus.open,
      createdAt: DateTime.now(),
      updatedAt: null,
    );

    item.validate();
    await doc.set(item.toMap());
    return item;
  }

  Future<AgentFeedbackItem?> getById(
    String feedbackId,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _collection.doc(feedbackId).get();

    if (!snapshot.exists) return null;
    return AgentFeedbackItem.fromSnapshot(snapshot);
  }

  Stream<List<AgentFeedbackItem>> watchOpen() {
    return _collection
        .where(
          'status',
          whereIn: <String>[
            AgentFeedbackStatus.open,
            AgentFeedbackStatus.underReview,
            AgentFeedbackStatus.escalated,
          ],
        )
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        return snapshot.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  AgentFeedbackItem.fromSnapshot(doc),
            )
            .toList(growable: false);
      },
    );
  }

  Future<void> setStatus({
    required String feedbackId,
    required String status,
  }) async {
    if (!AgentFeedbackStatus.isValid(status)) {
      throw AgentFeedbackValidationException(
        'Invalid status "$status".',
      );
    }

    await _collection.doc(feedbackId).update(
      <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }
}

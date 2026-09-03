import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/agent_website_deployment_history.dart';

/// Phase 34 Step 3D-D2B.
///
/// Persistent website deployment lifecycle store.
///
/// Firestore collection:
/// agent_website_deployment_history
///
/// Safety:
/// - deploymentId is the document identity;
/// - history validates before every write;
/// - this repository stores state only;
/// - no Vercel/GitHub execution;
/// - no secrets;
/// - no DNS/domain mutation.
class AgentWebsiteDeploymentHistoryRepository {
  final FirebaseFirestore _firestore;

  AgentWebsiteDeploymentHistoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionPath = 'agent_website_deployment_history';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionPath);

  Future<AgentWebsiteDeploymentHistory> save(
    AgentWebsiteDeploymentHistory history,
  ) async {
    history.validate();

    final String deploymentId = history.deploymentId.trim();

    if (deploymentId.isEmpty) {
      throw const AgentWebsiteDeploymentHistoryRepositoryException(
        'deploymentId is required.',
      );
    }

    final DocumentReference<Map<String, dynamic>> document = _collection.doc(
      deploymentId,
    );

    await document.set(history.toMap(), SetOptions(merge: false));

    return history;
  }

  Future<AgentWebsiteDeploymentHistory?> getById(String deploymentId) async {
    final String normalized = deploymentId.trim();

    if (normalized.isEmpty) {
      throw const AgentWebsiteDeploymentHistoryRepositoryException(
        'deploymentId is required.',
      );
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _collection
        .doc(normalized)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return AgentWebsiteDeploymentHistory.fromMap(
      Map<String, dynamic>.from(snapshot.data() ?? <String, dynamic>{}),
      documentId: snapshot.id,
    );
  }

  Stream<AgentWebsiteDeploymentHistory?> watchById(String deploymentId) {
    final String normalized = deploymentId.trim();

    if (normalized.isEmpty) {
      throw const AgentWebsiteDeploymentHistoryRepositoryException(
        'deploymentId is required.',
      );
    }

    return _collection.doc(normalized).snapshots().map((
      DocumentSnapshot<Map<String, dynamic>> snapshot,
    ) {
      if (!snapshot.exists) {
        return null;
      }

      return AgentWebsiteDeploymentHistory.fromMap(
        Map<String, dynamic>.from(snapshot.data() ?? <String, dynamic>{}),
        documentId: snapshot.id,
      );
    });
  }

  Stream<List<AgentWebsiteDeploymentHistory>> watchRecent({int limit = 50}) {
    if (limit < 1 || limit > 100) {
      throw const AgentWebsiteDeploymentHistoryRepositoryException(
        'History limit must be between 1 and 100.',
      );
    }

    return _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs
              .map((QueryDocumentSnapshot<Map<String, dynamic>> document) {
                return AgentWebsiteDeploymentHistory.fromMap(
                  document.data(),
                  documentId: document.id,
                );
              })
              .toList(growable: false);
        });
  }

  Stream<List<AgentWebsiteDeploymentHistory>> watchByChangeId(
    String changeId, {
    int limit = 20,
  }) {
    final String normalized = changeId.trim();

    if (normalized.isEmpty) {
      throw const AgentWebsiteDeploymentHistoryRepositoryException(
        'changeId is required.',
      );
    }

    if (limit < 1 || limit > 100) {
      throw const AgentWebsiteDeploymentHistoryRepositoryException(
        'History limit must be between 1 and 100.',
      );
    }

    return _collection
        .where('changeId', isEqualTo: normalized)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          return snapshot.docs
              .map((QueryDocumentSnapshot<Map<String, dynamic>> document) {
                return AgentWebsiteDeploymentHistory.fromMap(
                  document.data(),
                  documentId: document.id,
                );
              })
              .toList(growable: false);
        });
  }
}

class AgentWebsiteDeploymentHistoryRepositoryException implements Exception {
  final String message;

  const AgentWebsiteDeploymentHistoryRepositoryException(this.message);

  @override
  String toString() =>
      'AgentWebsiteDeploymentHistoryRepositoryException: $message';
}

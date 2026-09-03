import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_provider_constants.dart';
import '../models/agent_provider_health.dart';

// =========================================================
// AI AGENT — PROVIDER HEALTH SERVICE
// =========================================================
//
// Firestore collection: ai_provider_status
// AI operational metadata only.

class AgentProviderHealthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collectionPath = 'ai_provider_status';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  Future<void> recordSuccess({
    required String providerId,
    required String providerType,
  }) async {
    await _collection.doc(providerId).set(
      <String, dynamic>{
        'providerId': providerId,
        'providerType': providerType,
        'status': AgentProviderStatus.healthy,
        'consecutiveFailures': 0,
        'requestsToday': FieldValue.increment(1),
        'lastSuccessAt': FieldValue.serverTimestamp(),
        'lastError': '',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> recordFailure({
    required String providerId,
    required String providerType,
    required String error,
  }) async {
    await _collection.doc(providerId).set(
      <String, dynamic>{
        'providerId': providerId,
        'providerType': providerType,
        'status': AgentProviderStatus.degraded,
        'consecutiveFailures': FieldValue.increment(1),
        'requestsToday': FieldValue.increment(1),
        'lastFailureAt': FieldValue.serverTimestamp(),
        'lastError': error,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> markUnavailable({
    required String providerId,
    required String providerType,
    String reason = '',
  }) async {
    await _collection.doc(providerId).set(
      <String, dynamic>{
        'providerId': providerId,
        'providerType': providerType,
        'status': AgentProviderStatus.unavailable,
        'lastError': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<AgentProviderHealth>> watchAll() {
    return _collection.snapshots().map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        return snapshot.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  AgentProviderHealth.fromMap(
                <String, dynamic>{
                  ...doc.data(),
                  'providerId': doc.id,
                },
              ),
            )
            .toList(growable: false);
      },
    );
  }
}

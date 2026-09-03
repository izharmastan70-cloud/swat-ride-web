import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_audit_constants.dart';
import '../constants/agent_provider_constants.dart';
import '../models/agent_provider_health.dart';
import 'agent_audit_service.dart';

// =========================================================
// AI AGENT â€” PROVIDER HEALTH SERVICE
// =========================================================
//
// Firestore collection: ai_provider_status
// AI operational metadata only.

class AgentProviderHealthService {
  final FirebaseFirestore _firestore;
  late final AgentAuditService _auditService;

  AgentProviderHealthService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance {
    _auditService = AgentAuditService(firestore: _firestore);
  }

  static const String _collectionPath = 'ai_provider_status';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  Future<void> recordSuccess({
    required String providerId,
    required String providerType,
  }) async {
    final String normalizedProviderId = providerId.trim();
    final String normalizedProviderType = providerType.trim();

    if (normalizedProviderId.isEmpty || normalizedProviderType.isEmpty) {
      throw ArgumentError('providerId and providerType are required.');
    }

    final DocumentReference<Map<String, dynamic>> document = _collection.doc(
      normalizedProviderId,
    );

    final WriteBatch batch = _firestore.batch();

    batch.set(document, <String, dynamic>{
      'providerId': normalizedProviderId,
      'providerType': normalizedProviderType,
      'status': AgentProviderStatus.healthy,
      'consecutiveFailures': 0,
      'requestsToday': FieldValue.increment(1),
      'lastSuccessAt': FieldValue.serverTimestamp(),
      'lastError': '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _auditService.appendToBatch(
      batch: batch,
      eventType: AgentAuditEventType.providerRequestSucceeded,
      severity: AgentAuditSeverity.info,
      actorType: AgentAuditActorType.system,
      actorId: 'system',
      module: 'core',
      actionId: 'provider.health.success',
      result: AgentProviderStatus.healthy,
      reason: 'Provider request succeeded and health usage was updated.',
      scope: <String, dynamic>{'providerId': normalizedProviderId},
      metadata: <String, dynamic>{
        'providerType': normalizedProviderType,
        'requestCountIncremented': true,
      },
    );

    await batch.commit();
  }

  Future<void> recordFailure({
    required String providerId,
    required String providerType,
    required String error,
  }) async {
    final String normalizedProviderId = providerId.trim();
    final String normalizedProviderType = providerType.trim();
    final String normalizedError = error.trim();

    if (normalizedProviderId.isEmpty || normalizedProviderType.isEmpty) {
      throw ArgumentError('providerId and providerType are required.');
    }

    final DocumentReference<Map<String, dynamic>> document = _collection.doc(
      normalizedProviderId,
    );

    final WriteBatch batch = _firestore.batch();

    batch.set(document, <String, dynamic>{
      'providerId': normalizedProviderId,
      'providerType': normalizedProviderType,
      'status': AgentProviderStatus.degraded,
      'consecutiveFailures': FieldValue.increment(1),
      'requestsToday': FieldValue.increment(1),
      'lastFailureAt': FieldValue.serverTimestamp(),
      'lastError': normalizedError,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _auditService.appendToBatch(
      batch: batch,
      eventType: AgentAuditEventType.providerRequestFailed,
      severity: AgentAuditSeverity.warning,
      actorType: AgentAuditActorType.system,
      actorId: 'system',
      module: 'core',
      actionId: 'provider.health.failure',
      result: AgentProviderStatus.degraded,
      reason: 'Provider request failed and health usage was updated.',
      scope: <String, dynamic>{'providerId': normalizedProviderId},
      metadata: <String, dynamic>{
        'providerType': normalizedProviderType,
        'requestCountIncremented': true,
      },
    );

    await batch.commit();
  }

  Future<void> markUnavailable({
    required String providerId,
    required String providerType,
    String reason = '',
  }) async {
    final String normalizedProviderId = providerId.trim();
    final String normalizedProviderType = providerType.trim();
    final String normalizedReason = reason.trim();

    if (normalizedProviderId.isEmpty || normalizedProviderType.isEmpty) {
      throw ArgumentError('providerId and providerType are required.');
    }

    final DocumentReference<Map<String, dynamic>> document = _collection.doc(
      normalizedProviderId,
    );

    final WriteBatch batch = _firestore.batch();

    batch.set(document, <String, dynamic>{
      'providerId': normalizedProviderId,
      'providerType': normalizedProviderType,
      'status': AgentProviderStatus.unavailable,
      'lastError': normalizedReason,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _auditService.appendToBatch(
      batch: batch,
      eventType: AgentAuditEventType.providerMarkedUnavailable,
      severity: AgentAuditSeverity.warning,
      actorType: AgentAuditActorType.system,
      actorId: 'system',
      module: 'core',
      actionId: 'provider.health.unavailable',
      result: AgentProviderStatus.unavailable,
      reason: 'Provider was marked unavailable.',
      scope: <String, dynamic>{'providerId': normalizedProviderId},
      metadata: <String, dynamic>{
        'providerType': normalizedProviderType,
        'requestCountIncremented': false,
      },
    );

    await batch.commit();
  }

  Stream<List<AgentProviderHealth>> watchAll() {
    return _collection.snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      return snapshot.docs
          .map(
            (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                AgentProviderHealth.fromMap(<String, dynamic>{
                  ...doc.data(),
                  'providerId': doc.id,
                }),
          )
          .toList(growable: false);
    });
  }
}

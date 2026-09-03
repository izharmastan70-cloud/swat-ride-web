import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_audit_constants.dart';
import '../models/agent_audit_log.dart';

// =========================================================
// AI AGENT — AUDIT LOG SERVICE
// =========================================================
//
// Firestore collection: agent_audit_logs
//
// Application API is APPEND-ONLY.
// There are deliberately no update/delete methods.
//
// IMPORTANT:
// Client-side append-only design is not immutable security by itself.
// Later Firestore Security Rules / trusted backend must deny update/delete
// on audit documents, including to privileged clients where appropriate.

class AgentAuditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collectionPath = 'agent_audit_logs';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  Future<AgentAuditLog> append({
    required String eventType,
    required String severity,
    required String actorType,
    required String actorId,
    String roleId = '',
    String module = '',
    String actionId = '',
    String result = '',
    String reason = '',
    String relatedApprovalId = '',
    Map<String, dynamic> scope = const <String, dynamic>{},
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) async {
    final DocumentReference<Map<String, dynamic>> doc = _collection.doc();
    final DateTime now = DateTime.now();

    final AgentAuditLog log = AgentAuditLog(
      auditId: doc.id,
      eventType: eventType,
      severity: severity,
      actorType: actorType,
      actorId: actorId,
      roleId: roleId,
      module: module,
      actionId: actionId,
      result: result,
      reason: reason,
      relatedApprovalId: relatedApprovalId,
      scope: _sanitizeMap(scope),
      metadata: _sanitizeMap(metadata),
      createdAt: now,
    );

    log.validate();
    await doc.set(log.toMap());
    return log;
  }

  Future<AgentAuditLog> recordSystemEvent({
    required String reason,
    String module = '',
    String actionId = '',
    String result = '',
    String severity = AgentAuditSeverity.info,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    return append(
      eventType: AgentAuditEventType.systemEvent,
      severity: severity,
      actorType: AgentAuditActorType.system,
      actorId: 'system',
      module: module,
      actionId: actionId,
      result: result,
      reason: reason,
      metadata: metadata,
    );
  }

  Future<List<AgentAuditLog>> getRecent({
    int limit = 100,
  }) async {
    final int safeLimit = limit.clamp(1, 500).toInt();

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _collection
        .orderBy('createdAt', descending: true)
        .limit(safeLimit)
        .get();

    return snapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              AgentAuditLog.fromSnapshot(doc),
        )
        .toList(growable: false);
  }

  Stream<List<AgentAuditLog>> watchRecent({
    int limit = 100,
  }) {
    final int safeLimit = limit.clamp(1, 500).toInt();

    return _collection
        .orderBy('createdAt', descending: true)
        .limit(safeLimit)
        .snapshots()
        .map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        return snapshot.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  AgentAuditLog.fromSnapshot(doc),
            )
            .toList(growable: false);
      },
    );
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> input) {
    // Phase 4 safety foundation: remove obvious secret-like keys before
    // writing audit metadata. The Privacy Router later will provide a
    // stronger centralized redaction policy.
    final Map<String, dynamic> output = <String, dynamic>{};

    for (final MapEntry<String, dynamic> entry in input.entries) {
      final String key = entry.key.trim();
      final String normalized = key.toLowerCase();

      if (_looksSecret(normalized)) {
        output[key] = '[REDACTED]';
      } else {
        output[key] = _sanitizeValue(entry.value);
      }
    }

    return output;
  }

  dynamic _sanitizeValue(dynamic value) {
    if (value is Map) {
      final Map<String, dynamic> nested = value.map(
        (dynamic key, dynamic item) =>
            MapEntry<String, dynamic>(key.toString(), item),
      );
      return _sanitizeMap(nested);
    }

    if (value is Iterable) {
      return value
          .map<dynamic>((dynamic item) => _sanitizeValue(item))
          .toList(growable: false);
    }

    return value;
  }

  bool _looksSecret(String normalizedKey) {
    const List<String> blockedFragments = <String>[
      'password',
      'passwd',
      'secret',
      'token',
      'apikey',
      'api_key',
      'privatekey',
      'private_key',
      'authorization',
      'credential',
      'banklogin',
      'gatewaykey',
    ];

    return blockedFragments.any(normalizedKey.contains);
  }
}

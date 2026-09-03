import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_crash_constants.dart';
import '../models/agent_crash_event.dart';
import 'agent_crash_sanitizer.dart';

// =========================================================
// AI AGENT — CRASH EVENT SERVICE
// =========================================================
//
// Firestore collection: agent_crash_events
// Standalone Phase 14 crash store.
//
// This does NOT automatically hook FlutterError/onError yet.
// Existing app bootstrap remains untouched until integration phase.

class AgentCrashEventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AgentCrashSanitizer _sanitizer = const AgentCrashSanitizer();

  static const String _collectionPath = 'agent_crash_events';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  Future<AgentCrashEvent> record({
    required String module,
    required String errorType,
    required String message,
    required String stackSummary,
    required String appVersion,
    required String platform,
  }) async {
    final String fingerprint = _fingerprint(
      module: module,
      errorType: errorType,
      message: message,
    );

    final DocumentReference<Map<String, dynamic>> ref =
        _collection.doc(fingerprint);

    return _firestore.runTransaction<AgentCrashEvent>(
      (Transaction transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await transaction.get(ref);

        if (snapshot.exists) {
          final AgentCrashEvent current =
              AgentCrashEvent.fromSnapshot(snapshot);

          final AgentCrashEvent updated = AgentCrashEvent(
            crashId: current.crashId,
            module: current.module,
            errorType: current.errorType,
            message: current.message,
            stackSummary: current.stackSummary,
            appVersion: appVersion,
            platform: platform,
            severity: current.severity,
            category: current.category,
            status: current.status,
            occurrenceCount: current.occurrenceCount + 1,
            firstSeenAt: current.firstSeenAt,
            lastSeenAt: DateTime.now(),
          );

          transaction.set(
            ref,
            updated.toMap(),
            SetOptions(merge: true),
          );

          return updated;
        }

        final AgentCrashEvent created = AgentCrashEvent(
          crashId: fingerprint,
          module: module.trim(),
          errorType: _sanitizer.sanitizeText(errorType, maxLength: 200),
          message: _sanitizer.sanitizeText(message),
          stackSummary:
              _sanitizer.sanitizeText(stackSummary, maxLength: 6000),
          appVersion: appVersion.trim(),
          platform: platform.trim(),
          severity: AgentCrashSeverity.warning,
          category: AgentCrashCategory.unknown,
          status: AgentCrashStatus.open,
          occurrenceCount: 1,
          firstSeenAt: DateTime.now(),
          lastSeenAt: DateTime.now(),
        );

        created.validate();
        transaction.set(ref, created.toMap());
        return created;
      },
    );
  }

  Stream<List<AgentCrashEvent>> watchOpen() {
    return _collection
        .where(
          'status',
          whereIn: <String>[
            AgentCrashStatus.open,
            AgentCrashStatus.classified,
            AgentCrashStatus.handedToCodeAgent,
          ],
        )
        .orderBy('lastSeenAt', descending: true)
        .snapshots()
        .map(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        return snapshot.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  AgentCrashEvent.fromSnapshot(doc),
            )
            .toList(growable: false);
      },
    );
  }

  Future<void> markClassification({
    required String crashId,
    required String severity,
    required String category,
  }) async {
    await _collection.doc(crashId).update(
      <String, dynamic>{
        'severity': severity,
        'category': category,
        'status': AgentCrashStatus.classified,
        'lastSeenAt': FieldValue.serverTimestamp(),
      },
    );
  }

  Future<void> markHandedToCodeAgent(String crashId) async {
    await _collection.doc(crashId).update(
      <String, dynamic>{
        'status': AgentCrashStatus.handedToCodeAgent,
        'lastSeenAt': FieldValue.serverTimestamp(),
      },
    );
  }

  String _fingerprint({
    required String module,
    required String errorType,
    required String message,
  }) {
    final String normalized =
        '${module.trim().toLowerCase()}|'
        '${errorType.trim().toLowerCase()}|'
        '${message.trim().toLowerCase()}';

    int hash = 2166136261;
    for (final int code in normalized.codeUnits) {
      hash ^= code;
      hash = (hash * 16777619) & 0x7fffffff;
    }

    return 'crash_$hash';
  }
}

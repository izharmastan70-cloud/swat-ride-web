import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_call_constants.dart';
import '../models/agent_call_session.dart';

// =========================================================
// AI AGENT — CALL SESSION SERVICE
// =========================================================
//
// Test-mode session metadata only.
// No telephony provider connection exists yet.

class AgentCallSessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _collectionPath = 'agent_call_sessions';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionPath);

  Future<void> save(AgentCallSession session) async {
    await _collection.doc(session.sessionId).set(session.toMap());
  }

  Future<void> markEscalated({
    required String sessionId,
    required String level,
    required Map<String, dynamic> summary,
  }) async {
    await _collection.doc(sessionId).set(
      <String, dynamic>{
        'status': AgentCallSessionStatus.escalated,
        'escalationLevel': level,
        'escalationSummary': summary,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

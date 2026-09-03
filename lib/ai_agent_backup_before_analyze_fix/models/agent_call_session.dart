import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_call_constants.dart';

// =========================================================
// AI AGENT — CALL SESSION
// =========================================================
//
// Stores minimum operational call metadata.
// Call recording/audio storage is NOT part of Phase 17.

class AgentCallSession {
  final String sessionId;
  final String mode;
  final String callerName;
  final String callerPhoneMasked;
  final String intent;
  final String module;
  final String referenceId;
  final String status;
  final String escalationLevel;
  final bool recordingEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AgentCallSession({
    required this.sessionId,
    required this.mode,
    required this.callerName,
    required this.callerPhoneMasked,
    required this.intent,
    required this.module,
    required this.referenceId,
    required this.status,
    required this.escalationLevel,
    required this.recordingEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        'sessionId': sessionId,
        'mode': mode,
        'callerName': callerName,
        'callerPhoneMasked': callerPhoneMasked,
        'intent': intent,
        'module': module,
        'referenceId': referenceId,
        'status': status,
        'escalationLevel': escalationLevel,
        'recordingEnabled': recordingEnabled,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory AgentCallSession.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> map =
        snapshot.data() ?? <String, dynamic>{};

    DateTime parse(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return AgentCallSession(
      sessionId: (map['sessionId'] ?? snapshot.id).toString(),
      mode: (map['mode'] ?? AgentCallMode.test).toString(),
      callerName: (map['callerName'] ?? '').toString(),
      callerPhoneMasked: (map['callerPhoneMasked'] ?? '').toString(),
      intent: (map['intent'] ?? AgentCallIntent.unknown).toString(),
      module: (map['module'] ?? 'call').toString(),
      referenceId: (map['referenceId'] ?? '').toString(),
      status:
          (map['status'] ?? AgentCallSessionStatus.active).toString(),
      escalationLevel:
          (map['escalationLevel'] ?? AgentCallEscalationLevel.ai)
              .toString(),
      recordingEnabled: map['recordingEnabled'] == true,
      createdAt: parse(map['createdAt']),
      updatedAt: parse(map['updatedAt']),
    );
  }
}

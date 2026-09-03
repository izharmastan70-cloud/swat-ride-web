import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_audit_constants.dart';

// =========================================================
// AI AGENT — AUDIT LOG MODEL
// =========================================================
//
// Firestore collection: agent_audit_logs
//
// Audit records are append-only from application code.
// This class intentionally has no copyWith/update workflow for stored
// records. Firestore Security Rules/trusted backend enforcement is still
// required later to prevent privileged direct edits/deletes.

class AgentAuditLog {
  final String auditId;
  final String eventType;
  final String severity;
  final String actorType;
  final String actorId;
  final String roleId;
  final String module;
  final String actionId;
  final String result;
  final String reason;
  final String relatedApprovalId;
  final Map<String, dynamic> scope;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const AgentAuditLog({
    required this.auditId,
    required this.eventType,
    required this.severity,
    required this.actorType,
    required this.actorId,
    required this.roleId,
    required this.module,
    required this.actionId,
    required this.result,
    required this.reason,
    required this.relatedApprovalId,
    required this.scope,
    required this.metadata,
    required this.createdAt,
  });

  void validate() {
    if (auditId.trim().isEmpty) {
      throw const AgentAuditValidationException('auditId cannot be empty.');
    }

    if (!AgentAuditEventType.isValid(eventType)) {
      throw AgentAuditValidationException(
        'Invalid eventType "$eventType".',
      );
    }

    if (!AgentAuditSeverity.isValid(severity)) {
      throw AgentAuditValidationException(
        'Invalid severity "$severity".',
      );
    }

    if (!AgentAuditActorType.isValid(actorType)) {
      throw AgentAuditValidationException(
        'Invalid actorType "$actorType".',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'auditId': auditId,
      'eventType': eventType,
      'severity': severity,
      'actorType': actorType,
      'actorId': actorId,
      'roleId': roleId,
      'module': module,
      'actionId': actionId,
      'result': result,
      'reason': reason,
      'relatedApprovalId': relatedApprovalId,
      'scope': scope,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AgentAuditLog.fromMap(Map<String, dynamic> map) {
    return AgentAuditLog(
      auditId: _string(map['auditId']),
      eventType: _string(
        map['eventType'],
        fallback: AgentAuditEventType.systemEvent,
      ),
      severity: _string(
        map['severity'],
        fallback: AgentAuditSeverity.warning,
      ),
      actorType: _string(
        map['actorType'],
        fallback: AgentAuditActorType.system,
      ),
      actorId: _string(map['actorId']),
      roleId: _string(map['roleId']),
      module: _string(map['module']),
      actionId: _string(map['actionId']),
      result: _string(map['result']),
      reason: _string(map['reason']),
      relatedApprovalId: _string(map['relatedApprovalId']),
      scope: _safeMap(map['scope']),
      metadata: _safeMap(map['metadata']),
      createdAt: _date(map['createdAt']),
    );
  }

  factory AgentAuditLog.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(snapshot.data() ?? <String, dynamic>{});

    data['auditId'] ??= snapshot.id;

    final AgentAuditLog log = AgentAuditLog.fromMap(data);
    log.validate();
    return log;
  }

  static String _string(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final String result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }

    if (value is Map) {
      return value.map(
        (dynamic key, dynamic item) =>
            MapEntry<String, dynamic>(key.toString(), item),
      );
    }

    return <String, dynamic>{};
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class AgentAuditValidationException implements Exception {
  final String message;

  const AgentAuditValidationException(this.message);

  @override
  String toString() => 'AgentAuditValidationException: $message';
}

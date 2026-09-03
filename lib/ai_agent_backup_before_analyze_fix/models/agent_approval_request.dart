import 'package:cloud_firestore/cloud_firestore.dart';

// =========================================================
// AI AGENT — APPROVAL REQUEST MODEL
// =========================================================
//
// Firestore collection: agent_approvals
// One approval = one specific action request.
// Approval must never silently authorize future or wider actions.

class AgentApprovalStatus {
  AgentApprovalStatus._();

  static const String pending = 'PENDING';
  static const String approved = 'APPROVED';
  static const String rejected = 'REJECTED';
  static const String expired = 'EXPIRED';
  static const String consumed = 'CONSUMED';
  static const String cancelled = 'CANCELLED';

  static const Set<String> values = <String>{
    pending,
    approved,
    rejected,
    expired,
    consumed,
    cancelled,
  };

  static bool isValid(String value) => values.contains(value);
}

class AgentApprovalRequest {
  final String approvalId;
  final String roleId;
  final String actionId;
  final String module;
  final String reason;
  final String risk;
  final String requestedBy;
  final Map<String, dynamic> actionScope;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? decidedAt;
  final DateTime? consumedAt;
  final String? decidedBy;
  final String? decisionNote;

  const AgentApprovalRequest({
    required this.approvalId,
    required this.roleId,
    required this.actionId,
    required this.module,
    required this.reason,
    required this.risk,
    required this.requestedBy,
    required this.actionScope,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.decidedAt,
    this.consumedAt,
    this.decidedBy,
    this.decisionNote,
  });

  bool get isPending => status == AgentApprovalStatus.pending;
  bool get isApproved => status == AgentApprovalStatus.approved;
  bool get isRejected => status == AgentApprovalStatus.rejected;
  bool get isConsumed => status == AgentApprovalStatus.consumed;
  bool get isExpiredStatus => status == AgentApprovalStatus.expired;

  bool get isExpiredNow =>
      DateTime.now().isAfter(expiresAt) || isExpiredStatus;

  bool get canBeConsumed =>
      isApproved && !isExpiredNow && consumedAt == null;

  AgentApprovalRequest copyWith({
    String? approvalId,
    String? roleId,
    String? actionId,
    String? module,
    String? reason,
    String? risk,
    String? requestedBy,
    Map<String, dynamic>? actionScope,
    String? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? decidedAt,
    DateTime? consumedAt,
    String? decidedBy,
    String? decisionNote,
  }) {
    return AgentApprovalRequest(
      approvalId: approvalId ?? this.approvalId,
      roleId: roleId ?? this.roleId,
      actionId: actionId ?? this.actionId,
      module: module ?? this.module,
      reason: reason ?? this.reason,
      risk: risk ?? this.risk,
      requestedBy: requestedBy ?? this.requestedBy,
      actionScope: actionScope ?? this.actionScope,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      decidedAt: decidedAt ?? this.decidedAt,
      consumedAt: consumedAt ?? this.consumedAt,
      decidedBy: decidedBy ?? this.decidedBy,
      decisionNote: decisionNote ?? this.decisionNote,
    );
  }

  void validate() {
    if (approvalId.trim().isEmpty) {
      throw const AgentApprovalValidationException(
        'approvalId cannot be empty.',
      );
    }
    if (roleId.trim().isEmpty) {
      throw const AgentApprovalValidationException(
        'roleId cannot be empty.',
      );
    }
    if (actionId.trim().isEmpty) {
      throw const AgentApprovalValidationException(
        'actionId cannot be empty.',
      );
    }
    if (module.trim().isEmpty) {
      throw const AgentApprovalValidationException(
        'module cannot be empty.',
      );
    }
    if (!AgentApprovalStatus.isValid(status)) {
      throw AgentApprovalValidationException(
        'Invalid approval status "$status".',
      );
    }
    if (!expiresAt.isAfter(createdAt)) {
      throw const AgentApprovalValidationException(
        'expiresAt must be after createdAt.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'approvalId': approvalId,
      'roleId': roleId,
      'actionId': actionId,
      'module': module,
      'reason': reason,
      'risk': risk,
      'requestedBy': requestedBy,
      'actionScope': actionScope,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'decidedAt': _toTimestamp(decidedAt),
      'consumedAt': _toTimestamp(consumedAt),
      'decidedBy': decidedBy,
      'decisionNote': decisionNote,
    };
  }

  factory AgentApprovalRequest.fromMap(Map<String, dynamic> map) {
    return AgentApprovalRequest(
      approvalId: _string(map['approvalId']),
      roleId: _string(map['roleId']),
      actionId: _string(map['actionId']),
      module: _string(map['module']),
      reason: _string(map['reason']),
      risk: _string(map['risk'], fallback: 'UNKNOWN'),
      requestedBy: _string(map['requestedBy']),
      actionScope: _map(map['actionScope']),
      status: _string(
        map['status'],
        fallback: AgentApprovalStatus.pending,
      ),
      createdAt: _date(map['createdAt']),
      expiresAt: _date(map['expiresAt']),
      decidedAt: _nullableDate(map['decidedAt']),
      consumedAt: _nullableDate(map['consumedAt']),
      decidedBy: _nullableString(map['decidedBy']),
      decisionNote: _nullableString(map['decisionNote']),
    );
  }

  factory AgentApprovalRequest.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(snapshot.data() ?? <String, dynamic>{});
    data['approvalId'] ??= snapshot.id;
    return AgentApprovalRequest.fromMap(data);
  }

  static String _string(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final String result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final String result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  static Map<String, dynamic> _map(dynamic value) {
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
    return _nullableDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _nullableDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static Timestamp? _toTimestamp(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value);
  }
}

class AgentApprovalValidationException implements Exception {
  final String message;

  const AgentApprovalValidationException(this.message);

  @override
  String toString() => 'AgentApprovalValidationException: $message';
}

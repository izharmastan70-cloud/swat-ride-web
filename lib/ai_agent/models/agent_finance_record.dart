import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_finance_constants.dart';

// =========================================================
// AI AGENT — FINANCE RECORD
// =========================================================
//
// Firestore collection: agent_finance_records
//
// Standalone AI-owned monitoring record only.
// No real SWAT RIDE wallet/payment/commission collection is connected yet.

class AgentFinanceRecord {
  final String recordId;
  final String type;
  final String module;
  final String referenceId;
  final int amountRs;
  final int commissionRs;
  final int netAmountRs;
  final String status;
  final String note;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AgentFinanceRecord({
    required this.recordId,
    required this.type,
    required this.module,
    required this.referenceId,
    required this.amountRs,
    required this.commissionRs,
    required this.netAmountRs,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  void validate() {
    if (recordId.trim().isEmpty) {
      throw const AgentFinanceValidationException(
        'recordId cannot be empty.',
      );
    }

    if (!AgentFinanceRecordType.isValid(type)) {
      throw AgentFinanceValidationException(
        'Invalid finance type "$type".',
      );
    }

    if (amountRs < 0 || commissionRs < 0 || netAmountRs < 0) {
      throw const AgentFinanceValidationException(
        'Finance amounts cannot be negative.',
      );
    }

    if (commissionRs > amountRs) {
      throw const AgentFinanceValidationException(
        'commissionRs cannot exceed amountRs.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'recordId': recordId,
      'type': type,
      'module': module,
      'referenceId': referenceId,
      'amountRs': amountRs,
      'commissionRs': commissionRs,
      'netAmountRs': netAmountRs,
      'status': status,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt':
          updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory AgentFinanceRecord.fromMap(Map<String, dynamic> map) {
    final AgentFinanceRecord record = AgentFinanceRecord(
      recordId: (map['recordId'] ?? '').toString(),
      type: (map['type'] ?? '').toString(),
      module: (map['module'] ?? '').toString(),
      referenceId: (map['referenceId'] ?? '').toString(),
      amountRs: _int(map['amountRs']),
      commissionRs: _int(map['commissionRs']),
      netAmountRs: _int(map['netAmountRs']),
      status: (map['status'] ?? AgentFinanceStatus.pending).toString(),
      note: (map['note'] ?? '').toString(),
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      updatedAt: _date(map['updatedAt']),
    );

    record.validate();
    return record;
  }

  factory AgentFinanceRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> map =
        Map<String, dynamic>.from(snapshot.data() ?? <String, dynamic>{});
    map['recordId'] ??= snapshot.id;
    return AgentFinanceRecord.fromMap(map);
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class AgentFinanceValidationException implements Exception {
  final String message;
  const AgentFinanceValidationException(this.message);

  @override
  String toString() => 'AgentFinanceValidationException: $message';
}

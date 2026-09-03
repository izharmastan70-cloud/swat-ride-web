import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_crash_constants.dart';

// =========================================================
// AI AGENT — CRASH EVENT
// =========================================================
//
// Firestore collection: agent_crash_events
//
// Stores sanitized technical crash/error metadata only.
// Raw secrets/tokens/credentials must never be persisted here.

class AgentCrashEvent {
  final String crashId;
  final String module;
  final String errorType;
  final String message;
  final String stackSummary;
  final String appVersion;
  final String platform;
  final String severity;
  final String category;
  final String status;
  final int occurrenceCount;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;

  const AgentCrashEvent({
    required this.crashId,
    required this.module,
    required this.errorType,
    required this.message,
    required this.stackSummary,
    required this.appVersion,
    required this.platform,
    required this.severity,
    required this.category,
    required this.status,
    required this.occurrenceCount,
    required this.firstSeenAt,
    required this.lastSeenAt,
  });

  void validate() {
    if (crashId.trim().isEmpty) {
      throw const AgentCrashValidationException(
        'crashId cannot be empty.',
      );
    }

    if (occurrenceCount < 1) {
      throw const AgentCrashValidationException(
        'occurrenceCount must be at least 1.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'crashId': crashId,
      'module': module,
      'errorType': errorType,
      'message': message,
      'stackSummary': stackSummary,
      'appVersion': appVersion,
      'platform': platform,
      'severity': severity,
      'category': category,
      'status': status,
      'occurrenceCount': occurrenceCount,
      'firstSeenAt': Timestamp.fromDate(firstSeenAt),
      'lastSeenAt': Timestamp.fromDate(lastSeenAt),
    };
  }

  factory AgentCrashEvent.fromMap(Map<String, dynamic> map) {
    final AgentCrashEvent event = AgentCrashEvent(
      crashId: (map['crashId'] ?? '').toString(),
      module: (map['module'] ?? '').toString(),
      errorType: (map['errorType'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      stackSummary: (map['stackSummary'] ?? '').toString(),
      appVersion: (map['appVersion'] ?? '').toString(),
      platform: (map['platform'] ?? '').toString(),
      severity:
          (map['severity'] ?? AgentCrashSeverity.warning).toString(),
      category:
          (map['category'] ?? AgentCrashCategory.unknown).toString(),
      status:
          (map['status'] ?? AgentCrashStatus.open).toString(),
      occurrenceCount: _int(map['occurrenceCount'], fallback: 1),
      firstSeenAt: _date(map['firstSeenAt']) ?? DateTime.now(),
      lastSeenAt: _date(map['lastSeenAt']) ?? DateTime.now(),
    );

    event.validate();
    return event;
  }

  factory AgentCrashEvent.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(snapshot.data() ?? <String, dynamic>{});
    data['crashId'] ??= snapshot.id;
    return AgentCrashEvent.fromMap(data);
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class AgentCrashValidationException implements Exception {
  final String message;

  const AgentCrashValidationException(this.message);

  @override
  String toString() => 'AgentCrashValidationException: $message';
}

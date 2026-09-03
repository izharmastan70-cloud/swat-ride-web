import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_provider_constants.dart';

// =========================================================
// AI AGENT — PROVIDER HEALTH
// =========================================================
//
// Firestore collection: ai_provider_status
// This is AI-owned operational metadata only.

class AgentProviderHealth {
  final String providerId;
  final String providerType;
  final String status;
  final int consecutiveFailures;
  final int requestsToday;
  final DateTime? lastSuccessAt;
  final DateTime? lastFailureAt;
  final String lastError;
  final DateTime updatedAt;

  const AgentProviderHealth({
    required this.providerId,
    required this.providerType,
    required this.status,
    required this.consecutiveFailures,
    required this.requestsToday,
    required this.lastSuccessAt,
    required this.lastFailureAt,
    required this.lastError,
    required this.updatedAt,
  });

  factory AgentProviderHealth.initial({
    required String providerId,
    required String providerType,
  }) {
    return AgentProviderHealth(
      providerId: providerId,
      providerType: providerType,
      status: AgentProviderStatus.unknown,
      consecutiveFailures: 0,
      requestsToday: 0,
      lastSuccessAt: null,
      lastFailureAt: null,
      lastError: '',
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'providerId': providerId,
      'providerType': providerType,
      'status': status,
      'consecutiveFailures': consecutiveFailures,
      'requestsToday': requestsToday,
      'lastSuccessAt': _ts(lastSuccessAt),
      'lastFailureAt': _ts(lastFailureAt),
      'lastError': lastError,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AgentProviderHealth.fromMap(Map<String, dynamic> map) {
    return AgentProviderHealth(
      providerId: (map['providerId'] ?? '').toString(),
      providerType: (map['providerType'] ?? '').toString(),
      status: AgentProviderStatus.isValid(
        (map['status'] ?? '').toString(),
      )
          ? (map['status'] ?? '').toString()
          : AgentProviderStatus.unknown,
      consecutiveFailures: _int(map['consecutiveFailures']),
      requestsToday: _int(map['requestsToday']),
      lastSuccessAt: _date(map['lastSuccessAt']),
      lastFailureAt: _date(map['lastFailureAt']),
      lastError: (map['lastError'] ?? '').toString(),
      updatedAt: _date(map['updatedAt']) ?? DateTime.now(),
    );
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

  static Timestamp? _ts(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value);
  }
}

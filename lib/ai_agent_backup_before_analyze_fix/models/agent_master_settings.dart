import 'package:cloud_firestore/cloud_firestore.dart';

// =========================================================
// AI AGENT — MASTER SETTINGS MODEL
// =========================================================
//
// Firestore document:
// agent_settings/master
//
// This is the standalone AI control plane.
// It does NOT switch SWAT RIDE business modules on/off yet.
// Existing app module connectors will be added later.

class AgentMasterSettings {
  static const String documentId = 'master';

  final bool masterEnabled;
  final bool emergencyReadOnly;
  final bool freeAiEnabled;
  final bool localAiEnabled;
  final bool paidCodeAiEnabled;
  final bool callAgentEnabled;
  final bool approvalEngineEnabled;
  final bool auditLoggingEnabled;
  final int monthlyPaidCodeBudgetRs;
  final int paidCodeBudgetUsedRs;
  final DateTime? emergencyActivatedAt;
  final String emergencyActivatedBy;
  final String emergencyReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AgentMasterSettings({
    required this.masterEnabled,
    required this.emergencyReadOnly,
    required this.freeAiEnabled,
    required this.localAiEnabled,
    required this.paidCodeAiEnabled,
    required this.callAgentEnabled,
    required this.approvalEngineEnabled,
    required this.auditLoggingEnabled,
    required this.monthlyPaidCodeBudgetRs,
    required this.paidCodeBudgetUsedRs,
    required this.emergencyActivatedAt,
    required this.emergencyActivatedBy,
    required this.emergencyReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AgentMasterSettings.safeDefaults() {
    final DateTime now = DateTime.now();

    return AgentMasterSettings(
      masterEnabled: false,
      emergencyReadOnly: true,
      freeAiEnabled: false,
      localAiEnabled: false,
      paidCodeAiEnabled: false,
      callAgentEnabled: false,
      approvalEngineEnabled: true,
      auditLoggingEnabled: true,
      monthlyPaidCodeBudgetRs: 0,
      paidCodeBudgetUsedRs: 0,
      emergencyActivatedAt: now,
      emergencyActivatedBy: 'system',
      emergencyReason: 'Safe defaults until owner explicitly enables AI.',
      createdAt: now,
      updatedAt: null,
    );
  }

  bool get paidBudgetAvailable =>
      monthlyPaidCodeBudgetRs > 0 &&
      paidCodeBudgetUsedRs < monthlyPaidCodeBudgetRs;

  bool get anyWriteAllowed =>
      masterEnabled && !emergencyReadOnly;

  bool get freeAiOperational =>
      masterEnabled && freeAiEnabled;

  bool get paidCodeAiOperational =>
      masterEnabled &&
      paidCodeAiEnabled &&
      paidBudgetAvailable;

  AgentMasterSettings copyWith({
    bool? masterEnabled,
    bool? emergencyReadOnly,
    bool? freeAiEnabled,
    bool? localAiEnabled,
    bool? paidCodeAiEnabled,
    bool? callAgentEnabled,
    bool? approvalEngineEnabled,
    bool? auditLoggingEnabled,
    int? monthlyPaidCodeBudgetRs,
    int? paidCodeBudgetUsedRs,
    DateTime? emergencyActivatedAt,
    bool clearEmergencyActivatedAt = false,
    String? emergencyActivatedBy,
    String? emergencyReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgentMasterSettings(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      emergencyReadOnly: emergencyReadOnly ?? this.emergencyReadOnly,
      freeAiEnabled: freeAiEnabled ?? this.freeAiEnabled,
      localAiEnabled: localAiEnabled ?? this.localAiEnabled,
      paidCodeAiEnabled: paidCodeAiEnabled ?? this.paidCodeAiEnabled,
      callAgentEnabled: callAgentEnabled ?? this.callAgentEnabled,
      approvalEngineEnabled:
          approvalEngineEnabled ?? this.approvalEngineEnabled,
      auditLoggingEnabled:
          auditLoggingEnabled ?? this.auditLoggingEnabled,
      monthlyPaidCodeBudgetRs:
          monthlyPaidCodeBudgetRs ?? this.monthlyPaidCodeBudgetRs,
      paidCodeBudgetUsedRs:
          paidCodeBudgetUsedRs ?? this.paidCodeBudgetUsedRs,
      emergencyActivatedAt: clearEmergencyActivatedAt
          ? null
          : (emergencyActivatedAt ?? this.emergencyActivatedAt),
      emergencyActivatedBy:
          emergencyActivatedBy ?? this.emergencyActivatedBy,
      emergencyReason: emergencyReason ?? this.emergencyReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  void validate() {
    if (monthlyPaidCodeBudgetRs < 0) {
      throw const AgentSettingsValidationException(
        'monthlyPaidCodeBudgetRs cannot be negative.',
      );
    }

    if (paidCodeBudgetUsedRs < 0) {
      throw const AgentSettingsValidationException(
        'paidCodeBudgetUsedRs cannot be negative.',
      );
    }

    if (paidCodeAiEnabled && monthlyPaidCodeBudgetRs <= 0) {
      throw const AgentSettingsValidationException(
        'Paid Code AI cannot be enabled without a positive monthly budget.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'masterEnabled': masterEnabled,
      'emergencyReadOnly': emergencyReadOnly,
      'freeAiEnabled': freeAiEnabled,
      'localAiEnabled': localAiEnabled,
      'paidCodeAiEnabled': paidCodeAiEnabled,
      'callAgentEnabled': callAgentEnabled,
      'approvalEngineEnabled': approvalEngineEnabled,
      'auditLoggingEnabled': auditLoggingEnabled,
      'monthlyPaidCodeBudgetRs': monthlyPaidCodeBudgetRs,
      'paidCodeBudgetUsedRs': paidCodeBudgetUsedRs,
      'emergencyActivatedAt': _timestamp(emergencyActivatedAt),
      'emergencyActivatedBy': emergencyActivatedBy,
      'emergencyReason': emergencyReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': _timestamp(updatedAt),
    };
  }

  factory AgentMasterSettings.fromMap(Map<String, dynamic> map) {
    final AgentMasterSettings settings = AgentMasterSettings(
      masterEnabled: _bool(map['masterEnabled']),
      emergencyReadOnly: _bool(
        map['emergencyReadOnly'],
        fallback: true,
      ),
      freeAiEnabled: _bool(map['freeAiEnabled']),
      localAiEnabled: _bool(map['localAiEnabled']),
      paidCodeAiEnabled: _bool(map['paidCodeAiEnabled']),
      callAgentEnabled: _bool(map['callAgentEnabled']),
      approvalEngineEnabled: _bool(
        map['approvalEngineEnabled'],
        fallback: true,
      ),
      auditLoggingEnabled: _bool(
        map['auditLoggingEnabled'],
        fallback: true,
      ),
      monthlyPaidCodeBudgetRs: _int(map['monthlyPaidCodeBudgetRs']),
      paidCodeBudgetUsedRs: _int(map['paidCodeBudgetUsedRs']),
      emergencyActivatedAt: _date(map['emergencyActivatedAt']),
      emergencyActivatedBy: _string(map['emergencyActivatedBy']),
      emergencyReason: _string(map['emergencyReason']),
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      updatedAt: _date(map['updatedAt']),
    );

    try {
      settings.validate();
      return settings;
    } on AgentSettingsValidationException {
      return AgentMasterSettings.safeDefaults();
    }
  }

  static String _string(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    final String normalized = value.toString().toLowerCase().trim();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    return fallback;
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static Timestamp? _timestamp(DateTime? value) {
    return value == null ? null : Timestamp.fromDate(value);
  }
}

class AgentSettingsValidationException implements Exception {
  final String message;

  const AgentSettingsValidationException(this.message);

  @override
  String toString() => 'AgentSettingsValidationException: $message';
}

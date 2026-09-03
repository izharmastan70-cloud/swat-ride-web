import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/agent_orchestrator_constants.dart';

// =========================================================
// AI AGENT — ORCHESTRATOR CONFIG
// =========================================================
//
// Firestore:
// agent_settings/orchestrator
//
// No API keys/secrets are stored here.
// endpointLabel is only a human-readable label in Phase 10.
// Real transport/security configuration comes later.

class AgentOrchestratorConfig {
  static const String documentId = 'orchestrator';

  final String orchestratorType;
  final bool enabled;
  final bool readOnlyOnly;
  final String endpointLabel;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AgentOrchestratorConfig({
    required this.orchestratorType,
    required this.enabled,
    required this.readOnlyOnly,
    required this.endpointLabel,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AgentOrchestratorConfig.safeDefaults() {
    return AgentOrchestratorConfig(
      orchestratorType: AgentOrchestratorType.openClaw,
      enabled: false,
      readOnlyOnly: true,
      endpointLabel: 'OpenClaw not connected',
      status: AgentOrchestratorStatus.disconnected,
      createdAt: DateTime.now(),
      updatedAt: null,
    );
  }

  void validate() {
    if (!AgentOrchestratorType.isValid(orchestratorType)) {
      throw AgentOrchestratorConfigException(
        'Invalid orchestratorType "$orchestratorType".',
      );
    }

    if (!AgentOrchestratorStatus.isValid(status)) {
      throw AgentOrchestratorConfigException(
        'Invalid orchestrator status "$status".',
      );
    }

    if (!readOnlyOnly) {
      throw const AgentOrchestratorConfigException(
        'Phase 10 OpenClaw foundation must remain read-only.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'orchestratorType': orchestratorType,
      'enabled': enabled,
      'readOnlyOnly': readOnlyOnly,
      'endpointLabel': endpointLabel,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt':
          updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory AgentOrchestratorConfig.fromMap(
    Map<String, dynamic> map,
  ) {
    final AgentOrchestratorConfig config = AgentOrchestratorConfig(
      orchestratorType:
          (map['orchestratorType'] ??
                  AgentOrchestratorType.openClaw)
              .toString(),
      enabled: _bool(map['enabled']),
      readOnlyOnly: _bool(
        map['readOnlyOnly'],
        fallback: true,
      ),
      endpointLabel: (map['endpointLabel'] ??
              'OpenClaw not connected')
          .toString(),
      status: AgentOrchestratorStatus.isValid(
        (map['status'] ?? '').toString(),
      )
          ? (map['status'] ?? '').toString()
          : AgentOrchestratorStatus.disconnected,
      createdAt: _date(map['createdAt']) ?? DateTime.now(),
      updatedAt: _date(map['updatedAt']),
    );

    try {
      config.validate();
      return config;
    } catch (_) {
      return AgentOrchestratorConfig.safeDefaults();
    }
  }

  static bool _bool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    final String normalized =
        value.toString().trim().toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
    return fallback;
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class AgentOrchestratorConfigException implements Exception {
  final String message;

  const AgentOrchestratorConfigException(this.message);

  @override
  String toString() => 'AgentOrchestratorConfigException: $message';
}

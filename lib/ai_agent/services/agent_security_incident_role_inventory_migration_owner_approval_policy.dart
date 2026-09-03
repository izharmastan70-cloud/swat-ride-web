import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/agent_security_incident_role_inventory_migration_owner_approval.dart';

class AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalDecision {
  const AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalDecision({
    required this.valid,
    required this.reasonCode,
    required this.bindingFingerprintSha256,
  });

  final bool valid;
  final String reasonCode;
  final String bindingFingerprintSha256;

  bool get writesFirestore => false;
  bool get createsCentralApproval => false;
  bool get consumesCentralApproval => false;
  bool get executesMigration => false;
  bool get createsRole => false;
  bool get mutatesGuard => false;
  bool get createsArmingToken => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}

class AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalPolicy {
  const AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalPolicy();

  AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalDecision evaluate({
    required AgentSecurityIncidentRoleInventoryMigrationOwnerApproval approval,
    required DateTime nowUtc,
  }) {
    try {
      approval.validate();
    } on FormatException {
      return _blocked(
        approval: approval,
        reasonCode: 'invalid_migration_owner_approval_contract',
      );
    }

    final DateTime now = nowUtc.toUtc();

    if (nowUtc != now || now.isBefore(approval.approvedAtUtc)) {
      return _blocked(
        approval: approval,
        reasonCode: 'invalid_approval_time_reference',
      );
    }

    if (!now.isBefore(approval.expiresAtUtc)) {
      return _blocked(
        approval: approval,
        reasonCode: 'migration_owner_approval_expired',
      );
    }

    return AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalDecision(
      valid: true,
      reasonCode: 'exact_fresh_owner_migration_approval_binding_valid',
      bindingFingerprintSha256: bindingFingerprintSha256(approval),
    );
  }

  String bindingFingerprintSha256(
    AgentSecurityIncidentRoleInventoryMigrationOwnerApproval approval,
  ) {
    approval.validate();

    final Map<String, Object> canonical = _canonicalMap(
      approval.toExactBindingMap(),
    );

    return sha256.convert(utf8.encode(jsonEncode(canonical))).toString();
  }

  AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalDecision _blocked({
    required AgentSecurityIncidentRoleInventoryMigrationOwnerApproval approval,
    required String reasonCode,
  }) {
    String fingerprint = '';

    try {
      fingerprint = bindingFingerprintSha256(approval);
    } on Object {
      fingerprint = '';
    }

    return AgentSecurityIncidentRoleInventoryMigrationOwnerApprovalDecision(
      valid: false,
      reasonCode: reasonCode,
      bindingFingerprintSha256: fingerprint,
    );
  }

  Map<String, Object> _canonicalMap(Map<String, Object> source) {
    final List<String> keys = source.keys.toList(growable: false)..sort();

    return <String, Object>{for (final String key in keys) key: source[key]!};
  }
}

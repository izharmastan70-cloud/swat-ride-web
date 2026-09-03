abstract final class AgentSecurityIncidentRoleInventoryTransactionStatus {
  static const String blockedInvalid = 'BLOCKED_INVALID';
  static const String blockedNotArmed = 'BLOCKED_NOT_ARMED';
  static const String blockedRulesNotVerified = 'BLOCKED_RULES_NOT_VERIFIED';
  static const String blockedPlan = 'BLOCKED_PLAN';
  static const String blockedMissingAuthorityManifest =
      'BLOCKED_MISSING_AUTHORITY_MANIFEST';
  static const String blockedAuthorityManifestMismatch =
      'BLOCKED_AUTHORITY_MANIFEST_MISMATCH';
  static const String blockedMigrationHold = 'BLOCKED_MIGRATION_HOLD';
  static const String blockedCurrentState = 'BLOCKED_CURRENT_STATE';
  static const String blockedRoleInventory = 'BLOCKED_ROLE_INVENTORY';
  static const String blockedRoleExists = 'BLOCKED_ROLE_EXISTS';
  static const String blockedProposedRole = 'BLOCKED_PROPOSED_ROLE';
  static const String blockedFingerprint = 'BLOCKED_FINGERPRINT';
  static const String committedRoleDelta = 'COMMITTED_ROLE_DELTA';
}

class AgentSecurityIncidentRoleInventoryTransactionResult {
  const AgentSecurityIncidentRoleInventoryTransactionResult({
    required this.status,
    required this.reasonCode,
    required this.roleCreated,
    required this.authorityManifestUpdated,
    required this.migrationHoldUpdated,
  });

  final String status;
  final String reasonCode;
  final bool roleCreated;
  final bool authorityManifestUpdated;
  final bool migrationHoldUpdated;

  bool get committed =>
      status ==
          AgentSecurityIncidentRoleInventoryTransactionStatus
              .committedRoleDelta &&
      roleCreated &&
      authorityManifestUpdated &&
      migrationHoldUpdated;

  bool get oldGuardMutated => false;
  bool get oldArmingTokenMutated => false;
  bool get oldActivationReceiptMutated => false;
  bool get approvalConsumed => false;
  bool get repositoryAttached => false;
  bool get repositoryArmed => false;
  bool get incidentWritten => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}

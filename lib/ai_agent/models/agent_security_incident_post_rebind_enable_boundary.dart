abstract final class AgentSecurityIncidentPostRebindEnableBoundaryStatus {
  static const String blockedInvalid = 'BLOCKED_INVALID';
  static const String blockedRoleInventory = 'BLOCKED_ROLE_INVENTORY';
  static const String blockedRoleAuthority = 'BLOCKED_ROLE_AUTHORITY';
  static const String blockedRebindEvidence = 'BLOCKED_REBIND_EVIDENCE';
  static const String blockedMigrationHold = 'BLOCKED_MIGRATION_HOLD';
  static const String blockedSecurityRebind = 'BLOCKED_SECURITY_REBIND';
  static const String blockedOwnerIdentity = 'BLOCKED_OWNER_IDENTITY';
  static const String blockedOwnerApproval = 'BLOCKED_OWNER_APPROVAL';
  static const String blockedRuntimeState = 'BLOCKED_RUNTIME_STATE';
  static const String eligible =
      'POST_REBIND_ENABLE_IMPLEMENTATION_ELIGIBLE_NOT_EXECUTED';
}

class AgentSecurityIncidentPostRebindEnableEvidence {
  const AgentSecurityIncidentPostRebindEnableEvidence({
    required this.postMigrationRoleCount,
    required this.roleId,
    required this.module,
    required this.roleEnabled,
    required this.exactDisabledRolePayloadVerified,
    required this.postMigrationSnapshotVerified,
    required this.authorityManifestRebound,
    required this.migrationReceiptVerified,
    required this.migrationHoldPresent,
    required this.productionGuardReboundToPostMigrationInventory,
    required this.freshArmingTokenIssuedAfterRebind,
    required this.oldArmingTokenReused,
    required this.freshOwnerIdentityVerified,
    required this.freshOwnerApprovalPresent,
    required this.ownerApprovalSeparateFromMigrationApproval,
    required this.ownerApprovalExactBindingVerified,
    required this.repositoryRuntimeAttached,
    required this.repositoryExecutionArmed,
    required this.incidentWritePerformed,
  });

  final int postMigrationRoleCount;
  final String roleId;
  final String module;
  final bool roleEnabled;
  final bool exactDisabledRolePayloadVerified;
  final bool postMigrationSnapshotVerified;
  final bool authorityManifestRebound;
  final bool migrationReceiptVerified;
  final bool migrationHoldPresent;
  final bool productionGuardReboundToPostMigrationInventory;
  final bool freshArmingTokenIssuedAfterRebind;
  final bool oldArmingTokenReused;
  final bool freshOwnerIdentityVerified;
  final bool freshOwnerApprovalPresent;
  final bool ownerApprovalSeparateFromMigrationApproval;
  final bool ownerApprovalExactBindingVerified;
  final bool repositoryRuntimeAttached;
  final bool repositoryExecutionArmed;
  final bool incidentWritePerformed;

  void validate() {
    if (postMigrationRoleCount < 0 ||
        roleId.trim().isEmpty ||
        module.trim().isEmpty) {
      throw const FormatException('Invalid post-rebind enable evidence.');
    }
  }
}

class AgentSecurityIncidentPostRebindEnableDecision {
  const AgentSecurityIncidentPostRebindEnableDecision({
    required this.status,
    required this.reasonCode,
    required this.eligibleForSeparateEnableImplementation,
  });

  final String status;
  final String reasonCode;
  final bool eligibleForSeparateEnableImplementation;

  bool get roleEnablePerformed => false;
  bool get migrationHoldReleased => false;
  bool get writesFirestore => false;
  bool get readsLiveFirestore => false;
  bool get consumesApproval => false;
  bool get createsApproval => false;
  bool get grantsPermission => false;
  bool get changesFirestoreRules => false;
  bool get deploysFirestoreRules => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get changesEmergencyStop => false;
  bool get repositoryAttached => false;
  bool get repositoryArmed => false;
  bool get incidentWritten => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}

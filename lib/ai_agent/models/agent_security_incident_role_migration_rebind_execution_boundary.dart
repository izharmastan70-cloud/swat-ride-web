abstract final class AgentSecurityIncidentRoleMigrationRebindStatus {
  static const String blockedInvalid = 'BLOCKED_INVALID';
  static const String blockedCurrentInventory = 'BLOCKED_CURRENT_INVENTORY';
  static const String blockedRolePayload = 'BLOCKED_ROLE_PAYLOAD';
  static const String blockedMigrationAuthority = 'BLOCKED_MIGRATION_AUTHORITY';
  static const String blockedOwnerMigrationApproval =
      'BLOCKED_OWNER_MIGRATION_APPROVAL';
  static const String blockedAtomicMigration = 'BLOCKED_ATOMIC_MIGRATION';
  static const String blockedPostMigrationPlan = 'BLOCKED_POST_MIGRATION_PLAN';
  static const String blockedEnableSeparation = 'BLOCKED_ENABLE_SEPARATION';
  static const String eligible =
      'ELIGIBLE_FOR_SEPARATE_MIGRATION_EXECUTION_IMPLEMENTATION';
}

class AgentSecurityIncidentRoleMigrationRebindEvidence {
  const AgentSecurityIncidentRoleMigrationRebindEvidence({
    required this.currentRoleCount,
    required this.targetRoleCount,
    required this.roleId,
    required this.module,
    required this.roleEnabledAtMigrationCommit,
    required this.exactTSPayloadVerified,
    required this.dedicatedMigrationRepositoryReady,
    required this.migrationRulesManifestCouplingVerified,
    required this.trustedBackendExecutionEnvironmentReady,
    required this.freshOwnerIdentityVerified,
    required this.freshOwnerMigrationApprovalPresent,
    required this.ownerMigrationApprovalExactBindingVerified,
    required this.roleCreateSameTransactionRequired,
    required this.authorityManifestUpdateSameTransactionRequired,
    required this.migrationHoldSameTransactionRequired,
    required this.migrationAuditSameTransactionRequired,
    required this.postMigrationSnapshotRequired,
    required this.postMigrationAuthorityManifestRebindRequired,
    required this.postMigrationGuardRebindRequired,
    required this.postMigrationFreshArmingTokenRequired,
    required this.postMigrationMigrationReceiptRequired,
    required this.separatePostRebindEnableApprovalRequired,
    required this.roleEnableIncludedInMigrationTransaction,
    required this.oldArmingTokenReuseAllowed,
    required this.repositoryRuntimeAttached,
    required this.repositoryExecutionArmed,
    required this.incidentWritePerformed,
  });

  final int currentRoleCount;
  final int targetRoleCount;
  final String roleId;
  final String module;
  final bool roleEnabledAtMigrationCommit;
  final bool exactTSPayloadVerified;

  final bool dedicatedMigrationRepositoryReady;
  final bool migrationRulesManifestCouplingVerified;
  final bool trustedBackendExecutionEnvironmentReady;

  final bool freshOwnerIdentityVerified;
  final bool freshOwnerMigrationApprovalPresent;
  final bool ownerMigrationApprovalExactBindingVerified;

  final bool roleCreateSameTransactionRequired;
  final bool authorityManifestUpdateSameTransactionRequired;
  final bool migrationHoldSameTransactionRequired;
  final bool migrationAuditSameTransactionRequired;

  final bool postMigrationSnapshotRequired;
  final bool postMigrationAuthorityManifestRebindRequired;
  final bool postMigrationGuardRebindRequired;
  final bool postMigrationFreshArmingTokenRequired;
  final bool postMigrationMigrationReceiptRequired;

  final bool separatePostRebindEnableApprovalRequired;
  final bool roleEnableIncludedInMigrationTransaction;
  final bool oldArmingTokenReuseAllowed;

  final bool repositoryRuntimeAttached;
  final bool repositoryExecutionArmed;
  final bool incidentWritePerformed;

  void validate() {
    if (currentRoleCount < 0 ||
        targetRoleCount < 0 ||
        roleId.trim().isEmpty ||
        module.trim().isEmpty) {
      throw const FormatException(
        'Invalid security incident role migration/rebind evidence.',
      );
    }
  }
}

class AgentSecurityIncidentRoleMigrationRebindDecision {
  const AgentSecurityIncidentRoleMigrationRebindDecision({
    required this.status,
    required this.reasonCode,
    required this.eligibleForSeparateMigrationExecutionImplementation,
  });

  final String status;
  final String reasonCode;
  final bool eligibleForSeparateMigrationExecutionImplementation;

  bool get liveMigrationPerformed => false;
  bool get roleCreated => false;
  bool get roleEnabled => false;
  bool get migrationHoldReleased => false;
  bool get writesFirestore => false;
  bool get readsLiveFirestore => false;
  bool get createsApproval => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get mutatesGuard => false;
  bool get mutatesArmingToken => false;
  bool get repositoryAttached => false;
  bool get repositoryArmed => false;
  bool get incidentWritten => false;
  bool get changesFirestoreRules => false;
  bool get deploysFirestoreRules => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get changesEmergencyStop => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}

abstract final class AgentSecurityIncidentPostMigrationRebindStatus {
  static const String blockedInvalid = 'BLOCKED_INVALID';
  static const String blockedSnapshot = 'BLOCKED_POST_MIGRATION_SNAPSHOT';
  static const String blockedRoleAuthority = 'BLOCKED_ROLE_AUTHORITY';
  static const String blockedManifest = 'BLOCKED_AUTHORITY_MANIFEST';
  static const String blockedMigrationHold = 'BLOCKED_MIGRATION_HOLD';
  static const String blockedHistoricalEvidence = 'BLOCKED_HISTORICAL_EVIDENCE';
  static const String blockedCurrentGuard = 'BLOCKED_CURRENT_GUARD';
  static const String blockedOwner = 'BLOCKED_OWNER_REBIND_AUTHORITY';
  static const String blockedSafety = 'BLOCKED_SAFETY_BOUNDARY';
  static const String eligible =
      'ELIGIBLE_FOR_DEDICATED_TRUSTED_POST_MIGRATION_REBIND_IMPLEMENTATION';
}

class AgentSecurityIncidentPostMigrationRebindEvidence {
  const AgentSecurityIncidentPostMigrationRebindEvidence({
    required this.postMigrationSnapshotSha256,
    required this.roleInventoryFingerprintSha256,
    required this.roleCount,
    required this.targetRoleExists,
    required this.targetRoleEnabled,
    required this.targetRoleMode,
    required this.authorityManifestRevision,
    required this.authorityManifestRoleCount,
    required this.authorityManifestFingerprintSha256,
    required this.postMigrationRebindRequired,
    required this.migrationHoldStatus,
    required this.migrationHoldActive,
    required this.currentGuardRevision,
    required this.currentGuardRoleCount,
    required this.currentRolloutStage,
    required this.currentAutoTrafficPercent,
    required this.currentBusinessWriteTrafficPercent,
    required this.externalChannelsEnabled,
    required this.oldArmingTokenConsumed,
    required this.oldActivationReceiptApplied,
    required this.oldArmingTokenReuseRequested,
    required this.freshOwnerIdentityVerified,
    required this.freshRebindOwnerApprovalPresent,
    required this.rebindApprovalSeparateFromMigrationApproval,
    required this.rebindApprovalExactSnapshotBindingVerified,
    required this.securityBypassDetected,
    required this.duplicateAlternateAuthorityDetected,
    required this.repositoryRuntimeAttached,
    required this.repositoryExecutionArmed,
    required this.incidentWritePerformed,
  });

  final String postMigrationSnapshotSha256;
  final String roleInventoryFingerprintSha256;
  final int roleCount;

  final bool targetRoleExists;
  final bool targetRoleEnabled;
  final String targetRoleMode;

  final int authorityManifestRevision;
  final int authorityManifestRoleCount;
  final String authorityManifestFingerprintSha256;
  final bool postMigrationRebindRequired;

  final String migrationHoldStatus;
  final bool migrationHoldActive;

  final int currentGuardRevision;
  final int currentGuardRoleCount;

  final String currentRolloutStage;
  final int currentAutoTrafficPercent;
  final int currentBusinessWriteTrafficPercent;
  final bool externalChannelsEnabled;

  final bool oldArmingTokenConsumed;
  final bool oldActivationReceiptApplied;
  final bool oldArmingTokenReuseRequested;

  final bool freshOwnerIdentityVerified;
  final bool freshRebindOwnerApprovalPresent;
  final bool rebindApprovalSeparateFromMigrationApproval;
  final bool rebindApprovalExactSnapshotBindingVerified;

  final bool securityBypassDetected;
  final bool duplicateAlternateAuthorityDetected;

  final bool repositoryRuntimeAttached;
  final bool repositoryExecutionArmed;
  final bool incidentWritePerformed;
}

class AgentSecurityIncidentPostMigrationRebindPlan {
  const AgentSecurityIncidentPostMigrationRebindPlan({
    required this.targetGuardRevision,
    required this.targetRoleCount,
    required this.targetRolloutStage,
    required this.updateAuthorityManifest,
    required this.persistFreshGuard,
    required this.issueFreshOneTimeArmingToken,
    required this.createFreshRebindReceipt,
    required this.appendAuditInSameTrustedBoundary,
    required this.keepMigrationHoldActive,
    required this.enableSecurityIncidentRole,
    required this.releaseMigrationHold,
    required this.reuseOldArmingToken,
    required this.persistRawArmingToken,
    required this.attachRepositoryRuntime,
    required this.armRepositoryExecution,
    required this.writeIncident,
    required this.authorizeSuggestOnly,
    required this.authorizeAuto,
  });

  final int targetGuardRevision;
  final int targetRoleCount;
  final String targetRolloutStage;

  final bool updateAuthorityManifest;
  final bool persistFreshGuard;
  final bool issueFreshOneTimeArmingToken;
  final bool createFreshRebindReceipt;
  final bool appendAuditInSameTrustedBoundary;

  final bool keepMigrationHoldActive;
  final bool enableSecurityIncidentRole;
  final bool releaseMigrationHold;

  final bool reuseOldArmingToken;
  final bool persistRawArmingToken;

  final bool attachRepositoryRuntime;
  final bool armRepositoryExecution;
  final bool writeIncident;

  final bool authorizeSuggestOnly;
  final bool authorizeAuto;

  int get plannedAuthorityWriteSurfaces => 6;
}

class AgentSecurityIncidentPostMigrationRebindDecision {
  const AgentSecurityIncidentPostMigrationRebindDecision({
    required this.status,
    required this.reasonCode,
    required this.eligibleForDedicatedTrustedImplementation,
    required this.plan,
  });

  final String status;
  final String reasonCode;
  final bool eligibleForDedicatedTrustedImplementation;
  final AgentSecurityIncidentPostMigrationRebindPlan? plan;

  bool get performsLiveRebind => false;
  bool get writesFirestore => false;
  bool get changesRoleEnabledState => false;
  bool get releasesMigrationHold => false;
  bool get issuesArmingToken => false;
  bool get createsRebindReceipt => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}

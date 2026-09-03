class AgentSecurityIncidentRoleInventoryMigrationPlan {
  const AgentSecurityIncidentRoleInventoryMigrationPlan({
    required this.currentInventoryVersion,
    required this.proposedInventoryVersion,
    required this.currentRoleCount,
    required this.proposedRoleCount,
    required this.currentInventoryFingerprintSha256,
    required this.proposedInventoryFingerprintSha256,
    required this.currentControlFingerprintSha256,
    required this.freshOwnerVerified,
    required this.ownerApprovalBindingSha256,
    required this.currentRolloutStage,
    required this.dedicatedRoleId,
    required this.dedicatedModule,
    required this.dedicatedActionId,
    required this.currentGuardRevision,
    required this.proposedGuardRevision,
    required this.oldGuardImmutable,
    required this.oldArmingTokenImmutable,
    required this.oldActivationReceiptImmutable,
    required this.existingArmingTokenReuseAllowed,
    required this.migrationHoldRequired,
    required this.migrationHoldActive,
    required this.newLiveSnapshotRequired,
    required this.newGuardRequired,
    required this.newOneTimeTokenRequired,
    required this.newMigrationReceiptRequired,
    required this.firstIncidentWriteAuthorized,
    required this.repositoryAttachAuthorized,
    required this.repositoryArmAuthorized,
    required this.authorizesSuggestOnly,
    required this.authorizesAuto,
  });

  final String currentInventoryVersion;
  final String proposedInventoryVersion;

  final int currentRoleCount;
  final int proposedRoleCount;

  /// Hashes only. Raw snapshots/claims/tokens are not stored in this plan.
  final String currentInventoryFingerprintSha256;
  final String proposedInventoryFingerprintSha256;
  final String currentControlFingerprintSha256;

  final bool freshOwnerVerified;

  /// Exact Owner approval binding hash for old inventory + proposed inventory
  /// + role delta. Never a raw token or session secret.
  final String ownerApprovalBindingSha256;

  final String currentRolloutStage;

  final String dedicatedRoleId;
  final String dedicatedModule;
  final String dedicatedActionId;

  final int currentGuardRevision;
  final int proposedGuardRevision;

  final bool oldGuardImmutable;
  final bool oldArmingTokenImmutable;
  final bool oldActivationReceiptImmutable;
  final bool existingArmingTokenReuseAllowed;

  /// Because T-J proved no atomic role+bound-evidence migration executor exists,
  /// a future live implementation must hold runtime fail-closed while the role
  /// inventory is between old and newly rebound evidence.
  final bool migrationHoldRequired;
  final bool migrationHoldActive;

  final bool newLiveSnapshotRequired;
  final bool newGuardRequired;
  final bool newOneTimeTokenRequired;
  final bool newMigrationReceiptRequired;

  final bool firstIncidentWriteAuthorized;
  final bool repositoryAttachAuthorized;
  final bool repositoryArmAuthorized;

  final bool authorizesSuggestOnly;
  final bool authorizesAuto;

  bool get containsRawAuthToken => false;
  bool get containsRawArmingToken => false;
  bool get containsRawOwnerUid => false;
}

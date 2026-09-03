abstract final class AgentSecurityIncidentPostMigrationRebindAtomicWriteSchema {
  static const String operation =
      'REBIND_SECURITY_INCIDENT_POST_MIGRATION_AUTHORITY_23_ROLE';

  static const int expectedCurrentAuthorityManifestRevision = 2;
  static const int targetAuthorityManifestRevision = 3;

  static const int expectedCurrentGuardRevision = 2;
  static const int targetGuardRevision = 3;

  static const int roleCount = 23;
  static const String rolloutStage = 'MONITOR_ONLY';

  static const String targetRoleId = 'security_incident_agent';

  static const String receiptCollection =
      'agent_security_incident_post_migration_rebind_receipts';

  static const List<String> orderedWriteSurfaces = <String>[
    'WRITE_1_CONSUME_EXACT_REBIND_OWNER_APPROVAL',
    'WRITE_2_REBIND_AUTHORITY_MANIFEST_REVISION_3',
    'WRITE_3_PERSIST_PRODUCTION_GUARD_REVISION_3_ROLECOUNT_23',
    'WRITE_4_CREATE_FRESH_ONE_TIME_ARMING_TOKEN_READY',
    'WRITE_5_CREATE_POST_MIGRATION_REBIND_RECEIPT',
    'WRITE_6_APPEND_AUDIT_IN_SAME_TRANSACTION',
  ];

  static const int exactWriteSurfaceCount = 6;

  static const bool singleTrustedBackendTransactionRequired = true;
  static const bool allReadsBeforeFirstWriteRequired = true;
  static const bool approvalConsumptionInSameTransactionRequired = true;
  static const bool auditInSameTransactionRequired = true;

  static const bool authorityManifestUpdateRequired = true;
  static const bool authorityManifestRevisionMustIncrementByOne = true;
  static const bool authorityManifestRoleCountMustRemain23 = true;
  static const bool authorityManifestRoleFingerprintMustRemainExact = true;
  static const bool authorityManifestRebindFlagClearedOnlyInTransaction = true;

  static const bool guardRevision2To3Required = true;
  static const bool guardRoleCount23Required = true;
  static const bool guardMonitorOnlyRequired = true;
  static const bool guardAutoTrafficMustRemainZero = true;
  static const bool guardBusinessWriteTrafficMustRemainZero = true;
  static const bool guardExternalChannelsMustRemainOff = true;

  static const bool freshTokenCreateOnlyRequired = true;
  static const bool freshTokenStartsReady = true;
  static const bool freshTokenStartsUnconsumed = true;
  static const bool rawTokenPersistenceAllowed = false;
  static const bool oldTokenReuseAllowed = false;

  static const bool rebindReceiptCreateOnlyRequired = true;
  static const bool rebindReceiptMustBindSnapshot = true;
  static const bool rebindReceiptMustBindRoleInventory = true;
  static const bool rebindReceiptMustBindManifestRevision3 = true;
  static const bool rebindReceiptMustBindGuardRevision3 = true;
  static const bool rebindReceiptMustBindFreshTokenSha = true;
  static const bool rebindReceiptMustBindOwnerApproval = true;

  // The migration hold is deliberately NOT released by the rebind transaction.
  // The role is deliberately NOT enabled by the rebind transaction. Those two
  // writes belong to a later, separate Owner-bound atomic enable step.
  static const bool writesMigrationHold = false;
  static const bool releasesMigrationHold = false;
  static const bool writesSecurityIncidentRole = false;
  static const bool enablesSecurityIncidentRole = false;

  static const bool writesRolloutStage = false;
  static const bool changesRolloutStage = false;

  static const bool attachesRepositoryRuntime = false;
  static const bool armsRepositoryExecution = false;
  static const bool writesIncident = false;

  static const bool securityBypassAllowed = false;
  static const bool duplicateAlternateAuthorityAllowed = false;

  static const bool authorizesSuggestOnly = false;
  static const bool authorizesAuto = false;
}

class AgentSecurityIncidentPostMigrationRebindReceiptSchema {
  const AgentSecurityIncidentPostMigrationRebindReceiptSchema({
    required this.receiptIdSha256,
    required this.ownerApprovalId,
    required this.postMigrationSnapshotSha256,
    required this.roleInventoryFingerprintSha256,
    required this.roleCount,
    required this.authorityManifestRevision,
    required this.guardRevision,
    required this.freshArmingTokenIdSha256,
    required this.rolloutStage,
    required this.migrationHoldStillActive,
    required this.securityIncidentRoleStillDisabled,
    required this.repositoryAttachAuthorized,
    required this.repositoryArmAuthorized,
    required this.firstIncidentWriteAuthorized,
    required this.authorizesSuggestOnly,
    required this.authorizesAuto,
  });

  final String receiptIdSha256;
  final String ownerApprovalId;
  final String postMigrationSnapshotSha256;
  final String roleInventoryFingerprintSha256;
  final int roleCount;
  final int authorityManifestRevision;
  final int guardRevision;
  final String freshArmingTokenIdSha256;
  final String rolloutStage;

  final bool migrationHoldStillActive;
  final bool securityIncidentRoleStillDisabled;

  final bool repositoryAttachAuthorized;
  final bool repositoryArmAuthorized;
  final bool firstIncidentWriteAuthorized;
  final bool authorizesSuggestOnly;
  final bool authorizesAuto;

  bool get failClosed =>
      migrationHoldStillActive &&
      securityIncidentRoleStillDisabled &&
      !repositoryAttachAuthorized &&
      !repositoryArmAuthorized &&
      !firstIncidentWriteAuthorized &&
      !authorizesSuggestOnly &&
      !authorizesAuto;
}

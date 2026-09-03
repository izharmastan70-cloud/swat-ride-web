
export const POST_MIGRATION_REBIND_CONTRACT = Object.freeze({
  operation: 'REBIND_SECURITY_INCIDENT_POST_MIGRATION_AUTHORITY_23_ROLE',
  migrationOperation: 'MIGRATE_SECURITY_INCIDENT_ROLE_INVENTORY_22_TO_23',
  targetRoleId: 'security_incident_agent',
  targetModule: 'security_incident',
  targetActionId: 'security_incident.attach_runtime',
  rolloutStage: 'MONITOR_ONLY',
  guardVersion: 'MONITOR_ONLY_GUARD_V1',
  inventoryVersion: 'phase66_roles_v2_23_security_incident',
  lockedPostMigrationSnapshotSha256:
    '01ac8f1fc48b9d95a3ca1179ab550fe7c7a630b9605ff937b2feedd10a6c1888',
  lockedRoleInventoryFingerprintSha256:
    'd16c6ff23b0d56a9e3b76146eefe22832d86196dee48bb05d6bc0129f48e2f2a',
  currentAuthorityManifestRevision: 2,
  targetAuthorityManifestRevision: 3,
  currentGuardRevision: 2,
  targetGuardRevision: 3,
  currentGuardRoleCount: 22,
  targetRoleCount: 23,
  maxApprovalValidityMs: 15 * 60 * 1000,
  minimumApprovalRemainingMs: 60 * 1000,
  maxFreshTokenValidityMs: 90 * 1000,
  receiptCollection: 'agent_security_incident_post_migration_rebind_receipts',
});

export const POST_MIGRATION_REBIND_WRITE_ORDER = Object.freeze([
  'WRITE_1_CONSUME_EXACT_REBIND_OWNER_APPROVAL',
  'WRITE_2_REBIND_AUTHORITY_MANIFEST_REVISION_3',
  'WRITE_3_PERSIST_PRODUCTION_GUARD_REVISION_3_ROLECOUNT_23',
  'WRITE_4_CREATE_FRESH_ONE_TIME_ARMING_TOKEN_READY',
  'WRITE_5_CREATE_POST_MIGRATION_REBIND_RECEIPT',
  'WRITE_6_APPEND_AUDIT_IN_SAME_TRANSACTION',
]);

export const POST_MIGRATION_REBIND_DEFAULTS = Object.freeze({
  executionArmed: false,
  trustedCallerIntegrated: false,
  liveFirestoreInitializationAllowed: false,
  roleEnableAuthorized: false,
  migrationHoldReleaseAuthorized: false,
  repositoryAttachAuthorized: false,
  repositoryArmAuthorized: false,
  firstIncidentWriteAuthorized: false,
  securityBypassAllowed: false,
  duplicateAlternateAuthorityAllowed: false,
  suggestOnlyAuthorized: false,
  autoAuthorized: false,
});
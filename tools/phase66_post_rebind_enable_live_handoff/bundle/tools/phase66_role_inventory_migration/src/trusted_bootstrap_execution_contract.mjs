import {
  AUTHORITY_MANIFEST_DOCUMENT,
  CURRENT_INVENTORY_VERSION,
  CURRENT_ROLE_COUNT,
  LOCKED_ROLLOUT_STAGE,
  MIGRATION_HOLD_DOCUMENT,
  PHASE66_PROJECT_ID,
  PROPOSED_INVENTORY_VERSION,
  PROPOSED_ROLE_COUNT,
  SECURITY_INCIDENT_ACTION_ID,
  SECURITY_INCIDENT_ROLE_ID,
} from './contract.mjs';

export const AGENT_SETTINGS_COLLECTION = 'agent_settings';
export const AGENT_ROLES_COLLECTION = 'agent_roles';
export const AGENT_APPROVALS_COLLECTION = 'agent_approvals';
export const AGENT_AUDIT_COLLECTION = 'agent_audit_logs';

export const BOOTSTRAP_MANIFEST_REVISION = 1;
export const BOOTSTRAP_MANIFEST_STATUS = 'ACTIVE';
export const BOOTSTRAP_HOLD_STATUS = 'HELD';

export const BOOTSTRAP_AUDIT_ACTION_ID =
  'ai.production_rollout.role_inventory.bootstrap_22_to_23';

export const BOOTSTRAP_AUDIT_RESULT = 'MIGRATION_HOLD_HELD';

export const AUTHORITY_MANIFEST_REQUIRED_FIELDS = Object.freeze([
  'status',
  'inventoryVersion',
  'roleCount',
  'roleProjectionFingerprintSha256',
  'revision',
  'postMigrationRebindRequired',
  'updatedAt',
]);

export const MIGRATION_HOLD_REQUIRED_FIELDS = Object.freeze([
  'status',
  'migrationIdSha256',
  'ownerApprovalId',
  'ownerApprovalBindingSha256',
  'currentInventoryFingerprintSha256',
  'proposedInventoryFingerprintSha256',
  'currentControlFingerprintSha256',
  'expectedRoleIds',
  'expectedRoleCount',
  'proposedRoleCount',
  'expectedGuardRevision',
  'targetRoleId',
  'targetActionId',
  'migrationHoldActive',
  'repositoryAttachAuthorized',
  'repositoryArmAuthorized',
  'firstIncidentWriteAuthorized',
  'authorizesSuggestOnly',
  'authorizesAuto',
  'updatedAt',
]);

export const TRUSTED_BOOTSTRAP_SAFETY = Object.freeze({
  executionArmed: false,
  dryRunOnly: true,
  adminSdkInitializationEnabled: false,
  credentialLoadingEnabled: false,
  networkReadEnabled: false,
  networkWriteEnabled: false,
  firestoreTransactionEnabled: false,
  approvalCreateEnabled: false,
  approvalDecisionEnabled: false,
  approvalConsumptionEnabled: false,
  manifestBootstrapEnabled: false,
  migrationHoldBootstrapEnabled: false,
  auditWriteEnabled: false,
  roleDeltaEnabled: false,
  roleEnableEnabled: false,
  guardMutationEnabled: false,
  tokenMutationEnabled: false,
  receiptMutationEnabled: false,
  repositoryAttachEnabled: false,
  repositoryArmEnabled: false,
  incidentWriteEnabled: false,
  suggestOnlyAuthorized: false,
  autoAuthorized: false,
});

function fail(code) {
  throw new Error(code);
}

function normalizeSha(value, name) {
  const normalized = String(value ?? '').trim().toLowerCase();

  if (!/^[0-9a-f]{64}$/.test(normalized)) {
    fail(`${name}_must_be_sha256`);
  }

  return normalized;
}

function requireBooleanTrue(value, name) {
  if (value !== true) {
    fail(`${name}_must_be_true`);
  }
}

function requireBooleanFalse(value, name) {
  if (value !== false) {
    fail(`${name}_must_be_false`);
  }
}

function normalizeRoleIds(value) {
  if (!Array.isArray(value)) {
    fail('exact_current_role_ids_required');
  }

  const roleIds = value
    .map((item) => String(item ?? '').trim())
    .sort((a, b) => a.localeCompare(b));

  if (
    roleIds.length !== CURRENT_ROLE_COUNT ||
    new Set(roleIds).size !== CURRENT_ROLE_COUNT ||
    roleIds.some((item) => item.length === 0) ||
    roleIds.includes(SECURITY_INCIDENT_ROLE_ID)
  ) {
    fail('exact_current_22_role_ids_invalid');
  }

  return roleIds;
}

export function assertTrustedBootstrapContractDisarmed() {
  for (const [name, enabled] of Object.entries(TRUSTED_BOOTSTRAP_SAFETY)) {
    if (name === 'dryRunOnly') {
      if (enabled !== true) {
        fail('trusted_bootstrap_dry_run_must_remain_true');
      }
      continue;
    }

    if (
      name.endsWith('Enabled') ||
      name.endsWith('Authorized') ||
      name === 'executionArmed'
    ) {
      if (enabled !== false) {
        fail(`trusted_bootstrap_safety_flag_must_be_false:${name}`);
      }
    }
  }

  return true;
}

export function buildTrustedBootstrapPlan(evidence) {
  assertTrustedBootstrapContractDisarmed();

  if (String(evidence?.projectId ?? '').trim() !== PHASE66_PROJECT_ID) {
    fail('project_binding_mismatch');
  }

  if (String(evidence?.rolloutStage ?? '').trim() !== LOCKED_ROLLOUT_STAGE) {
    fail('rollout_must_remain_monitor_only');
  }

  if (Number(evidence?.guardRevision) !== 2) {
    fail('bootstrap_requires_guard_revision_2');
  }

  if (Number(evidence?.guardRoleCount) !== CURRENT_ROLE_COUNT) {
    fail('bootstrap_requires_guard_role_count_22');
  }

  requireBooleanTrue(
    evidence?.freshTrustedLiveInventoryRead,
    'fresh_trusted_live_inventory_read',
  );

  requireBooleanTrue(
    evidence?.freshOwnerVerified,
    'fresh_owner_verified',
  );

  requireBooleanTrue(
    evidence?.ownerApprovalBound,
    'owner_approval_bound',
  );

  requireBooleanTrue(
    evidence?.clientSecurityRoleWritesDenied,
    'client_security_role_writes_denied',
  );

  requireBooleanTrue(
    evidence?.clientManifestWritesDenied,
    'client_manifest_writes_denied',
  );

  requireBooleanTrue(
    evidence?.clientMigrationHoldWritesDenied,
    'client_migration_hold_writes_denied',
  );

  requireBooleanTrue(
    evidence?.oldGuardImmutable,
    'old_guard_immutable',
  );

  requireBooleanTrue(
    evidence?.oldArmingTokenImmutable,
    'old_arming_token_immutable',
  );

  requireBooleanTrue(
    evidence?.oldActivationReceiptImmutable,
    'old_activation_receipt_immutable',
  );

  requireBooleanTrue(
    evidence?.sameTransactionAuditReady,
    'same_transaction_audit_ready',
  );

  requireBooleanTrue(
    evidence?.dedicatedRoleAbsent,
    'dedicated_role_absent',
  );

  if (String(evidence?.approvalStatus ?? '').trim() !== 'APPROVED') {
    fail('fresh_approval_must_be_approved');
  }

  requireBooleanFalse(
    evidence?.approvalExpired,
    'approval_expired',
  );

  requireBooleanFalse(
    evidence?.approvalConsumed,
    'approval_consumed',
  );

  requireBooleanFalse(
    evidence?.existingActivationTokenReuseAllowed,
    'existing_activation_token_reuse_allowed',
  );

  const ownerApprovalId =
    String(evidence?.ownerApprovalId ?? '').trim();

  if (!ownerApprovalId) {
    fail('owner_approval_id_required');
  }

  const exactCurrentRoleIds =
    normalizeRoleIds(evidence?.exactCurrentRoleIds);

  const migrationIdSha256 =
    normalizeSha(evidence?.migrationIdSha256, 'migration_id');

  const ownerApprovalBindingSha256 =
    normalizeSha(
      evidence?.ownerApprovalBindingSha256,
      'owner_approval_binding',
    );

  const currentInventoryFingerprintSha256 =
    normalizeSha(
      evidence?.currentInventoryFingerprintSha256,
      'current_inventory_fingerprint',
    );

  const proposedInventoryFingerprintSha256 =
    normalizeSha(
      evidence?.proposedInventoryFingerprintSha256,
      'proposed_inventory_fingerprint',
    );

  const currentControlFingerprintSha256 =
    normalizeSha(
      evidence?.currentControlFingerprintSha256,
      'current_control_fingerprint',
    );

  const actorReferenceSha256 =
    normalizeSha(
      evidence?.actorReferenceSha256,
      'actor_reference',
    );

  const manifest = Object.freeze({
    status: BOOTSTRAP_MANIFEST_STATUS,
    inventoryVersion: CURRENT_INVENTORY_VERSION,
    roleCount: CURRENT_ROLE_COUNT,
    roleProjectionFingerprintSha256:
      currentInventoryFingerprintSha256,
    revision: BOOTSTRAP_MANIFEST_REVISION,
    postMigrationRebindRequired: false,
    updatedAt: 'SERVER_TIMESTAMP',
  });

  const migrationHold = Object.freeze({
    status: BOOTSTRAP_HOLD_STATUS,
    migrationIdSha256,
    ownerApprovalId,
    ownerApprovalBindingSha256,
    currentInventoryFingerprintSha256,
    proposedInventoryFingerprintSha256,
    currentControlFingerprintSha256,
    expectedRoleIds: Object.freeze(exactCurrentRoleIds),
    expectedRoleCount: CURRENT_ROLE_COUNT,
    proposedRoleCount: PROPOSED_ROLE_COUNT,
    expectedGuardRevision: 2,
    targetRoleId: SECURITY_INCIDENT_ROLE_ID,
    targetActionId: SECURITY_INCIDENT_ACTION_ID,
    migrationHoldActive: true,
    repositoryAttachAuthorized: false,
    repositoryArmAuthorized: false,
    firstIncidentWriteAuthorized: false,
    authorizesSuggestOnly: false,
    authorizesAuto: false,
    updatedAt: 'SERVER_TIMESTAMP',
  });

  const audit = Object.freeze({
    eventType: 'SYSTEM_EVENT',
    severity: 'WARNING',
    actorType: 'ADMIN',
    actorId: actorReferenceSha256,
    module: 'ai_core',
    actionId: BOOTSTRAP_AUDIT_ACTION_ID,
    result: BOOTSTRAP_AUDIT_RESULT,
    reason:
      'Owner-bound 22-to-23 role inventory migration manifest and fail-closed hold bootstrapped.',
    relatedApprovalId: ownerApprovalId,
    scope: Object.freeze({
      currentInventoryVersion: CURRENT_INVENTORY_VERSION,
      proposedInventoryVersion: PROPOSED_INVENTORY_VERSION,
      currentRoleCount: CURRENT_ROLE_COUNT,
      proposedRoleCount: PROPOSED_ROLE_COUNT,
      currentInventoryFingerprintSha256,
      proposedInventoryFingerprintSha256,
      currentControlFingerprintSha256,
      ownerApprovalBindingSha256,
      migrationIdSha256,
      expectedGuardRevision: 2,
      targetRoleId: SECURITY_INCIDENT_ROLE_ID,
      targetActionId: SECURITY_INCIDENT_ACTION_ID,
      migrationHoldActive: true,
      repositoryAttachAuthorized: false,
      repositoryArmAuthorized: false,
      firstIncidentWriteAuthorized: false,
      authorizesSuggestOnly: false,
      authorizesAuto: false,
    }),
    createdAt: 'SERVER_TIMESTAMP',
  });

  return Object.freeze({
    mode: 'OFFLINE_TRUSTED_BOOTSTRAP_PLAN_ONLY',
    executionArmed: false,
    projectId: PHASE66_PROJECT_ID,

    preconditions: Object.freeze({
      authorityManifestMustBeAbsent: true,
      migrationHoldMustBeAbsent: true,
      dedicatedRoleMustBeAbsent: true,
      approvalMustRemainApprovedFreshUnconsumed: true,
      rolloutMustRemainMonitorOnly: true,
      guardRevisionMustRemain: 2,
      guardRoleCountMustRemain: CURRENT_ROLE_COUNT,
      oldGuardMustRemainImmutable: true,
      oldArmingTokenMustRemainImmutable: true,
      oldActivationReceiptMustRemainImmutable: true,
    }),

    transaction: Object.freeze({
      required: true,
      exactWriteCount: 3,
      approvalConsumedInBootstrap: false,
      roleCreatedInBootstrap: false,
      authorityManifestCreate: true,
      migrationHoldCreate: true,
      auditCreate: true,
    }),

    paths: Object.freeze({
      authorityManifest:
        `${AGENT_SETTINGS_COLLECTION}/${AUTHORITY_MANIFEST_DOCUMENT}`,
      migrationHold:
        `${AGENT_SETTINGS_COLLECTION}/${MIGRATION_HOLD_DOCUMENT}`,
      auditCollection: AGENT_AUDIT_COLLECTION,
    }),

    authorityManifest: manifest,
    migrationHold,
    audit,

    postconditions: Object.freeze({
      roleDeltaExecuted: false,
      approvalConsumed: false,
      migrationHoldActive: true,
      repositoryAttachAuthorized: false,
      repositoryArmAuthorized: false,
      firstIncidentWriteAuthorized: false,
      suggestOnlyAuthorized: false,
      autoAuthorized: false,
    }),
  });
}
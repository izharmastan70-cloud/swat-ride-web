import {
  CURRENT_INVENTORY_VERSION,
  CURRENT_ROLE_COUNT,
  LOCKED_ROLLOUT_STAGE,
  PHASE66_PROJECT_ID,
  PROPOSED_INVENTORY_VERSION,
  PROPOSED_ROLE_COUNT,
  SECURITY_INCIDENT_ACTION_ID,
  SECURITY_INCIDENT_MODULE,
  SECURITY_INCIDENT_ROLE_DESCRIPTION,
  SECURITY_INCIDENT_ROLE_ID,
  SECURITY_INCIDENT_ROLE_NAME,
} from './contract.mjs';

import {
  proposedInventoryFingerprint,
  proposedRoleProjection,
  roleInventoryFingerprint,
} from './fingerprint.mjs';

export const MIGRATION_OPERATION =
  'MIGRATE_SECURITY_INCIDENT_ROLE_INVENTORY_22_TO_23';

export const ATOMIC_MIGRATION_AUDIT_ACTION_ID =
  'ai.production_rollout.role_inventory.migrate_22_to_23';

export const ATOMIC_MIGRATION_SAFETY = Object.freeze({
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
  roleDeltaEnabled: false,
  roleEnableEnabled: false,
  manifestMutationEnabled: false,
  migrationHoldMutationEnabled: false,
  auditWriteEnabled: false,
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

function requireTrue(value, name) {
  if (value !== true) {
    fail(`${name}_must_be_true`);
  }
}

function requireFalse(value, name) {
  if (value !== false) {
    fail(`${name}_must_be_false`);
  }
}

function exactString(value, expected, code) {
  if (String(value ?? '').trim() !== expected) {
    fail(code);
  }
}

function exactRoleIdsFromRoles(roles) {
  if (!Array.isArray(roles)) {
    fail('current_roles_required');
  }

  const roleIds = roles
    .map((role) => String(role?.roleId ?? '').trim())
    .sort((a, b) => a.localeCompare(b));

  if (
    roleIds.length !== CURRENT_ROLE_COUNT ||
    new Set(roleIds).size !== CURRENT_ROLE_COUNT ||
    roleIds.includes('') ||
    roleIds.includes(SECURITY_INCIDENT_ROLE_ID)
  ) {
    fail('exact_current_22_role_inventory_invalid');
  }

  return roleIds;
}

function exactExpectedRoleIds(value) {
  if (!Array.isArray(value)) {
    fail('migration_hold_expected_role_ids_required');
  }

  const roleIds = value
    .map((item) => String(item ?? '').trim())
    .sort((a, b) => a.localeCompare(b));

  if (
    roleIds.length !== CURRENT_ROLE_COUNT ||
    new Set(roleIds).size !== CURRENT_ROLE_COUNT ||
    roleIds.includes('') ||
    roleIds.includes(SECURITY_INCIDENT_ROLE_ID)
  ) {
    fail('migration_hold_expected_role_ids_invalid');
  }

  return roleIds;
}

function sameStringList(a, b) {
  return (
    a.length === b.length &&
    a.every((value, index) => value === b[index])
  );
}

function deepEqualJson(a, b) {
  return JSON.stringify(a) === JSON.stringify(b);
}

export function assertAtomicMigrationContractDisarmed() {
  for (const [name, enabled] of Object.entries(ATOMIC_MIGRATION_SAFETY)) {
    if (name === 'dryRunOnly') {
      if (enabled !== true) {
        fail('atomic_migration_dry_run_must_remain_true');
      }
      continue;
    }

    if (
      name.endsWith('Enabled') ||
      name.endsWith('Authorized') ||
      name === 'executionArmed'
    ) {
      if (enabled !== false) {
        fail(`atomic_migration_safety_flag_must_be_false:${name}`);
      }
    }
  }

  return true;
}

export function buildAtomicMigrationExecutionPlan(evidence) {
  assertAtomicMigrationContractDisarmed();

  exactString(
    evidence?.projectId,
    PHASE66_PROJECT_ID,
    'project_binding_mismatch',
  );

  exactString(
    evidence?.rolloutStage,
    LOCKED_ROLLOUT_STAGE,
    'rollout_must_remain_monitor_only',
  );

  if (Number(evidence?.guardRevision) !== 2) {
    fail('migration_requires_guard_revision_2');
  }

  if (Number(evidence?.guardRoleCount) !== CURRENT_ROLE_COUNT) {
    fail('migration_requires_guard_role_count_22');
  }

  if (Number(evidence?.autoTrafficPercent) !== 0) {
    fail('auto_traffic_must_remain_zero');
  }

  if (Number(evidence?.businessWriteTrafficPercent) !== 0) {
    fail('business_write_traffic_must_remain_zero');
  }

  requireFalse(
    evidence?.externalChannelsEnabled,
    'external_channels_enabled',
  );

  requireTrue(
    evidence?.runtimeMonitorOnlyOverlayEnforced,
    'runtime_monitor_only_overlay_enforced',
  );

  requireTrue(
    evidence?.noAutoBusinessWriteBoundaryEnforced,
    'no_auto_business_write_boundary_enforced',
  );

  requireTrue(
    evidence?.freshTrustedLiveInventoryRead,
    'fresh_trusted_live_inventory_read',
  );

  requireTrue(
    evidence?.dedicatedRoleAbsent,
    'dedicated_role_absent',
  );

  requireTrue(
    evidence?.requesterApproverSeparated,
    'requester_approver_separated',
  );

  requireTrue(
    evidence?.freshOwnerDecisionVerified,
    'fresh_owner_decision_verified',
  );

  requireTrue(
    evidence?.migrationRulesVerified,
    'migration_rules_verified',
  );

  requireTrue(
    evidence?.oldGuardImmutable,
    'old_guard_immutable',
  );

  requireTrue(
    evidence?.oldArmingTokenImmutable,
    'old_arming_token_immutable',
  );

  requireTrue(
    evidence?.oldActivationReceiptImmutable,
    'old_activation_receipt_immutable',
  );

  requireFalse(
    evidence?.existingArmingTokenReuseAllowed,
    'existing_arming_token_reuse_allowed',
  );

  const approval = evidence?.approval ?? {};

  exactString(
    approval.status,
    'APPROVED',
    'approval_must_be_approved',
  );

  requireFalse(
    approval.expired,
    'approval_expired',
  );

  requireFalse(
    approval.consumed,
    'approval_consumed',
  );

  exactString(
    approval.operation,
    MIGRATION_OPERATION,
    'approval_operation_mismatch',
  );

  exactString(
    approval.roleId,
    SECURITY_INCIDENT_ROLE_ID,
    'approval_role_mismatch',
  );

  exactString(
    approval.actionId,
    SECURITY_INCIDENT_ACTION_ID,
    'approval_action_mismatch',
  );

  exactString(
    approval.module,
    SECURITY_INCIDENT_MODULE,
    'approval_module_mismatch',
  );

  const approvalId =
    String(approval.approvalId ?? '').trim();

  if (!approvalId) {
    fail('approval_id_required');
  }

  const approvalBindingSha256 =
    normalizeSha(
      approval.bindingFingerprintSha256,
      'approval_binding',
    );

  const migrationIdSha256 =
    normalizeSha(
      evidence?.migrationIdSha256,
      'migration_id',
    );

  const actorReferenceSha256 =
    normalizeSha(
      evidence?.actorReferenceSha256,
      'actor_reference',
    );

  const currentControlFingerprintSha256 =
    normalizeSha(
      evidence?.currentControlFingerprintSha256,
      'current_control_fingerprint',
    );

  const currentRoles =
    Array.isArray(evidence?.currentRoles)
      ? evidence.currentRoles
      : [];

  const exactCurrentRoleIds =
    exactRoleIdsFromRoles(currentRoles);

  const computedCurrentFingerprint =
    roleInventoryFingerprint(currentRoles).toLowerCase();

  const computedProposedFingerprint =
    proposedInventoryFingerprint(currentRoles).toLowerCase();

  const expectedCurrentFingerprint =
    normalizeSha(
      evidence?.currentInventoryFingerprintSha256,
      'current_inventory_fingerprint',
    );

  const expectedProposedFingerprint =
    normalizeSha(
      evidence?.proposedInventoryFingerprintSha256,
      'proposed_inventory_fingerprint',
    );

  if (computedCurrentFingerprint !== expectedCurrentFingerprint) {
    fail('current_inventory_fingerprint_mismatch');
  }

  if (computedProposedFingerprint !== expectedProposedFingerprint) {
    fail('proposed_inventory_fingerprint_mismatch');
  }

  const manifest = evidence?.authorityManifest ?? {};

  exactString(
    manifest.status,
    'ACTIVE',
    'authority_manifest_status_mismatch',
  );

  exactString(
    manifest.inventoryVersion,
    CURRENT_INVENTORY_VERSION,
    'authority_manifest_inventory_version_mismatch',
  );

  if (Number(manifest.roleCount) !== CURRENT_ROLE_COUNT) {
    fail('authority_manifest_role_count_mismatch');
  }

  if (Number(manifest.revision) !== 1) {
    fail('authority_manifest_revision_must_be_1');
  }

  if (manifest.postMigrationRebindRequired !== false) {
    fail('authority_manifest_post_rebind_must_be_false_before_role_delta');
  }

  if (
    normalizeSha(
      manifest.roleProjectionFingerprintSha256,
      'authority_manifest_inventory_fingerprint',
    ) !== expectedCurrentFingerprint
  ) {
    fail('authority_manifest_inventory_fingerprint_mismatch');
  }

  const hold = evidence?.migrationHold ?? {};

  exactString(
    hold.status,
    'HELD',
    'migration_hold_status_mismatch',
  );

  if (hold.migrationHoldActive !== true) {
    fail('migration_hold_must_be_active');
  }

  if (
    normalizeSha(hold.migrationIdSha256, 'hold_migration_id') !==
    migrationIdSha256
  ) {
    fail('migration_hold_migration_id_mismatch');
  }

  exactString(
    hold.ownerApprovalId,
    approvalId,
    'migration_hold_approval_id_mismatch',
  );

  if (
    normalizeSha(
      hold.ownerApprovalBindingSha256,
      'hold_owner_approval_binding',
    ) !== approvalBindingSha256
  ) {
    fail('migration_hold_approval_binding_mismatch');
  }

  if (
    normalizeSha(
      hold.currentInventoryFingerprintSha256,
      'hold_current_inventory_fingerprint',
    ) !== expectedCurrentFingerprint
  ) {
    fail('migration_hold_current_inventory_fingerprint_mismatch');
  }

  if (
    normalizeSha(
      hold.proposedInventoryFingerprintSha256,
      'hold_proposed_inventory_fingerprint',
    ) !== expectedProposedFingerprint
  ) {
    fail('migration_hold_proposed_inventory_fingerprint_mismatch');
  }

  if (
    normalizeSha(
      hold.currentControlFingerprintSha256,
      'hold_current_control_fingerprint',
    ) !== currentControlFingerprintSha256
  ) {
    fail('migration_hold_control_fingerprint_mismatch');
  }

  if (Number(hold.expectedRoleCount) !== CURRENT_ROLE_COUNT) {
    fail('migration_hold_expected_role_count_mismatch');
  }

  if (Number(hold.proposedRoleCount) !== PROPOSED_ROLE_COUNT) {
    fail('migration_hold_proposed_role_count_mismatch');
  }

  if (Number(hold.expectedGuardRevision) !== 2) {
    fail('migration_hold_guard_revision_mismatch');
  }

  exactString(
    hold.targetRoleId,
    SECURITY_INCIDENT_ROLE_ID,
    'migration_hold_target_role_mismatch',
  );

  exactString(
    hold.targetActionId,
    SECURITY_INCIDENT_ACTION_ID,
    'migration_hold_target_action_mismatch',
  );

  const holdRoleIds =
    exactExpectedRoleIds(hold.expectedRoleIds);

  if (!sameStringList(exactCurrentRoleIds, holdRoleIds)) {
    fail('migration_hold_exact_role_ids_mismatch');
  }

  for (const [name, value] of Object.entries({
    repositoryAttachAuthorized: hold.repositoryAttachAuthorized,
    repositoryArmAuthorized: hold.repositoryArmAuthorized,
    firstIncidentWriteAuthorized: hold.firstIncidentWriteAuthorized,
    authorizesSuggestOnly: hold.authorizesSuggestOnly,
    authorizesAuto: hold.authorizesAuto,
  })) {
    if (value === true) {
      fail(`migration_hold_must_fail_closed:${name}`);
    }
  }

  const roleProjection =
    proposedRoleProjection();

  const rolePayload = Object.freeze({
    ...roleProjection,
    name: SECURITY_INCIDENT_ROLE_NAME,
    description: SECURITY_INCIDENT_ROLE_DESCRIPTION,
  });

  if (rolePayload.enabled !== false) {
    fail('proposed_security_role_must_commit_disabled');
  }

  if (
    rolePayload.roleId !== SECURITY_INCIDENT_ROLE_ID ||
    rolePayload.name !== SECURITY_INCIDENT_ROLE_NAME ||
    rolePayload.description !== SECURITY_INCIDENT_ROLE_DESCRIPTION ||
    rolePayload.module !== SECURITY_INCIDENT_MODULE ||
    rolePayload.mode !== 'ASK_FIRST' ||
    rolePayload.aiClass !== 'FREE_AI' ||
    rolePayload.privacyLevel !== 'HIGHLY_SENSITIVE' ||
    !deepEqualJson(
      rolePayload.allowedActions,
      [SECURITY_INCIDENT_ACTION_ID],
    ) ||
    !deepEqualJson(
      rolePayload.approvalRequiredActions,
      [SECURITY_INCIDENT_ACTION_ID],
    ) ||
    !deepEqualJson(rolePayload.forbiddenActions, [])
  ) {
    fail('proposed_security_role_authority_mismatch');
  }

  return Object.freeze({
    mode: 'OFFLINE_ATOMIC_MIGRATION_EXECUTION_PLAN_ONLY',
    executionArmed: false,
    projectId: PHASE66_PROJECT_ID,

    preconditions: Object.freeze({
      approvalReadInsideSameTransaction: true,
      approvalMustRemainApprovedFreshUnconsumed: true,
      exactApprovalScopeBindingRequired: true,
      requesterApproverSeparationRequired: true,
      exact22RoleReadsInsideSameTransaction: true,
      targetRoleMustRemainAbsent: true,
      monitorOnlyGuardMustRemainExact: true,
      authorityManifestRevisionMustRemain: 1,
      migrationHoldMustRemainHeldAndExact: true,
      currentInventoryFingerprintMustRecompute: true,
      proposedInventoryFingerprintMustRecompute: true,
    }),

    transaction: Object.freeze({
      required: true,
      exactLogicalWriteCount: 5,

      write1ApprovalConsume: Object.freeze({
        status: 'CONSUMED',
        consumedAt: 'SERVER_TIMESTAMP',
      }),

      write2CreateDisabledRole: rolePayload,

      write3AuthorityManifestPatch: Object.freeze({
        status: 'ACTIVE',
        inventoryVersion: PROPOSED_INVENTORY_VERSION,
        roleCount: PROPOSED_ROLE_COUNT,
        roleProjectionFingerprintSha256:
          expectedProposedFingerprint,
        revision: 2,
        lastMigrationIdSha256: migrationIdSha256,
        postMigrationRebindRequired: true,
        updatedAt: 'SERVER_TIMESTAMP',
      }),

      write4MigrationHoldPatch: Object.freeze({
        status: 'ROLE_DELTA_COMMITTED',
        migrationHoldActive: true,
        authorityManifestRevision: 2,
        postMigrationRebindRequired: true,
        repositoryAttachAuthorized: false,
        repositoryArmAuthorized: false,
        firstIncidentWriteAuthorized: false,
        authorizesSuggestOnly: false,
        authorizesAuto: false,
        updatedAt: 'SERVER_TIMESTAMP',
      }),

      write5Audit: Object.freeze({
        eventType: 'SYSTEM_EVENT',
        severity: 'WARNING',
        actorType: 'ADMIN',
        actorId: actorReferenceSha256,
        module: 'ai_core',
        actionId: ATOMIC_MIGRATION_AUDIT_ACTION_ID,
        result: 'ROLE_DELTA_COMMITTED',
        reason:
          'Fresh Owner-bound approval consumed atomically with disabled 22-to-23 role delta under migration hold.',
        relatedApprovalId: approvalId,
        createdAt: 'SERVER_TIMESTAMP',
      }),
    }),

    postconditions: Object.freeze({
      approvalConsumed: true,
      roleCount: PROPOSED_ROLE_COUNT,
      securityIncidentRoleExists: true,
      securityIncidentRoleEnabled: false,
      authorityManifestRevision: 2,
      authorityManifestPostMigrationRebindRequired: true,
      migrationHoldStatus: 'ROLE_DELTA_COMMITTED',
      migrationHoldActive: true,
      postMigrationSnapshotRequired: true,
      postMigrationGuardRebindRequired: true,
      freshPostMigrationArmingTokenRequired: true,
      migrationReceiptRequired: true,
      oldArmingTokenReuseAllowed: false,
      repositoryAttachAuthorized: false,
      repositoryArmAuthorized: false,
      firstIncidentWriteAuthorized: false,
      suggestOnlyAuthorized: false,
      autoAuthorized: false,
    }),
  });
}
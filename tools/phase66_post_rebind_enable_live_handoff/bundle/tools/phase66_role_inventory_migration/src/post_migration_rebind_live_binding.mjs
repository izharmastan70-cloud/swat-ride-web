import crypto from 'node:crypto';

export const POST_MIGRATION_REBIND_PLAN_BINDING_ALGORITHM =
  'SHA256_POST_MIGRATION_REBIND_PLAN_V1';

function fail(code) {
  throw new Error(code);
}

function text(value, fallback = '') {
  if (value == null) return fallback;
  const result = String(value).trim();
  return result || fallback;
}

function lower(value) {
  return text(value).toLowerCase();
}

function boolValue(value, fallback = false) {
  if (value == null) return fallback;
  if (typeof value === 'boolean') return value;
  const normalized = String(value).toLowerCase().trim();
  if (normalized === 'true') return true;
  if (normalized === 'false') return false;
  return fallback;
}

function intValue(value) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.trunc(value);
  }

  const raw = value == null ? '' : String(value).trim();
  if (!/^[+-]?\d+$/.test(raw)) return 0;

  const parsed = Number.parseInt(raw, 10);
  return Number.isSafeInteger(parsed) ? parsed : 0;
}

function stringList(value) {
  if (!Array.isArray(value)) return [];

  const unique = new Set();
  for (const item of value) {
    const normalized = String(item).trim();
    if (normalized) unique.add(normalized);
  }

  return [...unique];
}

function canonical(value) {
  if (Array.isArray(value)) {
    return value.map(canonical);
  }

  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.keys(value)
        .sort()
        .map((key) => [key, canonical(value[key])]),
    );
  }

  return value;
}

function sha256Canonical(value) {
  return crypto
    .createHash('sha256')
    .update(JSON.stringify(canonical(value)), 'utf8')
    .digest('hex');
}

function isSha256(value) {
  return /^[a-f0-9]{64}$/.test(lower(value));
}

function validateMasterProjection(master) {
  if (
    master.paidReasoningPerTaskLimitRs < 0 ||
    master.paidReasoningDailyLimitRs < 0 ||
    master.paidReasoningMonthlyLimitRs < 0 ||
    master.monthlyPaidCodeBudgetRs < 0 ||
    master.paidCodeBudgetUsedRs < 0
  ) {
    fail('post_migration_master_projection_invalid_budget');
  }

  const paidReasoningBudgetConfigured =
    master.paidReasoningPerTaskLimitRs > 0 &&
    master.paidReasoningDailyLimitRs > 0 &&
    master.paidReasoningMonthlyLimitRs > 0;

  if (master.paidReasoningEnabled && !paidReasoningBudgetConfigured) {
    fail('post_migration_master_projection_invalid_paid_reasoning_budget');
  }

  if (master.paidCodeAiEnabled && master.monthlyPaidCodeBudgetRs <= 0) {
    fail('post_migration_master_projection_invalid_paid_code_budget');
  }
}

export function projectPostMigrationMasterControl(rawMaster) {
  if (!rawMaster || typeof rawMaster !== 'object' || Array.isArray(rawMaster)) {
    fail('post_migration_master_projection_missing');
  }

  const projection = {
    masterEnabled: boolValue(rawMaster.masterEnabled),
    emergencyReadOnly: boolValue(rawMaster.emergencyReadOnly, true),
    freeAiEnabled: boolValue(rawMaster.freeAiEnabled),
    localAiEnabled: boolValue(rawMaster.localAiEnabled),
    paidCodeAiEnabled: boolValue(rawMaster.paidCodeAiEnabled),
    callAgentEnabled: boolValue(rawMaster.callAgentEnabled),
    emailAgentEnabled: boolValue(rawMaster.emailAgentEnabled),
    customerWhatsAppAgentEnabled:
      boolValue(rawMaster.customerWhatsAppAgentEnabled),
    ownerWhatsAppAgentEnabled:
      boolValue(rawMaster.ownerWhatsAppAgentEnabled),
    emergencyWhatsAppAgentEnabled:
      boolValue(rawMaster.emergencyWhatsAppAgentEnabled),
    voiceSuperAdminAgentEnabled:
      boolValue(rawMaster.voiceSuperAdminAgentEnabled),
    approvalEngineEnabled: boolValue(rawMaster.approvalEngineEnabled, true),
    auditLoggingEnabled: boolValue(rawMaster.auditLoggingEnabled, true),
    paidReasoningEnabled: boolValue(rawMaster.paidReasoningEnabled),
    askBeforePaid: boolValue(rawMaster.askBeforePaid, true),
    paidReasoningPerTaskLimitRs:
      intValue(rawMaster.paidReasoningPerTaskLimitRs),
    paidReasoningDailyLimitRs:
      intValue(rawMaster.paidReasoningDailyLimitRs),
    paidReasoningMonthlyLimitRs:
      intValue(rawMaster.paidReasoningMonthlyLimitRs),
    monthlyPaidCodeBudgetRs: intValue(rawMaster.monthlyPaidCodeBudgetRs),
    paidCodeBudgetUsedRs: intValue(rawMaster.paidCodeBudgetUsedRs),
    emergencyActivatedBy: text(rawMaster.emergencyActivatedBy),
    emergencyReason: text(rawMaster.emergencyReason),
  };

  validateMasterProjection(projection);
  return canonical(projection);
}

export function projectPostMigrationRoleControl(rawRole) {
  if (!rawRole || typeof rawRole !== 'object' || Array.isArray(rawRole)) {
    fail('post_migration_role_projection_missing');
  }

  const roleId = text(rawRole.roleId);
  const module = text(rawRole.module);

  if (!roleId || !module) {
    fail('post_migration_role_projection_identity_missing');
  }

  const allowedActions = stringList(rawRole.allowedActions).sort();
  const approvalRequiredActions =
    stringList(rawRole.approvalRequiredActions).sort();
  const forbiddenActions = stringList(rawRole.forbiddenActions).sort();

  return {
    roleId,
    module,
    enabled: boolValue(rawRole.enabled),
    mode: text(rawRole.mode, 'OFF'),
    allowedActions,
    approvalRequiredActions,
    forbiddenActions,
    aiClass: text(rawRole.aiClass, 'FREE_AI'),
    privacyLevel: text(rawRole.privacyLevel, 'INTERNAL'),
    // AgentRole.isFailClosed is client-side only and is not persisted/read by
    // AgentRole.fromMap. Exact live inventory validation happens separately.
    isFailClosed: false,
  };
}

export function buildPostMigrationControlProjection({ master, roles }) {
  if (!Array.isArray(roles) || roles.length === 0) {
    fail('post_migration_role_projection_set_missing');
  }

  const roleProjections = roles
    .map(projectPostMigrationRoleControl)
    .sort((left, right) => {
      if (left.roleId < right.roleId) return -1;
      if (left.roleId > right.roleId) return 1;
      return 0;
    });

  return {
    masterSettings: projectPostMigrationMasterControl(master),
    roles: roleProjections,
  };
}

export function postMigrationControlStateFingerprint({ master, roles }) {
  return sha256Canonical(
    buildPostMigrationControlProjection({ master, roles }),
  );
}

function requireContract(contract) {
  const required = [
    'operation',
    'lockedPostMigrationSnapshotSha256',
    'lockedRoleInventoryFingerprintSha256',
    'targetRoleId',
    'targetModule',
    'targetActionId',
    'rolloutStage',
    'guardVersion',
  ];

  for (const key of required) {
    if (!text(contract?.[key])) {
      fail(`post_migration_rebind_contract_field_missing:${key}`);
    }
  }

  for (const key of [
    'lockedPostMigrationSnapshotSha256',
    'lockedRoleInventoryFingerprintSha256',
  ]) {
    if (!isSha256(contract[key])) {
      fail(`post_migration_rebind_contract_sha_invalid:${key}`);
    }
  }

  for (const key of [
    'targetRoleCount',
    'currentAuthorityManifestRevision',
    'targetAuthorityManifestRevision',
    'currentGuardRevision',
    'targetGuardRevision',
    'currentGuardRoleCount',
  ]) {
    if (!Number.isInteger(contract?.[key])) {
      fail(`post_migration_rebind_contract_integer_invalid:${key}`);
    }
  }
}

export function postMigrationRebindPlanFingerprint({
  contract,
  approvalId,
  migrationApprovalId,
  requesterReferenceSha256,
  ownerApproverReferenceSha256,
  postMigrationControlStateFingerprintSha256,
  freshTokenIdSha256,
  receiptIdSha256,
}) {
  requireContract(contract);

  if (!text(approvalId) || !text(migrationApprovalId)) {
    fail('post_migration_rebind_plan_approval_id_missing');
  }

  if (approvalId === migrationApprovalId) {
    fail('post_migration_rebind_plan_migration_approval_reuse_forbidden');
  }

  for (const [name, value] of Object.entries({
    requesterReferenceSha256,
    ownerApproverReferenceSha256,
    postMigrationControlStateFingerprintSha256,
    freshTokenIdSha256,
    receiptIdSha256,
  })) {
    if (!isSha256(value)) {
      fail(`post_migration_rebind_plan_sha_invalid:${name}`);
    }
  }

  if (lower(requesterReferenceSha256) === lower(ownerApproverReferenceSha256)) {
    fail('post_migration_rebind_plan_requester_owner_separation_required');
  }

  const payload = {
    algorithm: POST_MIGRATION_REBIND_PLAN_BINDING_ALGORITHM,
    operation: contract.operation,
    approvalId: text(approvalId),
    migrationApprovalId: text(migrationApprovalId),
    requesterReferenceSha256: lower(requesterReferenceSha256),
    ownerApproverReferenceSha256: lower(ownerApproverReferenceSha256),
    postMigrationSnapshotSha256:
      lower(contract.lockedPostMigrationSnapshotSha256),
    roleInventoryFingerprintSha256:
      lower(contract.lockedRoleInventoryFingerprintSha256),
    postMigrationControlStateFingerprintSha256:
      lower(postMigrationControlStateFingerprintSha256),
    freshTokenIdSha256: lower(freshTokenIdSha256),
    receiptIdSha256: lower(receiptIdSha256),
    roleCount: contract.targetRoleCount,
    currentAuthorityManifestRevision:
      contract.currentAuthorityManifestRevision,
    targetAuthorityManifestRevision:
      contract.targetAuthorityManifestRevision,
    currentGuardRevision: contract.currentGuardRevision,
    targetGuardRevision: contract.targetGuardRevision,
    currentGuardRoleCount: contract.currentGuardRoleCount,
    targetRoleId: contract.targetRoleId,
    targetModule: contract.targetModule,
    targetActionId: contract.targetActionId,
    requestedRolloutStage: contract.rolloutStage,
    guardVersion: contract.guardVersion,
    targetGuard: {
      enabled: true,
      guardVersion: contract.guardVersion,
      revision: contract.targetGuardRevision,
      targetStage: contract.rolloutStage,
      runtimeMonitorOnlyOverlayEnforced: true,
      noAutoBusinessWriteBoundaryEnforced: true,
      appChatOnly: true,
      autoTrafficPercent: 0,
      businessWriteTrafficPercent: 0,
      externalChannelsEnabled: false,
      roleCount: contract.targetRoleCount,
      ownerApprovalId: text(approvalId),
      actorReferenceSha256: lower(ownerApproverReferenceSha256),
    },
    safetyBoundary: {
      freshOwnerVerifiedAtApproval: true,
      explicitOwnerApproval: true,
      selfApprovalAllowed: false,
      migrationApprovalReuseAllowed: false,
      oldArmingTokenReuseAllowed: false,
      roleEnableAuthorized: false,
      migrationHoldReleaseAuthorized: false,
      repositoryAttachAuthorized: false,
      repositoryArmAuthorized: false,
      firstIncidentWriteAuthorized: false,
      authorizesSuggestOnly: false,
      authorizesAuto: false,
    },
  };

  return sha256Canonical(payload);
}

export const POST_MIGRATION_REBIND_LIVE_BINDING_CONTRACT = Object.freeze({
  controlAlgorithm: 'SHA256_CONTROL_STATE_V1',
  planAlgorithm: POST_MIGRATION_REBIND_PLAN_BINDING_ALGORITHM,
  mirrorsDartMasterProjection: true,
  mirrorsDartRoleProjection: true,
  roleFailClosedProjectionForPersistedValidRole: false,
  readsFirestore: false,
  writesFirestore: false,
  initializesFirebaseAdmin: false,
  ownsFirestoreTransaction: false,
  grantsAuthority: false,
});

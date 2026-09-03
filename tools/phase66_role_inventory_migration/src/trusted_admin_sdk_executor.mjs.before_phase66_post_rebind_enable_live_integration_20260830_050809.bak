import crypto from 'node:crypto';

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
  SECURITY_INCIDENT_MODULE,
  SECURITY_INCIDENT_ROLE_ID,
} from './contract.mjs';

import {
  proposedInventoryFingerprint,
  proposedRoleProjection,
  roleInventoryFingerprint,
} from './fingerprint.mjs';

import {
  buildTrustedBootstrapPlan,
} from './trusted_bootstrap_execution_contract.mjs';

import {
  MIGRATION_OPERATION,
  buildAtomicMigrationExecutionPlan,
} from './atomic_migration_execution_contract.mjs';

import {
  POST_MIGRATION_REBIND_CONTRACT as REBIND_CONTRACT,
} from '../../phase66_post_migration_rebind_offline/src/rebind_contract.mjs';

import {
  executePostMigrationRebindInCallerTransaction,
} from '../../phase66_post_migration_rebind_offline/src/trusted_rebind_transaction_body.mjs';

import {
  postMigrationControlStateFingerprint,
  postMigrationRebindPlanFingerprint,
} from './post_migration_rebind_live_binding.mjs';

const AGENT_APPROVALS = 'agent_approvals';
const AGENT_ROLES = 'agent_roles';
const AGENT_SETTINGS = 'agent_settings';
const AGENT_AUDIT_LOGS = 'agent_audit_logs';

const MASTER_DOC = 'master';
const ROLLOUT_DOC = 'production_rollout';
const GUARD_DOC = 'production_rollout_guard';

const EXPECTED_CURRENT_INVENTORY_SHA256 =
  '3ba eafc2e8ce82d138f884f6f3990c4ff644d981be864a35182c5475997b1f1d'
    .replaceAll(' ', '');

const EXPECTED_PROPOSED_INVENTORY_SHA256 =
  'd16c6ff23b0d56a9e3b76146eefe22832d86196dee48bb05d6bc0129f48e2f2a';

const EXPECTED_PRE_MIGRATION_CONTROL_SHA256 =
  'db72e5c0888ea558c07ef002d059c3d92f909fb77f223725a029f35fa6ee9b5e';

const EXPECTED_TZ_EVIDENCE_SHA256 =
  '6cb1df3565e6a9130cadb54d888e6cfe89d7ed393dda369a54ad32d40d937240';

// Bootstrap is a separate transaction from role migration. Do not bootstrap
// a hold when too little approval lifetime remains for the immediate
// follow-up atomic migration transaction.
const MIN_BOOTSTRAP_APPROVAL_REMAINING_MS =
  5 * 60 * 1000;

const MIN_MIGRATION_APPROVAL_REMAINING_MS =
  60 * 1000;

export const LIVE_EXECUTOR_DEFAULTS = Object.freeze({
  executionArmed: false,
  allowAdminSdkInit: false,
  allowCredentialLoad: false,
  allowNetworkRead: false,
  allowNetworkWrite: false,
  allowBootstrapTransaction: false,
  allowMigrationTransaction: false,
  allowPostMigrationRebindTransaction: false,
  allowApprovalConsume: false,
  allowRoleCreate: false,
  allowManifestMutation: false,
  allowMigrationHoldMutation: false,
  allowAuditWrite: false,
  allowGuardMutation: false,
  allowTokenMutation: false,
  allowReceiptMutation: false,
  allowRepositoryAttach: false,
  allowRepositoryArm: false,
  allowIncidentWrite: false,
  allowSuggestOnly: false,
  allowAuto: false,
});

function fail(code) {
  throw new Error(code);
}

function norm(value) {
  return String(value ?? '').trim();
}

function upper(value) {
  return norm(value).toUpperCase();
}

function lower(value) {
  return norm(value).toLowerCase();
}

function isSha256(value) {
  return /^[0-9a-f]{64}$/i.test(norm(value));
}

function toMillis(value) {
  if (typeof value?.toMillis === 'function') {
    return value.toMillis();
  }

  if (value instanceof Date) {
    return value.getTime();
  }

  return Number.NaN;
}

function sha256Hex(value) {
  return crypto
    .createHash('sha256')
    .update(String(value), 'utf8')
    .digest('hex');
}

function stableNormalize(value) {
  if (Array.isArray(value)) {
    return value.map(stableNormalize);
  }

  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.keys(value)
        .sort((a, b) => a.localeCompare(b))
        .map((key) => [key, stableNormalize(value[key])]),
    );
  }

  return value;
}

function stableSha256(value) {
  return sha256Hex(
    JSON.stringify(stableNormalize(value)),
  );
}

function assertAllWriteControlsFalse(config) {
  for (const [name, value] of Object.entries(config)) {
    if (
      name.startsWith('allow') &&
      value === true
    ) {
      fail(`live_executor_write_or_network_flag_enabled:${name}`);
    }
  }
}

export function assertLiveExecutorDefaultDisarmed() {
  if (LIVE_EXECUTOR_DEFAULTS.executionArmed !== false) {
    fail('live_executor_default_execution_must_be_disarmed');
  }

  assertAllWriteControlsFalse(LIVE_EXECUTOR_DEFAULTS);

  return true;
}

function assertExecutionWord(config, expected) {
  if (norm(config?.executionWord) !== expected) {
    fail('exact_execution_word_required');
  }
}

function assertBootstrapArmed(config) {
  if (config?.executionArmed !== true) {
    fail('bootstrap_execution_not_armed');
  }

  assertExecutionWord(
    config,
    'PHASE66_BOOTSTRAP_MANIFEST_HOLD_ONLY',
  );

  const requiredTrue = [
    'allowAdminSdkInit',
    'allowCredentialLoad',
    'allowNetworkRead',
    'allowNetworkWrite',
    'allowBootstrapTransaction',
    'allowManifestMutation',
    'allowMigrationHoldMutation',
    'allowAuditWrite',
  ];

  for (const key of requiredTrue) {
    if (config?.[key] !== true) {
      fail(`bootstrap_required_execution_flag_missing:${key}`);
    }
  }

  const requiredFalse = [
    'allowMigrationTransaction',
    'allowPostMigrationRebindTransaction',
    'allowApprovalConsume',
    'allowRoleCreate',
    'allowGuardMutation',
    'allowTokenMutation',
    'allowReceiptMutation',
    'allowRepositoryAttach',
    'allowRepositoryArm',
    'allowIncidentWrite',
    'allowSuggestOnly',
    'allowAuto',
  ];

  for (const key of requiredFalse) {
    if (config?.[key] !== false) {
      fail(`bootstrap_forbidden_flag_must_remain_false:${key}`);
    }
  }
}

function assertMigrationArmed(config) {
  if (config?.executionArmed !== true) {
    fail('migration_execution_not_armed');
  }

  assertExecutionWord(
    config,
    'PHASE66_ATOMIC_MIGRATION_22_TO_23_ONLY',
  );

  const requiredTrue = [
    'allowAdminSdkInit',
    'allowCredentialLoad',
    'allowNetworkRead',
    'allowNetworkWrite',
    'allowMigrationTransaction',
    'allowApprovalConsume',
    'allowRoleCreate',
    'allowManifestMutation',
    'allowMigrationHoldMutation',
    'allowAuditWrite',
  ];

  for (const key of requiredTrue) {
    if (config?.[key] !== true) {
      fail(`migration_required_execution_flag_missing:${key}`);
    }
  }

  const requiredFalse = [
    'allowBootstrapTransaction',
    'allowPostMigrationRebindTransaction',
    'allowGuardMutation',
    'allowTokenMutation',
    'allowReceiptMutation',
    'allowRepositoryAttach',
    'allowRepositoryArm',
    'allowIncidentWrite',
    'allowSuggestOnly',
    'allowAuto',
  ];

  for (const key of requiredFalse) {
    if (config?.[key] !== false) {
      fail(`migration_forbidden_flag_must_remain_false:${key}`);
    }
  }
}

function assertPostMigrationRebindArmed(config) {
  if (config?.executionArmed !== true) {
    fail('post_migration_rebind_execution_not_armed');
  }

  assertExecutionWord(
    config,
    'PHASE66_POST_MIGRATION_REBIND_23_ROLE_ONLY',
  );

  const requiredTrue = [
    'allowAdminSdkInit',
    'allowCredentialLoad',
    'allowNetworkRead',
    'allowNetworkWrite',
    'allowPostMigrationRebindTransaction',
    'allowApprovalConsume',
    'allowManifestMutation',
    'allowGuardMutation',
    'allowTokenMutation',
    'allowReceiptMutation',
    'allowAuditWrite',
  ];

  for (const key of requiredTrue) {
    if (config?.[key] !== true) {
      fail(`post_migration_rebind_required_execution_flag_missing:${key}`);
    }
  }

  const requiredFalse = [
    'allowBootstrapTransaction',
    'allowMigrationTransaction',
    'allowRoleCreate',
    'allowMigrationHoldMutation',
    'allowRepositoryAttach',
    'allowRepositoryArm',
    'allowIncidentWrite',
    'allowSuggestOnly',
    'allowAuto',
  ];

  for (const key of requiredFalse) {
    if (config?.[key] !== false) {
      fail(`post_migration_rebind_forbidden_flag_must_remain_false:${key}`);
    }
  }
}

function normalizeApproval(snapshot) {
  if (!snapshot.exists) {
    fail('approval_document_missing');
  }

  const data = snapshot.data() ?? {};
  const persistedApprovalId = norm(data.approvalId);

  if (!persistedApprovalId) {
    fail('approval_payload_id_missing');
  }

  if (persistedApprovalId !== snapshot.id) {
    fail('approval_document_id_payload_id_mismatch');
  }

  const scope =
    data.actionScope && typeof data.actionScope === 'object'
      ? data.actionScope
      : {};

  return {
    approvalId: persistedApprovalId,
    roleId: norm(data.roleId),
    actionId: norm(data.actionId),
    module: norm(data.module),
    risk: upper(data.risk),
    requestedBy: norm(data.requestedBy),
    status: upper(data.status),
    createdAt: data.createdAt,
    expiresAt: data.expiresAt,
    decidedAt: data.decidedAt,
    consumedAt: data.consumedAt,
    decidedBy: norm(data.decidedBy),
    actionScope: scope,
  };
}

function validateFreshApprovedMigrationApproval(
  approval,
  nowMillis,
  expectedBindingSha256,
  actorReferenceSha256,
  minimumRemainingMillis,
) {
  if (
    approval.roleId !== SECURITY_INCIDENT_ROLE_ID ||
    approval.actionId !== SECURITY_INCIDENT_ACTION_ID ||
    approval.module !== SECURITY_INCIDENT_MODULE ||
    approval.risk !== 'CRITICAL'
  ) {
    fail('approval_exact_role_action_module_risk_mismatch');
  }

  if (approval.status !== 'APPROVED') {
    fail('approval_must_be_approved');
  }

  if (approval.consumedAt != null) {
    fail('approval_already_consumed');
  }

  if (!approval.decidedBy) {
    fail('approval_decided_by_missing');
  }

  if (
    approval.requestedBy &&
    approval.decidedBy === approval.requestedBy
  ) {
    fail('requester_approver_separation_violated');
  }

  const expectedCoordinatorDigest =
    sha256Hex(
      `PHASE66_MIGRATION_COORDINATOR|${lower(expectedBindingSha256)}`,
    );

  const expectedRequestedBy =
    `phase66_migration_coordinator_sha256:${expectedCoordinatorDigest}`;

  if (approval.requestedBy !== expectedRequestedBy) {
    fail('approval_system_requester_binding_mismatch');
  }

  const createdMillis = toMillis(approval.createdAt);
  const expiresMillis = toMillis(approval.expiresAt);
  const decidedMillis = toMillis(approval.decidedAt);

  if (
    !Number.isFinite(createdMillis) ||
    !Number.isFinite(expiresMillis) ||
    !Number.isFinite(decidedMillis)
  ) {
    fail('approval_timestamp_evidence_incomplete');
  }

  if (expiresMillis - createdMillis !== 15 * 60 * 1000) {
    fail('approval_validity_window_must_be_exactly_15_minutes');
  }

  if (
    decidedMillis < createdMillis ||
    decidedMillis > expiresMillis
  ) {
    fail('approval_decision_outside_validity_window');
  }

  if (nowMillis > expiresMillis) {
    fail('approval_expired_before_execution');
  }

  if (
    !Number.isFinite(minimumRemainingMillis) ||
    minimumRemainingMillis < 0
  ) {
    fail('approval_minimum_remaining_ttl_invalid');
  }

  const remainingMillis =
    expiresMillis - nowMillis;

  if (remainingMillis < minimumRemainingMillis) {
    fail('approval_remaining_ttl_below_execution_floor');
  }

  const scope = approval.actionScope;

  if (
    norm(scope.operation) !== MIGRATION_OPERATION ||
    lower(scope.bindingFingerprintSha256) !==
      lower(expectedBindingSha256) ||
    norm(scope.requestPrincipal) !==
      'PHASE66_MIGRATION_COORDINATOR' ||
    norm(scope.currentInventoryVersion) !==
      CURRENT_INVENTORY_VERSION ||
    norm(scope.proposedInventoryVersion) !==
      PROPOSED_INVENTORY_VERSION ||
    Number(scope.currentRoleCount) !== CURRENT_ROLE_COUNT ||
    Number(scope.proposedRoleCount) !== PROPOSED_ROLE_COUNT ||
    Number(scope.currentGuardRevision) !== 2 ||
    Number(scope.proposedGuardRevision) !== 3 ||
    norm(scope.targetRoleId) !== SECURITY_INCIDENT_ROLE_ID ||
    norm(scope.targetModule) !== SECURITY_INCIDENT_MODULE ||
    norm(scope.targetActionId) !== SECURITY_INCIDENT_ACTION_ID ||
    norm(scope.requestedRolloutStage) !== LOCKED_ROLLOUT_STAGE ||
    scope.proposedRoleEnabled !== false ||
    scope.oldGuardImmutable !== true ||
    scope.oldArmingTokenImmutable !== true ||
    scope.oldActivationReceiptImmutable !== true ||
    scope.existingActivationTokenReuseAllowed !== false ||
    scope.repositoryAttachAuthorized !== false ||
    scope.repositoryArmAuthorized !== false ||
    scope.firstIncidentWriteAuthorized !== false ||
    scope.authorizesSuggestOnly !== false ||
    scope.authorizesAuto !== false ||
    scope.selfApprovalAllowed !== false
  ) {
    fail('approval_action_scope_exact_binding_mismatch');
  }

  for (const key of [
    'currentInventoryFingerprintSha256',
    'proposedInventoryFingerprintSha256',
    'currentControlFingerprintSha256',
    'preconditionEvidenceFingerprintSha256',
    'ownerApproverReferenceSha256',
  ]) {
    if (!isSha256(scope[key])) {
      fail(`approval_scope_sha256_missing_or_invalid:${key}`);
    }
  }

  if (
    lower(scope.currentInventoryFingerprintSha256) !==
      EXPECTED_CURRENT_INVENTORY_SHA256 ||
    lower(scope.proposedInventoryFingerprintSha256) !==
      EXPECTED_PROPOSED_INVENTORY_SHA256 ||
    lower(scope.currentControlFingerprintSha256) !==
      EXPECTED_PRE_MIGRATION_CONTROL_SHA256 ||
    lower(scope.preconditionEvidenceFingerprintSha256) !==
      EXPECTED_TZ_EVIDENCE_SHA256
  ) {
    fail('approval_locked_ty_tz_evidence_mismatch');
  }

  if (
    lower(scope.ownerApproverReferenceSha256) ===
    lower(expectedCoordinatorDigest)
  ) {
    fail('owner_approver_must_not_equal_system_requester');
  }

  const expectedDecidedBy =
    `phase66_owner_sha256:${lower(scope.ownerApproverReferenceSha256)}`;

  if (approval.decidedBy !== expectedDecidedBy) {
    fail('approval_decided_by_owner_sha_binding_mismatch');
  }

  if (
    lower(actorReferenceSha256) !==
    lower(scope.ownerApproverReferenceSha256)
  ) {
    fail('audit_actor_must_equal_expected_owner_sha');
  }

  return true;
}

function roleDocumentsToMaps(snapshot) {
  return snapshot.docs.map((doc) => {
    const data = doc.data() ?? {};
    const persistedRoleId = norm(data.roleId);

    if (!persistedRoleId) {
      fail('live_role_document_missing_role_id');
    }

    if (doc.id !== persistedRoleId) {
      fail('live_role_document_id_role_id_mismatch');
    }

    return {
      ...data,
      roleId: persistedRoleId,
    };
  });
}

function exactRoleIds(roles) {
  return roles
    .map((role) => norm(role.roleId))
    .sort((a, b) => a.localeCompare(b));
}

function validateMonitorOnlyBoundary(
  rollout,
  guard,
  currentControlFingerprintSha256,
) {
  if (
    upper(rollout.stage) !== 'MONITOR_ONLY' ||
    Number(rollout.autoTrafficPercent ?? 0) !== 0 ||
    Number(rollout.businessWriteTrafficPercent ?? 0) !== 0 ||
    rollout.externalChannelsEnabled !== false
  ) {
    fail('rollout_not_exact_monitor_only');
  }

  if (
    guard.enabled !== true ||
    Number(guard.revision) !== 2 ||
    upper(guard.targetStage) !== 'MONITOR_ONLY' ||
    guard.runtimeMonitorOnlyOverlayEnforced !== true ||
    guard.noAutoBusinessWriteBoundaryEnforced !== true ||
    Number(guard.autoTrafficPercent ?? 0) !== 0 ||
    Number(guard.businessWriteTrafficPercent ?? 0) !== 0 ||
    guard.externalChannelsEnabled !== false ||
    Number(guard.roleCount) !== 22 ||
    lower(guard.controlStateFingerprintSha256) !==
      lower(currentControlFingerprintSha256)
  ) {
    fail('guard_not_exact_monitor_only_revision_2');
  }
}

function validateExactMonitorOnlyMaster(master) {
  const exactMonitorMaster =
    master.masterEnabled === true &&
    master.emergencyReadOnly === false &&
    master.freeAiEnabled === true &&
    master.localAiEnabled === false &&
    master.paidCodeAiEnabled === false &&
    master.paidReasoningEnabled === false &&
    master.callAgentEnabled === false &&
    master.emailAgentEnabled === false &&
    master.customerWhatsAppAgentEnabled === false &&
    master.ownerWhatsAppAgentEnabled === false &&
    master.emergencyWhatsAppAgentEnabled === false &&
    master.voiceSuperAdminAgentEnabled === false &&
    master.approvalEngineEnabled === true &&
    master.auditLoggingEnabled === true &&
    master.askBeforePaid === true;

  if (!exactMonitorMaster) {
    fail('master_not_exact_monitor_only_target');
  }
}

async function validateImmutableHistoricalEvidence({
  tx,
  db,
  master,
  rollout,
  guard,
  currentRoleSha,
  proposedRoleSha,
}) {
  validateExactMonitorOnlyMaster(master);

  if (
    rollout.appChatOnly !== true ||
    rollout.providerClass !== 'FREE_AI_ONLY'
  ) {
    fail('rollout_extended_monitor_only_boundary_mismatch');
  }

  if (
    guard.guardVersion !== 'MONITOR_ONLY_GUARD_V1' ||
    guard.appChatOnly !== true
  ) {
    fail('guard_extended_monitor_only_boundary_mismatch');
  }

  const activationId =
    norm(rollout.activationId);

  if (!activationId) {
    fail('historical_activation_id_missing');
  }

  const activationRef =
    db
      .collection('agent_production_rollout_activations')
      .doc(activationId);

  const activationSnap =
    await tx.get(activationRef);

  if (!activationSnap.exists) {
    fail('historical_activation_receipt_missing');
  }

  const activation =
    activationSnap.data() ?? {};

  const tokenSha =
    lower(activation.armingTokenIdSha256);

  if (!isSha256(tokenSha)) {
    fail('historical_arming_token_sha_invalid');
  }

  const tokenRef =
    db
      .collection('agent_production_rollout_arming_tokens')
      .doc(tokenSha);

  const tokenSnap =
    await tx.get(tokenRef);

  if (!tokenSnap.exists) {
    fail('historical_arming_token_missing');
  }

  const token =
    tokenSnap.data() ?? {};

  if (
    activation.status !== 'APPLIED' ||
    activation.targetStage !== 'MONITOR_ONLY' ||
    activation.armingTokenConsumed !== true ||
    Number(activation.autoTrafficPercent ?? 0) !== 0 ||
    Number(activation.businessWriteTrafficPercent ?? 0) !== 0 ||
    activation.externalChannelsEnabled !== false
  ) {
    fail('historical_activation_receipt_not_exact_monitor_only');
  }

  if (
    token.status !== 'CONSUMED' ||
    token.consumedAt == null ||
    lower(token.tokenIdSha256) !== tokenSha ||
    token.targetStage !== 'MONITOR_ONLY' ||
    token.guardVersion !== 'MONITOR_ONLY_GUARD_V1'
  ) {
    fail('historical_arming_token_not_exact_consumed');
  }

  const guardRevision =
    Number(guard.revision);

  if (
    guardRevision !== 2 ||
    Number(rollout.guardRevision) !== 2 ||
    Number(activation.guardRevision) !== 2 ||
    Number(token.guardRevision) !== 2
  ) {
    fail('historical_guard_revision_binding_mismatch');
  }

  if (
    Number(guard.roleCount) !== CURRENT_ROLE_COUNT ||
    Number(token.roleCount) !== CURRENT_ROLE_COUNT
  ) {
    fail('historical_role_count_binding_mismatch');
  }

  const rolloutControlSha =
    lower(rollout.sourceControlStateFingerprintSha256);

  const guardControlSha =
    lower(guard.controlStateFingerprintSha256);

  const activationControlSha =
    lower(activation.sourceControlStateFingerprintSha256);

  const tokenControlSha =
    lower(token.controlStateFingerprintSha256);

  if (
    rolloutControlSha !== EXPECTED_PRE_MIGRATION_CONTROL_SHA256 ||
    guardControlSha !== rolloutControlSha ||
    activationControlSha !== rolloutControlSha ||
    tokenControlSha !== rolloutControlSha
  ) {
    fail('historical_control_sha_binding_mismatch');
  }

  const guardPlanSha =
    lower(guard.planFingerprintSha256);

  const activationPlanSha =
    lower(activation.planFingerprintSha256);

  const tokenPlanSha =
    lower(token.planFingerprintSha256);

  if (
    !isSha256(guardPlanSha) ||
    activationPlanSha !== guardPlanSha ||
    tokenPlanSha !== guardPlanSha
  ) {
    fail('historical_plan_sha_binding_mismatch');
  }

  const guardActorSha =
    lower(guard.actorReferenceSha256);

  const activationActorSha =
    lower(activation.actorReferenceSha256);

  const tokenActorSha =
    lower(token.actorReferenceSha256);

  if (
    !isSha256(guardActorSha) ||
    activationActorSha !== guardActorSha ||
    tokenActorSha !== guardActorSha
  ) {
    fail('historical_owner_actor_sha_binding_mismatch');
  }

  const guardApprovalId =
    norm(guard.ownerApprovalId);

  const rolloutApprovalId =
    norm(rollout.ownerApprovalId);

  const activationApprovalId =
    norm(activation.ownerApprovalId);

  const tokenApprovalId =
    norm(token.ownerApprovalId);

  if (
    !guardApprovalId ||
    rolloutApprovalId !== guardApprovalId ||
    activationApprovalId !== guardApprovalId ||
    tokenApprovalId !== guardApprovalId
  ) {
    fail('historical_owner_approval_binding_mismatch');
  }

  const tZPreconditionEvidence = {
    projectId: PHASE66_PROJECT_ID,
    currentRoleInventorySha256:
      lower(currentRoleSha),
    proposedRoleInventorySha256:
      lower(proposedRoleSha),
    currentMasterSafetyClass:
      'EXACT_MONITOR_ONLY_TARGET',
    rollout: {
      stage: rollout.stage,
      autoTrafficPercent:
        Number(rollout.autoTrafficPercent ?? 0),
      businessWriteTrafficPercent:
        Number(rollout.businessWriteTrafficPercent ?? 0),
      appChatOnly: rollout.appChatOnly === true,
      externalChannelsEnabled:
        rollout.externalChannelsEnabled === true,
      providerClass:
        norm(rollout.providerClass),
    },
    guard: {
      enabled: guard.enabled === true,
      guardVersion:
        norm(guard.guardVersion),
      revision: guardRevision,
      targetStage:
        norm(guard.targetStage),
      roleCount:
        Number(guard.roleCount),
      runtimeMonitorOnlyOverlayEnforced:
        guard.runtimeMonitorOnlyOverlayEnforced === true,
      noAutoBusinessWriteBoundaryEnforced:
        guard.noAutoBusinessWriteBoundaryEnforced === true,
    },
    immutableHistoricalBinding: {
      sourceControlStateFingerprintSha256:
        rolloutControlSha,
      planFingerprintSha256:
        guardPlanSha,
      actorReferenceSha256:
        guardActorSha,
      approvalIdSha256:
        sha256Hex(guardApprovalId),
      activationIdSha256:
        sha256Hex(activationId),
      armingTokenIdSha256:
        tokenSha,
      activationStatus:
        norm(activation.status),
      armingTokenStatus:
        norm(token.status),
    },
  };

  const tZEvidenceSha =
    stableSha256(tZPreconditionEvidence);

  if (tZEvidenceSha !== EXPECTED_TZ_EVIDENCE_SHA256) {
    fail('historical_tz_precondition_evidence_sha_mismatch');
  }

  return true;
}
function bootstrapAuditData({
  approvalId,
  actorReferenceSha256,
  migrationIdSha256,
  currentInventoryFingerprintSha256,
  proposedInventoryFingerprintSha256,
  currentControlFingerprintSha256,
  ownerApprovalBindingSha256,
  serverTimestamp,
}) {
  return {
    eventType: 'SYSTEM_EVENT',
    severity: 'WARNING',
    actorType: 'ADMIN',
    actorId: actorReferenceSha256,
    module: 'ai_core',
    actionId:
      'ai.production_rollout.role_inventory.bootstrap_22_to_23',
    result: 'MIGRATION_HOLD_HELD',
    reason:
      'Owner-bound 22-to-23 role inventory migration manifest and fail-closed hold bootstrapped.',
    relatedApprovalId: approvalId,
    scope: {
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
    },
    createdAt: serverTimestamp(),
  };
}

function migrationAuditData({
  approvalId,
  actorReferenceSha256,
  migrationIdSha256,
  serverTimestamp,
}) {
  return {
    eventType: 'SYSTEM_EVENT',
    severity: 'WARNING',
    actorType: 'ADMIN',
    actorId: actorReferenceSha256,
    module: 'ai_core',
    actionId:
      'ai.production_rollout.role_inventory.migrate_22_to_23',
    result: 'ROLE_DELTA_COMMITTED',
    reason:
      'Fresh Owner-bound approval consumed atomically with disabled 22-to-23 role delta under migration hold.',
    relatedApprovalId: approvalId,
    scope: {
      currentInventoryVersion: CURRENT_INVENTORY_VERSION,
      proposedInventoryVersion: PROPOSED_INVENTORY_VERSION,
      currentRoleCount: CURRENT_ROLE_COUNT,
      proposedRoleCount: PROPOSED_ROLE_COUNT,
      migrationIdSha256,
      postMigrationRebindRequired: true,
      migrationHoldActive: true,
      repositoryAttachAuthorized: false,
      repositoryArmAuthorized: false,
      firstIncidentWriteAuthorized: false,
      authorizesSuggestOnly: false,
      authorizesAuto: false,
      guardRevision: 2,
    },
    createdAt: serverTimestamp(),
  };
}

async function createAdminContext(config) {
  if (
    config.allowAdminSdkInit !== true ||
    config.allowCredentialLoad !== true ||
    config.allowNetworkRead !== true
  ) {
    fail('admin_context_not_authorized');
  }

  const [
    appModule,
    firestoreModule,
  ] = await Promise.all([
    import('firebase-admin/app'),
    import('firebase-admin/firestore'),
  ]);

  const app = appModule.initializeApp(
    {
      credential: appModule.applicationDefault(),
      projectId: PHASE66_PROJECT_ID,
    },
    `phase66-step1i-trusted-executor-${Date.now()}`,
  );

  const db = firestoreModule.getFirestore(app);

  return {
    app,
    db,
    deleteApp: appModule.deleteApp,
    FieldValue: firestoreModule.FieldValue,
  };
}

export async function executeTrustedBootstrap({
  config = LIVE_EXECUTOR_DEFAULTS,
  approvalId,
  expectedBindingSha256,
  migrationIdSha256,
  actorReferenceSha256,
}) {
  assertBootstrapArmed(config);

  if (
    !norm(approvalId) ||
    !isSha256(expectedBindingSha256) ||
    !isSha256(migrationIdSha256) ||
    !isSha256(actorReferenceSha256)
  ) {
    fail('bootstrap_input_binding_invalid');
  }

  const context = await createAdminContext(config);

  try {
    const { db, FieldValue } = context;

    const result =
      await db.runTransaction(async (tx) => {
        const approvals =
          db.collection(AGENT_APPROVALS);

        const roles =
          db.collection(AGENT_ROLES);

        const settings =
          db.collection(AGENT_SETTINGS);

        const audit =
          db.collection(AGENT_AUDIT_LOGS).doc();

        const approvalRef =
          approvals.doc(approvalId);

        const targetRoleRef =
          roles.doc(SECURITY_INCIDENT_ROLE_ID);

        const masterRef =
          settings.doc(MASTER_DOC);

        const rolloutRef =
          settings.doc(ROLLOUT_DOC);

        const guardRef =
          settings.doc(GUARD_DOC);

        const manifestRef =
          settings.doc(AUTHORITY_MANIFEST_DOCUMENT);

        const holdRef =
          settings.doc(MIGRATION_HOLD_DOCUMENT);

        const [
          approvalSnap,
          targetRoleSnap,
          masterSnap,
          rolloutSnap,
          guardSnap,
          manifestSnap,
          holdSnap,
          rolesSnap,
        ] = await Promise.all([
          tx.get(approvalRef),
          tx.get(targetRoleRef),
          tx.get(masterRef),
          tx.get(rolloutRef),
          tx.get(guardRef),
          tx.get(manifestRef),
          tx.get(holdRef),
          tx.get(roles.orderBy('__name__')),
        ]);

        if (manifestSnap.exists || holdSnap.exists) {
          fail('bootstrap_manifest_or_hold_already_exists');
        }

        if (targetRoleSnap.exists) {
          fail('bootstrap_target_role_already_exists');
        }

        const approval =
          normalizeApproval(approvalSnap);

        validateFreshApprovedMigrationApproval(
          approval,
          Date.now(),
          expectedBindingSha256,
          actorReferenceSha256,
          MIN_BOOTSTRAP_APPROVAL_REMAINING_MS,
        );

        const currentRoles =
          roleDocumentsToMaps(rolesSnap);

        if (currentRoles.length !== 22) {
          fail('bootstrap_live_role_count_not_22');
        }

        const currentFingerprint =
          roleInventoryFingerprint(currentRoles);

        const proposedFingerprint =
          proposedInventoryFingerprint(currentRoles);

        if (
          lower(currentFingerprint) !==
            EXPECTED_CURRENT_INVENTORY_SHA256 ||
          lower(proposedFingerprint) !==
            EXPECTED_PROPOSED_INVENTORY_SHA256
        ) {
          fail('bootstrap_live_ty_inventory_not_exact_locked_snapshot');
        }

        const scope =
          approval.actionScope;

        if (
          lower(scope.currentInventoryFingerprintSha256) !==
            lower(currentFingerprint) ||
          lower(scope.proposedInventoryFingerprintSha256) !==
            lower(proposedFingerprint)
        ) {
          fail('bootstrap_live_inventory_fingerprint_mismatch');
        }

        const rollout =
          rolloutSnap.data() ?? {};

        const guard =
          guardSnap.data() ?? {};

        validateMonitorOnlyBoundary(
          rollout,
          guard,
          scope.currentControlFingerprintSha256,
        );

        await validateImmutableHistoricalEvidence({
          tx,
          db,
          master: masterSnap.data() ?? {},
          rollout,
          guard,
          currentRoleSha: currentFingerprint,
          proposedRoleSha: proposedFingerprint,
        });

        const evidence = {
          projectId: PHASE66_PROJECT_ID,
          rolloutStage: 'MONITOR_ONLY',
          guardRevision: 2,
          guardRoleCount: 22,
          freshTrustedLiveInventoryRead: true,
          freshOwnerVerified: true,
          ownerApprovalBound: true,
          clientSecurityRoleWritesDenied: true,
          clientManifestWritesDenied: true,
          clientMigrationHoldWritesDenied: true,
          oldGuardImmutable: true,
          oldArmingTokenImmutable: true,
          oldActivationReceiptImmutable: true,
          sameTransactionAuditReady: true,
          dedicatedRoleAbsent: true,
          approvalStatus: 'APPROVED',
          approvalExpired: false,
          approvalConsumed: false,
          ownerApprovalId: approvalId,
          ownerApprovalBindingSha256:
            expectedBindingSha256,
          migrationIdSha256,
          currentInventoryFingerprintSha256:
            currentFingerprint,
          proposedInventoryFingerprintSha256:
            proposedFingerprint,
          currentControlFingerprintSha256:
            scope.currentControlFingerprintSha256,
          actorReferenceSha256,
          exactCurrentRoleIds:
            exactRoleIds(currentRoles),
          existingActivationTokenReuseAllowed: false,
        };

        const plan =
          buildTrustedBootstrapPlan(evidence);

        tx.create(
          manifestRef,
          {
            ...plan.authorityManifest,
            updatedAt: FieldValue.serverTimestamp(),
          },
        );

        tx.create(
          holdRef,
          {
            ...plan.migrationHold,
            updatedAt: FieldValue.serverTimestamp(),
          },
        );

        tx.create(
          audit,
          bootstrapAuditData({
            approvalId,
            actorReferenceSha256,
            migrationIdSha256,
            currentInventoryFingerprintSha256:
              currentFingerprint,
            proposedInventoryFingerprintSha256:
              proposedFingerprint,
            currentControlFingerprintSha256:
              scope.currentControlFingerprintSha256,
            ownerApprovalBindingSha256:
              expectedBindingSha256,
            serverTimestamp:
              FieldValue.serverTimestamp,
          }),
        );

        return {
          status: 'BOOTSTRAP_COMMITTED',
          manifestRevision: 1,
          migrationHoldStatus: 'HELD',
          roleCreated: false,
          approvalConsumed: false,
          currentRoleCount: 22,
        };
      });

    return result;
  } finally {
    await context.deleteApp(context.app);
  }
}

export async function executeAtomicMigration({
  config = LIVE_EXECUTOR_DEFAULTS,
  approvalId,
  expectedBindingSha256,
  migrationIdSha256,
  actorReferenceSha256,
}) {
  assertMigrationArmed(config);

  if (
    !norm(approvalId) ||
    !isSha256(expectedBindingSha256) ||
    !isSha256(migrationIdSha256) ||
    !isSha256(actorReferenceSha256)
  ) {
    fail('migration_input_binding_invalid');
  }

  const context = await createAdminContext(config);

  try {
    const { db, FieldValue } = context;

    const result =
      await db.runTransaction(async (tx) => {
        const approvals =
          db.collection(AGENT_APPROVALS);

        const roles =
          db.collection(AGENT_ROLES);

        const settings =
          db.collection(AGENT_SETTINGS);

        const audit =
          db.collection(AGENT_AUDIT_LOGS).doc();

        const approvalRef =
          approvals.doc(approvalId);

        const targetRoleRef =
          roles.doc(SECURITY_INCIDENT_ROLE_ID);

        const masterRef =
          settings.doc(MASTER_DOC);

        const rolloutRef =
          settings.doc(ROLLOUT_DOC);

        const guardRef =
          settings.doc(GUARD_DOC);

        const manifestRef =
          settings.doc(AUTHORITY_MANIFEST_DOCUMENT);

        const holdRef =
          settings.doc(MIGRATION_HOLD_DOCUMENT);

        const [
          approvalSnap,
          targetRoleSnap,
          masterSnap,
          rolloutSnap,
          guardSnap,
          manifestSnap,
          holdSnap,
          rolesSnap,
        ] = await Promise.all([
          tx.get(approvalRef),
          tx.get(targetRoleRef),
          tx.get(masterRef),
          tx.get(rolloutRef),
          tx.get(guardRef),
          tx.get(manifestRef),
          tx.get(holdRef),
          tx.get(roles.orderBy('__name__')),
        ]);

        if (!manifestSnap.exists || !holdSnap.exists) {
          fail('migration_manifest_and_hold_required');
        }

        if (targetRoleSnap.exists) {
          fail('migration_target_role_collision');
        }

        const approval =
          normalizeApproval(approvalSnap);

        validateFreshApprovedMigrationApproval(
          approval,
          Date.now(),
          expectedBindingSha256,
          actorReferenceSha256,
          MIN_MIGRATION_APPROVAL_REMAINING_MS,
        );

        const currentRoles =
          roleDocumentsToMaps(rolesSnap);

        if (currentRoles.length !== 22) {
          fail('migration_live_role_count_not_22');
        }

        const currentFingerprint =
          roleInventoryFingerprint(currentRoles);

        const proposedFingerprint =
          proposedInventoryFingerprint(currentRoles);

        if (
          lower(currentFingerprint) !==
            EXPECTED_CURRENT_INVENTORY_SHA256 ||
          lower(proposedFingerprint) !==
            EXPECTED_PROPOSED_INVENTORY_SHA256
        ) {
          fail('migration_live_ty_inventory_not_exact_locked_snapshot');
        }

        const scope =
          approval.actionScope;

        if (
          lower(scope.currentInventoryFingerprintSha256) !==
            lower(currentFingerprint) ||
          lower(scope.proposedInventoryFingerprintSha256) !==
            lower(proposedFingerprint)
        ) {
          fail('migration_live_inventory_fingerprint_mismatch');
        }

        const rollout =
          rolloutSnap.data() ?? {};

        const guard =
          guardSnap.data() ?? {};

        validateMonitorOnlyBoundary(
          rollout,
          guard,
          scope.currentControlFingerprintSha256,
        );

        await validateImmutableHistoricalEvidence({
          tx,
          db,
          master: masterSnap.data() ?? {},
          rollout,
          guard,
          currentRoleSha: currentFingerprint,
          proposedRoleSha: proposedFingerprint,
        });

        const manifest =
          manifestSnap.data() ?? {};

        const hold =
          holdSnap.data() ?? {};

        const evidence = {
          projectId: PHASE66_PROJECT_ID,
          rolloutStage: 'MONITOR_ONLY',
          guardRevision: 2,
          guardRoleCount: 22,
          autoTrafficPercent: 0,
          businessWriteTrafficPercent: 0,
          externalChannelsEnabled: false,
          runtimeMonitorOnlyOverlayEnforced: true,
          noAutoBusinessWriteBoundaryEnforced: true,

          freshTrustedLiveInventoryRead: true,
          dedicatedRoleAbsent: true,
          requesterApproverSeparated:
            Boolean(approval.decidedBy) &&
            approval.decidedBy !== approval.requestedBy,
          freshOwnerDecisionVerified: true,
          migrationRulesVerified: true,

          oldGuardImmutable: true,
          oldArmingTokenImmutable: true,
          oldActivationReceiptImmutable: true,
          existingArmingTokenReuseAllowed: false,

          migrationIdSha256,
          actorReferenceSha256,
          currentControlFingerprintSha256:
            scope.currentControlFingerprintSha256,

          currentRoles,
          currentInventoryFingerprintSha256:
            currentFingerprint,
          proposedInventoryFingerprintSha256:
            proposedFingerprint,

          approval: {
            approvalId,
            status: 'APPROVED',
            expired: false,
            consumed: false,
            operation: scope.operation,
            roleId: approval.roleId,
            actionId: approval.actionId,
            module: approval.module,
            bindingFingerprintSha256:
              expectedBindingSha256,
          },

          authorityManifest: manifest,
          migrationHold: hold,
        };

        const plan =
          buildAtomicMigrationExecutionPlan(evidence);

        tx.update(
          approvalRef,
          {
            status: 'CONSUMED',
            consumedAt: FieldValue.serverTimestamp(),
          },
        );

        tx.create(
          targetRoleRef,
          {
            ...plan.transaction.write2CreateDisabledRole,
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          },
        );

        tx.set(
          manifestRef,
          {
            ...plan.transaction.write3AuthorityManifestPatch,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: false },
        );

        tx.set(
          holdRef,
          {
            ...hold,
            ...plan.transaction.write4MigrationHoldPatch,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: false },
        );

        tx.create(
          audit,
          migrationAuditData({
            approvalId,
            actorReferenceSha256,
            migrationIdSha256,
            serverTimestamp:
              FieldValue.serverTimestamp,
          }),
        );

        return {
          status: 'ROLE_DELTA_COMMITTED',
          approvalConsumed: true,
          roleCount: 23,
          roleEnabled: false,
          manifestRevision: 2,
          migrationHoldActive: true,
          postMigrationRebindRequired: true,
        };
      });

    return result;
  } finally {
    await context.deleteApp(context.app);
  }
}

export async function executePostMigrationRebind({
  config = LIVE_EXECUTOR_DEFAULTS,
  approvalId,
  migrationApprovalId,
  requesterReferenceSha256,
  ownerApproverReferenceSha256,
  freshTokenIdSha256,
  receiptIdSha256,
}) {
  assertPostMigrationRebindArmed(config);

  if (
    !norm(approvalId) ||
    !norm(migrationApprovalId) ||
    approvalId === migrationApprovalId ||
    !isSha256(requesterReferenceSha256) ||
    !isSha256(ownerApproverReferenceSha256) ||
    !isSha256(freshTokenIdSha256) ||
    !isSha256(receiptIdSha256) ||
    lower(requesterReferenceSha256) === lower(ownerApproverReferenceSha256)
  ) {
    fail('post_migration_rebind_input_binding_invalid');
  }

  const context = await createAdminContext(config);

  try {
    const { db, FieldValue } = context;

    const result =
      await db.runTransaction(async (tx) => {
        const approvals =
          db.collection(AGENT_APPROVALS);

        const roles =
          db.collection(AGENT_ROLES);

        const settings =
          db.collection(AGENT_SETTINGS);

        const auditLogs =
          db.collection(AGENT_AUDIT_LOGS);

        const armingTokens =
          db.collection('agent_production_rollout_arming_tokens');

        const activations =
          db.collection('agent_production_rollout_activations');

        const rebindReceipts =
          db.collection(REBIND_CONTRACT.receiptCollection);

        const approvalRef =
          approvals.doc(approvalId);

        const migrationApprovalRef =
          approvals.doc(migrationApprovalId);

        const masterRef =
          settings.doc(MASTER_DOC);

        const rolloutRef =
          settings.doc(ROLLOUT_DOC);

        const guardRef =
          settings.doc(GUARD_DOC);

        const manifestRef =
          settings.doc(AUTHORITY_MANIFEST_DOCUMENT);

        const holdRef =
          settings.doc(MIGRATION_HOLD_DOCUMENT);

        const targetRoleRef =
          roles.doc(SECURITY_INCIDENT_ROLE_ID);

        const freshTokenRef =
          armingTokens.doc(lower(freshTokenIdSha256));

        const receiptRef =
          rebindReceipts.doc(lower(receiptIdSha256));

        const auditRef =
          auditLogs.doc();

        // Pre-read only what the canonical wrapper itself must derive. No write
        // occurs here. T-AM-W will re-read its full evidence set before write 1.
        const [
          masterSnap,
          rolloutSnap,
          rolesSnap,
        ] = await Promise.all([
          tx.get(masterRef),
          tx.get(rolloutRef),
          tx.get(roles.orderBy('__name__')),
        ]);

        if (!masterSnap.exists || !rolloutSnap.exists) {
          fail('post_migration_rebind_control_source_missing');
        }

        const master =
          masterSnap.data() ?? {};

        const rollout =
          rolloutSnap.data() ?? {};

        validateExactMonitorOnlyMaster(master);

        const currentRoles =
          roleDocumentsToMaps(rolesSnap);

        if (currentRoles.length !== REBIND_CONTRACT.targetRoleCount) {
          fail('post_migration_rebind_live_role_count_not_23');
        }

        const currentInventorySha =
          roleInventoryFingerprint(currentRoles);

        if (
          lower(currentInventorySha) !==
          lower(REBIND_CONTRACT.lockedRoleInventoryFingerprintSha256)
        ) {
          fail('post_migration_rebind_live_inventory_not_exact_locked_23_role');
        }

        const controlStateSha =
          postMigrationControlStateFingerprint({
            master,
            roles: currentRoles,
          });

        if (!isSha256(controlStateSha)) {
          fail('post_migration_rebind_control_state_sha_invalid');
        }

        const rebindPlanSha =
          postMigrationRebindPlanFingerprint({
            contract: REBIND_CONTRACT,
            approvalId,
            migrationApprovalId,
            requesterReferenceSha256,
            ownerApproverReferenceSha256,
            postMigrationControlStateFingerprintSha256:
              controlStateSha,
            freshTokenIdSha256,
            receiptIdSha256,
          });

        const historicalActivationId =
          norm(rollout.activationId);

        if (!historicalActivationId) {
          fail('post_migration_rebind_historical_activation_id_missing');
        }

        const oldActivationRef =
          activations.doc(historicalActivationId);

        const oldActivationSnap =
          await tx.get(oldActivationRef);

        if (!oldActivationSnap.exists) {
          fail('post_migration_rebind_historical_activation_missing');
        }

        const oldActivation =
          oldActivationSnap.data() ?? {};

        const oldTokenSha =
          lower(oldActivation.armingTokenIdSha256);

        if (!isSha256(oldTokenSha)) {
          fail('post_migration_rebind_historical_token_sha_invalid');
        }

        const oldTokenRef =
          armingTokens.doc(oldTokenSha);

        const nowMs = Date.now();
        const issuedAt = new Date(nowMs);
        const expiresAt = new Date(
          nowMs + REBIND_CONTRACT.maxFreshTokenValidityMs,
        );

        const request = {
          approvalId,
          migrationApprovalId,
          requesterReferenceSha256:
            lower(requesterReferenceSha256),
          ownerApproverReferenceSha256:
            lower(ownerApproverReferenceSha256),
          postMigrationControlStateFingerprintSha256:
            controlStateSha,
          rebindPlanFingerprintSha256:
            rebindPlanSha,
          freshTokenIdSha256:
            lower(freshTokenIdSha256),
          receiptIdSha256:
            lower(receiptIdSha256),
          nowMs,
          issuedAt,
          expiresAt,
          newGuard: {
            enabled: true,
            guardVersion: REBIND_CONTRACT.guardVersion,
            revision: REBIND_CONTRACT.targetGuardRevision,
            targetStage: REBIND_CONTRACT.rolloutStage,
            runtimeMonitorOnlyOverlayEnforced: true,
            noAutoBusinessWriteBoundaryEnforced: true,
            appChatOnly: true,
            autoTrafficPercent: 0,
            businessWriteTrafficPercent: 0,
            externalChannelsEnabled: false,
            controlStateFingerprintSha256:
              controlStateSha,
            planFingerprintSha256:
              rebindPlanSha,
            roleCount: REBIND_CONTRACT.targetRoleCount,
            ownerApprovalId: approvalId,
            actorReferenceSha256:
              lower(ownerApproverReferenceSha256),
          },
        };

        const refs = {
          approval: approvalRef,
          migrationApproval: migrationApprovalRef,
          manifest: manifestRef,
          hold: holdRef,
          guard: guardRef,
          rollout: rolloutRef,
          master: masterRef,
          role: targetRoleRef,
          oldActivation: oldActivationRef,
          oldToken: oldTokenRef,
          freshToken: freshTokenRef,
          receipt: receiptRef,
          audit: auditRef,
        };

        return executePostMigrationRebindInCallerTransaction({
          tx,
          refs,
          request,
          serverTimestamp:
            FieldValue.serverTimestamp,
          executionArmed: true,
          trustedCallerIntegrated: true,
        });
      });

    return result;
  } finally {
    await context.deleteApp(context.app);
  }
}

export const LIVE_EXECUTOR_CONTRACT = Object.freeze({
  projectId: PHASE66_PROJECT_ID,
  defaultExecutionArmed: false,
  bootstrapExecutionWord:
    'PHASE66_BOOTSTRAP_MANIFEST_HOLD_ONLY',
  migrationExecutionWord:
    'PHASE66_ATOMIC_MIGRATION_22_TO_23_ONLY',
  postMigrationRebindExecutionWord:
    'PHASE66_POST_MIGRATION_REBIND_23_ROLE_ONLY',
  bootstrapConsumesApproval: false,
  migrationConsumesApproval: true,
  postMigrationRebindConsumesApproval: true,
  postMigrationRebindExactWrites: 6,
  postMigrationRebindRecomputesControlFingerprint: true,
  postMigrationRebindRecomputesPlanFingerprint: true,
  postMigrationRebindCreatesFreshTokenReady: true,
  postMigrationRebindCreatesReceipt: true,
  postMigrationRebindWritesAuditSameTransaction: true,
  migrationCreatesRoleEnabled: false,
  migrationReleasesHold: false,
  postMigrationRebindEnablesRole: false,
  postMigrationRebindReleasesHold: false,
  writesOldGuard: false,
  writesOldArmingToken: false,
  writesOldActivationReceipt: false,
  repositoryAttachAuthorized: false,
  repositoryArmAuthorized: false,
  firstIncidentWriteAuthorized: false,
  suggestOnlyAuthorized: false,
  autoAuthorized: false,
});
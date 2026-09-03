import {
  CURRENT_ROLE_COUNT,
  LOCKED_ROLLOUT_STAGE,
  PHASE66_PROJECT_ID,
  SECURITY_INCIDENT_ROLE_ID,
  assertOfflineSafety,
} from './contract.mjs';

import {
  proposedInventoryFingerprint,
  roleInventoryFingerprint,
} from './fingerprint.mjs';

const sha256Pattern = /^[0-9a-f]{64}$/;

function isSha256(value) {
  return sha256Pattern.test(String(value ?? '').trim().toLowerCase());
}

export function validateDryRunEvidence(evidence) {
  assertOfflineSafety();

  const errors = [];

  if (evidence.projectId !== PHASE66_PROJECT_ID) {
    errors.push('project_id_mismatch');
  }

  if (evidence.rolloutStage !== LOCKED_ROLLOUT_STAGE) {
    errors.push('rollout_must_remain_monitor_only');
  }

  if (!Array.isArray(evidence.currentRoles)) {
    errors.push('current_roles_missing');
    return {
      ok: false,
      errors,
      computed: {},
    };
  }

  if (evidence.currentRoles.length !== CURRENT_ROLE_COUNT) {
    errors.push('current_role_count_must_be_22');
  }

  const roleIds = evidence.currentRoles.map((role) =>
    String(role.roleId ?? '').trim(),
  );

  if (new Set(roleIds).size !== roleIds.length) {
    errors.push('current_role_ids_not_unique');
  }

  if (roleIds.includes(SECURITY_INCIDENT_ROLE_ID)) {
    errors.push('security_incident_role_must_be_absent');
  }

  if (roleIds.some((roleId) => roleId.length === 0)) {
    errors.push('empty_role_id');
  }

  if (evidence.freshTrustedLiveInventoryRead !== true) {
    errors.push('fresh_trusted_live_inventory_read_required');
  }

  if (evidence.freshOwnerVerified !== true) {
    errors.push('fresh_owner_verification_required');
  }

  if (evidence.ownerApprovalBound !== true) {
    errors.push('owner_approval_binding_required');
  }

  if (
    typeof evidence.ownerApprovalId !== 'string' ||
    evidence.ownerApprovalId.trim().length === 0
  ) {
    errors.push('owner_approval_id_required');
  }

  if (!isSha256(evidence.ownerApprovalBindingSha256)) {
    errors.push('owner_approval_binding_sha256_invalid');
  }

  if (!isSha256(evidence.currentControlFingerprintSha256)) {
    errors.push('current_control_fingerprint_invalid');
  }

  if (evidence.oldGuardImmutable !== true) {
    errors.push('old_guard_must_remain_immutable');
  }

  if (evidence.oldArmingTokenImmutable !== true) {
    errors.push('old_arming_token_must_remain_immutable');
  }

  if (evidence.oldActivationReceiptImmutable !== true) {
    errors.push('old_activation_receipt_must_remain_immutable');
  }

  if (evidence.existingActivationTokenReuseAllowed !== false) {
    errors.push('existing_activation_token_reuse_forbidden');
  }

  if (evidence.repositoryAttachAuthorized !== false) {
    errors.push('repository_attach_must_remain_false');
  }

  if (evidence.repositoryArmAuthorized !== false) {
    errors.push('repository_arm_must_remain_false');
  }

  if (evidence.firstIncidentWriteAuthorized !== false) {
    errors.push('first_incident_write_must_remain_false');
  }

  if (evidence.authorizesSuggestOnly !== false) {
    errors.push('suggest_only_must_remain_false');
  }

  if (evidence.authorizesAuto !== false) {
    errors.push('auto_must_remain_false');
  }

  const currentFingerprint =
    evidence.currentRoles.length === CURRENT_ROLE_COUNT
      ? roleInventoryFingerprint(evidence.currentRoles)
      : null;

  const proposedFingerprint =
    evidence.currentRoles.length === CURRENT_ROLE_COUNT
      ? proposedInventoryFingerprint(evidence.currentRoles)
      : null;

  if (
    currentFingerprint &&
    evidence.expectedCurrentInventoryFingerprintSha256 !== currentFingerprint
  ) {
    errors.push('current_inventory_fingerprint_mismatch');
  }

  if (
    proposedFingerprint &&
    evidence.expectedProposedInventoryFingerprintSha256 !== proposedFingerprint
  ) {
    errors.push('proposed_inventory_fingerprint_mismatch');
  }

  return {
    ok: errors.length === 0,
    errors,
    computed: {
      currentInventoryFingerprintSha256: currentFingerprint,
      proposedInventoryFingerprintSha256: proposedFingerprint,
      currentRoleCount: evidence.currentRoles.length,
      proposedRoleCount:
        evidence.currentRoles.length === CURRENT_ROLE_COUNT ? 23 : null,
    },
  };
}
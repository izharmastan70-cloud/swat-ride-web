import test from 'node:test';
import assert from 'node:assert/strict';

import {
  AUTHORITY_MANIFEST_REQUIRED_FIELDS,
  MIGRATION_HOLD_REQUIRED_FIELDS,
  TRUSTED_BOOTSTRAP_SAFETY,
  assertTrustedBootstrapContractDisarmed,
  buildTrustedBootstrapPlan,
} from '../src/trusted_bootstrap_execution_contract.mjs';

const shaA = 'a'.repeat(64);
const shaB = 'b'.repeat(64);
const shaC = 'c'.repeat(64);
const shaD = 'd'.repeat(64);
const shaE = 'e'.repeat(64);

function exact22RoleIds() {
  return Array.from(
    { length: 22 },
    (_, index) => `existing_role_${String(index + 1).padStart(2, '0')}`,
  );
}

function validEvidence() {
  return {
    projectId: 'swat-ride-v2',
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
    ownerApprovalId: 'future-fresh-owner-approval',
    ownerApprovalBindingSha256: shaA,
    migrationIdSha256: shaB,
    currentInventoryFingerprintSha256: shaC,
    proposedInventoryFingerprintSha256: shaD,
    currentControlFingerprintSha256: shaE,
    actorReferenceSha256: shaA,
    exactCurrentRoleIds: exact22RoleIds(),
    existingActivationTokenReuseAllowed: false,
  };
}

test('trusted bootstrap contract is permanently offline/disarmed in T-AK-P', () => {
  assert.equal(assertTrustedBootstrapContractDisarmed(), true);
  assert.equal(TRUSTED_BOOTSTRAP_SAFETY.executionArmed, false);
  assert.equal(TRUSTED_BOOTSTRAP_SAFETY.networkReadEnabled, false);
  assert.equal(TRUSTED_BOOTSTRAP_SAFETY.networkWriteEnabled, false);
  assert.equal(TRUSTED_BOOTSTRAP_SAFETY.adminSdkInitializationEnabled, false);
  assert.equal(TRUSTED_BOOTSTRAP_SAFETY.approvalConsumptionEnabled, false);
  assert.equal(TRUSTED_BOOTSTRAP_SAFETY.roleDeltaEnabled, false);
  assert.equal(TRUSTED_BOOTSTRAP_SAFETY.roleEnableEnabled, false);
  assert.equal(TRUSTED_BOOTSTRAP_SAFETY.repositoryAttachEnabled, false);
  assert.equal(TRUSTED_BOOTSTRAP_SAFETY.repositoryArmEnabled, false);
  assert.equal(TRUSTED_BOOTSTRAP_SAFETY.suggestOnlyAuthorized, false);
  assert.equal(TRUSTED_BOOTSTRAP_SAFETY.autoAuthorized, false);
});

test('manifest and hold field lists exactly match locked Dart contract', () => {
  assert.deepEqual(AUTHORITY_MANIFEST_REQUIRED_FIELDS, [
    'status',
    'inventoryVersion',
    'roleCount',
    'roleProjectionFingerprintSha256',
    'revision',
    'postMigrationRebindRequired',
    'updatedAt',
  ]);

  assert.deepEqual(MIGRATION_HOLD_REQUIRED_FIELDS, [
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
});

test('valid evidence produces exact three-write bootstrap plan only', () => {
  const plan = buildTrustedBootstrapPlan(validEvidence());

  assert.equal(plan.executionArmed, false);
  assert.equal(plan.transaction.required, true);
  assert.equal(plan.transaction.exactWriteCount, 3);
  assert.equal(plan.transaction.authorityManifestCreate, true);
  assert.equal(plan.transaction.migrationHoldCreate, true);
  assert.equal(plan.transaction.auditCreate, true);
  assert.equal(plan.transaction.approvalConsumedInBootstrap, false);
  assert.equal(plan.transaction.roleCreatedInBootstrap, false);

  assert.equal(plan.authorityManifest.status, 'ACTIVE');
  assert.equal(plan.authorityManifest.inventoryVersion, 'phase66_roles_v1_22');
  assert.equal(plan.authorityManifest.roleCount, 22);
  assert.equal(plan.authorityManifest.revision, 1);
  assert.equal(plan.authorityManifest.postMigrationRebindRequired, false);

  assert.equal(plan.migrationHold.status, 'HELD');
  assert.equal(plan.migrationHold.expectedRoleCount, 22);
  assert.equal(plan.migrationHold.proposedRoleCount, 23);
  assert.equal(plan.migrationHold.expectedGuardRevision, 2);
  assert.equal(plan.migrationHold.targetRoleId, 'security_incident_agent');
  assert.equal(
    plan.migrationHold.targetActionId,
    'security_incident.attach_runtime',
  );
  assert.equal(plan.migrationHold.migrationHoldActive, true);
  assert.equal(plan.migrationHold.repositoryAttachAuthorized, false);
  assert.equal(plan.migrationHold.repositoryArmAuthorized, false);
  assert.equal(plan.migrationHold.firstIncidentWriteAuthorized, false);
  assert.equal(plan.migrationHold.authorizesSuggestOnly, false);
  assert.equal(plan.migrationHold.authorizesAuto, false);

  assert.equal(plan.paths.auditCollection, 'agent_audit_logs');
  assert.equal(plan.audit.eventType, 'SYSTEM_EVENT');
  assert.equal(plan.audit.severity, 'WARNING');
  assert.equal(plan.audit.actorType, 'ADMIN');

  assert.equal(plan.postconditions.roleDeltaExecuted, false);
  assert.equal(plan.postconditions.approvalConsumed, false);
  assert.equal(plan.postconditions.migrationHoldActive, true);
});

test('expired or consumed approval fails closed before any bootstrap plan', () => {
  assert.throws(
    () =>
      buildTrustedBootstrapPlan({
        ...validEvidence(),
        approvalExpired: true,
      }),
    /approval_expired_must_be_false/,
  );

  assert.throws(
    () =>
      buildTrustedBootstrapPlan({
        ...validEvidence(),
        approvalConsumed: true,
      }),
    /approval_consumed_must_be_false/,
  );
});

test('missing exact 22-role authority fails closed', () => {
  assert.throws(
    () =>
      buildTrustedBootstrapPlan({
        ...validEvidence(),
        exactCurrentRoleIds: ['only_one'],
      }),
    /exact_current_22_role_ids_invalid/,
  );

  const collision = exact22RoleIds();
  collision[0] = 'security_incident_agent';

  assert.throws(
    () =>
      buildTrustedBootstrapPlan({
        ...validEvidence(),
        exactCurrentRoleIds: collision,
      }),
    /exact_current_22_role_ids_invalid/,
  );
});

test('rollout, guard and client-write denial boundaries fail closed', () => {
  assert.throws(
    () =>
      buildTrustedBootstrapPlan({
        ...validEvidence(),
        rolloutStage: 'SUGGEST_ONLY',
      }),
    /rollout_must_remain_monitor_only/,
  );

  assert.throws(
    () =>
      buildTrustedBootstrapPlan({
        ...validEvidence(),
        guardRevision: 3,
      }),
    /bootstrap_requires_guard_revision_2/,
  );

  assert.throws(
    () =>
      buildTrustedBootstrapPlan({
        ...validEvidence(),
        clientManifestWritesDenied: false,
      }),
    /client_manifest_writes_denied_must_be_true/,
  );
});
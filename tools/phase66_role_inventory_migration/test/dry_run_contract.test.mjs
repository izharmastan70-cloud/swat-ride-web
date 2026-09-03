import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

import {
  CURRENT_ROLE_COUNT,
  PHASE66_PROJECT_ID,
  SAFETY,
  SECURITY_INCIDENT_ROLE_ID,
  assertOfflineSafety,
} from '../src/contract.mjs';

import {
  proposedInventoryFingerprint,
  roleInventoryFingerprint,
} from '../src/fingerprint.mjs';

import { validateDryRunEvidence } from '../src/validate_evidence.mjs';

const fixture = JSON.parse(
  await readFile(
    new URL('./fixtures/valid_dry_run_evidence.json', import.meta.url),
    'utf8',
  ),
);

test('offline safety is permanently fail-closed in T-Q', () => {
  assert.doesNotThrow(assertOfflineSafety);
  assert.equal(SAFETY.executionArmed, false);
  assert.equal(SAFETY.dryRunOnly, true);
  assert.equal(SAFETY.networkReadEnabled, false);
  assert.equal(SAFETY.networkWriteEnabled, false);
  assert.equal(SAFETY.credentialLoadingEnabled, false);
  assert.equal(SAFETY.adminSdkInitializationEnabled, false);
  assert.equal(SAFETY.roleDeltaEnabled, false);
  assert.equal(SAFETY.repositoryAttachEnabled, false);
  assert.equal(SAFETY.repositoryArmEnabled, false);
  assert.equal(SAFETY.incidentWriteEnabled, false);
  assert.equal(SAFETY.suggestOnlyAuthorized, false);
  assert.equal(SAFETY.autoAuthorized, false);
});

test('project binding is exact', () => {
  assert.equal(PHASE66_PROJECT_ID, 'swat-ride-v2');
});

test('fixture contains exactly 22 unique existing roles', () => {
  assert.equal(fixture.currentRoles.length, CURRENT_ROLE_COUNT);

  const ids = fixture.currentRoles.map((role) => role.roleId);

  assert.equal(new Set(ids).size, CURRENT_ROLE_COUNT);
  assert.equal(ids.includes(SECURITY_INCIDENT_ROLE_ID), false);
});

test('fingerprints are deterministic', () => {
  const currentA = roleInventoryFingerprint(fixture.currentRoles);
  const currentB = roleInventoryFingerprint(
    [...fixture.currentRoles].reverse(),
  );

  assert.equal(currentA, currentB);
  assert.equal(
    currentA,
    fixture.expectedCurrentInventoryFingerprintSha256,
  );

  assert.equal(
    proposedInventoryFingerprint(fixture.currentRoles),
    fixture.expectedProposedInventoryFingerprintSha256,
  );
});

test('valid offline evidence passes without granting execution', () => {
  const result = validateDryRunEvidence(fixture);

  assert.equal(result.ok, true);
  assert.deepEqual(result.errors, []);
  assert.equal(result.computed.currentRoleCount, 22);
  assert.equal(result.computed.proposedRoleCount, 23);
});

test('wrong project id fails closed', () => {
  const result = validateDryRunEvidence({
    ...fixture,
    projectId: 'wrong-project',
  });

  assert.equal(result.ok, false);
  assert.ok(result.errors.includes('project_id_mismatch'));
});

test('security incident role collision fails closed', () => {
  const currentRoles = fixture.currentRoles.map((role, index) =>
    index === 0
      ? { ...role, roleId: SECURITY_INCIDENT_ROLE_ID }
      : role,
  );

  const result = validateDryRunEvidence({
    ...fixture,
    currentRoles,
  });

  assert.equal(result.ok, false);
  assert.ok(
    result.errors.includes('security_incident_role_must_be_absent'),
  );
});

test('missing fresh Owner binding fails closed', () => {
  const result = validateDryRunEvidence({
    ...fixture,
    freshOwnerVerified: false,
    ownerApprovalBound: false,
  });

  assert.equal(result.ok, false);
  assert.ok(
    result.errors.includes('fresh_owner_verification_required'),
  );
  assert.ok(
    result.errors.includes('owner_approval_binding_required'),
  );
});

test('attempted attach/arm/auto authority fails closed', () => {
  const result = validateDryRunEvidence({
    ...fixture,
    repositoryAttachAuthorized: true,
    repositoryArmAuthorized: true,
    authorizesAuto: true,
  });

  assert.equal(result.ok, false);
  assert.ok(
    result.errors.includes('repository_attach_must_remain_false'),
  );
  assert.ok(
    result.errors.includes('repository_arm_must_remain_false'),
  );
  assert.ok(result.errors.includes('auto_must_remain_false'));
});

test('existing activation token reuse is forbidden', () => {
  const result = validateDryRunEvidence({
    ...fixture,
    existingActivationTokenReuseAllowed: true,
  });

  assert.equal(result.ok, false);
  assert.ok(
    result.errors.includes('existing_activation_token_reuse_forbidden'),
  );
});
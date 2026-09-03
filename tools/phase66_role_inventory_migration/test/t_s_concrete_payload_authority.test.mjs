import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

import {
  PROPOSED_ROLE_AI_CLASS,
  PROPOSED_ROLE_ENABLED,
  PROPOSED_ROLE_FORBIDDEN_ACTIONS,
  PROPOSED_ROLE_PRIVACY_LEVEL,
  REQUIRES_SEPARATE_POST_REBIND_ENABLE_BOUNDARY,
  SECURITY_INCIDENT_ACTION_ID,
} from '../src/contract.mjs';

import {
  proposedInventoryFingerprint,
  proposedRoleProjection,
} from '../src/fingerprint.mjs';

const fixture = JSON.parse(
  await readFile(
    new URL('./fixtures/valid_dry_run_evidence.json', import.meta.url),
    'utf8',
  ),
);

test('proposed role remains disabled until separate post-rebind enable', () => {
  assert.equal(PROPOSED_ROLE_ENABLED, false);
  assert.equal(REQUIRES_SEPARATE_POST_REBIND_ENABLE_BOUNDARY, true);

  const role = proposedRoleProjection();

  assert.equal(role.enabled, false);
});

test('proposed role uses exact valid AI/privacy authority literals', () => {
  assert.equal(PROPOSED_ROLE_AI_CLASS, 'FREE_AI');
  assert.equal(PROPOSED_ROLE_PRIVACY_LEVEL, 'HIGHLY_SENSITIVE');

  const role = proposedRoleProjection();

  assert.equal(role.aiClass, PROPOSED_ROLE_AI_CLASS);
  assert.equal(role.privacyLevel, PROPOSED_ROLE_PRIVACY_LEVEL);
});

test('proposed role remains one-action and forbidden list is exact empty', () => {
  const role = proposedRoleProjection();

  assert.deepEqual(role.allowedActions, [SECURITY_INCIDENT_ACTION_ID]);
  assert.deepEqual(role.approvalRequiredActions, [
    SECURITY_INCIDENT_ACTION_ID,
  ]);
  assert.deepEqual(role.forbiddenActions, []);
  assert.deepEqual(PROPOSED_ROLE_FORBIDDEN_ACTIONS, []);
});

test('synthetic fixture proposed fingerprint matches new disabled payload', () => {
  assert.equal(
    proposedInventoryFingerprint(fixture.currentRoles),
    fixture.expectedProposedInventoryFingerprintSha256,
  );
});
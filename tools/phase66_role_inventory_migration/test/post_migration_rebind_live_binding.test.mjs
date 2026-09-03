import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

import {
  POST_MIGRATION_REBIND_LIVE_BINDING_CONTRACT,
  buildPostMigrationControlProjection,
  postMigrationControlStateFingerprint,
  postMigrationRebindPlanFingerprint,
} from '../src/post_migration_rebind_live_binding.mjs';

const CONTRACT = Object.freeze({
  operation: 'REBIND_SECURITY_INCIDENT_POST_MIGRATION_AUTHORITY_23_ROLE',
  lockedPostMigrationSnapshotSha256:
    '01ac8f1fc48b9d95a3ca1179ab550fe7c7a630b9605ff937b2feedd10a6c1888',
  lockedRoleInventoryFingerprintSha256:
    'd16c6ff23b0d56a9e3b76146eefe22832d86196dee48bb05d6bc0129f48e2f2a',
  targetRoleId: 'security_incident_agent',
  targetModule: 'security_incident',
  targetActionId: 'security_incident.attach_runtime',
  rolloutStage: 'MONITOR_ONLY',
  guardVersion: 'MONITOR_ONLY_GUARD_V1',
  targetRoleCount: 23,
  currentAuthorityManifestRevision: 2,
  targetAuthorityManifestRevision: 3,
  currentGuardRevision: 2,
  targetGuardRevision: 3,
  currentGuardRoleCount: 22,
});

function masterFixture() {
  return {
    masterEnabled: true,
    emergencyReadOnly: false,
    freeAiEnabled: true,
    localAiEnabled: false,
    paidCodeAiEnabled: false,
    callAgentEnabled: false,
    emailAgentEnabled: false,
    customerWhatsAppAgentEnabled: false,
    ownerWhatsAppAgentEnabled: false,
    emergencyWhatsAppAgentEnabled: false,
    voiceSuperAdminAgentEnabled: false,
    approvalEngineEnabled: true,
    auditLoggingEnabled: true,
    paidReasoningEnabled: false,
    askBeforePaid: true,
    paidReasoningPerTaskLimitRs: 0,
    paidReasoningDailyLimitRs: 0,
    paidReasoningMonthlyLimitRs: 0,
    monthlyPaidCodeBudgetRs: 0,
    paidCodeBudgetUsedRs: 0,
    emergencyActivatedBy: ' owner ',
    emergencyReason: ' monitor only ',
    createdAt: 'volatile-created',
    updatedAt: 'volatile-updated',
    emergencyActivatedAt: 'volatile-emergency-time',
    unknownFieldMustBeDropped: 'not-part-of-Dart-toMap',
  };
}

function roleFixtures() {
  return [
    {
      roleId: 'z_agent',
      module: 'z',
      enabled: false,
      mode: 'ASK_FIRST',
      allowedActions: ['z.b', 'z.a', 'z.a'],
      approvalRequiredActions: ['z.a'],
      forbiddenActions: [],
      aiClass: 'FREE_AI',
      privacyLevel: 'HIGHLY_SENSITIVE',
      // Persisted maps do not own this client-only field.
      isFailClosed: true,
      name: 'ignored-by-control-projection',
    },
    {
      roleId: 'a_agent',
      module: 'a',
      enabled: true,
      mode: 'MONITOR_ONLY',
      allowedActions: ['a.read'],
      approvalRequiredActions: [],
      forbiddenActions: ['a.write'],
      aiClass: 'FREE_AI',
      privacyLevel: 'INTERNAL',
    },
  ];
}

function planArgs(overrides = {}) {
  return {
    contract: CONTRACT,
    approvalId: 'approval-23',
    migrationApprovalId: 'migration-11',
    requesterReferenceSha256: 'a'.repeat(64),
    ownerApproverReferenceSha256: 'b'.repeat(64),
    postMigrationControlStateFingerprintSha256: 'e'.repeat(64),
    freshTokenIdSha256: 'c'.repeat(64),
    receiptIdSha256: 'd'.repeat(64),
    ...overrides,
  };
}

test('control-state projection matches locked Dart-compatible fixture SHA', () => {
  const sha = postMigrationControlStateFingerprint({
    master: masterFixture(),
    roles: roleFixtures(),
  });

  assert.equal(
    sha,
    'c2d16ae82a8241a23231f5c3b238468473fa8fb254e3c7bcf9ebf39dc398c19f',
  );
});

test('control projection drops volatile/unknown master fields and canonicalizes roles/actions', () => {
  const projection = buildPostMigrationControlProjection({
    master: masterFixture(),
    roles: roleFixtures(),
  });

  assert.equal('createdAt' in projection.masterSettings, false);
  assert.equal('updatedAt' in projection.masterSettings, false);
  assert.equal('emergencyActivatedAt' in projection.masterSettings, false);
  assert.equal('unknownFieldMustBeDropped' in projection.masterSettings, false);
  assert.deepEqual(
    projection.roles.map((role) => role.roleId),
    ['a_agent', 'z_agent'],
  );
  assert.deepEqual(
    projection.roles[1].allowedActions,
    ['z.a', 'z.b'],
  );
  assert.equal(projection.roles[1].isFailClosed, false);
});

test('control fingerprint is stable across role/action input order', () => {
  const first = postMigrationControlStateFingerprint({
    master: masterFixture(),
    roles: roleFixtures(),
  });

  const reordered = roleFixtures().reverse();
  reordered[0].allowedActions = [...reordered[0].allowedActions].reverse();
  reordered[1].allowedActions = [...reordered[1].allowedActions].reverse();

  const second = postMigrationControlStateFingerprint({
    master: masterFixture(),
    roles: reordered,
  });

  assert.equal(first, second);
});

test('dedicated post-migration rebind plan has deterministic locked fixture SHA', () => {
  assert.equal(
    postMigrationRebindPlanFingerprint(planArgs()),
    'd585fe6d951d1433faf0843e55fdf662facd1d0f56171e3fe2e0b38164541d2d',
  );
});

test('control/token/receipt binding changes the rebind plan fingerprint', () => {
  const base = postMigrationRebindPlanFingerprint(planArgs());

  assert.notEqual(
    base,
    postMigrationRebindPlanFingerprint(
      planArgs({
        postMigrationControlStateFingerprintSha256: '1'.repeat(64),
      }),
    ),
  );

  assert.notEqual(
    base,
    postMigrationRebindPlanFingerprint(
      planArgs({ freshTokenIdSha256: '2'.repeat(64) }),
    ),
  );

  assert.notEqual(
    base,
    postMigrationRebindPlanFingerprint(
      planArgs({ receiptIdSha256: '3'.repeat(64) }),
    ),
  );
});

test('binding helper owns no Admin SDK, Firestore transaction or live authority', async () => {
  const source = await readFile(
    new URL('../src/post_migration_rebind_live_binding.mjs', import.meta.url),
    'utf8',
  );

  assert.doesNotMatch(source, /firebase-admin/);
  assert.doesNotMatch(source, /initializeApp/);
  assert.doesNotMatch(source, /getFirestore/);
  assert.doesNotMatch(source, /runTransaction\s*\(/);
  assert.equal(POST_MIGRATION_REBIND_LIVE_BINDING_CONTRACT.readsFirestore, false);
  assert.equal(POST_MIGRATION_REBIND_LIVE_BINDING_CONTRACT.writesFirestore, false);
  assert.equal(POST_MIGRATION_REBIND_LIVE_BINDING_CONTRACT.grantsAuthority, false);
});

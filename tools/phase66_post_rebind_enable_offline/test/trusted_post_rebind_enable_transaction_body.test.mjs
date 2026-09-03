import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

import {
  POST_REBIND_ENABLE,
  POST_REBIND_ENABLE_TRANSACTION_BODY_CONTRACT,
  issueFreshReplacementTokenInCallerTransaction,
  executeAtomicRoleEnableAndHoldReleaseInCallerTransaction,
} from '../src/trusted_post_rebind_enable_transaction_body.mjs';

const SHA_A = 'a'.repeat(64);
const SHA_B = 'b'.repeat(64);
const SHA_C = 'c'.repeat(64);
const SHA_D = 'd'.repeat(64);

const APPROVAL_ID = 'enable-approval-test';

function stamp(ms) {
  return {
    toMillis() {
      return ms;
    },
  };
}

function ref(id, key) {
  return { id, key };
}

function snap(data, exists = true) {
  return {
    exists,
    data() {
      return data;
    },
  };
}

function approvalScope() {
  return {
    operation: POST_REBIND_ENABLE.enableOperation,
    roleId: POST_REBIND_ENABLE.roleId,
    module: POST_REBIND_ENABLE.module,
    actionId: POST_REBIND_ENABLE.actionId,
    rolloutStage: POST_REBIND_ENABLE.rolloutStage,
    roleCount: 23,
    authorityManifestRevision: 3,
    guardRevision: 3,
    rebindReceiptIdSha256: SHA_C,
    replacementTokenIdSha256: SHA_D,
    freshOwnerVerifiedAtApproval: true,
    explicitOwnerApproval: true,
    migrationApprovalReuseAllowed: false,
    rebindApprovalReuseAllowed: false,
    oldArmingTokenReuseAllowed: false,
    replacementTokenConsumeAuthorized: true,
    roleEnableAuthorized: true,
    migrationHoldReleaseAuthorized: true,
    repositoryAttachAuthorized: false,
    repositoryArmAuthorized: false,
    firstIncidentWriteAuthorized: false,
    authorizesSuggestOnly: false,
    authorizesAuto: false,
  };
}

function fixture(nowMs = 1_800_000_000_000) {
  const refs = {
    approval: ref(APPROVAL_ID, 'approval'),
    manifest: ref(
      'security_incident_role_inventory_authority_manifest',
      'manifest',
    ),
    hold: ref(
      'security_incident_role_inventory_migration_hold',
      'hold',
    ),
    guard: ref('production_rollout_guard', 'guard'),
    rollout: ref('production_rollout', 'rollout'),
    role: ref(POST_REBIND_ENABLE.roleId, 'role'),
    rebindReceipt: ref(SHA_C, 'rebindReceipt'),
    historicalToken: ref(SHA_A, 'historicalToken'),
    replacementToken: ref(SHA_D, 'replacementToken'),
    tokenAudit: ref('token-audit-test', 'tokenAudit'),
    enableAudit: ref('enable-audit-test', 'enableAudit'),
  };

  const data = {
    approval: {
      approvalId: APPROVAL_ID,
      roleId: POST_REBIND_ENABLE.roleId,
      module: POST_REBIND_ENABLE.module,
      actionId: POST_REBIND_ENABLE.actionId,
      risk: 'HIGH',
      requestedBy:
        `${POST_REBIND_ENABLE.requesterPrefix}${SHA_A}`,
      decidedBy: `${POST_REBIND_ENABLE.ownerPrefix}${SHA_B}`,
      status: 'APPROVED',
      consumedAt: null,
      expiresAt: stamp(nowMs + 600_000),
      actionScope: approvalScope(),
    },

    manifest: {
      status: 'ACTIVE',
      revision: 3,
      roleCount: 23,
      postMigrationRebindRequired: false,
    },

    hold: {
      status: 'ROLE_DELTA_COMMITTED',
      migrationHoldActive: true,
      authorityManifestRevision: 3,
      postMigrationRebindRequired: false,
      repositoryAttachAuthorized: false,
      repositoryArmAuthorized: false,
      firstIncidentWriteAuthorized: false,
      authorizesSuggestOnly: false,
      authorizesAuto: false,
    },

    guard: {
      revision: 3,
      roleCount: 23,
      targetStage: 'MONITOR_ONLY',
    },

    rollout: {
      stage: 'MONITOR_ONLY',
      autoTrafficPercent: 0,
      businessWriteTrafficPercent: 0,
      externalChannelsEnabled: false,
    },

    role: {
      roleId: POST_REBIND_ENABLE.roleId,
      module: POST_REBIND_ENABLE.module,
      enabled: false,
      mode: 'ASK_FIRST',
      aiClass: 'FREE_AI',
      privacyLevel: 'HIGHLY_SENSITIVE',
      allowedActions: [POST_REBIND_ENABLE.actionId],
      approvalRequiredActions: [POST_REBIND_ENABLE.actionId],
      forbiddenActions: [],
    },

    rebindReceipt: {
      receiptIdSha256: SHA_C,
      authorityManifestRevision: 3,
      guardRevision: 3,
      roleCount: 23,
      migrationHoldStillActive: true,
      securityIncidentRoleStillDisabled: true,
      repositoryAttachAuthorized: false,
      repositoryArmAuthorized: false,
      firstIncidentWriteAuthorized: false,
      authorizesSuggestOnly: false,
      authorizesAuto: false,
    },

    historicalToken: {
      tokenIdSha256: SHA_A,
      status: 'READY',
      consumedAt: null,
      guardRevision: 3,
      roleCount: 23,
      expiresAt: stamp(nowMs - 30_000),
    },

    replacementToken: {
      tokenIdSha256: SHA_D,
      status: 'READY',
      consumedAt: null,
      purpose: POST_REBIND_ENABLE.tokenPurpose,
      targetStage: 'MONITOR_ONLY',
      actorReferenceSha256: SHA_B,
      ownerApprovalId: APPROVAL_ID,
      rebindReceiptIdSha256: SHA_C,
      guardRevision: 3,
      roleCount: 23,
      expiresAt: stamp(nowMs + 80_000),
    },
  };

  const snapshots = new Map([
    ['approval', snap(data.approval)],
    ['manifest', snap(data.manifest)],
    ['hold', snap(data.hold)],
    ['guard', snap(data.guard)],
    ['rollout', snap(data.rollout)],
    ['role', snap(data.role)],
    ['rebindReceipt', snap(data.rebindReceipt)],
    ['historicalToken', snap(data.historicalToken)],
    ['replacementToken', snap(data.replacementToken)],
  ]);

  const operations = [];

  const tx = {
    async get(reference) {
      operations.push({ type: 'get', key: reference.key });
      return snapshots.get(reference.key) ?? snap({}, false);
    },

    create(reference, payload) {
      operations.push({
        type: 'create',
        key: reference.key,
        payload,
      });
    },

    update(reference, payload) {
      operations.push({
        type: 'update',
        key: reference.key,
        payload,
      });
    },

    set(reference, payload, options) {
      operations.push({
        type: 'set',
        key: reference.key,
        payload,
        options,
      });
    },

    delete(reference) {
      operations.push({
        type: 'delete',
        key: reference.key,
      });
    },
  };

  const request = {
    approvalId: APPROVAL_ID,
    requesterReferenceSha256: SHA_A,
    ownerApproverReferenceSha256: SHA_B,
    rebindReceiptIdSha256: SHA_C,
    replacementTokenIdSha256: SHA_D,
    nowMs,
    issuedAt: stamp(nowMs),
    expiresAt: stamp(nowMs + 80_000),
  };

  return {
    refs,
    data,
    snapshots,
    operations,
    tx,
    request,
    nowMs,
  };
}

function writes(operations) {
  return operations.filter(
    (item) => item.type !== 'get',
  );
}

test('contract is pure caller-owned and exact 2 + 5 write surfaces', () => {
  assert.equal(
    POST_REBIND_ENABLE_TRANSACTION_BODY_CONTRACT
      .ownsFirestoreTransaction,
    false,
  );
  assert.equal(
    POST_REBIND_ENABLE_TRANSACTION_BODY_CONTRACT
      .initializesFirebaseAdmin,
    false,
  );
  assert.equal(
    POST_REBIND_ENABLE_TRANSACTION_BODY_CONTRACT
      .replacementTokenIssuanceWrites,
    2,
  );
  assert.equal(
    POST_REBIND_ENABLE_TRANSACTION_BODY_CONTRACT.atomicEnableWrites,
    5,
  );
  assert.deepEqual(
    POST_REBIND_ENABLE.atomicEnableWriteOrder,
    [
      'OWNER_ENABLE_APPROVAL_CONSUME',
      'REPLACEMENT_TOKEN_CONSUME',
      'SECURITY_INCIDENT_ROLE_ENABLE',
      'MIGRATION_HOLD_RELEASE',
      'ENABLE_AUDIT_CREATE',
    ],
  );
});

test('fresh replacement token issuance is exactly two writes after all reads', async () => {
  const f = fixture();

  f.snapshots.set(
    'replacementToken',
    snap({}, false),
  );

  const result =
    await issueFreshReplacementTokenInCallerTransaction({
      tx: f.tx,
      refs: f.refs,
      request: f.request,
      serverTimestamp: () => 'SERVER_TIMESTAMP',
    });

  assert.equal(
    result.status,
    'FRESH_REPLACEMENT_TOKEN_ISSUED_FAIL_CLOSED',
  );

  const w = writes(f.operations);

  assert.deepEqual(
    w.map((item) => `${item.type}:${item.key}`),
    [
      'create:replacementToken',
      'create:tokenAudit',
    ],
  );

  const firstWriteIndex =
    f.operations.findIndex((item) => item.type !== 'get');

  assert.equal(firstWriteIndex, 9);

  assert.equal(
    w[0].payload.status,
    'READY',
  );
  assert.equal(
    w[0].payload.consumedAt,
    null,
  );
});

test('replacement token collision fails closed with zero writes', async () => {
  const f = fixture();

  await assert.rejects(
    issueFreshReplacementTokenInCallerTransaction({
      tx: f.tx,
      refs: f.refs,
      request: f.request,
      serverTimestamp: () => 'SERVER_TIMESTAMP',
    }),
    /replacement_token_sha_collision/,
  );

  assert.equal(writes(f.operations).length, 0);
});

test('non-expired historical rebind token blocks replacement issuance', async () => {
  const f = fixture();

  f.snapshots.set(
    'replacementToken',
    snap({}, false),
  );

  f.data.historicalToken.expiresAt =
    stamp(f.nowMs + 5_000);

  await assert.rejects(
    issueFreshReplacementTokenInCallerTransaction({
      tx: f.tx,
      refs: f.refs,
      request: f.request,
      serverTimestamp: () => 'SERVER_TIMESTAMP',
    }),
    /historical_rebind_token_not_exact_expired_ready_history/,
  );

  assert.equal(writes(f.operations).length, 0);
});

test('atomic enable is exact five writes after all reads', async () => {
  const f = fixture();

  const result =
    await executeAtomicRoleEnableAndHoldReleaseInCallerTransaction({
      tx: f.tx,
      refs: f.refs,
      request: f.request,
      serverTimestamp: () => 'SERVER_TIMESTAMP',
    });

  assert.equal(
    result.status,
    'ROLE_ENABLED_AND_MIGRATION_HOLD_RELEASED_FAIL_CLOSED',
  );

  const w = writes(f.operations);

  assert.deepEqual(
    w.map((item) => `${item.type}:${item.key}`),
    [
      'update:approval',
      'update:replacementToken',
      'update:role',
      'update:hold',
      'create:enableAudit',
    ],
  );

  const firstWriteIndex =
    f.operations.findIndex((item) => item.type !== 'get');

  assert.equal(firstWriteIndex, 8);

  assert.equal(w[0].payload.status, 'CONSUMED');
  assert.equal(w[1].payload.status, 'CONSUMED');
  assert.equal(w[2].payload.enabled, true);
  assert.equal(w[2].payload.mode, 'ASK_FIRST');
  assert.equal(w[3].payload.status, 'RELEASED');
  assert.equal(w[3].payload.migrationHoldActive, false);
  assert.equal(
    w[3].payload.repositoryAttachAuthorized,
    false,
  );
  assert.equal(
    w[3].payload.repositoryArmAuthorized,
    false,
  );
  assert.equal(
    w[3].payload.firstIncidentWriteAuthorized,
    false,
  );
});

test('expired replacement token fails closed with zero writes', async () => {
  const f = fixture();

  f.data.replacementToken.expiresAt =
    stamp(f.nowMs - 1);

  await assert.rejects(
    executeAtomicRoleEnableAndHoldReleaseInCallerTransaction({
      tx: f.tx,
      refs: f.refs,
      request: f.request,
      serverTimestamp: () => 'SERVER_TIMESTAMP',
    }),
    /replacement_token_expired/,
  );

  assert.equal(writes(f.operations).length, 0);
});

test('approval scope cannot omit token consume or hold release authorization', async () => {
  const f = fixture();

  f.data.approval.actionScope =
    approvalScope();

  f.data.approval.actionScope
    .replacementTokenConsumeAuthorized = false;

  await assert.rejects(
    executeAtomicRoleEnableAndHoldReleaseInCallerTransaction({
      tx: f.tx,
      refs: f.refs,
      request: f.request,
      serverTimestamp: () => 'SERVER_TIMESTAMP',
    }),
    /enable_approval_scope_mismatch/,
  );

  assert.equal(writes(f.operations).length, 0);
});

test('role enabled early fails closed with zero writes', async () => {
  const f = fixture();

  f.data.role.enabled = true;

  await assert.rejects(
    executeAtomicRoleEnableAndHoldReleaseInCallerTransaction({
      tx: f.tx,
      refs: f.refs,
      request: f.request,
      serverTimestamp: () => 'SERVER_TIMESTAMP',
    }),
    /security_incident_role_not_exact_disabled_ask_first/,
  );

  assert.equal(writes(f.operations).length, 0);
});

test('hold released early fails closed with zero writes', async () => {
  const f = fixture();

  f.data.hold.migrationHoldActive = false;

  await assert.rejects(
    executeAtomicRoleEnableAndHoldReleaseInCallerTransaction({
      tx: f.tx,
      refs: f.refs,
      request: f.request,
      serverTimestamp: () => 'SERVER_TIMESTAMP',
    }),
    /migration_hold_not_exact_active_post_rebind_state/,
  );

  assert.equal(writes(f.operations).length, 0);
});

test('requester cannot equal Owner pseudonym', async () => {
  const f = fixture();

  f.request.ownerApproverReferenceSha256 = SHA_A;

  await assert.rejects(
    executeAtomicRoleEnableAndHoldReleaseInCallerTransaction({
      tx: f.tx,
      refs: f.refs,
      request: f.request,
      serverTimestamp: () => 'SERVER_TIMESTAMP',
    }),
    /requester_owner_must_differ/,
  );

  assert.equal(writes(f.operations).length, 0);
});

test('source contains no Admin SDK, runTransaction, raw token, attach/arm authority', async () => {
  const source = await readFile(
    new URL(
      '../src/trusted_post_rebind_enable_transaction_body.mjs',
      import.meta.url,
    ),
    'utf8',
  );

  for (const forbidden of [
    'firebase-admin',
    'initializeApp(',
    'getFirestore(',
    'runTransaction(',
    'request.rawToken',
    'rawToken:',
    'repositoryAttachAuthorized: true',
    'repositoryArmAuthorized: true',
    'firstIncidentWriteAuthorized: true',
    'authorizesSuggestOnly: true',
    'authorizesAuto: true',
  ]) {
    assert.equal(
      source.includes(forbidden),
      false,
      `forbidden source authority found: ${forbidden}`,
    );
  }
});
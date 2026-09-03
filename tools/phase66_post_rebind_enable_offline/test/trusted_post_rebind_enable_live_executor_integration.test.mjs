
import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

import {
  POST_REBIND_ENABLE_LIVE_DEFAULTS,
  POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT,
  executePostRebindEnableAtomicRoleEnableHoldRelease,
  executePostRebindEnableReplacementTokenIssue,
} from '../../phase66_role_inventory_migration/src/trusted_admin_sdk_executor.mjs';

test('post-rebind enable live defaults are fully disarmed', () => {
  assert.equal(
    POST_REBIND_ENABLE_LIVE_DEFAULTS.executionArmed,
    false,
  );

  for (const [name, value] of
    Object.entries(POST_REBIND_ENABLE_LIVE_DEFAULTS)) {
    if (name.startsWith('allow')) {
      assert.equal(
        value,
        false,
        `${name} must default false`,
      );
    }
  }
});

test('replacement token issue blocks before Admin SDK import when disarmed', async () => {
  await assert.rejects(
    executePostRebindEnableReplacementTokenIssue({}),
    /post_rebind_enable_token_issue_not_armed/,
  );
});

test('atomic enable blocks before Admin SDK import when disarmed', async () => {
  await assert.rejects(
    executePostRebindEnableAtomicRoleEnableHoldRelease({}),
    /post_rebind_enable_atomic_not_armed/,
  );
});

test('live executor contract preserves exact 2 plus 5 boundary', () => {
  assert.equal(
    POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
      .canonicalAdminSdkAuthorityOnly,
    true,
  );
  assert.equal(
    POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
      .secondAdminSdkAuthorityAllowed,
    false,
  );
  assert.equal(
    POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
      .replacementTokenRawCredentialRequired,
    true,
  );
  assert.equal(
    POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
      .replacementTokenRawCredentialPersisted,
    false,
  );
  assert.equal(
    POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
      .replacementTokenIssueExactWrites,
    2,
  );
  assert.equal(
    POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
      .atomicEnableExactWrites,
    5,
  );
  assert.equal(
    POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
      .roleModeAfterEnable,
    'ASK_FIRST',
  );
  assert.equal(
    POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
      .rolloutStageAfterEnable,
    'MONITOR_ONLY',
  );
  assert.equal(
    POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
      .repositoryAttachAuthorized,
    false,
  );
  assert.equal(
    POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
      .repositoryArmAuthorized,
    false,
  );
  assert.equal(
    POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
      .firstIncidentWriteAuthorized,
    false,
  );
  assert.equal(
    POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
      .suggestOnlyAuthorized,
    false,
  );
  assert.equal(
    POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
      .autoAuthorized,
    false,
  );
});

test('canonical source has one Admin SDK context and new guards precede it', async () => {
  const source = await readFile(
    new URL(
      '../../phase66_role_inventory_migration/src/trusted_admin_sdk_executor.mjs',
      import.meta.url,
    ),
    'utf8',
  );

  assert.equal(
    (source.match(/async function createAdminContext\s*\(/g) ?? [])
      .length,
    1,
  );

  assert.equal(
    (source.match(/import\('firebase-admin\/app'\)/g) ?? [])
      .length,
    1,
  );

  assert.equal(
    (source.match(/import\('firebase-admin\/firestore'\)/g) ?? [])
      .length,
    1,
  );

  const issueStart =
    source.indexOf(
      'export async function executePostRebindEnableReplacementTokenIssue(',
    );

  const atomicStart =
    source.indexOf(
      'export async function executePostRebindEnableAtomicRoleEnableHoldRelease(',
    );

  assert.ok(issueStart >= 0);
  assert.ok(atomicStart > issueStart);

  const issueSection =
    source.slice(issueStart, atomicStart);

  const atomicSection =
    source.slice(atomicStart);

  assert.ok(
    issueSection.indexOf(
      'assertPostRebindEnableTokenIssueArmed(config);',
    ) <
      issueSection.indexOf(
        'await createAdminContext(config)',
      ),
  );

  assert.ok(
    atomicSection.indexOf(
      'assertPostRebindEnableAtomicArmed(config);',
    ) <
      atomicSection.indexOf(
        'await createAdminContext(config)',
      ),
  );

  assert.ok(
    issueSection.indexOf(
      'assertReplacementTokenCredential(',
    ) <
      issueSection.indexOf(
        'await createAdminContext(config)',
      ),
  );

  assert.ok(
    atomicSection.indexOf(
      'assertReplacementTokenCredential(',
    ) <
      atomicSection.indexOf(
        'await createAdminContext(config)',
      ),
  );
});

test('raw replacement token is checked but never placed in Firestore request payload', async () => {
  const source = await readFile(
    new URL(
      '../../phase66_role_inventory_migration/src/trusted_admin_sdk_executor.mjs',
      import.meta.url,
    ),
    'utf8',
  );

  assert.ok(
    source.includes(
      'replacement_token_raw_credential_sha_mismatch',
    ),
  );

  const issueStart =
    source.indexOf(
      'export async function executePostRebindEnableReplacementTokenIssue(',
    );

  const atomicStart =
    source.indexOf(
      'export async function executePostRebindEnableAtomicRoleEnableHoldRelease(',
    );

  const contractStart =
    source.indexOf(
      'export const POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT',
      atomicStart,
    );

  assert.ok(issueStart >= 0);
  assert.ok(atomicStart > issueStart);
  assert.ok(contractStart > atomicStart);

  const sections = [
    source.slice(issueStart, atomicStart),
    source.slice(atomicStart, contractStart),
  ];

  for (const section of sections) {
    const requestStart =
      section.indexOf('const request = {');

    const transactionStart =
      section.indexOf(
        'return await db.runTransaction',
        requestStart,
      );

    assert.ok(requestStart >= 0);
    assert.ok(transactionStart > requestStart);

    const requestPayloadSource =
      section.slice(
        requestStart,
        transactionStart,
      );

    assert.ok(
      requestPayloadSource.includes(
        'replacementTokenIdSha256',
      ),
    );

    assert.ok(
      requestPayloadSource.includes(
        'rebindReceiptIdSha256',
      ),
    );

    assert.equal(
      requestPayloadSource.includes(
        'rawReplacementToken',
      ),
      false,
    );
  }
});
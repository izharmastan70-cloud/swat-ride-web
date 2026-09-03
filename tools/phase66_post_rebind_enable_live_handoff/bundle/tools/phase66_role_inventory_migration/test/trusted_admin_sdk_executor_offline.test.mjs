import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

import {
  LIVE_EXECUTOR_CONTRACT,
  LIVE_EXECUTOR_DEFAULTS,
  assertLiveExecutorDefaultDisarmed,
  executeAtomicMigration,
  executePostMigrationRebind,
  executeTrustedBootstrap,
} from '../src/trusted_admin_sdk_executor.mjs';

test('trusted live executor is default-disarmed', () => {
  assert.equal(assertLiveExecutorDefaultDisarmed(), true);
  assert.equal(LIVE_EXECUTOR_DEFAULTS.executionArmed, false);

  for (const [name, value] of Object.entries(LIVE_EXECUTOR_DEFAULTS)) {
    if (name.startsWith('allow')) {
      assert.equal(value, false, `${name} must default false`);
    }
  }
});

test('bootstrap blocks before Admin SDK dynamic import when not armed', async () => {
  await assert.rejects(
    executeTrustedBootstrap({
      approvalId: 'not-used',
      expectedBindingSha256: 'a'.repeat(64),
      migrationIdSha256: 'b'.repeat(64),
      actorReferenceSha256: 'c'.repeat(64),
    }),
    /bootstrap_execution_not_armed/,
  );
});

test('migration blocks before Admin SDK dynamic import when not armed', async () => {
  await assert.rejects(
    executeAtomicMigration({
      approvalId: 'not-used',
      expectedBindingSha256: 'a'.repeat(64),
      migrationIdSha256: 'b'.repeat(64),
      actorReferenceSha256: 'c'.repeat(64),
    }),
    /migration_execution_not_armed/,
  );
});

test('post-migration rebind blocks before Admin SDK dynamic import when not armed', async () => {
  await assert.rejects(
    executePostMigrationRebind({
      approvalId: 'not-used',
      migrationApprovalId: 'migration-not-used',
      requesterReferenceSha256: 'a'.repeat(64),
      ownerApproverReferenceSha256: 'b'.repeat(64),
      freshTokenIdSha256: 'c'.repeat(64),
      receiptIdSha256: 'd'.repeat(64),
    }),
    /post_migration_rebind_execution_not_armed/,
  );
});

test('executor contract preserves post-migration fail-closed boundaries', () => {
  assert.equal(LIVE_EXECUTOR_CONTRACT.bootstrapConsumesApproval, false);
  assert.equal(LIVE_EXECUTOR_CONTRACT.migrationConsumesApproval, true);
  assert.equal(LIVE_EXECUTOR_CONTRACT.migrationCreatesRoleEnabled, false);
  assert.equal(LIVE_EXECUTOR_CONTRACT.migrationReleasesHold, false);
  assert.equal(LIVE_EXECUTOR_CONTRACT.postMigrationRebindConsumesApproval, true);
  assert.equal(LIVE_EXECUTOR_CONTRACT.postMigrationRebindExactWrites, 6);
  assert.equal(
    LIVE_EXECUTOR_CONTRACT.postMigrationRebindRecomputesControlFingerprint,
    true,
  );
  assert.equal(
    LIVE_EXECUTOR_CONTRACT.postMigrationRebindRecomputesPlanFingerprint,
    true,
  );
  assert.equal(LIVE_EXECUTOR_CONTRACT.postMigrationRebindEnablesRole, false);
  assert.equal(LIVE_EXECUTOR_CONTRACT.postMigrationRebindReleasesHold, false);
  assert.equal(LIVE_EXECUTOR_CONTRACT.writesOldGuard, false);
  assert.equal(LIVE_EXECUTOR_CONTRACT.writesOldArmingToken, false);
  assert.equal(LIVE_EXECUTOR_CONTRACT.writesOldActivationReceipt, false);
  assert.equal(LIVE_EXECUTOR_CONTRACT.repositoryAttachAuthorized, false);
  assert.equal(LIVE_EXECUTOR_CONTRACT.repositoryArmAuthorized, false);
  assert.equal(LIVE_EXECUTOR_CONTRACT.firstIncidentWriteAuthorized, false);
  assert.equal(LIVE_EXECUTOR_CONTRACT.suggestOnlyAuthorized, false);
  assert.equal(LIVE_EXECUTOR_CONTRACT.autoAuthorized, false);
});

test('executor source enforces persisted role document identity and complete role writes', async () => {
  const source = await readFile(
    new URL('../src/trusted_admin_sdk_executor.mjs', import.meta.url),
    'utf8',
  );

  assert.match(
    source,
    /live_role_document_missing_role_id/,
  );

  assert.match(
    source,
    /live_role_document_id_role_id_mismatch/,
  );

  assert.match(
    source,
    /write2CreateDisabledRole/,
  );

  assert.match(
    source,
    /createdAt: FieldValue\.serverTimestamp\(\)/,
  );

  assert.match(
    source,
    /updatedAt: FieldValue\.serverTimestamp\(\)/,
  );
});

test('executor source enforces approval document identity and exact system requester binding', async () => {
  const source = await readFile(
    new URL('../src/trusted_admin_sdk_executor.mjs', import.meta.url),
    'utf8',
  );

  assert.match(
    source,
    /approval_payload_id_missing/,
  );

  assert.match(
    source,
    /approval_document_id_payload_id_mismatch/,
  );

  assert.match(
    source,
    /PHASE66_MIGRATION_COORDINATOR\|/,
  );

  assert.match(
    source,
    /phase66_migration_coordinator_sha256:/,
  );

  assert.match(
    source,
    /approval_system_requester_binding_mismatch/,
  );

  assert.match(
    source,
    /scope\.requestPrincipal/,
  );

  assert.match(
    source,
    /PHASE66_MIGRATION_COORDINATOR/,
  );

  assert.match(
    source,
    /owner_approver_must_not_equal_system_requester/,
  );
});

test('executor source binds decidedBy exactly to actionScope Owner SHA pseudonym', async () => {
  const source = await readFile(
    new URL('../src/trusted_admin_sdk_executor.mjs', import.meta.url),
    'utf8',
  );

  assert.match(
    source,
    /phase66_owner_sha256:/,
  );

  assert.match(
    source,
    /scope\.ownerApproverReferenceSha256/,
  );

  assert.match(
    source,
    /approval\.decidedBy !== expectedDecidedBy/,
  );

  assert.match(
    source,
    /approval_decided_by_owner_sha_binding_mismatch/,
  );
});

test('executor source exact-locks T-Y/T-Z evidence and audit actor to Owner SHA', async () => {
  const source = await readFile(
    new URL('../src/trusted_admin_sdk_executor.mjs', import.meta.url),
    'utf8',
  );

  assert.match(
    source,
    /3ba eafc2e8ce82d138f884f6f3990c4ff644d981be864a35182c5475997b1f1d/,
  );

  assert.match(
    source,
    /d16c6ff23b0d56a9e3b76146eefe22832d86196dee48bb05d6bc0129f48e2f2a/,
  );

  assert.match(
    source,
    /db72e5c0888ea558c07ef002d059c3d92f909fb77f223725a029f35fa6ee9b5e/,
  );

  assert.match(
    source,
    /6cb1df3565e6a9130cadb54d888e6cfe89d7ed393dda369a54ad32d40d937240/,
  );

  assert.match(
    source,
    /approval_locked_ty_tz_evidence_mismatch/,
  );

  assert.match(
    source,
    /bootstrap_live_ty_inventory_not_exact_locked_snapshot/,
  );

  assert.match(
    source,
    /migration_live_ty_inventory_not_exact_locked_snapshot/,
  );

  assert.match(
    source,
    /audit_actor_must_equal_expected_owner_sha/,
  );
});

test('executor source enforces remaining approval TTL before bootstrap and migration', async () => {
  const source = await readFile(
    new URL('../src/trusted_admin_sdk_executor.mjs', import.meta.url),
    'utf8',
  );

  assert.match(
    source,
    /MIN_BOOTSTRAP_APPROVAL_REMAINING_MS/,
  );

  assert.match(
    source,
    /5 \* 60 \* 1000/,
  );

  assert.match(
    source,
    /MIN_MIGRATION_APPROVAL_REMAINING_MS/,
  );

  assert.match(
    source,
    /60 \* 1000/,
  );

  assert.match(
    source,
    /approval_remaining_ttl_below_execution_floor/,
  );

  assert.match(
    source,
    /MIN_BOOTSTRAP_APPROVAL_REMAINING_MS,[\s\S]*const currentRoles/,
  );

  assert.match(
    source,
    /MIN_MIGRATION_APPROVAL_REMAINING_MS,[\s\S]*const currentRoles/,
  );
});

test('executor source revalidates immutable master guard activation token evidence inside both transactions', async () => {
  const source = await readFile(
    new URL('../src/trusted_admin_sdk_executor.mjs', import.meta.url),
    'utf8',
  );

  assert.match(source, /const MASTER_DOC = 'master'/);
  assert.match(source, /master_not_exact_monitor_only_target/);
  assert.match(source, /agent_production_rollout_activations/);
  assert.match(source, /agent_production_rollout_arming_tokens/);
  assert.match(source, /historical_activation_receipt_not_exact_monitor_only/);
  assert.match(source, /historical_arming_token_not_exact_consumed/);
  assert.match(source, /historical_guard_revision_binding_mismatch/);
  assert.match(source, /historical_control_sha_binding_mismatch/);
  assert.match(source, /historical_plan_sha_binding_mismatch/);
  assert.match(source, /historical_owner_actor_sha_binding_mismatch/);
  assert.match(source, /historical_owner_approval_binding_mismatch/);
  assert.match(source, /historical_tz_precondition_evidence_sha_mismatch/);

  const calls =
    source.match(/await validateImmutableHistoricalEvidence\(\{/g) ?? [];

  assert.equal(calls.length, 2);
});

test('canonical rebind wrapper requires Voice Super Admin switch OFF in MONITOR_ONLY', async () => {
  const source = await readFile(
    new URL('../src/trusted_admin_sdk_executor.mjs', import.meta.url),
    'utf8',
  );
  assert.match(source, /master\.voiceSuperAdminAgentEnabled === false/);
});

test('canonical executor owns the only Admin SDK rebind transaction wrapper', async () => {
  const source = await readFile(
    new URL('../src/trusted_admin_sdk_executor.mjs', import.meta.url),
    'utf8',
  );

  const adminContextOwners =
    source.match(/async function createAdminContext\(/g) ?? [];

  assert.equal(adminContextOwners.length, 1);
  assert.match(source, /executePostMigrationRebind\(/);
  assert.match(source, /allowPostMigrationRebindTransaction/);
  assert.match(source, /PHASE66_POST_MIGRATION_REBIND_23_ROLE_ONLY/);
  assert.match(source, /postMigrationControlStateFingerprint\(\{/);
  assert.match(source, /postMigrationRebindPlanFingerprint\(\{/);
  assert.match(source, /executePostMigrationRebindInCallerTransaction\(\{/);
  assert.match(source, /db\.runTransaction\(async \(tx\) => \{/);
  assert.match(source, /roleInventoryFingerprint\(currentRoles\)/);
  assert.match(source, /post_migration_rebind_live_inventory_not_exact_locked_23_role/);
});

test('rebind wrapper never accepts caller-supplied control or plan fingerprints', async () => {
  const source = await readFile(
    new URL('../src/trusted_admin_sdk_executor.mjs', import.meta.url),
    'utf8',
  );

  const start = source.indexOf('export async function executePostMigrationRebind({');
  const bodyStart = source.indexOf('  assertPostMigrationRebindArmed(config);', start);

  assert.notEqual(start, -1);
  assert.notEqual(bodyStart, -1);

  const signature = source.slice(start, bodyStart);

  assert.doesNotMatch(signature, /postMigrationControlStateFingerprintSha256/);
  assert.doesNotMatch(signature, /rebindPlanFingerprintSha256/);
  assert.match(signature, /freshTokenIdSha256/);
  assert.match(signature, /receiptIdSha256/);
});


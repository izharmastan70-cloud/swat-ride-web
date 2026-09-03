import {
  LIVE_EXECUTOR_CONTRACT,
  LIVE_EXECUTOR_DEFAULTS,
  assertLiveExecutorDefaultDisarmed,
  executePostMigrationRebind,
} from './tools/phase66_role_inventory_migration/src/trusted_admin_sdk_executor.mjs';

import {
  POST_MIGRATION_REBIND_PLAN_BINDING_ALGORITHM,
  postMigrationControlStateFingerprint,
  postMigrationRebindPlanFingerprint,
} from './tools/phase66_role_inventory_migration/src/post_migration_rebind_live_binding.mjs';

if (assertLiveExecutorDefaultDisarmed() !== true) {
  throw new Error('executor_default_disarmed_assertion_failed');
}

if (LIVE_EXECUTOR_DEFAULTS.executionArmed !== false) {
  throw new Error('executor_unexpectedly_armed');
}

for (const [name, value] of
  Object.entries(LIVE_EXECUTOR_DEFAULTS)) {
  if (name.startsWith('allow') && value !== false) {
    throw new Error(
      `executor_default_capability_enabled:${name}`,
    );
  }
}

if (
  LIVE_EXECUTOR_CONTRACT.projectId !== 'swat-ride-v2' ||
  LIVE_EXECUTOR_CONTRACT.defaultExecutionArmed !== false ||
  LIVE_EXECUTOR_CONTRACT.postMigrationRebindConsumesApproval !== true ||
  LIVE_EXECUTOR_CONTRACT.postMigrationRebindExactWrites !== 6 ||
  LIVE_EXECUTOR_CONTRACT.postMigrationRebindRecomputesControlFingerprint !== true ||
  LIVE_EXECUTOR_CONTRACT.postMigrationRebindRecomputesPlanFingerprint !== true ||
  LIVE_EXECUTOR_CONTRACT.postMigrationRebindEnablesRole !== false ||
  LIVE_EXECUTOR_CONTRACT.postMigrationRebindReleasesHold !== false ||
  LIVE_EXECUTOR_CONTRACT.repositoryAttachAuthorized !== false ||
  LIVE_EXECUTOR_CONTRACT.repositoryArmAuthorized !== false ||
  LIVE_EXECUTOR_CONTRACT.firstIncidentWriteAuthorized !== false ||
  LIVE_EXECUTOR_CONTRACT.suggestOnlyAuthorized !== false ||
  LIVE_EXECUTOR_CONTRACT.autoAuthorized !== false
) {
  throw new Error('executor_fail_closed_rebind_contract_mismatch');
}

if (
  POST_MIGRATION_REBIND_PLAN_BINDING_ALGORITHM !==
    'SHA256_POST_MIGRATION_REBIND_PLAN_V1' ||
  typeof postMigrationControlStateFingerprint !== 'function' ||
  typeof postMigrationRebindPlanFingerprint !== 'function' ||
  typeof executePostMigrationRebind !== 'function'
) {
  throw new Error('rebind_binding_or_executor_import_mismatch');
}

await executePostMigrationRebind({
  config: LIVE_EXECUTOR_DEFAULTS,
}).then(
  () => {
    throw new Error('default_disarmed_rebind_unexpectedly_executed');
  },
  (error) => {
    if (!String(error?.message ?? error)
      .includes('post_migration_rebind_execution_not_armed')) {
      throw error;
    }
  },
);

console.log('PASS: canonical executor imports with exact rebind dependencies.');
console.log('PASS: post-migration rebind blocks before Admin SDK dynamic import when not armed.');
console.log('PASS: control/plan binding helper imports as pure deterministic helper.');
console.log('PASS: role enable / hold release / attach / arm remain unauthorized.');
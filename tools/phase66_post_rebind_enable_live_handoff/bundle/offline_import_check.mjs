
import {
  LIVE_EXECUTOR_DEFAULTS,
  POST_REBIND_ENABLE_LIVE_DEFAULTS,
  POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT,
  assertLiveExecutorDefaultDisarmed,
  executePostRebindEnableAtomicRoleEnableHoldRelease,
  executePostRebindEnableReplacementTokenIssue,
} from './tools/phase66_role_inventory_migration/src/trusted_admin_sdk_executor.mjs';

import {
  POST_REBIND_ENABLE_TRANSACTION_BODY_CONTRACT,
} from './tools/phase66_post_rebind_enable_offline/src/trusted_post_rebind_enable_transaction_body.mjs';

if (assertLiveExecutorDefaultDisarmed() !== true) {
  throw new Error('canonical_executor_default_disarmed_assertion_failed');
}

if (LIVE_EXECUTOR_DEFAULTS.executionArmed !== false) {
  throw new Error('canonical_executor_unexpectedly_armed');
}

if (POST_REBIND_ENABLE_LIVE_DEFAULTS.executionArmed !== false) {
  throw new Error('post_rebind_enable_executor_unexpectedly_armed');
}

for (const [name, value] of
  Object.entries(POST_REBIND_ENABLE_LIVE_DEFAULTS)) {
  if (name.startsWith('allow') && value !== false) {
    throw new Error(
      `post_rebind_enable_default_capability_enabled:${name}`,
    );
  }
}

if (
  POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
    .canonicalAdminSdkAuthorityOnly !== true ||
  POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
    .secondAdminSdkAuthorityAllowed !== false ||
  POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
    .replacementTokenRawCredentialRequired !== true ||
  POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
    .replacementTokenRawCredentialPersisted !== false ||
  POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
    .replacementTokenIssueExactWrites !== 2 ||
  POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
    .atomicEnableExactWrites !== 5 ||
  POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
    .repositoryAttachAuthorized !== false ||
  POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
    .repositoryArmAuthorized !== false ||
  POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
    .firstIncidentWriteAuthorized !== false ||
  POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
    .suggestOnlyAuthorized !== false ||
  POST_REBIND_ENABLE_LIVE_EXECUTOR_CONTRACT
    .autoAuthorized !== false
) {
  throw new Error(
    'post_rebind_enable_live_contract_fail_closed_mismatch',
  );
}

if (
  POST_REBIND_ENABLE_TRANSACTION_BODY_CONTRACT
    .replacementTokenIssuanceWrites !== 2 ||
  POST_REBIND_ENABLE_TRANSACTION_BODY_CONTRACT
    .atomicEnableWrites !== 5 ||
  POST_REBIND_ENABLE_TRANSACTION_BODY_CONTRACT
    .roleEnableAndHoldReleaseAtomic !== true ||
  POST_REBIND_ENABLE_TRANSACTION_BODY_CONTRACT
    .replacementTokenConsumedInsideAtomicEnable !== true
) {
  throw new Error(
    'post_rebind_enable_transaction_body_contract_mismatch',
  );
}

await executePostRebindEnableReplacementTokenIssue({}).then(
  () => {
    throw new Error(
      'default_disarmed_token_issue_unexpectedly_executed',
    );
  },
  (error) => {
    if (
      !String(error?.message ?? error)
        .includes('post_rebind_enable_token_issue_not_armed')
    ) {
      throw error;
    }
  },
);

await executePostRebindEnableAtomicRoleEnableHoldRelease({}).then(
  () => {
    throw new Error(
      'default_disarmed_atomic_enable_unexpectedly_executed',
    );
  },
  (error) => {
    if (
      !String(error?.message ?? error)
        .includes('post_rebind_enable_atomic_not_armed')
    ) {
      throw error;
    }
  },
);

console.log(
  'PASS: canonical executor + post-rebind enable integration imports offline.',
);
console.log(
  'PASS: both new live entrypoints block before Admin SDK import when disarmed.',
);
console.log(
  'PASS: raw replacement-token credential required but not persisted.',
);
console.log(
  'PASS: exact 2-write token issue + 5-write atomic enable contract locked.',
);
import {
  LIVE_EXECUTOR_CONTRACT,
  LIVE_EXECUTOR_DEFAULTS,
  assertLiveExecutorDefaultDisarmed,
} from './src/trusted_admin_sdk_executor.mjs';

if (assertLiveExecutorDefaultDisarmed() !== true) {
  throw new Error('Executor default-disarmed assertion failed.');
}

if (LIVE_EXECUTOR_DEFAULTS.executionArmed !== false) {
  throw new Error('Executor unexpectedly armed.');
}

for (const [name, value] of
  Object.entries(LIVE_EXECUTOR_DEFAULTS)) {
  if (name.startsWith('allow') && value !== false) {
    throw new Error(
      `Executor default capability unexpectedly enabled: ${name}`,
    );
  }
}

if (
  LIVE_EXECUTOR_CONTRACT.projectId !== 'swat-ride-v2' ||
  LIVE_EXECUTOR_CONTRACT.migrationCreatesRoleEnabled !== false ||
  LIVE_EXECUTOR_CONTRACT.migrationReleasesHold !== false ||
  LIVE_EXECUTOR_CONTRACT.repositoryAttachAuthorized !== false ||
  LIVE_EXECUTOR_CONTRACT.repositoryArmAuthorized !== false ||
  LIVE_EXECUTOR_CONTRACT.suggestOnlyAuthorized !== false ||
  LIVE_EXECUTOR_CONTRACT.autoAuthorized !== false
) {
  throw new Error('Executor fail-closed contract mismatch.');
}

console.log('PASS: executor imported without Admin SDK initialization.');
console.log('PASS: executor remains default-disarmed.');
console.log('PASS: role enable / hold release / attach / arm remain unauthorized.');
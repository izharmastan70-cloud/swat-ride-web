import { readFile } from 'node:fs/promises';

import { SAFETY, assertOfflineSafety } from './contract.mjs';
import { validateDryRunEvidence } from './validate_evidence.mjs';

function parseEvidencePath(argv) {
  const index = argv.indexOf('--evidence');

  if (index === -1 || !argv[index + 1]) {
    throw new Error('Usage: node src/dry_run_cli.mjs --evidence <local-json>');
  }

  return argv[index + 1];
}

assertOfflineSafety();

if (
  SAFETY.networkReadEnabled !== false ||
  SAFETY.networkWriteEnabled !== false ||
  SAFETY.credentialLoadingEnabled !== false ||
  SAFETY.adminSdkInitializationEnabled !== false
) {
  throw new Error('Dry-run CLI is not allowed to access Firebase/Admin SDK');
}

const evidencePath = parseEvidencePath(process.argv.slice(2));
const raw = await readFile(evidencePath, 'utf8');
const evidence = JSON.parse(raw);

const result = validateDryRunEvidence(evidence);

console.log(
  JSON.stringify(
    {
      mode: 'OFFLINE_DRY_RUN_ONLY',
      executionArmed: false,
      networkRead: false,
      networkWrite: false,
      credentialLoad: false,
      adminSdkInit: false,
      firestoreWrite: false,
      roleCreate: false,
      approvalConsume: false,
      attach: false,
      arm: false,
      suggestOnly: false,
      auto: false,
      validation: result,
    },
    null,
    2,
  ),
);

if (!result.ok) {
  process.exitCode = 2;
}
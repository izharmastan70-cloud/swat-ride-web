
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here =
  path.dirname(fileURLToPath(import.meta.url));

const manifest =
  JSON.parse(
    fs.readFileSync(
      path.join(here, 'bundle_manifest.json'),
      'utf8',
    ),
  );

function sha256File(filePath) {
  return crypto
    .createHash('sha256')
    .update(fs.readFileSync(filePath))
    .digest('hex')
    .toUpperCase();
}

for (const [relativePath, expectedSha] of
  Object.entries(manifest.protectedFiles)) {
  const full =
    path.join(here, relativePath);

  if (!fs.existsSync(full)) {
    throw new Error(
      `bundle_file_missing:${relativePath}`,
    );
  }

  const actual =
    sha256File(full);

  if (actual !== expectedSha) {
    throw new Error(
      `bundle_sha_mismatch:${relativePath}:${actual}:${expectedSha}`,
    );
  }
}

if (
  manifest.projectId !== 'swat-ride-v2' ||
  manifest.defaultExecutionArmed !== false ||
  manifest.liveWritesAuthorizedByThisBundle !== false ||
  manifest.approvalCreateAuthorizedByThisBundle !== false ||
  manifest.replacementTokenIssueAuthorizedByThisBundle !== false ||
  manifest.atomicEnableAuthorizedByThisBundle !== false ||
  manifest.repositoryAttachAuthorizedByThisBundle !== false ||
  manifest.repositoryArmAuthorizedByThisBundle !== false ||
  manifest.firstIncidentWriteAuthorizedByThisBundle !== false
) {
  throw new Error('bundle_manifest_fail_closed_mismatch');
}

console.log(
  'PASS: post-rebind enable trusted handoff bundle hashes and fail-closed manifest verified.',
);
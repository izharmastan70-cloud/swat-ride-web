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

if (manifest.projectId !== 'swat-ride-v2') {
  throw new Error('Bundle project binding mismatch.');
}

if (manifest.defaultExecutionArmed !== false) {
  throw new Error('Bundle must remain default-disarmed.');
}

if (manifest.rolloutStage !== 'MONITOR_ONLY') {
  throw new Error('Bundle rollout boundary changed.');
}

for (const [relativePath, expectedSha] of
  Object.entries(manifest.protectedFiles)) {
  const fullPath =
    path.join(here, relativePath);

  if (!fs.existsSync(fullPath)) {
    throw new Error(
      `Bundle file missing: ${relativePath}`,
    );
  }

  const actual =
    sha256File(fullPath);

  if (actual !== String(expectedSha).toUpperCase()) {
    throw new Error(
      `Bundle SHA mismatch: ${relativePath}`,
    );
  }

  console.log(
    `PASS bundle SHA: ${relativePath}`,
  );
}

console.log('PASS: bundle exact hashes locked.');
console.log('PASS: default execution armed = NO.');
console.log('PASS: live write authority in bundle = NO.');
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
  throw new Error('bundle_project_binding_mismatch');
}

if (manifest.step !== '1I-T-AN-A-V2') {
  throw new Error('bundle_step_binding_mismatch');
}

if (manifest.defaultExecutionArmed !== false) {
  throw new Error('bundle_must_remain_default_disarmed');
}

if (manifest.intendedNextUse !==
    'READ_ONLY_LIVE_POST_MIGRATION_REBIND_PREFLIGHT') {
  throw new Error('bundle_next_use_boundary_mismatch');
}

if (manifest.freshRebindApprovalCreateAuthorizedNow !== false ||
    manifest.livePostMigrationRebindAuthorizedNow !== false) {
  throw new Error('bundle_live_authority_must_be_false');
}

if (manifest.currentRoleCount !== 23 ||
    manifest.currentAuthorityManifestRevision !== 2 ||
    manifest.targetAuthorityManifestRevision !== 3 ||
    manifest.currentGuardRevision !== 2 ||
    manifest.targetGuardRevision !== 3) {
  throw new Error('bundle_post_migration_revision_boundary_mismatch');
}

if (manifest.targetRoleEnabledRequired !== false ||
    manifest.targetRoleModeRequired !== 'ASK_FIRST' ||
    manifest.rolloutStageRequired !== 'MONITOR_ONLY' ||
    manifest.voiceSuperAdminMonitorOnlySwitchRequired !== false ||
    manifest.migrationHoldStatusRequired !== 'ROLE_DELTA_COMMITTED' ||
    manifest.migrationHoldMustRemainActive !== true) {
  throw new Error('bundle_fail_closed_post_migration_state_mismatch');
}

if (manifest.exactRebindWrites !== 6 ||
    manifest.exactRebindWriteShape !== 'update1_set2_create3_delete0') {
  throw new Error('bundle_rebind_write_shape_mismatch');
}

for (const [relativePath, expectedSha] of
  Object.entries(manifest.protectedFiles)) {
  const fullPath =
    path.join(here, relativePath);

  if (!fs.existsSync(fullPath)) {
    throw new Error(
      `bundle_file_missing:${relativePath}`,
    );
  }

  const actual =
    sha256File(fullPath);

  if (actual !== String(expectedSha).toUpperCase()) {
    throw new Error(
      `bundle_sha_mismatch:${relativePath}`,
    );
  }

  console.log(
    `PASS bundle SHA: ${relativePath}`,
  );
}

console.log('PASS: updated trusted rebind bundle exact hashes locked.');
console.log('PASS: bundle default execution armed = NO.');
console.log('PASS: bundle authorizes no Firestore read/write by itself.');
console.log('PASS: fresh rebind approval create now = NO.');
console.log('PASS: live post-migration rebind now = NO.');
export const POST_REBIND_ENABLE = Object.freeze({
  enableOperation:
    'ENABLE_SECURITY_INCIDENT_ROLE_AND_RELEASE_MIGRATION_HOLD_23_ROLE',
  replacementTokenOperation:
    'ISSUE_FRESH_SECURITY_INCIDENT_POST_REBIND_ENABLE_TOKEN',
  roleId: 'security_incident_agent',
  module: 'security_incident',
  actionId: 'security_incident.attach_runtime',
  rolloutStage: 'MONITOR_ONLY',
  holdPreStatus: 'ROLE_DELTA_COMMITTED',
  holdReleasedStatus: 'RELEASED',
  authorityManifestRevision: 3,
  guardRevision: 3,
  roleCount: 23,
  maxReplacementTokenTtlMs: 90_000,
  minApprovalRemainingMs: 60_000,
  requesterPrefix: 'phase66_enable_coordinator_sha256:',
  ownerPrefix: 'phase66_owner_sha256:',
  tokenPurpose: 'POST_REBIND_ROLE_ENABLE_HOLD_RELEASE',
  replacementTokenWriteOrder: Object.freeze([
    'FRESH_REPLACEMENT_TOKEN_CREATE',
    'REPLACEMENT_TOKEN_AUDIT_CREATE',
  ]),
  atomicEnableWriteOrder: Object.freeze([
    'OWNER_ENABLE_APPROVAL_CONSUME',
    'REPLACEMENT_TOKEN_CONSUME',
    'SECURITY_INCIDENT_ROLE_ENABLE',
    'MIGRATION_HOLD_RELEASE',
    'ENABLE_AUDIT_CREATE',
  ]),
});

function fail(code) {
  throw new Error(code);
}

function lower(value) {
  return String(value ?? '').trim().toLowerCase();
}

function upper(value) {
  return String(value ?? '').trim().toUpperCase();
}

function isSha(value) {
  return /^[a-f0-9]{64}$/.test(lower(value));
}

function toMillis(value) {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return value;
  }

  if (value && typeof value.toMillis === 'function') {
    return value.toMillis();
  }

  const parsed = Date.parse(String(value ?? ''));
  return Number.isFinite(parsed) ? parsed : NaN;
}

function dataOf(snapshot, label) {
  if (!snapshot || snapshot.exists !== true) {
    fail(`${label}_missing`);
  }

  const data =
    typeof snapshot.data === 'function'
      ? snapshot.data()
      : snapshot.data;

  if (!data || typeof data !== 'object') {
    fail(`${label}_unreadable`);
  }

  return data;
}

function refId(ref, label) {
  const value = String(ref?.id ?? '').trim();

  if (!value) {
    fail(`${label}_reference_id_missing`);
  }

  return value;
}

function exactRoleDisabled(role) {
  return (
    role.roleId === POST_REBIND_ENABLE.roleId &&
    role.module === POST_REBIND_ENABLE.module &&
    role.enabled === false &&
    role.mode === 'ASK_FIRST' &&
    role.aiClass === 'FREE_AI' &&
    role.privacyLevel === 'HIGHLY_SENSITIVE' &&
    Array.isArray(role.allowedActions) &&
    role.allowedActions.length === 1 &&
    role.allowedActions[0] === POST_REBIND_ENABLE.actionId &&
    Array.isArray(role.approvalRequiredActions) &&
    role.approvalRequiredActions.length === 1 &&
    role.approvalRequiredActions[0] === POST_REBIND_ENABLE.actionId &&
    Array.isArray(role.forbiddenActions) &&
    role.forbiddenActions.length === 0
  );
}

function exactCommonCheckpoint({
  manifest,
  hold,
  guard,
  rollout,
  role,
  rebindReceipt,
  request,
}) {
  if (
    manifest.status !== 'ACTIVE' ||
    Number(manifest.revision) !==
      POST_REBIND_ENABLE.authorityManifestRevision ||
    Number(manifest.roleCount) !== POST_REBIND_ENABLE.roleCount ||
    manifest.postMigrationRebindRequired !== false
  ) {
    fail('authority_manifest_not_exact_post_rebind_state');
  }

  if (
    hold.status !== POST_REBIND_ENABLE.holdPreStatus ||
    hold.migrationHoldActive !== true ||
    Number(hold.authorityManifestRevision) !==
      POST_REBIND_ENABLE.authorityManifestRevision ||
    hold.postMigrationRebindRequired !== false ||
    hold.repositoryAttachAuthorized !== false ||
    hold.repositoryArmAuthorized !== false ||
    hold.firstIncidentWriteAuthorized !== false ||
    hold.authorizesSuggestOnly !== false ||
    hold.authorizesAuto !== false
  ) {
    fail('migration_hold_not_exact_active_post_rebind_state');
  }

  if (
    Number(guard.revision) !== POST_REBIND_ENABLE.guardRevision ||
    Number(guard.roleCount) !== POST_REBIND_ENABLE.roleCount ||
    guard.targetStage !== POST_REBIND_ENABLE.rolloutStage
  ) {
    fail('guard_not_exact_revision3_role23_monitor_only');
  }

  if (
    rollout.stage !== POST_REBIND_ENABLE.rolloutStage ||
    Number(rollout.autoTrafficPercent ?? 0) !== 0 ||
    Number(rollout.businessWriteTrafficPercent ?? 0) !== 0 ||
    rollout.externalChannelsEnabled !== false
  ) {
    fail('rollout_not_exact_monitor_only');
  }

  if (!exactRoleDisabled(role)) {
    fail('security_incident_role_not_exact_disabled_ask_first');
  }

  if (
    Number(rebindReceipt.authorityManifestRevision) !==
      POST_REBIND_ENABLE.authorityManifestRevision ||
    Number(rebindReceipt.guardRevision) !==
      POST_REBIND_ENABLE.guardRevision ||
    Number(rebindReceipt.roleCount) !== POST_REBIND_ENABLE.roleCount ||
    rebindReceipt.migrationHoldStillActive !== true ||
    rebindReceipt.securityIncidentRoleStillDisabled !== true ||
    rebindReceipt.repositoryAttachAuthorized !== false ||
    rebindReceipt.repositoryArmAuthorized !== false ||
    rebindReceipt.firstIncidentWriteAuthorized !== false ||
    rebindReceipt.authorizesSuggestOnly !== false ||
    rebindReceipt.authorizesAuto !== false
  ) {
    fail('rebind_receipt_not_exact');
  }

  if (
    isSha(request.rebindReceiptIdSha256) !== true ||
    lower(rebindReceipt.receiptIdSha256) !==
      lower(request.rebindReceiptIdSha256)
  ) {
    fail('rebind_receipt_identity_mismatch');
  }
}

function validateEnableApproval(approval, request, nowMs) {
  if (
    approval.approvalId !== request.approvalId ||
    approval.roleId !== POST_REBIND_ENABLE.roleId ||
    approval.module !== POST_REBIND_ENABLE.module ||
    approval.actionId !== POST_REBIND_ENABLE.actionId ||
    upper(approval.risk) !== 'HIGH' ||
    upper(approval.status) !== 'APPROVED' ||
    approval.consumedAt != null
  ) {
    fail('enable_approval_not_approved_unconsumed_exact');
  }

  if (
    approval.requestedBy !==
      `${POST_REBIND_ENABLE.requesterPrefix}${lower(
        request.requesterReferenceSha256,
      )}`
  ) {
    fail('enable_approval_requester_binding_mismatch');
  }

  if (
    approval.decidedBy !==
      `${POST_REBIND_ENABLE.ownerPrefix}${lower(
        request.ownerApproverReferenceSha256,
      )}`
  ) {
    fail('enable_approval_owner_binding_mismatch');
  }

  const expiresAtMs = toMillis(approval.expiresAt);

  if (
    !Number.isFinite(expiresAtMs) ||
    expiresAtMs - nowMs < POST_REBIND_ENABLE.minApprovalRemainingMs
  ) {
    fail('enable_approval_ttl_too_short');
  }

  const scope = approval.actionScope;

  if (!scope || typeof scope !== 'object') {
    fail('enable_approval_scope_missing');
  }

  const exact =
    scope.operation === POST_REBIND_ENABLE.enableOperation &&
    scope.roleId === POST_REBIND_ENABLE.roleId &&
    scope.module === POST_REBIND_ENABLE.module &&
    scope.actionId === POST_REBIND_ENABLE.actionId &&
    scope.rolloutStage === POST_REBIND_ENABLE.rolloutStage &&
    Number(scope.roleCount) === POST_REBIND_ENABLE.roleCount &&
    Number(scope.authorityManifestRevision) ===
      POST_REBIND_ENABLE.authorityManifestRevision &&
    Number(scope.guardRevision) === POST_REBIND_ENABLE.guardRevision &&
    lower(scope.rebindReceiptIdSha256) ===
      lower(request.rebindReceiptIdSha256) &&
    lower(scope.replacementTokenIdSha256) ===
      lower(request.replacementTokenIdSha256) &&
    scope.freshOwnerVerifiedAtApproval === true &&
    scope.explicitOwnerApproval === true &&
    scope.migrationApprovalReuseAllowed === false &&
    scope.rebindApprovalReuseAllowed === false &&
    scope.oldArmingTokenReuseAllowed === false &&
    scope.replacementTokenConsumeAuthorized === true &&
    scope.roleEnableAuthorized === true &&
    scope.migrationHoldReleaseAuthorized === true &&
    scope.repositoryAttachAuthorized === false &&
    scope.repositoryArmAuthorized === false &&
    scope.firstIncidentWriteAuthorized === false &&
    scope.authorizesSuggestOnly === false &&
    scope.authorizesAuto === false;

  if (!exact) {
    fail('enable_approval_scope_mismatch');
  }
}

function validateReplacementToken(token, request, nowMs) {
  if (
    lower(token.tokenIdSha256) !== lower(request.replacementTokenIdSha256) ||
    upper(token.status) !== 'READY' ||
    token.consumedAt != null ||
    token.targetStage !== POST_REBIND_ENABLE.rolloutStage ||
    token.purpose !== POST_REBIND_ENABLE.tokenPurpose ||
    Number(token.guardRevision) !== POST_REBIND_ENABLE.guardRevision ||
    Number(token.roleCount) !== POST_REBIND_ENABLE.roleCount ||
    token.ownerApprovalId !== request.approvalId ||
    lower(token.actorReferenceSha256) !==
      lower(request.ownerApproverReferenceSha256) ||
    lower(token.rebindReceiptIdSha256) !==
      lower(request.rebindReceiptIdSha256)
  ) {
    fail('replacement_token_binding_mismatch');
  }

  const expiresAtMs = toMillis(token.expiresAt);

  if (!Number.isFinite(expiresAtMs) || expiresAtMs <= nowMs) {
    fail('replacement_token_expired');
  }
}

function validateRequest(request) {
  for (const [field, value] of Object.entries({
    requesterReferenceSha256: request.requesterReferenceSha256,
    ownerApproverReferenceSha256:
      request.ownerApproverReferenceSha256,
    replacementTokenIdSha256: request.replacementTokenIdSha256,
    rebindReceiptIdSha256: request.rebindReceiptIdSha256,
  })) {
    if (!isSha(value)) {
      fail(`${field}_invalid_sha256`);
    }
  }

  if (!String(request.approvalId ?? '').trim()) {
    fail('approval_id_required');
  }

  if (
    lower(request.requesterReferenceSha256) ===
    lower(request.ownerApproverReferenceSha256)
  ) {
    fail('requester_owner_must_differ');
  }
}

export async function issueFreshReplacementTokenInCallerTransaction({
  tx,
  refs,
  request,
  serverTimestamp,
}) {
  validateRequest(request);

  const nowMs = Number(request.nowMs);

  if (!Number.isFinite(nowMs)) {
    fail('now_ms_required');
  }

  const issuedAtMs = toMillis(request.issuedAt);
  const expiresAtMs = toMillis(request.expiresAt);

  if (
    !Number.isFinite(issuedAtMs) ||
    !Number.isFinite(expiresAtMs) ||
    issuedAtMs > nowMs + 5_000 ||
    expiresAtMs <= nowMs ||
    expiresAtMs - issuedAtMs >
      POST_REBIND_ENABLE.maxReplacementTokenTtlMs
  ) {
    fail('replacement_token_ttl_invalid');
  }

  const [
    approvalSnapshot,
    manifestSnapshot,
    holdSnapshot,
    guardSnapshot,
    rolloutSnapshot,
    roleSnapshot,
    rebindReceiptSnapshot,
    historicalTokenSnapshot,
    replacementTokenSnapshot,
  ] = await Promise.all([
    tx.get(refs.approval),
    tx.get(refs.manifest),
    tx.get(refs.hold),
    tx.get(refs.guard),
    tx.get(refs.rollout),
    tx.get(refs.role),
    tx.get(refs.rebindReceipt),
    tx.get(refs.historicalToken),
    tx.get(refs.replacementToken),
  ]);

  if (replacementTokenSnapshot?.exists === true) {
    fail('replacement_token_sha_collision');
  }

  const approval = dataOf(approvalSnapshot, 'approval');
  const manifest = dataOf(manifestSnapshot, 'manifest');
  const hold = dataOf(holdSnapshot, 'hold');
  const guard = dataOf(guardSnapshot, 'guard');
  const rollout = dataOf(rolloutSnapshot, 'rollout');
  const role = dataOf(roleSnapshot, 'role');
  const rebindReceipt = dataOf(
    rebindReceiptSnapshot,
    'rebind_receipt',
  );
  const historicalToken = dataOf(
    historicalTokenSnapshot,
    'historical_token',
  );

  validateEnableApproval(approval, request, nowMs);

  exactCommonCheckpoint({
    manifest,
    hold,
    guard,
    rollout,
    role,
    rebindReceipt,
    request,
  });

  if (
    upper(historicalToken.status) !== 'READY' ||
    historicalToken.consumedAt != null ||
    Number(historicalToken.guardRevision) !==
      POST_REBIND_ENABLE.guardRevision ||
    Number(historicalToken.roleCount) !==
      POST_REBIND_ENABLE.roleCount ||
    toMillis(historicalToken.expiresAt) >= nowMs
  ) {
    fail('historical_rebind_token_not_exact_expired_ready_history');
  }

  if (
    refId(refs.replacementToken, 'replacement_token') !==
    lower(request.replacementTokenIdSha256)
  ) {
    fail('replacement_token_reference_binding_mismatch');
  }

  const tokenPayload = {
    tokenIdSha256: lower(request.replacementTokenIdSha256),
    status: 'READY',
    purpose: POST_REBIND_ENABLE.tokenPurpose,
    targetStage: POST_REBIND_ENABLE.rolloutStage,
    actorReferenceSha256:
      lower(request.ownerApproverReferenceSha256),
    ownerApprovalId: request.approvalId,
    rebindReceiptIdSha256:
      lower(request.rebindReceiptIdSha256),
    guardRevision: POST_REBIND_ENABLE.guardRevision,
    roleCount: POST_REBIND_ENABLE.roleCount,
    issuedAt: request.issuedAt,
    expiresAt: request.expiresAt,
    consumedAt: null,
    createdAt: serverTimestamp(),
  };

  const auditPayload = {
    eventType: 'SYSTEM_EVENT',
    severity: 'WARNING',
    actorType: 'ADMIN',
    actorId: lower(request.ownerApproverReferenceSha256),
    roleId: POST_REBIND_ENABLE.roleId,
    module: 'ai_core',
    actionId:
      'ai.production_rollout.security_incident.post_rebind_enable_token.issue',
    result: 'FRESH_REPLACEMENT_TOKEN_ISSUED',
    reason:
      'Fresh Owner-approved short-lived replacement token issued for the separate post-rebind role-enable and migration-hold-release boundary.',
    relatedApprovalId: request.approvalId,
    scope: {
      roleCount: POST_REBIND_ENABLE.roleCount,
      authorityManifestRevision:
        POST_REBIND_ENABLE.authorityManifestRevision,
      guardRevision: POST_REBIND_ENABLE.guardRevision,
      rolloutStage: POST_REBIND_ENABLE.rolloutStage,
      roleEnabled: false,
      migrationHoldActive: true,
      replacementTokenIdSha256:
        lower(request.replacementTokenIdSha256),
      historicalTokenReused: false,
      repositoryAttachAuthorized: false,
      repositoryArmAuthorized: false,
      firstIncidentWriteAuthorized: false,
      authorizesSuggestOnly: false,
      authorizesAuto: false,
    },
    createdAt: serverTimestamp(),
  };

  tx.create(refs.replacementToken, tokenPayload);
  tx.create(refs.tokenAudit, auditPayload);

  return {
    status: 'FRESH_REPLACEMENT_TOKEN_ISSUED_FAIL_CLOSED',
    writeOrder: POST_REBIND_ENABLE.replacementTokenWriteOrder,
    replacementTokenStatus: 'READY',
    historicalTokenMutated: false,
    roleEnabled: false,
    migrationHoldReleased: false,
    repositoryAttached: false,
    repositoryArmed: false,
    incidentWritten: false,
    authorizesSuggestOnly: false,
    authorizesAuto: false,
  };
}

export async function executeAtomicRoleEnableAndHoldReleaseInCallerTransaction({
  tx,
  refs,
  request,
  serverTimestamp,
}) {
  validateRequest(request);

  const nowMs = Number(request.nowMs);

  if (!Number.isFinite(nowMs)) {
    fail('now_ms_required');
  }

  const [
    approvalSnapshot,
    manifestSnapshot,
    holdSnapshot,
    guardSnapshot,
    rolloutSnapshot,
    roleSnapshot,
    rebindReceiptSnapshot,
    replacementTokenSnapshot,
  ] = await Promise.all([
    tx.get(refs.approval),
    tx.get(refs.manifest),
    tx.get(refs.hold),
    tx.get(refs.guard),
    tx.get(refs.rollout),
    tx.get(refs.role),
    tx.get(refs.rebindReceipt),
    tx.get(refs.replacementToken),
  ]);

  const approval = dataOf(approvalSnapshot, 'approval');
  const manifest = dataOf(manifestSnapshot, 'manifest');
  const hold = dataOf(holdSnapshot, 'hold');
  const guard = dataOf(guardSnapshot, 'guard');
  const rollout = dataOf(rolloutSnapshot, 'rollout');
  const role = dataOf(roleSnapshot, 'role');
  const rebindReceipt = dataOf(
    rebindReceiptSnapshot,
    'rebind_receipt',
  );
  const replacementToken = dataOf(
    replacementTokenSnapshot,
    'replacement_token',
  );

  validateEnableApproval(approval, request, nowMs);

  exactCommonCheckpoint({
    manifest,
    hold,
    guard,
    rollout,
    role,
    rebindReceipt,
    request,
  });

  validateReplacementToken(replacementToken, request, nowMs);

  if (
    refId(refs.approval, 'approval') !== request.approvalId ||
    refId(refs.role, 'role') !== POST_REBIND_ENABLE.roleId ||
    refId(refs.hold, 'hold') !==
      'security_incident_role_inventory_migration_hold' ||
    refId(refs.replacementToken, 'replacement_token') !==
      lower(request.replacementTokenIdSha256)
  ) {
    fail('atomic_enable_reference_binding_mismatch');
  }

  const rolePatch = {
    enabled: true,
    mode: 'ASK_FIRST',
    updatedAt: serverTimestamp(),
  };

  const holdPatch = {
    status: POST_REBIND_ENABLE.holdReleasedStatus,
    migrationHoldActive: false,
    authorityManifestRevision:
      POST_REBIND_ENABLE.authorityManifestRevision,
    postMigrationRebindRequired: false,
    releasedByApprovalId: request.approvalId,
    releasedByOwnerReferenceSha256:
      lower(request.ownerApproverReferenceSha256),
    releasedAt: serverTimestamp(),
    repositoryAttachAuthorized: false,
    repositoryArmAuthorized: false,
    firstIncidentWriteAuthorized: false,
    authorizesSuggestOnly: false,
    authorizesAuto: false,
    updatedAt: serverTimestamp(),
  };

  const auditPayload = {
    eventType: 'SYSTEM_EVENT',
    severity: 'WARNING',
    actorType: 'ADMIN',
    actorId: lower(request.ownerApproverReferenceSha256),
    roleId: POST_REBIND_ENABLE.roleId,
    module: 'ai_core',
    actionId:
      'ai.production_rollout.security_incident.post_rebind_enable',
    result: 'ROLE_ENABLED_AND_MIGRATION_HOLD_RELEASED',
    reason:
      'Fresh separate Owner approval and fresh replacement token consumed atomically with security_incident_agent enable and migration-hold release under MONITOR_ONLY.',
    relatedApprovalId: request.approvalId,
    scope: {
      roleCount: POST_REBIND_ENABLE.roleCount,
      authorityManifestRevision:
        POST_REBIND_ENABLE.authorityManifestRevision,
      guardRevision: POST_REBIND_ENABLE.guardRevision,
      rolloutStage: POST_REBIND_ENABLE.rolloutStage,
      roleEnabled: true,
      roleMode: 'ASK_FIRST',
      migrationHoldActive: false,
      replacementTokenConsumed: true,
      repositoryAttachAuthorized: false,
      repositoryArmAuthorized: false,
      firstIncidentWriteAuthorized: false,
      authorizesSuggestOnly: false,
      authorizesAuto: false,
    },
    createdAt: serverTimestamp(),
  };

  tx.update(refs.approval, {
    status: 'CONSUMED',
    consumedAt: serverTimestamp(),
  });

  tx.update(refs.replacementToken, {
    status: 'CONSUMED',
    consumedAt: serverTimestamp(),
  });

  tx.update(refs.role, rolePatch);
  tx.update(refs.hold, holdPatch);
  tx.create(refs.enableAudit, auditPayload);

  return {
    status: 'ROLE_ENABLED_AND_MIGRATION_HOLD_RELEASED_FAIL_CLOSED',
    writeOrder: POST_REBIND_ENABLE.atomicEnableWriteOrder,
    approvalConsumed: true,
    replacementTokenConsumed: true,
    roleEnabled: true,
    roleMode: 'ASK_FIRST',
    migrationHoldActive: false,
    migrationHoldReleased: true,
    repositoryAttached: false,
    repositoryArmed: false,
    incidentWritten: false,
    authorizesSuggestOnly: false,
    authorizesAuto: false,
  };
}

export const POST_REBIND_ENABLE_TRANSACTION_BODY_CONTRACT = Object.freeze({
  ownsFirestoreTransaction: false,
  initializesFirebaseAdmin: false,
  initializesFirestore: false,
  performsNetworkIoByItself: false,
  rawTokenAccepted: false,
  rawTokenPersisted: false,
  historicalTokenMutationAllowed: false,
  replacementTokenIssuanceWrites: 2,
  atomicEnableWrites: 5,
  allReadsBeforeFirstWriteRequired: true,
  roleEnableAndHoldReleaseAtomic: true,
  replacementTokenConsumedInsideAtomicEnable: true,
  repositoryAttachAuthorized: false,
  repositoryArmAuthorized: false,
  firstIncidentWriteAuthorized: false,
  authorizesSuggestOnly: false,
  authorizesAuto: false,
});
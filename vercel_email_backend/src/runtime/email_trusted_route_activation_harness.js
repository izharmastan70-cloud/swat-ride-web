import {
  mayRequestRealSenderSetup,
} from '../config/email_sender_setup_workflow_contract.js';

function nonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function deny(stage, code) {
  return Object.freeze({
    ok: false,
    readyForRealSenderSetup: false,
    providerExecutionAllowed: false,
    liveRouteActivationAllowed: false,
    stage,
    code,
  });
}

export async function runSyntheticTrustedRouteActivationHarness({
  idToken,
  handoff,
  runtime,
}) {
  if (!runtime ||
      runtime.liveSendEnabled !== false ||
      runtime.providerNetworkAllowed !== false ||
      runtime.routeWiringAllowed !== false) {
    return deny(
        'RUNTIME',
        'TRUSTED_RUNTIME_NOT_HARD_DISABLED');
  }

  if (!handoff ||
      !nonEmptyString(handoff.approvalId) ||
      !nonEmptyString(handoff.handoffId) ||
      !nonEmptyString(handoff.authorizationRequestId) ||
      !nonEmptyString(handoff.draftId) ||
      !nonEmptyString(handoff.bindingFingerprint) ||
      !nonEmptyString(handoff.senderIdentityId) ||
      !nonEmptyString(handoff.providerId) ||
      !nonEmptyString(handoff.fromAddress)) {
    return deny(
        'HANDOFF',
        'TRUSTED_HARNESS_HANDOFF_INVALID');
  }

  if (runtime.providerTransport?.ready !== false ||
      runtime.providerTransport?.liveNetworkAllowed !== false) {
    return deny(
        'PROVIDER',
        'TRUSTED_HARNESS_PROVIDER_MUST_BE_DISABLED');
  }

  if (runtime.authVerifier?.ready !== true) {
    return deny(
        'AUTH',
        'TRUSTED_HARNESS_AUTH_NOT_READY');
  }

  const identity =
      await runtime.authVerifier.verifyIdToken(idToken);

  if (identity?.ok !== true ||
      !nonEmptyString(identity.uid)) {
    return deny(
        'AUTH',
        'TRUSTED_HARNESS_AUTH_REJECTED');
  }

  if (runtime.superAdminAuthorizer?.ready !== true) {
    return deny(
        'SUPER_ADMIN',
        'TRUSTED_HARNESS_SUPER_ADMIN_NOT_READY');
  }

  const superAdmin =
      await runtime.superAdminAuthorizer.authorize(identity);

  if (superAdmin?.ok !== true ||
      superAdmin?.authorized !== true ||
      superAdmin?.uid !== identity.uid) {
    return deny(
        'SUPER_ADMIN',
        'TRUSTED_HARNESS_SUPER_ADMIN_REJECTED');
  }

  if (runtime.masterToggleRechecker?.ready !== true) {
    return deny(
        'MASTER_TOGGLE',
        'TRUSTED_HARNESS_MASTER_TOGGLE_NOT_READY');
  }

  const masterToggle =
      await runtime.masterToggleRechecker
          .recheckEmailAgentEnabled();

  if (masterToggle?.ok !== true ||
      masterToggle?.enabled !== true) {
    return deny(
        'MASTER_TOGGLE',
        'TRUSTED_HARNESS_EMAIL_AGENT_OFF');
  }

  if (runtime.approvalRechecker?.ready !== true) {
    return deny(
        'APPROVAL',
        'TRUSTED_HARNESS_APPROVAL_NOT_READY');
  }

  const approval =
      await runtime.approvalRechecker
          .recheckConsumedApproval({
            callerUid: identity.uid,
            approvalId: handoff.approvalId,
            authorizationRequestId:
                handoff.authorizationRequestId,
            draftId: handoff.draftId,
            bindingFingerprint:
                handoff.bindingFingerprint,
            roleId: 'email_agent',
            actionId: 'email.send',
            module: 'email',
          });

  if (approval?.ok !== true ||
      approval?.consumed !== true ||
      approval?.exactActionScopeValidated !== true) {
    return deny(
        'APPROVAL',
        'TRUSTED_HARNESS_APPROVAL_REJECTED');
  }

  if (runtime.senderVerifier?.ready !== true) {
    return deny(
        'SENDER',
        'TRUSTED_HARNESS_SENDER_NOT_READY');
  }

  const sender =
      await runtime.senderVerifier
          .verifySenderIdentity({
            senderIdentityId:
                handoff.senderIdentityId,
            providerId:
                handoff.providerId,
            fromAddress:
                handoff.fromAddress,
          });

  if (sender?.ok !== true ||
      sender?.verified !== true ||
      sender?.enabled !== true) {
    return deny(
        'SENDER',
        'TRUSTED_HARNESS_SENDER_REJECTED');
  }

  if (runtime.replayGuard?.ready !== true) {
    return deny(
        'IDEMPOTENCY',
        'TRUSTED_HARNESS_REPLAY_GUARD_NOT_READY');
  }

  const replay =
      await runtime.replayGuard.claim({
        approvalId:
            handoff.approvalId,
        handoffId:
            handoff.handoffId,
        authorizationRequestId:
            handoff.authorizationRequestId,
        bindingFingerprint:
            handoff.bindingFingerprint,
        providerId:
            handoff.providerId,
      });

  if (replay?.ok !== true ||
      replay?.claimed !== true) {
    return deny(
        'IDEMPOTENCY',
        'TRUSTED_HARNESS_REPLAY_REJECTED');
  }

  const readyForRealSenderSetup =
      mayRequestRealSenderSetup({
        exactApprovalScopeValidatorReady:
            approval.exactActionScopeValidated === true,
        masterToggleRecheckerReady:
            masterToggle.enabled === true,
        firebaseAdminAdaptersReady:
            true,
        liveSendEnabled:
            runtime.liveSendEnabled,
      });

  if (!readyForRealSenderSetup) {
    return deny(
        'SENDER_SETUP_GATE',
        'TRUSTED_HARNESS_SENDER_SETUP_NOT_READY');
  }

  return Object.freeze({
    ok: true,
    readyForRealSenderSetup: true,
    providerExecutionAllowed: false,
    liveRouteActivationAllowed: false,
    stage: 'COMPLETE',
    code:
        'SYNTHETIC_TRUSTED_ROUTE_PRECHECK_PASSED',
    uid: identity.uid,
    approvalId: handoff.approvalId,
    handoffId: handoff.handoffId,
    senderIdentityId:
        handoff.senderIdentityId,
    providerId:
        handoff.providerId,
    idempotencyKey:
        replay.idempotencyKey ?? '',
  });
}
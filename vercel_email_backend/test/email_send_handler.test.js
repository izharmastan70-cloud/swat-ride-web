import assert from 'node:assert/strict';
import test from 'node:test';

import { buildPhase44F3dcServerConfig } from '../src/config/email_server_config.js';
import { createEmailSendHandler } from '../src/core/email_send_handler.js';
import { DisabledBrevoTransactionalEmailTransport } from '../src/providers/brevo_transactional_email_transport.js';

const handoff = Object.freeze({
  handoffId: 'handoff_server_test',
  authorizationRequestId: 'authorization_server_test',
  approvalId: 'approval_server_test',
  draftId: 'draft_server_test',
  bindingFingerprint: 'binding_server_test',
  senderIdentityId: 'sender_primary',
  providerId: 'brevo',
  fromAddress: 'support@example.com',
  to: ['customer@example.com'],
  cc: [],
  bcc: [],
  subject: 'Synthetic server test',
  bodyText: 'Synthetic server body.',
  attachmentIds: [],
});

function request({
  authorization = 'Bearer synthetic.firebase.id.token',
  body = { handoff },
  method = 'POST',
} = {}) {
  return new Request('https://example.vercel.app/api/email/send', {
    method,
    headers: {
      authorization,
      'content-type': 'application/json',
    },
    body: method === 'POST' ? JSON.stringify(body) : undefined,
  });
}

function readyDependencies(overrides = {}) {
  const calls = {
    auth: 0,
    superAdmin: 0,
    masterToggle: 0,
    approval: 0,
    sender: 0,
    replay: 0,
    provider: 0,
  };

  const config = {
    ...buildPhase44F3dcServerConfig(),
    liveSendEnabled: true,
  };

  const authVerifier = {
    ready: true,
    async verifyIdToken(token) {
      calls.auth += 1;
      return {
        ok: token === 'synthetic.firebase.id.token',
        uid: 'super_admin_uid',
        claims: {
          role: 'super_admin',
          superAdmin: true,
        },
      };
    },
  };

  const superAdminAuthorizer = {
    ready: true,
    async authorize(identity) {
      calls.superAdmin += 1;
      return {
        ok: identity?.uid === 'super_admin_uid',
        authorized: identity?.uid === 'super_admin_uid',
        uid: identity?.uid ?? '',
        source: 'SYNTHETIC_TEST',
      };
    },
  };

  const masterToggleRechecker = {
    ready: true,
    async recheckEmailAgentEnabled() {
      calls.masterToggle += 1;

      return {
        ok: true,
        enabled: true,
        reason: 'SYNTHETIC_MASTER_SWITCH_ON',
      };
    },
  };

  const approvalRechecker = {
    ready: true,
    async recheckConsumedApproval(scope) {
      calls.approval += 1;
      return {
        ok: true,
        consumed: true,
        callerUid: 'super_admin_uid',
        roleId: 'email_agent',
        actionId: 'email.send',
        module: 'email',
        approvalId: scope.approvalId,
        authorizationRequestId: scope.authorizationRequestId,
        draftId: scope.draftId,
        bindingFingerprint: scope.bindingFingerprint,
        exactActionScopeValidated: true,
      };
    },
  };

  const senderVerifier = {
    ready: true,
    async verifySenderIdentity(scope) {
      calls.sender += 1;
      return {
        ok: true,
        verified: true,
        enabled: true,
        senderIdentityId: scope.senderIdentityId,
        providerId: scope.providerId,
        fromAddress: scope.fromAddress,
      };
    },
  };

  const replayGuard = {
    ready: true,
    async claim() {
      calls.replay += 1;
      return {
        ok: true,
        claimed: true,
      };
    },
  };

  const providerTransport = {
    ready: true,
    providerId: 'brevo',
    liveNetworkAllowed: true,
    async deliver() {
      calls.provider += 1;
      return {
        ok: true,
        accepted: true,
        providerMessageId: 'synthetic-provider-message-id',
      };
    },
  };

  return {
    calls,
    config,
    authVerifier,
    superAdminAuthorizer,
    masterToggleRechecker,
    approvalRechecker,
    senderVerifier,
    replayGuard,
    providerTransport,
    ...overrides,
  };
}

async function responseJson(response) {
  return {
    status: response.status,
    body: await response.json(),
  };
}

test('production Phase 44-F3D-C config is hard-disabled', async () => {
  const dependencies = readyDependencies({
    config: buildPhase44F3dcServerConfig(),
  });

  const handler = createEmailSendHandler(dependencies);
  const result = await responseJson(await handler(request()));

  assert.equal(result.status, 503);
  assert.equal(result.body.code, 'SERVER_EMAIL_TRANSPORT_DISABLED');
  assert.deepEqual(dependencies.calls, {
    auth: 0,
    superAdmin: 0,
    masterToggle: 0,
    approval: 0,
    sender: 0,
    replay: 0,
    provider: 0,
  });
});

test('Bearer token is required before server pipeline', async () => {
  const dependencies = readyDependencies();
  const handler = createEmailSendHandler(dependencies);

  const result = await responseJson(
    await handler(request({ authorization: '' })),
  );

  assert.equal(result.status, 401);
  assert.equal(result.body.code, 'AUTH_BEARER_REQUIRED');
});

test('non-POST requests fail closed', async () => {
  const dependencies = readyDependencies();
  const handler = createEmailSendHandler(dependencies);

  const result = await responseJson(
    await handler(request({ method: 'GET' })),
  );

  assert.equal(result.status, 405);
  assert.equal(result.body.code, 'METHOD_NOT_ALLOWED');
});

test('Firebase identity rejection stops approval and provider', async () => {
  const dependencies = readyDependencies({
    authVerifier: {
      ready: true,
      async verifyIdToken() {
        return {
          ok: false,
          uid: '',
        };
      },
    },
  });

  const handler = createEmailSendHandler(dependencies);
  const result = await responseJson(await handler(request()));

  assert.equal(result.status, 401);
  assert.equal(result.body.code, 'FIREBASE_ID_TOKEN_REJECTED');
  assert.equal(dependencies.calls.approval, 0);
  assert.equal(dependencies.calls.provider, 0);
});


test('non-Super-Admin identity is denied before approval recheck', async () => {
  const base = readyDependencies();

  base.superAdminAuthorizer = {
    ready: true,
    async authorize(identity) {
      base.calls.superAdmin += 1;

      return {
        ok: false,
        authorized: false,
        uid: identity?.uid ?? '',
        source: 'SYNTHETIC_TEST',
      };
    },
  };

  const handler = createEmailSendHandler(base);
  const result = await responseJson(await handler(request()));

  assert.equal(result.status, 403);
  assert.equal(
      result.body.code,
      'SUPER_ADMIN_AUTHORIZATION_REQUIRED');
  assert.equal(base.calls.auth, 1);
  assert.equal(base.calls.superAdmin, 1);
  assert.equal(base.calls.approval, 0);
  assert.equal(base.calls.sender, 0);
  assert.equal(base.calls.replay, 0);
  assert.equal(base.calls.provider, 0);
});

test('Email master switch OFF blocks before approval recheck', async () => {
  const base = readyDependencies();

  base.masterToggleRechecker = {
    ready: true,
    async recheckEmailAgentEnabled() {
      base.calls.masterToggle += 1;

      return {
        ok: false,
        enabled: false,
        reason: 'EMAIL_AGENT_MASTER_SWITCH_OFF',
      };
    },
  };

  const handler = createEmailSendHandler(base);
  const result = await responseJson(await handler(request()));

  assert.equal(result.status, 403);
  assert.equal(
      result.body.code,
      'EMAIL_AGENT_MASTER_SWITCH_OFF');
  assert.equal(base.calls.auth, 1);
  assert.equal(base.calls.superAdmin, 1);
  assert.equal(base.calls.masterToggle, 1);
  assert.equal(base.calls.approval, 0);
  assert.equal(base.calls.sender, 0);
  assert.equal(base.calls.replay, 0);
  assert.equal(base.calls.provider, 0);
});
test('consumed approval exact-scope mismatch fails closed', async () => {
  const base = readyDependencies();

  base.approvalRechecker = {
    ready: true,
    async recheckConsumedApproval(scope) {
      base.calls.approval += 1;
      return {
        ok: true,
        consumed: true,
        callerUid: 'super_admin_uid',
        roleId: 'email_agent',
        actionId: 'email.send',
        module: 'email',
        approvalId: scope.approvalId,
        authorizationRequestId: scope.authorizationRequestId,
        draftId: scope.draftId,
        bindingFingerprint: 'wrong_binding_fingerprint',
      };
    },
  };

  const handler = createEmailSendHandler(base);
  const result = await responseJson(await handler(request()));

  assert.equal(result.status, 403);
  assert.equal(result.body.code, 'CONSUMED_APPROVAL_SCOPE_MISMATCH');
  assert.equal(base.calls.sender, 0);
  assert.equal(base.calls.provider, 0);
});

test('unverified sender fails before replay/provider', async () => {
  const base = readyDependencies();

  base.senderVerifier = {
    ready: true,
    async verifySenderIdentity(scope) {
      base.calls.sender += 1;
      return {
        ok: true,
        verified: false,
        enabled: true,
        senderIdentityId: scope.senderIdentityId,
        providerId: scope.providerId,
        fromAddress: scope.fromAddress,
      };
    },
  };

  const handler = createEmailSendHandler(base);
  const result = await responseJson(await handler(request()));

  assert.equal(result.status, 403);
  assert.equal(result.body.code, 'VERIFIED_SENDER_MISMATCH');
  assert.equal(base.calls.replay, 0);
  assert.equal(base.calls.provider, 0);
});

test('disabled Brevo adapter stops before anti-replay claim', async () => {
  const base = readyDependencies({
    providerTransport: new DisabledBrevoTransactionalEmailTransport(),
  });

  const handler = createEmailSendHandler(base);
  const result = await responseJson(await handler(request()));

  assert.equal(result.status, 503);
  assert.equal(result.body.code, 'PROVIDER_TRANSPORT_NOT_READY');
  assert.equal(base.calls.replay, 0);
});

test('anti-replay rejection prevents provider execution', async () => {
  const base = readyDependencies();

  base.replayGuard = {
    ready: true,
    async claim() {
      base.calls.replay += 1;
      return {
        ok: false,
        claimed: false,
      };
    },
  };

  const handler = createEmailSendHandler(base);
  const result = await responseJson(await handler(request()));

  assert.equal(result.status, 409);
  assert.equal(result.body.code, 'EMAIL_HANDOFF_REPLAY_REJECTED');
  assert.equal(base.calls.provider, 0);
});

test('pure fully gated synthetic pipeline can reach fake provider only after every gate', async () => {
  const base = readyDependencies();
  const handler = createEmailSendHandler(base);

  const result = await responseJson(await handler(request()));

  assert.equal(result.status, 202);
  assert.equal(result.body.code, 'EMAIL_ACCEPTED');
  assert.deepEqual(base.calls, {
    auth: 1,
    superAdmin: 1,
    masterToggle: 1,
    approval: 1,
    sender: 1,
    replay: 1,
    provider: 1,
  });
});


test('handoffId is not part of pre-existing approval scope and remains bound by anti-replay claim', async () => {
  const base = readyDependencies();

  let approvalScopeHadHandoffId = null;
  let replayClaimHandoffId = '';

  base.approvalRechecker = {
    ready: true,
    async recheckConsumedApproval(scope) {
      base.calls.approval += 1;
      approvalScopeHadHandoffId =
          Object.prototype.hasOwnProperty.call(scope, 'handoffId');

      return {
        ok: true,
        consumed: true,
        callerUid: 'super_admin_uid',
        roleId: 'email_agent',
        actionId: 'email.send',
        module: 'email',
        approvalId: scope.approvalId,
        authorizationRequestId: scope.authorizationRequestId,
        draftId: scope.draftId,
        bindingFingerprint: scope.bindingFingerprint,
        exactActionScopeValidated: true,
      };
    },
  };

  base.replayGuard = {
    ready: true,
    async claim(scope) {
      base.calls.replay += 1;
      replayClaimHandoffId = scope.handoffId;

      return {
        ok: true,
        claimed: true,
      };
    },
  };

  const handler = createEmailSendHandler(base);
  const result = await responseJson(await handler(request()));

  assert.equal(result.status, 202);
  assert.equal(approvalScopeHadHandoffId, false);
  assert.equal(replayClaimHandoffId, handoff.handoffId);
  assert.equal(base.calls.approval, 1);
  assert.equal(base.calls.replay, 1);
  assert.equal(base.calls.provider, 1);
});
test('invalid handoff is rejected before trusted dependencies', async () => {
  const base = readyDependencies();
  const handler = createEmailSendHandler(base);

  const result = await responseJson(
    await handler(request({
      body: {
        handoff: {
          ...handoff,
          bindingFingerprint: '',
        },
      },
    })),
  );

  assert.equal(result.status, 400);
  assert.equal(
    result.body.code,
    'HANDOFF_BINDINGFINGERPRINT_MISSING',
  );
  assert.deepEqual(base.calls, {
    auth: 0,
    superAdmin: 0,
    masterToggle: 0,
    approval: 0,
    sender: 0,
    replay: 0,
    provider: 0,
  });
});
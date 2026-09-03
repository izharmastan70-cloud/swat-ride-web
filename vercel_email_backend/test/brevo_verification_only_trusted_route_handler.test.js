import assert from 'node:assert/strict';
import test from 'node:test';

import routeHandler from '../api/email/sender/verify.js';

import {
  EMAIL_SENDER_VERIFICATION_OPERATION,
  EMAIL_SENDER_VERIFICATION_ROUTE_POLICY,
  handleTrustedBrevoVerificationOnlyRoute,
} from '../src/handlers/brevo_verification_only_trusted_route_handler.js';

function makeResponse() {
  const headers = {};

  return {
    statusCode:
        null,
    body:
        null,
    headers,

    setHeader(name, value) {
      headers[name] =
          value;
    },

    status(code) {
      this.statusCode =
          code;

      return this;
    },

    json(body) {
      this.body =
          body;

      return this;
    },
  };
}

function makeRequest({
  method = 'POST',
  token = null,
} = {}) {
  return {
    method,
    headers:
        token
            ? {
                authorization:
                    `Bearer ${token}`,
              }
            : {},
  };
}

test('verification route policy requires bearer Firebase identity and Super Admin and has zero send/write authority', () => {
  assert.equal(
      EMAIL_SENDER_VERIFICATION_OPERATION,
      'email.sender.verify.read_only');

  assert.equal(
      EMAIL_SENDER_VERIFICATION_ROUTE_POLICY
          .requiresBearerToken,
      true);

  assert.equal(
      EMAIL_SENDER_VERIFICATION_ROUTE_POLICY
          .requiresVerifiedFirebaseIdentity,
      true);

  assert.equal(
      EMAIL_SENDER_VERIFICATION_ROUTE_POLICY
          .requiresSuperAdmin,
      true);

  assert.equal(
      EMAIL_SENDER_VERIFICATION_ROUTE_POLICY
          .providerWriteAllowed,
      false);

  assert.equal(
      EMAIL_SENDER_VERIFICATION_ROUTE_POLICY
          .firestoreWriteAllowed,
      false);

  assert.equal(
      EMAIL_SENDER_VERIFICATION_ROUTE_POLICY
          .emailSendAllowed,
      false);

  assert.equal(
      EMAIL_SENDER_VERIFICATION_ROUTE_POLICY
          .liveSendAllowed,
      false);

  assert.equal(
      EMAIL_SENDER_VERIFICATION_ROUTE_POLICY
          .sha256DraftBindingRequiredBeforeLiveSend,
      true);
});

test('non-POST method fails before trusted gates', async () => {
  let identityCalls = 0;

  const response =
      makeResponse();

  await handleTrustedBrevoVerificationOnlyRoute({
    request:
        makeRequest({
          method:
              'GET',
          token:
              'token',
        }),
    response,
    idTokenVerifier: {
      async verify() {
        identityCalls += 1;
        return {
          uid:
              'owner',
        };
      },
    },
    superAdminAuthorizer: {
      async authorize() {
        return true;
      },
    },
    verificationRuntime: {
      async runVerificationOnly() {
        throw new Error(
            'must not run');
      },
    },
  });

  assert.equal(
      response.statusCode,
      405);

  assert.equal(
      response.headers.Allow,
      'POST');

  assert.equal(
      identityCalls,
      0);
});

test('missing bearer token fails before identity verification', async () => {
  let identityCalls = 0;

  const response =
      makeResponse();

  await handleTrustedBrevoVerificationOnlyRoute({
    request:
        makeRequest(),
    response,
    idTokenVerifier: {
      async verify() {
        identityCalls += 1;
        return {
          uid:
              'owner',
        };
      },
    },
    superAdminAuthorizer: {
      async authorize() {
        return true;
      },
    },
    verificationRuntime: {
      async runVerificationOnly() {
        throw new Error(
            'must not run');
      },
    },
  });

  assert.equal(
      response.statusCode,
      401);

  assert.equal(
      response.body.code,
      'EMAIL_SENDER_VERIFICATION_BEARER_REQUIRED');

  assert.equal(
      identityCalls,
      0);
});

test('Firebase identity rejection fails before Super Admin and provider runtime', async () => {
  let adminCalls = 0;
  let runtimeCalls = 0;

  const response =
      makeResponse();

  await handleTrustedBrevoVerificationOnlyRoute({
    request:
        makeRequest({
          token:
              'bad-token',
        }),
    response,
    idTokenVerifier: {
      async verify() {
        throw new Error(
            'rejected');
      },
    },
    superAdminAuthorizer: {
      async authorize() {
        adminCalls += 1;
        return true;
      },
    },
    verificationRuntime: {
      async runVerificationOnly() {
        runtimeCalls += 1;
        return {};
      },
    },
  });

  assert.equal(
      response.statusCode,
      401);

  assert.equal(
      response.body.code,
      'EMAIL_SENDER_VERIFICATION_IDENTITY_REJECTED');

  assert.equal(
      adminCalls,
      0);

  assert.equal(
      runtimeCalls,
      0);
});

test('non-Super-Admin identity fails before provider runtime', async () => {
  let runtimeCalls = 0;

  const response =
      makeResponse();

  await handleTrustedBrevoVerificationOnlyRoute({
    request:
        makeRequest({
          token:
              'valid-token',
        }),
    response,
    idTokenVerifier: {
      async verify() {
        return {
          uid:
              'normal-user',
        };
      },
    },
    superAdminAuthorizer: {
      async authorize() {
        return false;
      },
    },
    verificationRuntime: {
      async runVerificationOnly() {
        runtimeCalls += 1;
        return {};
      },
    },
  });

  assert.equal(
      response.statusCode,
      403);

  assert.equal(
      response.body.code,
      'EMAIL_SENDER_VERIFICATION_SUPER_ADMIN_REQUIRED');

  assert.equal(
      runtimeCalls,
      0);
});

test('trusted gates can reach disabled verification runtime but provider read remains OFF', async () => {
  const order = [];

  const response =
      makeResponse();

  await handleTrustedBrevoVerificationOnlyRoute({
    request:
        makeRequest({
          token:
              'valid-owner-token',
        }),
    response,
    idTokenVerifier: {
      async verify(token) {
        order.push(
            'identity');

        assert.equal(
            token,
            'valid-owner-token');

        return {
          uid:
              'owner-uid',
        };
      },
    },
    superAdminAuthorizer: {
      async authorize(identity) {
        order.push(
            'super-admin');

        assert.equal(
            identity.uid,
            'owner-uid');

        return true;
      },
    },
    verificationRuntime: {
      async runVerificationOnly() {
        order.push(
            'runtime');

        return {
          ok:
              false,
          trustedEvidenceEligible:
              false,
          evidence:
              null,
          providerReadPerformed:
              false,
          code:
              'BREVO_VERIFICATION_ONLY_SERVER_DISABLED',
        };
      },
    },
  });

  assert.deepEqual(
      order,
      [
        'identity',
        'super-admin',
        'runtime',
      ]);

  assert.equal(
      response.statusCode,
      503);

  assert.equal(
      response.body.providerReadPerformed,
      false);

  assert.equal(
      response.body.emailSendAllowed,
      false);

  assert.equal(
      response.body.liveSendAllowed,
      false);
});

test('synthetic successful read-only verification returns evidence but still cannot write/send', async () => {
  const response =
      makeResponse();

  await handleTrustedBrevoVerificationOnlyRoute({
    request:
        makeRequest({
          token:
              'valid-owner-token',
        }),
    response,
    idTokenVerifier: {
      async verify() {
        return {
          uid:
              'owner-uid',
        };
      },
    },
    superAdminAuthorizer: {
      async authorize() {
        return true;
      },
    },
    verificationRuntime: {
      async runVerificationOnly() {
        return {
          ok:
              true,
          trustedEvidenceEligible:
              true,
          providerReadPerformed:
              true,
          evidence: {
            senderIdentityId:
                'primary_official_sender',
            providerId:
                'brevo',
            providerSenderId:
                '101',
            fromAddress:
                'swatrideofficial@gmail.com',
            displayName:
                'SWAT RIDE',
            verificationSource:
                'SERVER_PROVIDER_VERIFIED',
          },
          code:
              'BREVO_EXACT_ACTIVE_SENDER_VERIFIED',
        };
      },
    },
  });

  assert.equal(
      response.statusCode,
      200);

  assert.equal(
      response.body.ok,
      true);

  assert.equal(
      response.body.trustedEvidenceEligible,
      true);

  assert.equal(
      response.body.providerReadPerformed,
      true);

  assert.equal(
      response.body.providerWriteAllowed,
      false);

  assert.equal(
      response.body.firestoreWriteAllowed,
      false);

  assert.equal(
      response.body.emailSendAllowed,
      false);

  assert.equal(
      response.body.liveSendAllowed,
      false);
});

test('actual Vercel route remains safely disabled before real trusted runtime wiring', async () => {
  const response =
      makeResponse();

  await routeHandler(
      makeRequest({
        token:
            'any-token',
      }),
      response);

  assert.equal(
      response.statusCode,
      401);

  assert.equal(
      response.body.code,
      'EMAIL_SENDER_VERIFICATION_IDENTITY_REJECTED');

  assert.equal(
      response.body.providerReadPerformed,
      false);

  assert.equal(
      response.body.emailSendAllowed,
      false);
});

test('responses are no-store and never expose request bearer token', async () => {
  const secretToken =
      'synthetic-owner-secret-token';

  const response =
      makeResponse();

  await routeHandler(
      makeRequest({
        token:
            secretToken,
      }),
      response);

  assert.equal(
      response.headers['Cache-Control'],
      'no-store, max-age=0');

  assert.equal(
      JSON.stringify(response.body)
          .includes(secretToken),
      false);
});
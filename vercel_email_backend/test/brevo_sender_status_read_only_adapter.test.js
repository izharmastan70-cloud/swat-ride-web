import assert from 'node:assert/strict';
import test from 'node:test';

import {
  BrevoApiKeySecret,
} from '../src/security/brevo_api_key_secret.js';

import {
  BREVO_API_BASE_URL,
  BrevoSenderStatusReadOnlyAdapter,
} from '../src/providers/brevo_sender_status_read_only_adapter.js';

import {
  BREVO_SENDER_VERIFICATION_EVALUATION_CODE,
  evaluateBrevoSenderVerificationSnapshot,
} from '../src/security/brevo_sender_verification_evidence_evaluator.js';

const syntheticKey =
    'synthetic_brevo_key_for_tests_only_123456';

function fakeResponse({
  status = 200,
  body = {
    senders: [],
  },
} = {}) {
  return {
    status,
    async text() {
      return typeof body === 'string'
          ? body
          : JSON.stringify(body);
    },
  };
}

test('Brevo API key wrapper redacts string and JSON representations', () => {
  const secret =
      new BrevoApiKeySecret(
          syntheticKey);

  assert.equal(
      secret.present,
      true);

  assert.equal(
      String(secret),
      '[REDACTED_BREVO_API_KEY]');

  assert.equal(
      JSON.stringify(secret),
      '"[REDACTED_BREVO_API_KEY]"');

  assert.equal(
      String(secret).includes(syntheticKey),
      false);

  assert.equal(
      JSON.stringify(secret).includes(syntheticKey),
      false);
});

test('sender-status adapter is network-disabled by default and never calls fetch', async () => {
  let calls = 0;

  const adapter =
      new BrevoSenderStatusReadOnlyAdapter({
        fetchImpl: async () => {
          calls += 1;
          return fakeResponse();
        },
        apiKeySecret:
            new BrevoApiKeySecret(
                syntheticKey),
      });

  assert.equal(
      adapter.ready,
      false);

  const result =
      await adapter.fetchSenderStatusSnapshot();

  assert.equal(
      result.ok,
      false);

  assert.equal(
      result.code,
      'BREVO_SENDER_STATUS_NETWORK_DISABLED');

  assert.equal(
      calls,
      0);
});

test('explicit synthetic network mode performs only exact GET /v3/senders with api-key header', async () => {
  const calls = [];

  const adapter =
      new BrevoSenderStatusReadOnlyAdapter({
        fetchImpl:
            async (url, options) => {
              calls.push({
                url,
                options,
              });

              return fakeResponse({
                body: {
                  senders: [
                    {
                      id: 101,
                      name:
                          'SWAT RIDE',
                      email:
                          'swatrideofficial@gmail.com',
                      active:
                          true,
                      ips:
                          [],
                    },
                  ],
                },
              });
            },
        apiKeySecret:
            new BrevoApiKeySecret(
                syntheticKey),
        networkAllowed:
            true,
      });

  const result =
      await adapter.fetchSenderStatusSnapshot();

  assert.equal(result.ok, true);
  assert.equal(calls.length, 1);

  assert.equal(
      calls[0].url,
      `${BREVO_API_BASE_URL}/v3/senders`);

  assert.equal(
      calls[0].options.method,
      'GET');

  assert.equal(
      calls[0].options.redirect,
      'error');

  assert.equal(
      calls[0].options.headers.accept,
      'application/json');

  assert.equal(
      calls[0].options.headers['api-key'],
      syntheticKey);

  assert.equal(
      Object.hasOwn(
          calls[0].options,
          'body'),
      false);

  assert.equal(
      result.providerWriteAllowed,
      false);

  assert.equal(
      result.emailSendAllowed,
      false);

  assert.equal(
      result.liveSendAllowed,
      false);
});

test('successful sender-status snapshot produces trusted evaluator source context', async () => {
  const adapter =
      new BrevoSenderStatusReadOnlyAdapter({
        fetchImpl:
            async () =>
              fakeResponse({
                body: {
                  senders: [
                    {
                      id: 101,
                      name:
                          'SWAT RIDE',
                      email:
                          'swatrideofficial@gmail.com',
                      active:
                          true,
                      ips:
                          [],
                    },
                  ],
                },
              }),
        apiKeySecret:
            new BrevoApiKeySecret(
                syntheticKey),
        networkAllowed:
            true,
      });

  const snapshot =
      await adapter.fetchSenderStatusSnapshot();

  const evaluated =
      evaluateBrevoSenderVerificationSnapshot({
        providerResponse:
            snapshot.providerResponse,
        expectedSender: {
          senderIdentityId:
              'primary_official_sender',
          fromAddress:
              'swatrideofficial@gmail.com',
          displayName:
              'SWAT RIDE',
        },
        sourceContext:
            snapshot.sourceContext,
        observedAt:
            new Date(
                '2026-08-17T00:00:00.000Z'),
      });

  assert.equal(
      evaluated.ok,
      true);

  assert.equal(
      evaluated.code,
      BREVO_SENDER_VERIFICATION_EVALUATION_CODE
          .verified);

  assert.equal(
      evaluated.mayWriteTrustedSenderRegistry,
      false);

  assert.equal(
      evaluated.mayEnableLiveSend,
      false);
});

test('duplicate same-email provider snapshot still fails closed through trusted evaluator', async () => {
  const adapter =
      new BrevoSenderStatusReadOnlyAdapter({
        fetchImpl:
            async () =>
              fakeResponse({
                body: {
                  senders: [
                    {
                      id: 101,
                      name:
                          'SWAT RIDE',
                      email:
                          'swatrideofficial@gmail.com',
                      active:
                          true,
                    },
                    {
                      id: 102,
                      name:
                          'swat ride',
                      email:
                          'swatrideofficial@gmail.com',
                      active:
                          true,
                    },
                  ],
                },
              }),
        apiKeySecret:
            new BrevoApiKeySecret(
                syntheticKey),
        networkAllowed:
            true,
      });

  const snapshot =
      await adapter.fetchSenderStatusSnapshot();

  const evaluated =
      evaluateBrevoSenderVerificationSnapshot({
        providerResponse:
            snapshot.providerResponse,
        expectedSender: {
          senderIdentityId:
              'primary_official_sender',
          fromAddress:
              'swatrideofficial@gmail.com',
          displayName:
              'SWAT RIDE',
        },
        sourceContext:
            snapshot.sourceContext,
      });

  assert.equal(
      evaluated.ok,
      false);

  assert.equal(
      evaluated.code,
      BREVO_SENDER_VERIFICATION_EVALUATION_CODE
          .duplicateEmail);

  assert.equal(
      evaluated.duplicateCount,
      2);
});

test('non-200 Brevo status is sanitized and provider body is not exposed', async () => {
  const adapter =
      new BrevoSenderStatusReadOnlyAdapter({
        fetchImpl:
            async () =>
              fakeResponse({
                status:
                    401,
                body: {
                  message:
                      'contains provider detail that must not escape',
                },
              }),
        apiKeySecret:
            new BrevoApiKeySecret(
                syntheticKey),
        networkAllowed:
            true,
      });

  const result =
      await adapter.fetchSenderStatusSnapshot();

  assert.equal(result.ok, false);

  assert.equal(
      result.code,
      'BREVO_SENDER_STATUS_HTTP_401');

  assert.equal(
      JSON.stringify(result)
          .includes('provider detail'),
      false);

  assert.equal(
      JSON.stringify(result)
          .includes(syntheticKey),
      false);
});

test('network exception is sanitized and never leaks API key', async () => {
  const adapter =
      new BrevoSenderStatusReadOnlyAdapter({
        fetchImpl:
            async () => {
              throw new Error(
                  `network failed with ${syntheticKey}`);
            },
        apiKeySecret:
            new BrevoApiKeySecret(
                syntheticKey),
        networkAllowed:
            true,
      });

  const result =
      await adapter.fetchSenderStatusSnapshot();

  assert.equal(result.ok, false);

  assert.equal(
      result.code,
      'BREVO_SENDER_STATUS_NETWORK_FAILED');

  assert.equal(
      JSON.stringify(result)
          .includes(syntheticKey),
      false);
});

test('malformed and oversized provider responses fail closed', async () => {
  const malformed =
      new BrevoSenderStatusReadOnlyAdapter({
        fetchImpl:
            async () =>
              fakeResponse({
                body:
                    '{not-json',
              }),
        apiKeySecret:
            new BrevoApiKeySecret(
                syntheticKey),
        networkAllowed:
            true,
      });

  assert.equal(
      (await malformed
          .fetchSenderStatusSnapshot()).code,
      'BREVO_SENDER_STATUS_JSON_INVALID');

  const oversized =
      new BrevoSenderStatusReadOnlyAdapter({
        fetchImpl:
            async () =>
              fakeResponse({
                body:
                    JSON.stringify({
                      senders: [],
                      padding:
                          'x'.repeat(200),
                    }),
              }),
        apiKeySecret:
            new BrevoApiKeySecret(
                syntheticKey),
        networkAllowed:
            true,
        maxResponseBytes:
            40,
      });

  assert.equal(
      (await oversized
          .fetchSenderStatusSnapshot()).code,
      'BREVO_SENDER_STATUS_RESPONSE_TOO_LARGE');
});

test('read-only adapter exposes no provider write or email-send authority', () => {
  const adapter =
      new BrevoSenderStatusReadOnlyAdapter({
        fetchImpl:
            async () =>
              fakeResponse(),
        apiKeySecret:
            new BrevoApiKeySecret(
                syntheticKey),
        networkAllowed:
            false,
      });

  assert.equal(
      adapter.readOnly,
      true);

  assert.equal(
      adapter.providerWriteAllowed,
      false);

  assert.equal(
      adapter.emailSendAllowed,
      false);

  assert.equal(
      adapter.liveSendAllowed,
      false);
});
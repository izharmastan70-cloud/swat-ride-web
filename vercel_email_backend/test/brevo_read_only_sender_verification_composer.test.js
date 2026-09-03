import assert from 'node:assert/strict';
import test from 'node:test';

import {
  BrevoReadOnlySenderVerificationComposer,
} from '../src/runtime/brevo_read_only_sender_verification_composer.js';

const syntheticSecret =
    'synthetic_brevo_key_b6f_tests_only_123456789';

const expectedSender =
    Object.freeze({
      senderIdentityId:
          'primary_official_sender',
      fromAddress:
          'swatrideofficial@gmail.com',
      displayName:
          'SWAT RIDE',
    });

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

test('B6-F verification is disabled by default and performs zero fetch calls', async () => {
  let calls = 0;

  const composer =
      new BrevoReadOnlySenderVerificationComposer({
        environment: {
          BREVO_API_KEY:
              syntheticSecret,
        },
        fetchImpl:
            async () => {
              calls += 1;
              return fakeResponse();
            },
        expectedSender,
      });

  const result =
      await composer.verifyExpectedSender();

  assert.equal(
      result.ok,
      false);

  assert.equal(
      result.code,
      'BREVO_READ_ONLY_VERIFICATION_DISABLED');

  assert.equal(
      result.verificationAttempted,
      false);

  assert.equal(
      calls,
      0);
});

test('enabled read-only verification still fails closed when server secret is absent', async () => {
  let calls = 0;

  const composer =
      new BrevoReadOnlySenderVerificationComposer({
        environment:
            {},
        fetchImpl:
            async () => {
              calls += 1;
              return fakeResponse();
            },
        expectedSender,
        readOnlyVerificationEnabled:
            true,
      });

  const result =
      await composer.verifyExpectedSender();

  assert.equal(
      result.ok,
      false);

  assert.equal(
      result.code,
      'BREVO_PROVIDER_SECRET_MISSING');

  assert.equal(
      result.verificationAttempted,
      false);

  assert.equal(
      calls,
      0);
});

test('enabled synthetic read-only verification can produce trusted evidence and no write/send authority', async () => {
  let calls = 0;

  const composer =
      new BrevoReadOnlySenderVerificationComposer({
        environment: {
          BREVO_API_KEY:
              syntheticSecret,
        },
        fetchImpl:
            async () => {
              calls += 1;

              return fakeResponse({
                body: {
                  senders: [
                    {
                      id:
                          101,
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
        expectedSender,
        readOnlyVerificationEnabled:
            true,
      });

  const result =
      await composer.verifyExpectedSender();

  assert.equal(
      calls,
      1);

  assert.equal(
      result.ok,
      true);

  assert.equal(
      result.verificationAttempted,
      true);

  assert.equal(
      result.trustedEvidenceEligible,
      true);

  assert.equal(
      result.evidence.verificationSource,
      'SERVER_PROVIDER_VERIFIED');

  assert.equal(
      result.providerWriteAllowed,
      false);

  assert.equal(
      result.emailSendAllowed,
      false);

  assert.equal(
      result.liveSendAllowed,
      false);

  assert.equal(
      result.firestoreWriteAllowed,
      false);

  assert.equal(
      JSON.stringify(result)
          .includes(syntheticSecret),
      false);
});

test('duplicate same-email sender remains fail closed in composed runtime', async () => {
  const composer =
      new BrevoReadOnlySenderVerificationComposer({
        environment: {
          BREVO_API_KEY:
              syntheticSecret,
        },
        fetchImpl:
            async () =>
              fakeResponse({
                body: {
                  senders: [
                    {
                      id:
                          101,
                      name:
                          'SWAT RIDE',
                      email:
                          'swatrideofficial@gmail.com',
                      active:
                          true,
                    },
                    {
                      id:
                          102,
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
        expectedSender,
        readOnlyVerificationEnabled:
            true,
      });

  const result =
      await composer.verifyExpectedSender();

  assert.equal(
      result.ok,
      false);

  assert.equal(
      result.code,
      'BREVO_DUPLICATE_SENDERS_FOR_EMAIL');

  assert.equal(
      result.trustedEvidenceEligible,
      false);

  assert.equal(
      result.firestoreWriteAllowed,
      false);
});

test('inactive sender remains fail closed in composed runtime', async () => {
  const composer =
      new BrevoReadOnlySenderVerificationComposer({
        environment: {
          BREVO_API_KEY:
              syntheticSecret,
        },
        fetchImpl:
            async () =>
              fakeResponse({
                body: {
                  senders: [
                    {
                      id:
                          101,
                      name:
                          'SWAT RIDE',
                      email:
                          'swatrideofficial@gmail.com',
                      active:
                          false,
                    },
                  ],
                },
              }),
        expectedSender,
        readOnlyVerificationEnabled:
            true,
      });

  const result =
      await composer.verifyExpectedSender();

  assert.equal(
      result.ok,
      false);

  assert.equal(
      result.code,
      'BREVO_SENDER_NOT_ACTIVE');

  assert.equal(
      result.trustedEvidenceEligible,
      false);
});

test('wrong display name remains fail closed in composed runtime', async () => {
  const composer =
      new BrevoReadOnlySenderVerificationComposer({
        environment: {
          BREVO_API_KEY:
              syntheticSecret,
        },
        fetchImpl:
            async () =>
              fakeResponse({
                body: {
                  senders: [
                    {
                      id:
                          101,
                      name:
                          'Different Name',
                      email:
                          'swatrideofficial@gmail.com',
                      active:
                          true,
                    },
                  ],
                },
              }),
        expectedSender,
        readOnlyVerificationEnabled:
            true,
      });

  const result =
      await composer.verifyExpectedSender();

  assert.equal(
      result.ok,
      false);

  assert.equal(
      result.code,
      'BREVO_SENDER_IDENTITY_MISMATCH');
});

test('provider HTTP failure is sanitized and never grants trusted evidence', async () => {
  const composer =
      new BrevoReadOnlySenderVerificationComposer({
        environment: {
          BREVO_API_KEY:
              syntheticSecret,
        },
        fetchImpl:
            async () =>
              fakeResponse({
                status:
                    401,
                body: {
                  message:
                      'synthetic provider failure',
                },
              }),
        expectedSender,
        readOnlyVerificationEnabled:
            true,
      });

  const result =
      await composer.verifyExpectedSender();

  assert.equal(
      result.ok,
      false);

  assert.equal(
      result.code,
      'BREVO_SENDER_STATUS_HTTP_401');

  assert.equal(
      result.trustedEvidenceEligible,
      false);

  assert.equal(
      JSON.stringify(result)
          .includes('synthetic provider failure'),
      false);

  assert.equal(
      JSON.stringify(result)
          .includes(syntheticSecret),
      false);
});

test('composer itself can never grant provider write email send live send or Firestore write authority', () => {
  const composer =
      new BrevoReadOnlySenderVerificationComposer({
        environment: {
          BREVO_API_KEY:
              syntheticSecret,
        },
        fetchImpl:
            async () =>
              fakeResponse(),
        expectedSender,
        readOnlyVerificationEnabled:
            true,
      });

  assert.equal(
      composer.providerWriteAllowed,
      false);

  assert.equal(
      composer.emailSendAllowed,
      false);

  assert.equal(
      composer.liveSendAllowed,
      false);

  assert.equal(
      composer.firestoreWriteAllowed,
      false);
});
import assert from 'node:assert/strict';
import test from 'node:test';

import {
  BREVO_VERIFICATION_ONLY_OPERATION,
  BREVO_VERIFICATION_ONLY_SERVER_POLICY,
  BrevoVerificationOnlyServerHarness,
} from '../src/runtime/brevo_verification_only_server_harness.js';

const syntheticSecret =
    'synthetic_brevo_key_b6g_tests_only_123456789';

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

test('B6-G policy is verification-only and default disabled', () => {
  assert.equal(
      BREVO_VERIFICATION_ONLY_OPERATION,
      'email.sender.verify.read_only');

  assert.equal(
      BREVO_VERIFICATION_ONLY_SERVER_POLICY
          .defaultEnabled,
      false);

  assert.equal(
      BREVO_VERIFICATION_ONLY_SERVER_POLICY
          .requiresExplicitServerActivation,
      true);

  assert.equal(
      BREVO_VERIFICATION_ONLY_SERVER_POLICY
          .providerWriteAllowed,
      false);

  assert.equal(
      BREVO_VERIFICATION_ONLY_SERVER_POLICY
          .firestoreWriteAllowed,
      false);

  assert.equal(
      BREVO_VERIFICATION_ONLY_SERVER_POLICY
          .emailSendAllowed,
      false);

  assert.equal(
      BREVO_VERIFICATION_ONLY_SERVER_POLICY
          .liveSendAllowed,
      false);

  assert.equal(
      BREVO_VERIFICATION_ONLY_SERVER_POLICY
          .mayConsumeEmailApproval,
      false);

  assert.equal(
      BREVO_VERIFICATION_ONLY_SERVER_POLICY
          .mayClaimEmailDeliveryIdempotency,
      false);

  assert.equal(
      BREVO_VERIFICATION_ONLY_SERVER_POLICY
          .sha256DraftBindingRequiredBeforeLiveSend,
      true);
});

test('default-disabled harness performs zero provider reads', async () => {
  let calls = 0;

  const harness =
      new BrevoVerificationOnlyServerHarness({
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
      await harness.runVerificationOnly();

  assert.equal(
      result.ok,
      false);

  assert.equal(
      result.code,
      'BREVO_VERIFICATION_ONLY_SERVER_DISABLED');

  assert.equal(
      result.verificationAttempted,
      false);

  assert.equal(
      result.providerReadPerformed,
      false);

  assert.equal(
      calls,
      0);
});

test('enabled synthetic harness verifies exact canonical sender read-only', async () => {
  let calls = 0;

  const harness =
      new BrevoVerificationOnlyServerHarness({
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
        serverActivationEnabled:
            true,
      });

  const result =
      await harness.runVerificationOnly();

  assert.equal(
      calls,
      1);

  assert.equal(
      result.ok,
      true);

  assert.equal(
      result.operation,
      BREVO_VERIFICATION_ONLY_OPERATION);

  assert.equal(
      result.verificationAttempted,
      true);

  assert.equal(
      result.providerReadPerformed,
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
      result.firestoreWriteAllowed,
      false);

  assert.equal(
      result.emailSendAllowed,
      false);

  assert.equal(
      result.liveSendAllowed,
      false);

  assert.equal(
      result.approvalConsumed,
      false);

  assert.equal(
      result.deliveryIdempotencyClaimed,
      false);

  assert.equal(
      JSON.stringify(result)
          .includes(syntheticSecret),
      false);
});

test('missing server secret fails before provider read', async () => {
  let calls = 0;

  const harness =
      new BrevoVerificationOnlyServerHarness({
        environment:
            {},
        fetchImpl:
            async () => {
              calls += 1;
              return fakeResponse();
            },
        expectedSender,
        serverActivationEnabled:
            true,
      });

  const result =
      await harness.runVerificationOnly();

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
      result.providerReadPerformed,
      false);

  assert.equal(
      calls,
      0);
});

test('duplicate same-email sender remains blocked in B6-G harness', async () => {
  const harness =
      new BrevoVerificationOnlyServerHarness({
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
        serverActivationEnabled:
            true,
      });

  const result =
      await harness.runVerificationOnly();

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
      result.emailSendAllowed,
      false);
});

test('provider failure remains sanitized and cannot escape secret or provider message', async () => {
  const harness =
      new BrevoVerificationOnlyServerHarness({
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
                      'synthetic private provider detail',
                },
              }),
        expectedSender,
        serverActivationEnabled:
            true,
      });

  const result =
      await harness.runVerificationOnly();

  assert.equal(
      result.ok,
      false);

  assert.equal(
      result.code,
      'BREVO_SENDER_STATUS_HTTP_401');

  const serialized =
      JSON.stringify(result);

  assert.equal(
      serialized.includes(syntheticSecret),
      false);

  assert.equal(
      serialized.includes(
          'synthetic private provider detail'),
      false);
});

test('B6-G harness object exposes no email approval idempotency provider-write Firestore-write or live-send authority', () => {
  const harness =
      new BrevoVerificationOnlyServerHarness({
        environment: {
          BREVO_API_KEY:
              syntheticSecret,
        },
        fetchImpl:
            async () =>
              fakeResponse(),
        expectedSender,
        serverActivationEnabled:
            true,
      });

  assert.equal(
      harness.providerWriteAllowed,
      false);

  assert.equal(
      harness.firestoreWriteAllowed,
      false);

  assert.equal(
      harness.emailSendAllowed,
      false);

  assert.equal(
      harness.liveSendAllowed,
      false);

  assert.equal(
      harness.mayConsumeEmailApproval,
      false);

  assert.equal(
      harness.mayClaimEmailDeliveryIdempotency,
      false);
});
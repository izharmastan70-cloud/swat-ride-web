import assert from 'node:assert/strict';
import test from 'node:test';

import {
  EMAIL_SENDER_PROVIDER_EVIDENCE_SOURCE,
} from '../src/models/email_sender_verification_evidence.js';

import {
  BREVO_SENDER_LIST_ENDPOINT,
  BREVO_SENDER_VERIFICATION_EVALUATION_CODE,
  evaluateBrevoSenderVerificationSnapshot,
} from '../src/security/brevo_sender_verification_evidence_evaluator.js';

const expectedSender =
    Object.freeze({
      senderIdentityId:
          'primary_official_sender',
      fromAddress:
          'swatrideofficial@gmail.com',
      displayName:
          'SWAT RIDE',
    });

const trustedSource =
    Object.freeze({
      providerEvidenceSource:
          EMAIL_SENDER_PROVIDER_EVIDENCE_SOURCE,
      serverAuthenticatedProviderResponse:
          true,
      endpoint:
          BREVO_SENDER_LIST_ENDPOINT,
    });

function evaluate(
  senders,
  overrides = {},
) {
  return evaluateBrevoSenderVerificationSnapshot({
    providerResponse: {
      senders,
    },
    expectedSender,
    sourceContext:
        trustedSource,
    observedAt:
        new Date('2026-08-17T00:00:00.000Z'),
    ...overrides,
  });
}

test('exact active Brevo sender becomes eligible provider verification evidence without enabling send', () => {
  const result =
      evaluate([
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
      ]);

  assert.equal(
      result.ok,
      true);

  assert.equal(
      result.code,
      BREVO_SENDER_VERIFICATION_EVALUATION_CODE
          .verified);

  assert.equal(
      result.eligibleForTrustedEvidence,
      true);

  assert.equal(
      result.evidence.providerId,
      'brevo');

  assert.equal(
      result.evidence.providerSenderId,
      '101');

  assert.equal(
      result.evidence.verificationSource,
      'SERVER_PROVIDER_VERIFIED');

  assert.equal(
      result.evidence.containsSecretMaterial,
      false);

  assert.equal(
      result.mayWriteTrustedSenderRegistry,
      false);

  assert.equal(
      result.mayEnableLiveSend,
      false);

  assert.equal(
      result.mayCallProvider,
      false);
});

test('owner UI manual verified claim cannot create trusted provider evidence', () => {
  const result =
      evaluateBrevoSenderVerificationSnapshot({
        providerResponse: {
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
          ],
        },
        expectedSender,
        sourceContext: {
          providerEvidenceSource:
              'OWNER_UI_SCREENSHOT',
          serverAuthenticatedProviderResponse:
              false,
          endpoint:
              '/manual',
        },
      });

  assert.equal(
      result.ok,
      false);

  assert.equal(
      result.code,
      BREVO_SENDER_VERIFICATION_EVALUATION_CODE
          .untrustedInput);

  assert.equal(
      result.eligibleForTrustedEvidence,
      false);
});

test('duplicate Brevo records for the same Gmail sender fail closed', () => {
  const result =
      evaluate([
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
      ]);

  assert.equal(
      result.ok,
      false);

  assert.equal(
      result.code,
      BREVO_SENDER_VERIFICATION_EVALUATION_CODE
          .duplicateEmail);

  assert.equal(
      result.duplicateCount,
      2);
});

test('wrong sender display name fails exact identity match', () => {
  const result =
      evaluate([
        {
          id:
              101,
          name:
              'swat ride',
          email:
              'swatrideofficial@gmail.com',
          active:
              true,
        },
      ]);

  assert.equal(
      result.ok,
      false);

  assert.equal(
      result.code,
      BREVO_SENDER_VERIFICATION_EVALUATION_CODE
          .identityMismatch);
});

test('inactive Brevo sender cannot create verification evidence', () => {
  const result =
      evaluate([
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
      ]);

  assert.equal(
      result.ok,
      false);

  assert.equal(
      result.code,
      BREVO_SENDER_VERIFICATION_EVALUATION_CODE
          .inactive);
});

test('missing sender fails closed', () => {
  const result =
      evaluate([]);

  assert.equal(
      result.ok,
      false);

  assert.equal(
      result.code,
      BREVO_SENDER_VERIFICATION_EVALUATION_CODE
          .missingSender);
});

test('trusted evidence contains no API key OTP password Firebase credential or raw provider response', () => {
  const result =
      evaluate([
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
      ]);

  const serialized =
      JSON.stringify(
          result.evidence);

  assert.equal(
      serialized.includes('BREVO_API_KEY'),
      false);

  assert.equal(
      serialized.includes('FIREBASE_SERVICE_ACCOUNT_JSON'),
      false);

  assert.equal(
      serialized.toLowerCase().includes('password'),
      false);

  assert.equal(
      serialized.toLowerCase().includes('otp'),
      false);

  assert.equal(
      serialized.includes('"senders"'),
      false);
});

test('B6-C evidence evaluation has zero Firestore write provider or live-send authority', () => {
  const result =
      evaluate([
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
      ]);

  assert.equal(
      result.evidence.mayWriteTrustedSenderRegistry,
      false);

  assert.equal(
      result.evidence.mayEnableLiveSend,
      false);

  assert.equal(
      result.evidence.mayCallProvider,
      false);
});
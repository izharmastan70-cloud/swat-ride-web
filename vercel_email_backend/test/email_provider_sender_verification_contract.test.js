import assert from 'node:assert/strict';
import test from 'node:test';

import {
  BREVO_MANUAL_SENDER_UI_STEPS,
  EMAIL_PROVIDER_SENDER_FUTURE_COMMENTS,
  EMAIL_PROVIDER_SENDER_VERIFICATION_MODE,
  EMAIL_PROVIDER_SENDER_VERIFICATION_POLICY,
  EMAIL_PROVIDER_SENDER_VERIFICATION_STATUS,
  buildBrevoSenderVerificationPreparation,
} from '../src/config/email_provider_sender_verification_contract.js';

test('Brevo verification preparation uses the current provisional SWAT RIDE sender', () => {
  const result =
      buildBrevoSenderVerificationPreparation();

  assert.equal(result.ok, true);
  assert.equal(
      result.status,
      EMAIL_PROVIDER_SENDER_VERIFICATION_STATUS
          .awaitingOwnerBrevoVerification);

  assert.equal(
      result.verificationMode,
      EMAIL_PROVIDER_SENDER_VERIFICATION_MODE);

  assert.equal(
      result.sender.providerId,
      'brevo');

  assert.equal(
      result.sender.fromAddress,
      'swatrideofficial@gmail.com');

  assert.equal(
      result.sender.displayName,
      'SWAT RIDE');

  assert.equal(
      result.sender.publicWebsiteUrl,
      'https://swat-ride-web.vercel.app/');

  assert.equal(
      result.sender.ownsSendingDomain,
      false);
});

test('provider verification preparation never enables provider or live-send authority', () => {
  const result =
      buildBrevoSenderVerificationPreparation();

  assert.equal(
      result.providerExecutionAllowed,
      false);

  assert.equal(
      result.liveSendAllowed,
      false);

  assert.equal(
      result.mayCreateTrustedVerificationEvidence,
      false);
});

test('verification code is owner-only transient data and can never be collected/stored/logged by app', () => {
  assert.equal(
      EMAIL_PROVIDER_SENDER_VERIFICATION_POLICY
          .ownerMustVerifyInProviderUi,
      true);

  assert.equal(
      EMAIL_PROVIDER_SENDER_VERIFICATION_POLICY
          .verificationCodeMayBeCollectedByApp,
      false);

  assert.equal(
      EMAIL_PROVIDER_SENDER_VERIFICATION_POLICY
          .verificationCodeMayBeStored,
      false);

  assert.equal(
      EMAIL_PROVIDER_SENDER_VERIFICATION_POLICY
          .verificationCodeMayBeLogged,
      false);
});

test('provider API key and network are not required during manual sender verification preparation', () => {
  assert.equal(
      EMAIL_PROVIDER_SENDER_VERIFICATION_POLICY
          .providerApiKeyRequiredNow,
      false);

  assert.equal(
      EMAIL_PROVIDER_SENDER_VERIFICATION_POLICY
          .providerNetworkAllowedNow,
      false);

  assert.equal(
      EMAIL_PROVIDER_SENDER_VERIFICATION_POLICY
          .emailSendAllowedNow,
      false);

  assert.equal(
      EMAIL_PROVIDER_SENDER_VERIFICATION_POLICY
          .liveSendAllowedNow,
      false);
});

test('owner UI confirmation alone cannot create SERVER_PROVIDER_VERIFIED evidence', () => {
  assert.equal(
      EMAIL_PROVIDER_SENDER_VERIFICATION_POLICY
          .ownerUiConfirmationAloneMayCreateTrustedVerificationEvidence,
      false);
});

test('manual Brevo steps include private code entry and no project storage', () => {
  const joined =
      BREVO_MANUAL_SENDER_UI_STEPS.join(' ');

  assert.match(
      joined,
      /Add a sender/i);

  assert.match(
      joined,
      /SWAT RIDE/i);

  assert.match(
      joined,
      /swatrideofficial@gmail\.com/i);

  assert.match(
      joined,
      /6-digit verification code/i);

  assert.match(
      joined,
      /directly in Brevo/i);

  assert.match(
      joined,
      /Do not paste or store/i);
});

test('future comments preserve custom-domain migration and server-only credential verification', () => {
  const joined =
      EMAIL_PROVIDER_SENDER_FUTURE_COMMENTS.join(' ');

  assert.match(
      joined,
      /owned authenticated custom-domain sender/i);

  assert.match(
      joined,
      /independently confirm provider verification/i);

  assert.match(
      joined,
      /credentials server-side only/i);

  assert.match(
      joined,
      /never enables live-send by itself/i);
});

test('preparation output contains no OTP, provider API key, password, or Firebase Admin secret material', () => {
  const serialized =
      JSON.stringify(
          buildBrevoSenderVerificationPreparation());

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
      serialized.includes('6-digit'),
      false);
});
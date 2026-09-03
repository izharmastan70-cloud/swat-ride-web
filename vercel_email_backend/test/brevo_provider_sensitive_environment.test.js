import assert from 'node:assert/strict';
import test from 'node:test';

import {
  BREVO_PROVIDER_SECRET_ENV_NAME,
  BREVO_PROVIDER_SECRET_POLICY,
  prepareBrevoProviderSecretFromEnvironment,
} from '../src/config/brevo_provider_sensitive_environment.js';

const syntheticSecret =
    'synthetic_brevo_key_b6e_tests_only_123456789';

test('B6-E locks the exact server-side Brevo environment variable name', () => {
  assert.equal(
      BREVO_PROVIDER_SECRET_ENV_NAME,
      'BREVO_API_KEY');

  assert.equal(
      BREVO_PROVIDER_SECRET_POLICY.serverOnly,
      true);

  assert.equal(
      BREVO_PROVIDER_SECRET_POLICY
          .mayAppearInClientPayload,
      false);

  assert.equal(
      BREVO_PROVIDER_SECRET_POLICY
          .mayAppearInLogs,
      false);

  assert.equal(
      BREVO_PROVIDER_SECRET_POLICY
          .mayAppearInFirestore,
      false);

  assert.equal(
      BREVO_PROVIDER_SECRET_POLICY
          .mayAppearInSourceControl,
      false);

  assert.equal(
      BREVO_PROVIDER_SECRET_POLICY
          .mayBePastedIntoChat,
      false);
});

test('B6-E does not authorize provider network or live send', () => {
  assert.equal(
      BREVO_PROVIDER_SECRET_POLICY
          .runtimeWiringNow,
      false);

  assert.equal(
      BREVO_PROVIDER_SECRET_POLICY
          .liveSendNow,
      false);

  assert.equal(
      BREVO_PROVIDER_SECRET_POLICY
          .providerNetworkNow,
      false);

  assert.equal(
      BREVO_PROVIDER_SECRET_POLICY
          .requiredForLiveSend,
      false);
});

test('missing environment object fails closed', () => {
  const result =
      prepareBrevoProviderSecretFromEnvironment(
          null);

  assert.equal(
      result.ok,
      false);

  assert.equal(
      result.secret,
      null);

  assert.equal(
      result.code,
      'BREVO_PROVIDER_ENV_OBJECT_MISSING');

  assert.equal(
      result.metadata.present,
      false);
});

test('missing Brevo key fails closed without secret material', () => {
  const result =
      prepareBrevoProviderSecretFromEnvironment(
          {});

  assert.equal(
      result.ok,
      false);

  assert.equal(
      result.secret,
      null);

  assert.equal(
      result.code,
      'BREVO_PROVIDER_SECRET_MISSING');

  assert.equal(
      JSON.stringify(result)
          .includes(syntheticSecret),
      false);
});

test('synthetic injected environment produces redacted secret wrapper only', () => {
  const result =
      prepareBrevoProviderSecretFromEnvironment({
        BREVO_API_KEY:
            syntheticSecret,
      });

  assert.equal(
      result.ok,
      true);

  assert.equal(
      result.metadata.present,
      true);

  assert.equal(
      result.metadata.value,
      '[REDACTED]');

  assert.equal(
      String(result.secret),
      '[REDACTED_BREVO_API_KEY]');

  assert.equal(
      JSON.stringify(result.metadata)
          .includes(syntheticSecret),
      false);

  assert.equal(
      JSON.stringify(result.secret)
          .includes(syntheticSecret),
      false);
});

test('metadata never grants network or live-send authority', () => {
  const result =
      prepareBrevoProviderSecretFromEnvironment({
        BREVO_API_KEY:
            syntheticSecret,
      });

  assert.equal(
      result.metadata.providerNetworkAllowed,
      false);

  assert.equal(
      result.metadata.liveSendAllowed,
      false);
});

test('secret is required only for future read-only sender-status check at B6-E boundary', () => {
  assert.equal(
      BREVO_PROVIDER_SECRET_POLICY
          .requiredForSenderStatusReadOnlyCheck,
      true);

  assert.equal(
      BREVO_PROVIDER_SECRET_POLICY
          .requiredForLiveSend,
      false);
});

test('Vercel sensitive Preview/Production migration note remains locked in policy', () => {
  assert.equal(
      BREVO_PROVIDER_SECRET_POLICY
          .vercelSensitivePreviewProduction,
      true);
});
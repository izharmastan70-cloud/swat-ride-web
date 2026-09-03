import assert from 'node:assert/strict';
import test from 'node:test';

import {
  EMAIL_SENDER_BOOTSTRAP_DEFAULTS,
  EMAIL_SENDER_FUTURE_MIGRATION_NOTES,
  buildEmailSenderBootstrapConfig,
} from '../src/config/email_sender_identity_bootstrap_config.js';

test('current provisional sender defaults are SWAT RIDE Gmail + current website', () => {
  assert.equal(
      EMAIL_SENDER_BOOTSTRAP_DEFAULTS.fromAddress,
      'swatrideofficial@gmail.com');

  assert.equal(
      EMAIL_SENDER_BOOTSTRAP_DEFAULTS.displayName,
      'SWAT RIDE');

  assert.equal(
      EMAIL_SENDER_BOOTSTRAP_DEFAULTS.publicWebsiteUrl,
      'https://swat-ride-web.vercel.app/');

  assert.equal(
      EMAIL_SENDER_BOOTSTRAP_DEFAULTS.ownsSendingDomain,
      false);

  assert.equal(
      EMAIL_SENDER_BOOTSTRAP_DEFAULTS.providerVerified,
      false);

  assert.equal(
      EMAIL_SENDER_BOOTSTRAP_DEFAULTS.liveSendAllowed,
      false);
});

test('sender address/name/website remain changeable by non-secret configuration', () => {
  const config =
      buildEmailSenderBootstrapConfig({
        EMAIL_SENDER_ADDRESS:
            'support@example-owned-domain.test',
        EMAIL_SENDER_DISPLAY_NAME:
            'SWAT RIDE Support',
        EMAIL_PUBLIC_WEBSITE_URL:
            'https://example-owned-domain.test/',
      });

  assert.equal(
      config.fromAddress,
      'support@example-owned-domain.test');

  assert.equal(
      config.displayName,
      'SWAT RIDE Support');

  assert.equal(
      config.publicWebsiteUrl,
      'https://example-owned-domain.test/');

  assert.equal(
      config.mutableConfiguration,
      true);

  assert.equal(
      config.hardCodedProductionDependency,
      false);
});

test('bootstrap configuration can never self-verify or self-enable live send', () => {
  const config =
      buildEmailSenderBootstrapConfig({
        EMAIL_SENDER_ADDRESS:
            'future@example.test',
        EMAIL_SENDER_DISPLAY_NAME:
            'Future Name',
      });

  assert.equal(
      config.providerVerified,
      false);

  assert.equal(
      config.liveSendAllowed,
      false);

  assert.equal(
      config.ownsSendingDomain,
      false);
});

test('future migration notes preserve custom-domain and secret-safety requirements', () => {
  const notes =
      EMAIL_SENDER_FUTURE_MIGRATION_NOTES.join(' ');

  assert.match(
      notes,
      /owned custom-domain sender/i);

  assert.match(
      notes,
      /Authenticate the future owned sending domain/i);

  assert.match(
      notes,
      /display name changeable/i);

  assert.match(
      notes,
      /website URL separate from email sender-domain ownership/i);

  assert.match(
      notes,
      /secrets server-side/i);
});

test('sender bootstrap contains no password, OTP, provider API key, or Firebase Admin secret values', () => {
  const serialized =
      JSON.stringify({
        defaults:
            EMAIL_SENDER_BOOTSTRAP_DEFAULTS,
        config:
            buildEmailSenderBootstrapConfig(),
      });

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
});
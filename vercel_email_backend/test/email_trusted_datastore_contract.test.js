import assert from 'node:assert/strict';
import test from 'node:test';

import {
  EMAIL_DELIVERY_IDEMPOTENCY_COLLECTION,
  EMAIL_DELIVERY_IDEMPOTENCY_STATUS,
  EMAIL_SENDER_IDENTITY_COLLECTION,
  EMAIL_TRUSTED_DATASTORE_POLICY,
  buildDeliveryIdempotencyKey,
  validateSenderRegistryShape,
} from '../src/config/email_trusted_datastore_contract.js';

test('trusted Email datastore collection names are explicit and isolated', () => {
  assert.equal(
      EMAIL_SENDER_IDENTITY_COLLECTION,
      'agent_email_sender_identities');
  assert.equal(
      EMAIL_DELIVERY_IDEMPOTENCY_COLLECTION,
      'agent_email_delivery_idempotency');
});

test('Flutter/client can never create/update/delete trusted sender verification', () => {
  assert.equal(
      EMAIL_TRUSTED_DATASTORE_POLICY
          .senderRegistryClientReadAllowedForSuperAdmin,
      true);
  assert.equal(
      EMAIL_TRUSTED_DATASTORE_POLICY.senderRegistryClientCreateAllowed,
      false);
  assert.equal(
      EMAIL_TRUSTED_DATASTORE_POLICY.senderRegistryClientUpdateAllowed,
      false);
  assert.equal(
      EMAIL_TRUSTED_DATASTORE_POLICY.senderRegistryClientDeleteAllowed,
      false);
  assert.equal(
      EMAIL_TRUSTED_DATASTORE_POLICY.senderVerificationServerOnly,
      true);
});

test('Email delivery idempotency ledger is server-transaction-only', () => {
  assert.equal(
      EMAIL_TRUSTED_DATASTORE_POLICY.deliveryIdempotencyClientReadAllowed,
      false);
  assert.equal(
      EMAIL_TRUSTED_DATASTORE_POLICY.deliveryIdempotencyClientCreateAllowed,
      false);
  assert.equal(
      EMAIL_TRUSTED_DATASTORE_POLICY.deliveryIdempotencyClientUpdateAllowed,
      false);
  assert.equal(
      EMAIL_TRUSTED_DATASTORE_POLICY.deliveryIdempotencyClientDeleteAllowed,
      false);
  assert.equal(
      EMAIL_TRUSTED_DATASTORE_POLICY.deliveryIdempotencyServerTransactionOnly,
      true);
});

test('trusted Email datastores never contain provider/admin credential material', () => {
  assert.equal(
      EMAIL_TRUSTED_DATASTORE_POLICY
          .providerSecretMayBeStoredInSenderRegistry,
      false);
  assert.equal(
      EMAIL_TRUSTED_DATASTORE_POLICY
          .firebaseAdminCredentialMayBeStoredInSenderRegistry,
      false);
  assert.equal(
      EMAIL_TRUSTED_DATASTORE_POLICY
          .providerSecretMayBeStoredInIdempotencyLedger,
      false);
  assert.equal(
      EMAIL_TRUSTED_DATASTORE_POLICY
          .firebaseAdminCredentialMayBeStoredInIdempotencyLedger,
      false);
});

test('trusted sender shape requires server verification evidence', () => {
  const valid = validateSenderRegistryShape({
    senderIdentityId: 'sender_primary',
    providerId: 'brevo',
    fromAddress: 'synthetic@example.com',
    displayName: 'Synthetic Sender',
    enabled: true,
    verifiedAt: Object.freeze({
      syntheticTimestamp: true,
    }),
    verificationSource: 'SERVER_PROVIDER_VERIFIED',
    createdAt: Object.freeze({
      syntheticTimestamp: true,
    }),
    updatedAt: Object.freeze({
      syntheticTimestamp: true,
    }),
  });

  assert.equal(valid.ok, true);

  const missingVerification = validateSenderRegistryShape({
    senderIdentityId: 'sender_primary',
    providerId: 'brevo',
    fromAddress: 'synthetic@example.com',
    displayName: 'Synthetic Sender',
    enabled: true,
    verifiedAt: null,
    verificationSource: '',
    createdAt: Object.freeze({
      syntheticTimestamp: true,
    }),
    updatedAt: Object.freeze({
      syntheticTimestamp: true,
    }),
  });

  assert.equal(missingVerification.ok, false);
  assert.equal(
      missingVerification.code,
      'SENDER_RECORD_NOT_TRUSTED_VERIFIED');
});

test('sender registry rejects unknown fields such as secrets', () => {
  const result = validateSenderRegistryShape({
    senderIdentityId: 'sender_primary',
    providerId: 'brevo',
    fromAddress: 'synthetic@example.com',
    displayName: 'Synthetic Sender',
    enabled: true,
    verifiedAt: Object.freeze({
      syntheticTimestamp: true,
    }),
    verificationSource: 'SERVER_PROVIDER_VERIFIED',
    createdAt: Object.freeze({
      syntheticTimestamp: true,
    }),
    updatedAt: Object.freeze({
      syntheticTimestamp: true,
    }),
    providerApiKey: 'must-never-be-accepted',
  });

  assert.equal(result.ok, false);
  assert.equal(result.code, 'SENDER_RECORD_FIELDS_INVALID');
});

test('idempotency key binds approvalId and handoffId', () => {
  const key = buildDeliveryIdempotencyKey({
    approvalId: 'approval_1',
    handoffId: 'handoff_1',
  });

  assert.equal(key, 'email:approval_1:handoff_1');

  assert.throws(
      () => buildDeliveryIdempotencyKey({
        approvalId: 'approval_1',
        handoffId: '',
      }),
      /approvalId and handoffId are required/);
});

test('idempotency statuses include safe retry and unknown-delivery states', () => {
  assert.equal(EMAIL_DELIVERY_IDEMPOTENCY_STATUS.reserved, 'RESERVED');
  assert.equal(EMAIL_DELIVERY_IDEMPOTENCY_STATUS.accepted, 'ACCEPTED');
  assert.equal(
      EMAIL_DELIVERY_IDEMPOTENCY_STATUS.failedRetryable,
      'FAILED_RETRYABLE');
  assert.equal(
      EMAIL_DELIVERY_IDEMPOTENCY_STATUS.deliveryUnknown,
      'DELIVERY_UNKNOWN');
});
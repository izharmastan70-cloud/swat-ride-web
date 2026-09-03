export const EMAIL_SENDER_IDENTITY_COLLECTION =
    'agent_email_sender_identities';

export const EMAIL_DELIVERY_IDEMPOTENCY_COLLECTION =
    'agent_email_delivery_idempotency';

export const EMAIL_SENDER_IDENTITY_ALLOWED_FIELDS = Object.freeze([
  'senderIdentityId',
  'providerId',
  'fromAddress',
  'displayName',
  'enabled',
  'verifiedAt',
  'verificationSource',
  'createdAt',
  'updatedAt',
]);

export const EMAIL_DELIVERY_IDEMPOTENCY_ALLOWED_FIELDS = Object.freeze([
  'idempotencyKey',
  'approvalId',
  'handoffId',
  'authorizationRequestId',
  'bindingFingerprint',
  'status',
  'createdAt',
  'updatedAt',
  'providerId',
  'providerMessageId',
]);

export const EMAIL_DELIVERY_IDEMPOTENCY_STATUS = Object.freeze({
  reserved: 'RESERVED',
  accepted: 'ACCEPTED',
  failedRetryable: 'FAILED_RETRYABLE',
  deliveryUnknown: 'DELIVERY_UNKNOWN',
});

export const EMAIL_TRUSTED_DATASTORE_POLICY = Object.freeze({
  senderRegistryClientReadAllowedForSuperAdmin: true,
  senderRegistryClientCreateAllowed: false,
  senderRegistryClientUpdateAllowed: false,
  senderRegistryClientDeleteAllowed: false,
  senderVerificationServerOnly: true,

  deliveryIdempotencyClientReadAllowed: false,
  deliveryIdempotencyClientCreateAllowed: false,
  deliveryIdempotencyClientUpdateAllowed: false,
  deliveryIdempotencyClientDeleteAllowed: false,
  deliveryIdempotencyServerTransactionOnly: true,

  providerSecretMayBeStoredInSenderRegistry: false,
  firebaseAdminCredentialMayBeStoredInSenderRegistry: false,
  providerSecretMayBeStoredInIdempotencyLedger: false,
  firebaseAdminCredentialMayBeStoredInIdempotencyLedger: false,
});

export function validateSenderRegistryShape(record) {
  if (!record || typeof record !== 'object' || Array.isArray(record)) {
    return Object.freeze({
      ok: false,
      code: 'SENDER_RECORD_MISSING',
    });
  }

  const keys = Object.keys(record).sort();
  const allowed = [...EMAIL_SENDER_IDENTITY_ALLOWED_FIELDS].sort();

  if (keys.length !== allowed.length ||
      keys.some((key, index) => key !== allowed[index])) {
    return Object.freeze({
      ok: false,
      code: 'SENDER_RECORD_FIELDS_INVALID',
    });
  }

  if (typeof record.senderIdentityId !== 'string' ||
      !record.senderIdentityId.trim() ||
      typeof record.providerId !== 'string' ||
      !record.providerId.trim() ||
      typeof record.fromAddress !== 'string' ||
      !record.fromAddress.trim() ||
      typeof record.displayName !== 'string' ||
      typeof record.enabled !== 'boolean') {
    return Object.freeze({
      ok: false,
      code: 'SENDER_RECORD_CORE_FIELDS_INVALID',
    });
  }

  if (record.verifiedAt == null ||
      typeof record.verificationSource !== 'string' ||
      !record.verificationSource.trim()) {
    return Object.freeze({
      ok: false,
      code: 'SENDER_RECORD_NOT_TRUSTED_VERIFIED',
    });
  }

  return Object.freeze({
    ok: true,
    code: 'SENDER_RECORD_SHAPE_VALID',
  });
}

export function buildDeliveryIdempotencyKey({
  approvalId,
  handoffId,
}) {
  const normalizedApprovalId =
      typeof approvalId === 'string' ? approvalId.trim() : '';

  const normalizedHandoffId =
      typeof handoffId === 'string' ? handoffId.trim() : '';

  if (!normalizedApprovalId || !normalizedHandoffId) {
    throw new Error(
        'approvalId and handoffId are required for Email idempotency.');
  }

  return `email:${normalizedApprovalId}:${normalizedHandoffId}`;
}
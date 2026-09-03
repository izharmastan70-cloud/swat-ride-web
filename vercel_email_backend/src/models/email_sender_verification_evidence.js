export const EMAIL_SENDER_PROVIDER_EVIDENCE_VERSION =
    'BREVO_GET_SENDERS_V1';

export const EMAIL_SENDER_PROVIDER_EVIDENCE_SOURCE =
    'SERVER_BREVO_GET_SENDERS_RESPONSE';

export function buildEmailSenderVerificationEvidence({
  senderIdentityId,
  providerSenderId,
  fromAddress,
  displayName,
  active,
  observedAt,
}) {
  const normalizedProviderSenderId =
      providerSenderId == null
          ? ''
          : String(providerSenderId).trim();

  if (typeof senderIdentityId !== 'string' ||
      senderIdentityId.trim().length === 0 ||
      normalizedProviderSenderId.length === 0 ||
      typeof fromAddress !== 'string' ||
      fromAddress.trim().length === 0 ||
      typeof displayName !== 'string' ||
      displayName.trim().length === 0 ||
      active !== true ||
      !(observedAt instanceof Date) ||
      Number.isNaN(observedAt.getTime())) {
    throw new Error(
        'Trusted Email sender provider evidence is invalid.');
  }

  return Object.freeze({
    senderIdentityId:
        senderIdentityId.trim(),
    providerId:
        'brevo',
    providerSenderId:
        normalizedProviderSenderId,
    fromAddress:
        fromAddress.trim().toLowerCase(),
    displayName:
        displayName.trim(),
    active:
        true,
    verificationSource:
        'SERVER_PROVIDER_VERIFIED',
    providerEvidenceSource:
        EMAIL_SENDER_PROVIDER_EVIDENCE_SOURCE,
    providerEvidenceVersion:
        EMAIL_SENDER_PROVIDER_EVIDENCE_VERSION,
    observedAt:
        observedAt.toISOString(),

    // SECURITY:
    // This evidence intentionally excludes provider API keys, OTP values,
    // passwords, Firebase Admin credentials, message contents, and raw
    // provider responses.
    containsSecretMaterial:
        false,

    // B6-C only evaluates a trusted future server response shape.
    // It does NOT write Firestore and does NOT activate live sending.
    mayWriteTrustedSenderRegistry:
        false,
    mayEnableLiveSend:
        false,
    mayCallProvider:
        false,
  });
}
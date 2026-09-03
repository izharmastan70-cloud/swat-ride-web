import {
  buildEmailSenderVerificationEvidence,
  EMAIL_SENDER_PROVIDER_EVIDENCE_SOURCE,
} from '../models/email_sender_verification_evidence.js';

export const BREVO_SENDER_LIST_ENDPOINT =
    '/v3/senders';

export const BREVO_SENDER_VERIFICATION_EVALUATION_CODE =
    Object.freeze({
      verified:
          'BREVO_EXACT_ACTIVE_SENDER_VERIFIED',
      untrustedInput:
          'BREVO_PROVIDER_SNAPSHOT_NOT_SERVER_TRUSTED',
      invalidResponse:
          'BREVO_PROVIDER_RESPONSE_INVALID',
      missingSender:
          'BREVO_EXPECTED_SENDER_NOT_FOUND',
      duplicateEmail:
          'BREVO_DUPLICATE_SENDERS_FOR_EMAIL',
      identityMismatch:
          'BREVO_SENDER_IDENTITY_MISMATCH',
      inactive:
          'BREVO_SENDER_NOT_ACTIVE',
    });

function normalizeEmail(value) {
  return typeof value === 'string'
      ? value.trim().toLowerCase()
      : '';
}

function normalizeDisplayName(value) {
  return typeof value === 'string'
      ? value.trim()
      : '';
}

function deny(code, details = {}) {
  return Object.freeze({
    ok:
        false,
    eligibleForTrustedEvidence:
        false,
    evidence:
        null,
    mayWriteTrustedSenderRegistry:
        false,
    mayEnableLiveSend:
        false,
    mayCallProvider:
        false,
    code,
    ...details,
  });
}

export function evaluateBrevoSenderVerificationSnapshot({
  providerResponse,
  expectedSender,
  sourceContext,
  observedAt = new Date(),
}) {
  // IMPORTANT:
  // Accept only a FUTURE server-side authenticated Brevo GET /v3/senders
  // response. Owner screenshots, Flutter payloads, manual text, or a UI
  // "Verified" label must never manufacture trusted provider evidence.
  if (sourceContext?.providerEvidenceSource !==
          EMAIL_SENDER_PROVIDER_EVIDENCE_SOURCE ||
      sourceContext?.serverAuthenticatedProviderResponse !== true ||
      sourceContext?.endpoint !==
          BREVO_SENDER_LIST_ENDPOINT) {
    return deny(
        BREVO_SENDER_VERIFICATION_EVALUATION_CODE
            .untrustedInput);
  }

  if (!providerResponse ||
      !Array.isArray(providerResponse.senders) ||
      !expectedSender ||
      typeof expectedSender.senderIdentityId !== 'string' ||
      typeof expectedSender.fromAddress !== 'string' ||
      typeof expectedSender.displayName !== 'string') {
    return deny(
        BREVO_SENDER_VERIFICATION_EVALUATION_CODE
            .invalidResponse);
  }

  const expectedEmail =
      normalizeEmail(
          expectedSender.fromAddress);

  const expectedName =
      normalizeDisplayName(
          expectedSender.displayName);

  if (!expectedEmail ||
      !expectedName) {
    return deny(
        BREVO_SENDER_VERIFICATION_EVALUATION_CODE
            .invalidResponse);
  }

  const sameEmail =
      providerResponse.senders.filter(
          (sender) =>
              normalizeEmail(sender?.email) ===
                  expectedEmail);

  if (sameEmail.length === 0) {
    return deny(
        BREVO_SENDER_VERIFICATION_EVALUATION_CODE
            .missingSender);
  }

  // FAIL CLOSED ON DUPLICATES:
  // If the same email appears in more than one Brevo sender record,
  // exact production identity selection is ambiguous. Keep one canonical
  // SWAT RIDE sender before live activation.
  if (sameEmail.length !== 1) {
    return deny(
        BREVO_SENDER_VERIFICATION_EVALUATION_CODE
            .duplicateEmail,
        Object.freeze({
          duplicateCount:
              sameEmail.length,
        }));
  }

  const sender =
      sameEmail[0];

  if (normalizeDisplayName(sender?.name) !==
      expectedName) {
    return deny(
        BREVO_SENDER_VERIFICATION_EVALUATION_CODE
            .identityMismatch);
  }

  if (sender?.active !== true) {
    return deny(
        BREVO_SENDER_VERIFICATION_EVALUATION_CODE
            .inactive);
  }

  const evidence =
      buildEmailSenderVerificationEvidence({
        senderIdentityId:
            expectedSender.senderIdentityId,
        providerSenderId:
            sender.id,
        fromAddress:
            sender.email,
        displayName:
            sender.name,
        active:
            sender.active,
        observedAt,
      });

  return Object.freeze({
    ok:
        true,
    eligibleForTrustedEvidence:
        true,
    evidence,
    mayWriteTrustedSenderRegistry:
        false,
    mayEnableLiveSend:
        false,
    mayCallProvider:
        false,
    code:
        BREVO_SENDER_VERIFICATION_EVALUATION_CODE
            .verified,
  });
}
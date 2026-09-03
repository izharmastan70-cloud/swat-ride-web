'use strict';

const MAX_CLOCK_SKEW_MS = 5 * 60 * 1000;

function validateWebhookVerificationEvidence({
  evidence,
  expectedProviderId,
  nowMs,
}) {
  if (!evidence || typeof evidence !== 'object') {
    return Object.freeze({
      ok: false,
      code: 'MISSING_VERIFICATION_EVIDENCE',
    });
  }

  if (evidence.signatureVerified !== true) {
    return Object.freeze({
      ok: false,
      code: 'SIGNATURE_NOT_VERIFIED',
    });
  }

  if (evidence.providerId !== expectedProviderId) {
    return Object.freeze({
      ok: false,
      code: 'PROVIDER_BINDING_MISMATCH',
    });
  }

  if (
    typeof evidence.verificationEvidenceId !== 'string' ||
    evidence.verificationEvidenceId.trim() === ''
  ) {
    return Object.freeze({
      ok: false,
      code: 'MISSING_VERIFICATION_EVIDENCE_ID',
    });
  }

  const verifiedAtMs = Number(evidence.verifiedAtMs);

  if (
    !Number.isSafeInteger(verifiedAtMs) ||
    Math.abs(nowMs - verifiedAtMs) > MAX_CLOCK_SKEW_MS
  ) {
    return Object.freeze({
      ok: false,
      code: 'VERIFICATION_EVIDENCE_STALE',
    });
  }

  return Object.freeze({
    ok: true,
    code: 'VERIFICATION_EVIDENCE_OK',
    verificationEvidenceId:
      evidence.verificationEvidenceId.trim(),
  });
}

module.exports = {
  MAX_CLOCK_SKEW_MS,
  validateWebhookVerificationEvidence,
};
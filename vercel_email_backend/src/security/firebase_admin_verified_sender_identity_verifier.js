import {
  EMAIL_SENDER_IDENTITY_COLLECTION,
  validateSenderRegistryShape,
} from '../config/email_trusted_datastore_contract.js';

function normalizedEmail(value) {
  return typeof value === 'string'
      ? value.trim().toLowerCase()
      : '';
}

export class FirebaseAdminVerifiedSenderIdentityVerifier {
  constructor({
    firestore,
  }) {
    this.firestore = firestore;
  }

  get ready() {
    return typeof this.firestore?.collection === 'function';
  }

  async verifySenderIdentity(request) {
    const senderIdentityId =
        typeof request?.senderIdentityId === 'string'
            ? request.senderIdentityId.trim()
            : '';

    const providerId =
        typeof request?.providerId === 'string'
            ? request.providerId.trim()
            : '';

    const fromAddress =
        normalizedEmail(request?.fromAddress);

    if (!this.ready ||
        !senderIdentityId ||
        !providerId ||
        !fromAddress) {
      return this.#deny(
          senderIdentityId,
          providerId,
          fromAddress,
          'VERIFIED_SENDER_INPUT_INVALID');
    }

    try {
      const snapshot =
          await this.firestore
              .collection(EMAIL_SENDER_IDENTITY_COLLECTION)
              .doc(senderIdentityId)
              .get();

      if (!snapshot?.exists) {
        return this.#deny(
            senderIdentityId,
            providerId,
            fromAddress,
            'VERIFIED_SENDER_NOT_FOUND');
      }

      const data = snapshot.data() ?? {};
      const shape = validateSenderRegistryShape(data);

      if (shape.ok !== true) {
        return this.#deny(
            senderIdentityId,
            providerId,
            fromAddress,
            shape.code);
      }

      const exact =
          data.senderIdentityId === senderIdentityId &&
          data.providerId === providerId &&
          normalizedEmail(data.fromAddress) === fromAddress &&
          data.enabled === true &&
          data.verifiedAt != null &&
          data.verificationSource === 'SERVER_PROVIDER_VERIFIED';

      if (!exact) {
        return this.#deny(
            senderIdentityId,
            providerId,
            fromAddress,
            'VERIFIED_SENDER_EXACT_MATCH_FAILED');
      }

      return Object.freeze({
        ok: true,
        verified: true,
        enabled: true,
        senderIdentityId,
        providerId,
        fromAddress,
        verificationSource:
            'SERVER_PROVIDER_VERIFIED',
        reason: 'VERIFIED_SENDER_RECHECK_PASSED',
      });
    } catch (_) {
      return this.#deny(
          senderIdentityId,
          providerId,
          fromAddress,
          'VERIFIED_SENDER_RECHECK_FAILED');
    }
  }

  #deny(senderIdentityId, providerId, fromAddress, reason) {
    return Object.freeze({
      ok: false,
      verified: false,
      enabled: false,
      senderIdentityId,
      providerId,
      fromAddress,
      verificationSource: '',
      reason,
    });
  }
}
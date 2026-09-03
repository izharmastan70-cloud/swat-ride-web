import { FieldValue } from 'firebase-admin/firestore';

import {
  EMAIL_DELIVERY_IDEMPOTENCY_COLLECTION,
  EMAIL_DELIVERY_IDEMPOTENCY_STATUS,
  buildDeliveryIdempotencyKey,
} from '../config/email_trusted_datastore_contract.js';

function nonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function exactStoredScope(data, request, idempotencyKey) {
  return data?.idempotencyKey === idempotencyKey &&
    data?.approvalId === request.approvalId.trim() &&
    data?.handoffId === request.handoffId.trim() &&
    data?.authorizationRequestId ===
        request.authorizationRequestId.trim() &&
    data?.bindingFingerprint ===
        request.bindingFingerprint.trim() &&
    data?.providerId === request.providerId.trim();
}

export class FirebaseAdminEmailReplayGuard {
  constructor({
    firestore,
    serverTimestamp = () => FieldValue.serverTimestamp(),
  }) {
    this.firestore = firestore;
    this.serverTimestamp = serverTimestamp;
  }

  get ready() {
    return typeof this.firestore?.collection === 'function' &&
      typeof this.firestore?.runTransaction === 'function';
  }

  async claim(request) {
    if (!this.ready ||
        !nonEmptyString(request?.approvalId) ||
        !nonEmptyString(request?.handoffId) ||
        !nonEmptyString(request?.authorizationRequestId) ||
        !nonEmptyString(request?.bindingFingerprint) ||
        !nonEmptyString(request?.providerId)) {
      return Object.freeze({
        ok: false,
        claimed: false,
        retry: false,
        reason: 'EMAIL_IDEMPOTENCY_INPUT_INVALID',
      });
    }

    const idempotencyKey =
        buildDeliveryIdempotencyKey({
          approvalId: request.approvalId,
          handoffId: request.handoffId,
        });

    const ref =
        this.firestore
            .collection(EMAIL_DELIVERY_IDEMPOTENCY_COLLECTION)
            .doc(idempotencyKey);

    try {
      return await this.firestore.runTransaction(
          async (transaction) => {
            const snapshot =
                await transaction.get(ref);

            if (!snapshot.exists) {
              transaction.set(ref, {
                idempotencyKey,
                approvalId: request.approvalId.trim(),
                handoffId: request.handoffId.trim(),
                authorizationRequestId:
                    request.authorizationRequestId.trim(),
                bindingFingerprint:
                    request.bindingFingerprint.trim(),
                status:
                    EMAIL_DELIVERY_IDEMPOTENCY_STATUS.reserved,
                createdAt: this.serverTimestamp(),
                updatedAt: this.serverTimestamp(),
                providerId: request.providerId.trim(),
                providerMessageId: '',
              });

              return Object.freeze({
                ok: true,
                claimed: true,
                retry: false,
                idempotencyKey,
                reason: 'EMAIL_IDEMPOTENCY_RESERVED',
              });
            }

            const data = snapshot.data() ?? {};

            if (!exactStoredScope(
                data,
                request,
                idempotencyKey)) {
              return Object.freeze({
                ok: false,
                claimed: false,
                retry: false,
                idempotencyKey,
                reason: 'EMAIL_IDEMPOTENCY_SCOPE_MISMATCH',
              });
            }

            if (data.status ===
                EMAIL_DELIVERY_IDEMPOTENCY_STATUS.failedRetryable) {
              transaction.update(ref, {
                status:
                    EMAIL_DELIVERY_IDEMPOTENCY_STATUS.reserved,
                updatedAt: this.serverTimestamp(),
              });

              return Object.freeze({
                ok: true,
                claimed: true,
                retry: true,
                idempotencyKey,
                reason: 'EMAIL_IDEMPOTENCY_RETRY_RESERVED',
              });
            }

            return Object.freeze({
              ok: false,
              claimed: false,
              retry: false,
              idempotencyKey,
              reason: 'EMAIL_IDEMPOTENCY_REPLAY_REJECTED',
            });
          });
    } catch (_) {
      return Object.freeze({
        ok: false,
        claimed: false,
        retry: false,
        idempotencyKey,
        reason: 'EMAIL_IDEMPOTENCY_TRANSACTION_FAILED',
      });
    }
  }

  async markAccepted({
    approvalId,
    handoffId,
    providerMessageId = '',
  }) {
    return this.#markFinalStatus({
      approvalId,
      handoffId,
      status: EMAIL_DELIVERY_IDEMPOTENCY_STATUS.accepted,
      providerMessageId,
    });
  }

  async markFailedRetryable({
    approvalId,
    handoffId,
  }) {
    return this.#markFinalStatus({
      approvalId,
      handoffId,
      status:
          EMAIL_DELIVERY_IDEMPOTENCY_STATUS.failedRetryable,
      providerMessageId: '',
    });
  }

  async markDeliveryUnknown({
    approvalId,
    handoffId,
  }) {
    return this.#markFinalStatus({
      approvalId,
      handoffId,
      status:
          EMAIL_DELIVERY_IDEMPOTENCY_STATUS.deliveryUnknown,
      providerMessageId: '',
    });
  }

  async #markFinalStatus({
    approvalId,
    handoffId,
    status,
    providerMessageId,
  }) {
    const idempotencyKey =
        buildDeliveryIdempotencyKey({
          approvalId,
          handoffId,
        });

    const ref =
        this.firestore
            .collection(EMAIL_DELIVERY_IDEMPOTENCY_COLLECTION)
            .doc(idempotencyKey);

    await ref.update({
      status,
      updatedAt: this.serverTimestamp(),
      providerMessageId:
          typeof providerMessageId === 'string'
              ? providerMessageId.trim()
              : '',
    });

    return Object.freeze({
      ok: true,
      idempotencyKey,
      status,
    });
  }
}
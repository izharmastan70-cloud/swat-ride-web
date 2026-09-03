import {
  EMAIL_SENDER_PROVIDER_EVIDENCE_SOURCE,
} from '../models/email_sender_verification_evidence.js';

import {
  BREVO_SENDER_LIST_ENDPOINT,
} from '../security/brevo_sender_verification_evidence_evaluator.js';

export const BREVO_API_BASE_URL =
    'https://api.brevo.com';

export const BREVO_SENDER_STATUS_MAX_RESPONSE_BYTES =
    262144;

function fail(code, details = {}) {
  return Object.freeze({
    ok: false,
    providerResponse: null,
    sourceContext: null,
    networkAttempted:
        details.networkAttempted === true,
    providerWriteAllowed: false,
    emailSendAllowed: false,
    liveSendAllowed: false,
    code,
  });
}

export class BrevoSenderStatusReadOnlyAdapter {
  constructor({
    fetchImpl,
    apiKeySecret,
    networkAllowed = false,
    maxResponseBytes =
        BREVO_SENDER_STATUS_MAX_RESPONSE_BYTES,
  }) {
    this.fetchImpl =
        fetchImpl;

    this.apiKeySecret =
        apiKeySecret;

    this.networkAllowed =
        networkAllowed === true;

    this.maxResponseBytes =
        maxResponseBytes;
  }

  get ready() {
    return this.networkAllowed === true &&
      typeof this.fetchImpl === 'function' &&
      this.apiKeySecret?.present === true &&
      Number.isInteger(this.maxResponseBytes) &&
      this.maxResponseBytes > 0;
  }

  get readOnly() {
    return true;
  }

  get providerWriteAllowed() {
    return false;
  }

  get emailSendAllowed() {
    return false;
  }

  get liveSendAllowed() {
    return false;
  }

  async fetchSenderStatusSnapshot() {
    if (this.networkAllowed !== true) {
      return fail(
          'BREVO_SENDER_STATUS_NETWORK_DISABLED');
    }

    if (typeof this.fetchImpl !== 'function') {
      return fail(
          'BREVO_SENDER_STATUS_FETCH_NOT_READY');
    }

    if (this.apiKeySecret?.present !== true ||
        typeof this.apiKeySecret
            .revealForRequestOnly !== 'function') {
      return fail(
          'BREVO_SENDER_STATUS_API_KEY_NOT_READY');
    }

    if (!Number.isInteger(this.maxResponseBytes) ||
        this.maxResponseBytes <= 0) {
      return fail(
          'BREVO_SENDER_STATUS_RESPONSE_LIMIT_INVALID');
    }

    const url =
        `${BREVO_API_BASE_URL}${BREVO_SENDER_LIST_ENDPOINT}`;

    let response;

    try {
      response =
          await this.fetchImpl(
              url,
              {
                method:
                    'GET',
                headers: {
                  accept:
                      'application/json',
                  'api-key':
                      this.apiKeySecret
                          .revealForRequestOnly(),
                },
                redirect:
                    'error',
              });
    } catch (_) {
      return fail(
          'BREVO_SENDER_STATUS_NETWORK_FAILED',
          {
            networkAttempted:
                true,
          });
    }

    if (!response ||
        typeof response.status !== 'number' ||
        typeof response.text !== 'function') {
      return fail(
          'BREVO_SENDER_STATUS_RESPONSE_INVALID',
          {
            networkAttempted:
                true,
          });
    }

    if (response.status !== 200) {
      return fail(
          `BREVO_SENDER_STATUS_HTTP_${response.status}`,
          {
            networkAttempted:
                true,
          });
    }

    let text;

    try {
      text =
          await response.text();
    } catch (_) {
      return fail(
          'BREVO_SENDER_STATUS_BODY_READ_FAILED',
          {
            networkAttempted:
                true,
          });
    }

    if (typeof text !== 'string' ||
        Buffer.byteLength(text, 'utf8') >
            this.maxResponseBytes) {
      return fail(
          'BREVO_SENDER_STATUS_RESPONSE_TOO_LARGE',
          {
            networkAttempted:
                true,
          });
    }

    let providerResponse;

    try {
      providerResponse =
          JSON.parse(text);
    } catch (_) {
      return fail(
          'BREVO_SENDER_STATUS_JSON_INVALID',
          {
            networkAttempted:
                true,
          });
    }

    if (!providerResponse ||
        !Array.isArray(providerResponse.senders)) {
      return fail(
          'BREVO_SENDER_STATUS_SHAPE_INVALID',
          {
            networkAttempted:
                true,
          });
    }

    return Object.freeze({
      ok:
          true,
      providerResponse,
      sourceContext:
          Object.freeze({
            providerEvidenceSource:
                EMAIL_SENDER_PROVIDER_EVIDENCE_SOURCE,
            serverAuthenticatedProviderResponse:
                true,
            endpoint:
                BREVO_SENDER_LIST_ENDPOINT,
          }),
      networkAttempted:
          true,
      providerWriteAllowed:
          false,
      emailSendAllowed:
          false,
      liveSendAllowed:
          false,
      code:
          'BREVO_SENDER_STATUS_SNAPSHOT_READY',
    });
  }
}
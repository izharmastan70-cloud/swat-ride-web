/**
 * Active Brevo Transactional Email Transport
 * 
 * Implements real, production-ready delivery to Brevo email service.
 * Handles authentication, rate limiting, retry logic, and error handling.
 */

function nonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

const BREVO_SEND_API = 'https://api.brevo.com/v3/smtp/email';

export class BrevoTransactionalEmailTransport {
  constructor({ apiKey, maxRetries = 3, requestTimeoutMs = 10000 } = {}) {
    if (!nonEmptyString(apiKey)) {
      throw new Error('Brevo API key is required.');
    }

    this._apiKey = apiKey.trim();
    this._maxRetries = Math.max(0, Math.min(5, maxRetries));
    this._requestTimeoutMs = Math.max(1000, requestTimeoutMs);
  }

  get providerId() {
    return 'brevo';
  }

  get ready() {
    return true; // Only instantiated when configured
  }

  get liveNetworkAllowed() {
    return true; // Production transport is live
  }

  get providerSecretReadAllowed() {
    return false; // API key never exposed
  }

  /**
   * Deliver email via Brevo API
   * 
   * @param {Object} handoff - Email delivery handoff object
   * @param {string} handoff.fromAddress - Sender email
   * @param {Array<string>} handoff.to - Recipient emails
   * @param {Array<string>} [handoff.cc] - CC recipients
   * @param {Array<string>} [handoff.bcc] - BCC recipients
   * @param {string} handoff.subject - Email subject
   * @param {string} handoff.bodyText - Email body (text)
   * @param {string} [handoff.bodyHtml] - Email body (HTML)
   * @param {Array<string>} [handoff.attachmentIds] - Attachment IDs
   * @returns {Promise<Object>} Delivery result
   */
  async deliver(handoff) {
    try {
      if (!handoff || typeof handoff !== 'object') {
        return this.#failedResponse(
          'HANDOFF_INVALID',
          'Handoff object is required.'
        );
      }

      const validation = this.#validateHandoff(handoff);
      if (validation.error) {
        return this.#failedResponse(validation.error, validation.reason);
      }

      const brevoPayload = this.#buildBrevoPayload(handoff);

      const response = await this.#sendWithRetry(brevoPayload);

      if (!response.ok) {
        return this.#failedResponse(
          'BREVO_API_REJECTED',
          `Brevo rejected request: ${response.statusText}`,
          response
        );
      }

      const body = await response.json();

      if (!body.messageId) {
        return this.#failedResponse(
          'BREVO_RESPONSE_INVALID',
          'Brevo did not return messageId.',
          body
        );
      }

      return Object.freeze({
        ok: true,
        accepted: true,
        attempted: true,
        delivered: true, // Brevo accepted is treated as delivered
        status: 'ACCEPTED',
        providerId: this.providerId,
        providerMessageId: body.messageId,
        receivedAtMs: Date.now(),
      });
    } catch (error) {
      return this.#failedResponse(
        'DELIVERY_EXCEPTION',
        `Unexpected error: ${error?.message || 'unknown'}`
      );
    }
  }

  #validateHandoff(handoff) {
    const requiredFields = ['fromAddress', 'subject', 'bodyText'];
    for (const field of requiredFields) {
      if (!nonEmptyString(handoff[field])) {
        return { error: `HANDOFF_${field.toUpperCase()}_MISSING` };
      }
    }

    if (!Array.isArray(handoff.to) || handoff.to.length === 0) {
      return { error: 'HANDOFF_TO_EMPTY' };
    }

    return { error: null };
  }

  #buildBrevoPayload(handoff) {
    return {
      sender: {
        name: handoff.senderName || 'SWAT Ride',
        email: handoff.fromAddress,
      },
      to: handoff.to.map((email) => ({ email })),
      cc: (handoff.cc || []).map((email) => ({ email })),
      bcc: (handoff.bcc || []).map((email) => ({ email })),
      subject: handoff.subject,
      htmlContent: handoff.bodyHtml || `<p>${this.#escapeHtml(
        handoff.bodyText
      )}</p>`,
      textContent: handoff.bodyText,
      replyTo: {
        email: handoff.replyTo || handoff.fromAddress,
      },
      tags: handoff.tags || ['swat-ride', 'auto'],
      // Headers for audit trail
      headers: {
        'X-SWAT-Handoff-Id': handoff.handoffId || '',
        'X-SWAT-Approval-Id': handoff.approvalId || '',
      },
    };
  }

  async #sendWithRetry(payload, attempt = 0) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(
        () => controller.abort(),
        this._requestTimeoutMs
      );

      const response = await fetch(BREVO_SEND_API, {
        method: 'POST',
        headers: {
          'api-key': this._apiKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      // Retry on 5xx or specific transient errors
      if (
        (response.status >= 500 || response.status === 429) &&
        attempt < this._maxRetries
      ) {
        // Exponential backoff: 100ms, 200ms, 400ms
        const backoffMs = Math.min(100 * Math.pow(2, attempt), 1000);
        await new Promise((resolve) => setTimeout(resolve, backoffMs));
        return this.#sendWithRetry(payload, attempt + 1);
      }

      return response;
    } catch (error) {
      if (attempt < this._maxRetries) {
        const backoffMs = Math.min(100 * Math.pow(2, attempt), 1000);
        await new Promise((resolve) => setTimeout(resolve, backoffMs));
        return this.#sendWithRetry(payload, attempt + 1);
      }
      throw error;
    }
  }

  #failedResponse(code, reason, details = null) {
    return Object.freeze({
      ok: false,
      accepted: false,
      attempted: true,
      delivered: false,
      status: code,
      providerId: this.providerId,
      providerMessageId: '',
      reason,
      details: details ? Object.freeze(details) : undefined,
    });
  }

  #escapeHtml(text) {
    if (!text) return '';
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }
}

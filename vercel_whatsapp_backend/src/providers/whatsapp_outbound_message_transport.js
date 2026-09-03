/**
 * WhatsApp Outbound Message Transport Handler
 * 
 * Handles outbound message delivery via configured WhatsApp provider.
 * Implements provider-neutral interface for multi-provider support.
 * 
 * Supported providers:
 * - Meta WhatsApp Business Platform (CloudAPI)
 * - Twilio
 * - Others (pluggable)
 */

const WHATSAPP_PROVIDERS = Object.freeze({
  META: 'meta',
  TWILIO: 'twilio',
});

function normalizePhoneNumber(phone) {
  if (!phone) return null;
  // Remove all non-digits and ensure at least 10 digits
  const digits = String(phone).replace(/\D/g, '');
  return digits.length >= 10 ? digits : null;
}

function nonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

/**
 * Provider-neutral WhatsApp outbound transport
 */
export class WhatsAppOutboundMessageTransport {
  constructor({
    providerId,
    providerApiKey,
    senderPhoneNumber,
    maxRetries = 3,
    requestTimeoutMs = 10000,
  } = {}) {
    if (!Object.values(WHATSAPP_PROVIDERS).includes(providerId)) {
      throw new Error(`Unsupported WhatsApp provider: ${providerId}`);
    }

    if (!nonEmptyString(providerApiKey)) {
      throw new Error('WhatsApp provider API key is required.');
    }

    const normalizedPhone = normalizePhoneNumber(senderPhoneNumber);
    if (!normalizedPhone) {
      throw new Error('Valid sender phone number is required.');
    }

    this._providerId = providerId;
    this._providerApiKey = providerApiKey.trim();
    this._senderPhone = normalizedPhone;
    this._maxRetries = Math.max(0, Math.min(5, maxRetries));
    this._requestTimeoutMs = Math.max(1000, requestTimeoutMs);
  }

  get providerId() {
    return this._providerId;
  }

  get ready() {
    return true;
  }

  get liveNetworkAllowed() {
    return true;
  }

  /**
   * Send WhatsApp message to recipient
   * 
   * @param {Object} message - Message object
   * @param {string} message.recipientPhone - Recipient phone number
   * @param {string} message.messageBody - Message text content
   * @param {Object} [message.metadata] - Optional metadata for tracking
   * @returns {Promise<Object>} Send result
   */
  async send(message) {
    try {
      if (!message || typeof message !== 'object') {
        return this.#failedResponse(
          'MESSAGE_INVALID',
          'Message object is required.'
        );
      }

      const recipientPhone = normalizePhoneNumber(message.recipientPhone);
      if (!recipientPhone) {
        return this.#failedResponse(
          'RECIPIENT_PHONE_INVALID',
          'Valid recipient phone number is required.'
        );
      }

      if (!nonEmptyString(message.messageBody)) {
        return this.#failedResponse(
          'MESSAGE_BODY_EMPTY',
          'Message body is required.'
        );
      }

      if (message.messageBody.length > 4096) {
        return this.#failedResponse(
          'MESSAGE_BODY_TOO_LONG',
          'Message body exceeds 4096 characters.'
        );
      }

      // Route to appropriate provider
      let deliveryResult;
      if (this._providerId === WHATSAPP_PROVIDERS.META) {
        deliveryResult = await this.#sendViaMeta(
          recipientPhone,
          message.messageBody
        );
      } else if (this._providerId === WHATSAPP_PROVIDERS.TWILIO) {
        deliveryResult = await this.#sendViaTwilio(
          recipientPhone,
          message.messageBody
        );
      } else {
        return this.#failedResponse(
          'PROVIDER_NOT_IMPLEMENTED',
          `Provider ${this._providerId} delivery not implemented.`
        );
      }

      return deliveryResult;
    } catch (error) {
      return this.#failedResponse(
        'DELIVERY_EXCEPTION',
        `Unexpected error: ${error?.message || 'unknown'}`
      );
    }
  }

  async #sendViaMeta(recipientPhone, messageBody, attempt = 0) {
    // Meta WhatsApp Cloud API
    const metaApiUrl = `https://graph.instagram.com/v18.0/...`;

    const payload = {
      messaging_product: 'whatsapp',
      to: recipientPhone,
      type: 'text',
      text: { body: messageBody },
    };

    try {
      const response = await this.#requestWithRetry(
        metaApiUrl,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${this._providerApiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(payload),
        },
        attempt
      );

      if (!response.ok) {
        const body = await response.json().catch(() => ({}));
        return this.#failedResponse(
          'META_API_REJECTED',
          `Meta API rejected: ${response.statusText}`
        );
      }

      const body = await response.json();

      if (!body.messages?.[0]?.id) {
        return this.#failedResponse(
          'META_RESPONSE_INVALID',
          'Meta did not return message ID.'
        );
      }

      return Object.freeze({
        ok: true,
        accepted: true,
        attempted: true,
        delivered: true,
        status: 'ACCEPTED',
        providerId: this.providerId,
        providerMessageId: body.messages[0].id,
        sentAtMs: Date.now(),
      });
    } catch (error) {
      if (attempt < this._maxRetries) {
        const backoffMs = Math.min(100 * Math.pow(2, attempt), 1000);
        await new Promise((resolve) => setTimeout(resolve, backoffMs));
        return this.#sendViaMeta(recipientPhone, messageBody, attempt + 1);
      }
      throw error;
    }
  }

  async #sendViaTwilio(recipientPhone, messageBody, attempt = 0) {
    // Twilio SendGrid WhatsApp API
    const twilioApiUrl = `https://api.twilio.com/2010-04-01/Accounts/.../Messages`;

    const formData = new URLSearchParams();
    formData.append('From', `whatsapp:+${this._senderPhone}`);
    formData.append('To', `whatsapp:+${recipientPhone}`);
    formData.append('Body', messageBody);

    try {
      const response = await this.#requestWithRetry(
        twilioApiUrl,
        {
          method: 'POST',
          headers: {
            'Authorization': `Basic ${Buffer.from(
              `${process.env.TWILIO_ACCOUNT_SID}:${this._providerApiKey}`
            ).toString('base64')}`,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: formData.toString(),
        },
        attempt
      );

      if (!response.ok) {
        return this.#failedResponse(
          'TWILIO_API_REJECTED',
          `Twilio API rejected: ${response.statusText}`
        );
      }

      const body = await response.json();

      if (!body.sid) {
        return this.#failedResponse(
          'TWILIO_RESPONSE_INVALID',
          'Twilio did not return message SID.'
        );
      }

      return Object.freeze({
        ok: true,
        accepted: true,
        attempted: true,
        delivered: true,
        status: 'ACCEPTED',
        providerId: this.providerId,
        providerMessageId: body.sid,
        sentAtMs: Date.now(),
      });
    } catch (error) {
      if (attempt < this._maxRetries) {
        const backoffMs = Math.min(100 * Math.pow(2, attempt), 1000);
        await new Promise((resolve) => setTimeout(resolve, backoffMs));
        return this.#sendViaTwilio(recipientPhone, messageBody, attempt + 1);
      }
      throw error;
    }
  }

  async #requestWithRetry(url, options, attempt) {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(
        () => controller.abort(),
        this._requestTimeoutMs
      );

      const response = await fetch(url, {
        ...options,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (
        (response.status >= 500 || response.status === 429) &&
        attempt < this._maxRetries
      ) {
        const backoffMs = Math.min(100 * Math.pow(2, attempt), 1000);
        await new Promise((resolve) => setTimeout(resolve, backoffMs));
        return this.#requestWithRetry(url, options, attempt + 1);
      }

      return response;
    } catch (error) {
      if (attempt < this._maxRetries) {
        const backoffMs = Math.min(100 * Math.pow(2, attempt), 1000);
        await new Promise((resolve) => setTimeout(resolve, backoffMs));
        return this.#requestWithRetry(url, options, attempt + 1);
      }
      throw error;
    }
  }

  #failedResponse(code, reason) {
    return Object.freeze({
      ok: false,
      accepted: false,
      attempted: true,
      delivered: false,
      status: code,
      providerId: this.providerId,
      providerMessageId: '',
      reason,
      sentAtMs: Date.now(),
    });
  }
}

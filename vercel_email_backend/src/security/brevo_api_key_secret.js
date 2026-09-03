export class BrevoApiKeySecret {
  #value;

  constructor(value) {
    if (typeof value !== 'string' ||
        value.trim().length < 8) {
      throw new Error(
          'Brevo API key secret is missing or invalid.');
    }

    this.#value =
        value.trim();
  }

  get present() {
    return true;
  }

  revealForRequestOnly() {
    return this.#value;
  }

  toString() {
    return '[REDACTED_BREVO_API_KEY]';
  }

  toJSON() {
    return '[REDACTED_BREVO_API_KEY]';
  }

  inspect() {
    return '[REDACTED_BREVO_API_KEY]';
  }
}
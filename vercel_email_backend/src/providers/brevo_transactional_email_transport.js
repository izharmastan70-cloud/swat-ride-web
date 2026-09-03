export class DisabledBrevoTransactionalEmailTransport {
  get providerId() {
    return 'brevo';
  }

  get ready() {
    return false;
  }

  get liveNetworkAllowed() {
    return false;
  }

  get providerSecretReadAllowed() {
    return false;
  }

  async deliver(_handoff) {
    return Object.freeze({
      ok: false,
      attempted: false,
      accepted: false,
      delivered: false,
      status: 'DISABLED',
      providerId: this.providerId,
      reason: 'Brevo network execution is disabled in Phase 44-F3D-C.',
    });
  }
}
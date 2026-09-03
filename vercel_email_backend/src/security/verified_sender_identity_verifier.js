export class DisabledVerifiedSenderIdentityVerifier {
  get ready() {
    return false;
  }

  async verifySenderIdentity(_request) {
    return Object.freeze({
      ok: false,
      verified: false,
      enabled: false,
      reason:
          'Trusted sender identity verifier is not wired in Phase 44-F3D-C.',
    });
  }
}
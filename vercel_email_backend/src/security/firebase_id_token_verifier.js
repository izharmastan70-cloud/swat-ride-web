export class DisabledFirebaseIdTokenVerifier {
  get ready() {
    return false;
  }

  async verifyIdToken(_idToken) {
    return Object.freeze({
      ok: false,
      uid: '',
      reason: 'Firebase Admin ID-token verifier is not wired in Phase 44-F3D-C.',
    });
  }
}
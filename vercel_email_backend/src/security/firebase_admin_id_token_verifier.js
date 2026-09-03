export class FirebaseAdminIdTokenVerifier {
  constructor({
    auth,
    checkRevoked = true,
  }) {
    this.auth = auth;
    this.checkRevoked = checkRevoked === true;
  }

  get ready() {
    return typeof this.auth?.verifyIdToken === 'function';
  }

  async verifyIdToken(idToken) {
    const normalizedToken =
        typeof idToken === 'string' ? idToken.trim() : '';

    if (!this.ready || !normalizedToken) {
      return Object.freeze({
        ok: false,
        uid: '',
        claims: Object.freeze({}),
        reason: 'FIREBASE_ID_TOKEN_VERIFIER_NOT_READY_OR_TOKEN_EMPTY',
      });
    }

    try {
      const decoded =
          await this.auth.verifyIdToken(
              normalizedToken,
              this.checkRevoked);

      const uid =
          typeof decoded?.uid === 'string'
              ? decoded.uid.trim()
              : '';

      if (!uid) {
        return Object.freeze({
          ok: false,
          uid: '',
          claims: Object.freeze({}),
          reason: 'FIREBASE_ID_TOKEN_UID_MISSING',
        });
      }

      const role =
          typeof decoded?.role === 'string'
              ? decoded.role.trim().toLowerCase()
              : '';

      return Object.freeze({
        ok: true,
        uid,
        claims: Object.freeze({
          role,
          superAdmin: decoded?.superAdmin === true,
        }),
        reason: 'FIREBASE_ID_TOKEN_VERIFIED',
      });
    } catch (_) {
      return Object.freeze({
        ok: false,
        uid: '',
        claims: Object.freeze({}),
        reason: 'FIREBASE_ID_TOKEN_REJECTED',
      });
    }
  }
}
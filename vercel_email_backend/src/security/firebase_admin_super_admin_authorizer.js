export class FirebaseAdminSuperAdminAuthorizer {
  constructor({
    firestore,
  }) {
    this.firestore = firestore;
  }

  get ready() {
    return typeof this.firestore?.collection === 'function';
  }

  async authorize(identity) {
    const uid =
        typeof identity?.uid === 'string'
            ? identity.uid.trim()
            : '';

    if (!uid) {
      return Object.freeze({
        ok: false,
        authorized: false,
        uid: '',
        source: 'NONE',
        reason: 'SUPER_ADMIN_UID_MISSING',
      });
    }

    const claimRole =
        typeof identity?.claims?.role === 'string'
            ? identity.claims.role.trim().toLowerCase()
            : '';

    const superAdminClaim =
        identity?.claims?.superAdmin === true;

    if (claimRole === 'super_admin' || superAdminClaim) {
      return Object.freeze({
        ok: true,
        authorized: true,
        uid,
        source: 'CUSTOM_CLAIM',
        reason: 'SUPER_ADMIN_CUSTOM_CLAIM_ACCEPTED',
      });
    }

    if (!this.ready) {
      return Object.freeze({
        ok: false,
        authorized: false,
        uid,
        source: 'NONE',
        reason: 'SUPER_ADMIN_FIRESTORE_FALLBACK_NOT_READY',
      });
    }

    try {
      const snapshot =
          await this.firestore
              .collection('admins')
              .doc(uid)
              .get();

      if (!snapshot?.exists) {
        return Object.freeze({
          ok: false,
          authorized: false,
          uid,
          source: 'NONE',
          reason: 'SUPER_ADMIN_RECORD_NOT_FOUND',
        });
      }

      const data = snapshot.data() ?? {};

      const role =
          typeof data.role === 'string'
              ? data.role.trim().toLowerCase()
              : '';

      const authorized =
          data.isActive === true &&
          role === 'super_admin';

      return Object.freeze({
        ok: authorized,
        authorized,
        uid,
        source: authorized
            ? 'FIRESTORE_ADMIN_RECORD'
            : 'NONE',
        reason: authorized
            ? 'SUPER_ADMIN_FIRESTORE_RECORD_ACCEPTED'
            : 'SUPER_ADMIN_FIRESTORE_RECORD_REJECTED',
      });
    } catch (_) {
      return Object.freeze({
        ok: false,
        authorized: false,
        uid,
        source: 'NONE',
        reason: 'SUPER_ADMIN_FIRESTORE_LOOKUP_FAILED',
      });
    }
  }
}
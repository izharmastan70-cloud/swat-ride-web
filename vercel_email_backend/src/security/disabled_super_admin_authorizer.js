export class DisabledSuperAdminAuthorizer {
  get ready() {
    return false;
  }

  async authorize(identity) {
    return Object.freeze({
      ok: false,
      authorized: false,
      uid:
          typeof identity?.uid === 'string'
              ? identity.uid.trim()
              : '',
      source: 'DISABLED',
      reason:
          'Super Admin trusted server authorization is disabled in Phase 44-F3D-D-B3 route.',
    });
  }
}
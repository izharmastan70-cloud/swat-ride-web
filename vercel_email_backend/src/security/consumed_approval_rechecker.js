export class DisabledConsumedApprovalRechecker {
  get ready() {
    return false;
  }

  async recheckConsumedApproval(_request) {
    return Object.freeze({
      ok: false,
      consumed: false,
      reason:
          'Trusted consumed-approval datastore recheck is not wired in Phase 44-F3D-C.',
    });
  }
}
export class DisabledEmailReplayGuard {
  get ready() {
    return false;
  }

  async claim(_request) {
    return Object.freeze({
      ok: false,
      claimed: false,
      reason: 'Trusted anti-replay store is not wired in Phase 44-F3D-C.',
    });
  }
}
export class DisabledEmailMasterToggleRechecker {
  get ready() {
    return false;
  }

  async recheckEmailAgentEnabled() {
    return Object.freeze({
      ok: false,
      enabled: false,
      reason:
          'Email Agent master-toggle trusted server recheck is disabled on the live Phase 44 route.',
    });
  }
}
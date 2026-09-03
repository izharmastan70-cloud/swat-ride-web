export const AGENT_MASTER_SETTINGS_COLLECTION =
    'agent_settings';

export const AGENT_MASTER_SETTINGS_DOCUMENT =
    'master';

export class FirebaseAdminEmailMasterToggleRechecker {
  constructor({
    firestore,
  }) {
    this.firestore = firestore;
  }

  get ready() {
    return typeof this.firestore?.collection === 'function';
  }

  async recheckEmailAgentEnabled() {
    if (!this.ready) {
      return Object.freeze({
        ok: false,
        enabled: false,
        reason: 'EMAIL_MASTER_TOGGLE_RECHECK_NOT_READY',
      });
    }

    try {
      const snapshot =
          await this.firestore
              .collection(AGENT_MASTER_SETTINGS_COLLECTION)
              .doc(AGENT_MASTER_SETTINGS_DOCUMENT)
              .get();

      if (!snapshot?.exists) {
        return Object.freeze({
          ok: false,
          enabled: false,
          reason: 'EMAIL_MASTER_SETTINGS_NOT_FOUND',
        });
      }

      const data =
          snapshot.data() ?? {};

      if (data.emailAgentEnabled !== true) {
        return Object.freeze({
          ok: false,
          enabled: false,
          reason: 'EMAIL_AGENT_MASTER_SWITCH_OFF',
        });
      }

      return Object.freeze({
        ok: true,
        enabled: true,
        reason: 'EMAIL_AGENT_MASTER_SWITCH_ON',
      });
    } catch (_) {
      return Object.freeze({
        ok: false,
        enabled: false,
        reason: 'EMAIL_MASTER_TOGGLE_RECHECK_FAILED',
      });
    }
  }
}
import assert from 'node:assert/strict';
import test from 'node:test';

import {
  createDisabledTrustedEmailRuntime,
} from '../src/runtime/email_trusted_runtime_composer.js';

import {
  DisabledBrevoTransactionalEmailTransport,
} from '../src/providers/brevo_transactional_email_transport.js';

import {
  DisabledEmailMasterToggleRechecker,
} from '../src/security/disabled_email_master_toggle_rechecker.js';

test('trusted runtime composer includes server Email master-toggle rechecker', () => {
  const fakeFirestore = {
    collection() {
      return {};
    },
    async runTransaction() {
      return {};
    },
  };

  const runtime =
      createDisabledTrustedEmailRuntime({
        app: {
          syntheticApp: true,
        },
        serverConfig: {
          liveSendEnabled: false,
        },
        serviceHandleFactory() {
          return {
            auth: {
              async verifyIdToken() {
                return {
                  uid: 'synthetic_uid',
                };
              },
            },
            firestore: fakeFirestore,
          };
        },
        providerTransport:
            new DisabledBrevoTransactionalEmailTransport(),
        serverTimestamp: () => ({
          syntheticServerTimestamp: true,
        }),
      });

  assert.equal(runtime.masterToggleRechecker.ready, true);
  assert.equal(runtime.liveSendEnabled, false);
  assert.equal(runtime.providerNetworkAllowed, false);
  assert.equal(runtime.routeWiringAllowed, false);
});

test('disabled master-toggle adapter never authorizes Email Agent', async () => {
  const rechecker =
      new DisabledEmailMasterToggleRechecker();

  assert.equal(rechecker.ready, false);

  const result =
      await rechecker.recheckEmailAgentEnabled();

  assert.equal(result.ok, false);
  assert.equal(result.enabled, false);
});

test('B4-B2 source integration itself grants no provider or route execution authority', () => {
  const provider =
      new DisabledBrevoTransactionalEmailTransport();

  assert.equal(provider.ready, false);
  assert.equal(provider.liveNetworkAllowed, false);
});
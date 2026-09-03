import assert from 'node:assert/strict';
import test from 'node:test';

import {
  readEmailSensitiveEnvironment,
} from '../src/config/email_sensitive_environment_contract.js';

import {
  createFirebaseAdminAppInitializer,
} from '../src/firebase/firebase_admin_app_initializer.js';

import {
  createDisabledTrustedEmailRuntime,
} from '../src/runtime/email_trusted_runtime_composer.js';

import {
  DisabledBrevoTransactionalEmailTransport,
} from '../src/providers/brevo_transactional_email_transport.js';

test('sensitive environment exposes only redacted safe metadata', () => {
  const serviceAccountJson = JSON.stringify({
    project_id: 'swat-ride-v2',
    client_email:
        'synthetic@swat-ride-v2.iam.gserviceaccount.com',
    private_key:
        '-----BEGIN PRIVATE KEY-----\\nSYNTHETIC_ONLY\\n-----END PRIVATE KEY-----\\n',
  });

  const result = readEmailSensitiveEnvironment({
    FIREBASE_SERVICE_ACCOUNT_JSON:
        serviceAccountJson,
    SWAT_RIDE_FIREBASE_PROJECT_ID:
        'swat-ride-v2',
    BREVO_API_KEY:
        'synthetic-provider-secret',
    EMAIL_LIVE_SEND_ENABLED:
        'true',
  });

  assert.equal(result.ok, true);
  assert.equal(
      result.safeMetadata.firebaseAdminCredentialPresent,
      true);
  assert.equal(
      result.safeMetadata.providerApiKeyPresent,
      true);
  assert.equal(
      result.safeMetadata.liveSendRequested,
      true);
  assert.equal(
      result.safeMetadata.secretValuesIncluded,
      false);

  const safeJson =
      JSON.stringify(result.safeMetadata);

  assert.equal(
      safeJson.includes('SYNTHETIC_ONLY'),
      false);
  assert.equal(
      safeJson.includes('synthetic-provider-secret'),
      false);
});

test('provider secret may remain absent during Firebase Admin-only composition phase', () => {
  const result = readEmailSensitiveEnvironment(
      {
        FIREBASE_SERVICE_ACCOUNT_JSON:
            '{"synthetic":true}',
        SWAT_RIDE_FIREBASE_PROJECT_ID:
            'swat-ride-v2',
        BREVO_API_KEY: '',
        EMAIL_LIVE_SEND_ENABLED: 'false',
      },
      {
        requireFirebaseAdmin: true,
        requireProviderSecret: false,
      });

  assert.equal(result.ok, true);
  assert.equal(
      result.safeMetadata.providerApiKeyPresent,
      false);
});

test('Firebase Admin initializer validates project and is testable without real credentials', () => {
  const calls = {
    getApp: 0,
    cert: 0,
    initializeApp: 0,
  };

  const initializer =
      createFirebaseAdminAppInitializer({
        getAppFn() {
          calls.getApp += 1;
          throw new Error('not initialized');
        },
        certFn(serviceAccount) {
          calls.cert += 1;

          assert.equal(
              serviceAccount.projectId,
              'swat-ride-v2');
          assert.equal(
              serviceAccount.clientEmail,
              'synthetic@example.com');

          return {
            syntheticCredential: true,
          };
        },
        initializeAppFn(options, appName) {
          calls.initializeApp += 1;

          assert.equal(
              options.projectId,
              'swat-ride-v2');
          assert.equal(
              appName,
              'swat-ride-email-server');

          return {
            syntheticApp: true,
          };
        },
      });

  const result = initializer({
    serviceAccountJson: JSON.stringify({
      project_id: 'swat-ride-v2',
      client_email: 'synthetic@example.com',
      private_key:
          '-----BEGIN PRIVATE KEY-----\\nSYNTHETIC\\n-----END PRIVATE KEY-----\\n',
    }),
    expectedProjectId: 'swat-ride-v2',
  });

  assert.equal(result.initializedNow, true);
  assert.equal(result.projectId, 'swat-ride-v2');
  assert.deepEqual(calls, {
    getApp: 1,
    cert: 1,
    initializeApp: 1,
  });
});

test('Firebase Admin initializer fails closed on project mismatch', () => {
  const initializer =
      createFirebaseAdminAppInitializer({
        getAppFn() {
          throw new Error('not initialized');
        },
        certFn() {
          throw new Error(
              'cert must not run on mismatch');
        },
        initializeAppFn() {
          throw new Error(
              'initializeApp must not run on mismatch');
        },
      });

  assert.throws(
      () => initializer({
        serviceAccountJson: JSON.stringify({
          project_id: 'different-project',
          client_email: 'synthetic@example.com',
          private_key:
              '-----BEGIN PRIVATE KEY-----\\nSYNTHETIC\\n-----END PRIVATE KEY-----\\n',
        }),
        expectedProjectId: 'swat-ride-v2',
      }),
      /does not match configured project/);
});

test('Firebase Admin initializer reuses named existing app without parsing secret again', () => {
  const existingApp = {
    existing: true,
  };

  const initializer =
      createFirebaseAdminAppInitializer({
        getAppFn(appName) {
          assert.equal(
              appName,
              'swat-ride-email-server');

          return existingApp;
        },
        certFn() {
          throw new Error(
              'cert must not run for existing app');
        },
        initializeAppFn() {
          throw new Error(
              'initializeApp must not run for existing app');
        },
      });

  const result = initializer({
    serviceAccountJson: '',
    expectedProjectId: 'swat-ride-v2',
  });

  assert.equal(result.initializedNow, false);
  assert.equal(result.app, existingApp);
});

test('trusted runtime composer builds adapters only with disabled provider and liveSend=false', () => {
  const fakeFirestore = {
    collection() {
      return {};
    },
    async runTransaction() {
      return {};
    },
  };

  const fakeAuth = {
    async verifyIdToken() {
      return {
        uid: 'synthetic',
      };
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
            auth: fakeAuth,
            firestore: fakeFirestore,
          };
        },
        providerTransport:
            new DisabledBrevoTransactionalEmailTransport(),
        serverTimestamp: () => ({
          syntheticServerTimestamp: true,
        }),
      });

  assert.equal(runtime.liveSendEnabled, false);
  assert.equal(runtime.providerNetworkAllowed, false);
  assert.equal(runtime.routeWiringAllowed, false);
  assert.equal(runtime.authVerifier.ready, true);
  assert.equal(runtime.superAdminAuthorizer.ready, true);
  assert.equal(runtime.approvalRechecker.ready, true);
  assert.equal(runtime.senderVerifier.ready, true);
  assert.equal(runtime.replayGuard.ready, true);
  assert.equal(runtime.providerTransport.ready, false);
});

test('trusted runtime composer rejects any live-enabled config in B3', () => {
  assert.throws(
      () => createDisabledTrustedEmailRuntime({
        app: {
          syntheticApp: true,
        },
        serverConfig: {
          liveSendEnabled: true,
        },
        serviceHandleFactory() {
          return {
            auth: {},
            firestore: {},
          };
        },
        providerTransport:
            new DisabledBrevoTransactionalEmailTransport(),
      }),
      /only accepts liveSendEnabled=false/);
});
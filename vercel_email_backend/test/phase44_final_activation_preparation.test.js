import assert from 'node:assert/strict';
import test from 'node:test';

import {
  createTrustedBrevoVerificationActivation,
} from '../src/runtime/trusted_brevo_verification_activation_factory.js';

import {
  PHASE44_EMAIL_PRODUCTION_ACTIVATION,
} from '../src/config/phase44_email_production_activation_contract.js';

class FakeSnapshot {
  constructor(data) {
    this._data =
        data;

    this.exists =
        data !== undefined;
  }

  data() {
    return this._data;
  }
}

class FakeDoc {
  constructor(data) {
    this.dataValue =
        data;
  }

  async get() {
    return new FakeSnapshot(
        this.dataValue);
  }
}

class FakeCollection {
  constructor(documents = {}) {
    this.documents =
        documents;
  }

  doc(id) {
    return new FakeDoc(
        this.documents[id]);
  }
}

class FakeFirestore {
  constructor(collections = {}) {
    this.collections =
        collections;
  }

  collection(name) {
    return new FakeCollection(
        this.collections[name] ?? {});
  }
}

test('Phase 44 production contract marks implementation complete but live send OFF', () => {
  assert.equal(
      PHASE44_EMAIL_PRODUCTION_ACTIVATION
          .implementationComplete,
      true);

  assert.equal(
      PHASE44_EMAIL_PRODUCTION_ACTIVATION
          .liveSendDefault,
      false);

  assert.equal(
      PHASE44_EMAIL_PRODUCTION_ACTIVATION
          .providerReadDefault,
      false);

  assert.equal(
      PHASE44_EMAIL_PRODUCTION_ACTIVATION
          .providerWriteDefault,
      false);

  assert.equal(
      PHASE44_EMAIL_PRODUCTION_ACTIVATION
          .draftBindingAlgorithm,
      'CANONICAL_JSON_SHA256_BASE64URL_V2');

  assert.equal(
      PHASE44_EMAIL_PRODUCTION_ACTIVATION
          .realProviderVerificationPerformedNow,
      false);

  assert.equal(
      PHASE44_EMAIL_PRODUCTION_ACTIVATION
          .realEmailSendPerformedNow,
      false);

  assert.equal(
      PHASE44_EMAIL_PRODUCTION_ACTIVATION
          .firestoreRulesDeployedNow,
      false);

  assert.equal(
      PHASE44_EMAIL_PRODUCTION_ACTIVATION
          .vercelDeployedNow,
      false);
});

test('trusted activation factory adapts real Firebase Admin contracts and remains provider-read disabled by default', async () => {
  const fakeAuth = {
    async verifyIdToken(
      token,
      checkRevoked,
    ) {
      assert.equal(
          token,
          'synthetic-token');

      assert.equal(
          checkRevoked,
          true);

      return {
        uid:
            'owner-uid',
        role:
            'super_admin',
      };
    },
  };

  const fakeFirestore =
      new FakeFirestore({
        admins: {
          'owner-uid': {
            isActive:
                true,
            role:
                'super_admin',
          },
        },
      });

  const activation =
      createTrustedBrevoVerificationActivation({
        app: {
          synthetic:
              true,
        },
        environment:
            {},
        fetchImpl:
            async () => {
              throw new Error(
                  'Provider must remain disabled.');
            },
        expectedSender: {
          senderIdentityId:
              'primary_official_sender',
          fromAddress:
              'swatrideofficial@gmail.com',
          displayName:
              'SWAT RIDE',
        },
        serviceHandleFactory() {
          return {
            auth:
                fakeAuth,
            firestore:
                fakeFirestore,
          };
        },
      });

  const identity =
      await activation
          .idTokenVerifier
          .verify(
              'synthetic-token');

  assert.equal(
      identity.uid,
      'owner-uid');

  assert.equal(
      await activation
          .superAdminAuthorizer
          .authorize(
              identity),
      true);

  const verification =
      await activation
          .verificationRuntime
          .runVerificationOnly();

  assert.equal(
      verification.ok,
      false);

  assert.equal(
      verification.code,
      'BREVO_VERIFICATION_ONLY_SERVER_DISABLED');

  assert.equal(
      activation.readOnlyProviderVerificationEnabled,
      false);

  assert.equal(
      activation.providerReadAllowed,
      false);

  assert.equal(
      activation.providerWriteAllowed,
      false);

  assert.equal(
      activation.firestoreWriteAllowed,
      false);

  assert.equal(
      activation.emailSendAllowed,
      false);

  assert.equal(
      activation.liveSendAllowed,
      false);
});

test('non-Super-Admin identity remains rejected by adapted trusted authorizer', async () => {
  const activation =
      createTrustedBrevoVerificationActivation({
        app: {
          synthetic:
              true,
        },
        environment:
            {},
        fetchImpl:
            async () => {
              throw new Error(
                  'Provider must remain disabled.');
            },
        expectedSender: {
          senderIdentityId:
              'primary_official_sender',
          fromAddress:
              'swatrideofficial@gmail.com',
          displayName:
              'SWAT RIDE',
        },
        serviceHandleFactory() {
          return {
            auth: {
              async verifyIdToken() {
                return {
                  uid:
                      'normal-user',
                  role:
                      'customer',
                };
              },
            },
            firestore:
                new FakeFirestore({
                  admins: {},
                }),
          };
        },
      });

  const identity =
      await activation
          .idTokenVerifier
          .verify(
              'synthetic-token');

  assert.equal(
      await activation
          .superAdminAuthorizer
          .authorize(
              identity),
      false);
});

test('read-only provider activation can be synthetic-only and still grants zero send/write authority', async () => {
  let fetchCalls = 0;

  const activation =
      createTrustedBrevoVerificationActivation({
        app: {
          synthetic:
              true,
        },
        environment: {
          BREVO_API_KEY:
              'synthetic_brevo_key_phase44_final',
        },
        fetchImpl:
            async () => {
              fetchCalls += 1;

              return {
                status:
                    200,

                async text() {
                  return JSON.stringify({
                    senders: [
                      {
                        id:
                            101,
                        name:
                            'SWAT RIDE',
                        email:
                            'swatrideofficial@gmail.com',
                        active:
                            true,
                      },
                    ],
                  });
                },
              };
            },
        expectedSender: {
          senderIdentityId:
              'primary_official_sender',
          fromAddress:
              'swatrideofficial@gmail.com',
          displayName:
              'SWAT RIDE',
        },
        readOnlyProviderVerificationEnabled:
            true,
        serviceHandleFactory() {
          return {
            auth: {
              async verifyIdToken() {
                return {
                  uid:
                      'owner-uid',
                  role:
                      'super_admin',
                };
              },
            },
            firestore:
                new FakeFirestore({
                  admins: {
                    'owner-uid': {
                      isActive:
                          true,
                      role:
                          'super_admin',
                    },
                  },
                }),
          };
        },
      });

  const result =
      await activation
          .verificationRuntime
          .runVerificationOnly();

  assert.equal(
      fetchCalls,
      1);

  assert.equal(
      result.ok,
      true);

  assert.equal(
      result.trustedEvidenceEligible,
      true);

  assert.equal(
      activation.providerWriteAllowed,
      false);

  assert.equal(
      activation.firestoreWriteAllowed,
      false);

  assert.equal(
      activation.emailSendAllowed,
      false);

  assert.equal(
      activation.liveSendAllowed,
      false);

  assert.equal(
      JSON.stringify(result)
          .includes(
              'synthetic_brevo_key_phase44_final'),
      false);
});
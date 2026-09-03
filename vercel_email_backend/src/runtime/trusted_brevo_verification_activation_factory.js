import {
  createFirebaseAdminServiceHandles,
} from '../firebase/firebase_admin_service_factory.js';

import {
  FirebaseAdminIdTokenVerifier,
} from '../security/firebase_admin_id_token_verifier.js';

import {
  FirebaseAdminSuperAdminAuthorizer,
} from '../security/firebase_admin_super_admin_authorizer.js';

import {
  BrevoVerificationOnlyServerHarness,
} from './brevo_verification_only_server_harness.js';

function disabledVerificationRuntime() {
  return Object.freeze({
    providerReadAllowed:
        false,
    providerWriteAllowed:
        false,
    firestoreWriteAllowed:
        false,
    emailSendAllowed:
        false,
    liveSendAllowed:
        false,

    async runVerificationOnly() {
      return Object.freeze({
        ok:
            false,
        verificationAttempted:
            false,
        trustedEvidenceEligible:
            false,
        evidence:
            null,
        providerReadPerformed:
            false,
        providerWriteAllowed:
            false,
        firestoreWriteAllowed:
            false,
        emailSendAllowed:
            false,
        liveSendAllowed:
            false,
        code:
            'BREVO_VERIFICATION_ONLY_SERVER_DISABLED',
      });
    },
  });
}

export function createTrustedBrevoVerificationActivation({
  app,
  environment,
  fetchImpl,
  expectedSender,
  readOnlyProviderVerificationEnabled = false,
  serviceHandleFactory =
      createFirebaseAdminServiceHandles,
}) {
  if (!app) {
    throw new Error(
        'Trusted Brevo verification activation requires Firebase Admin app.');
  }

  const handles =
      serviceHandleFactory(
          app);

  if (!handles?.auth ||
      !handles?.firestore) {
    throw new Error(
        'Trusted Brevo verification activation requires Auth and Firestore handles.');
  }

  const firebaseIdTokenVerifier =
      new FirebaseAdminIdTokenVerifier({
        auth:
            handles.auth,
      });

  const firebaseSuperAdminAuthorizer =
      new FirebaseAdminSuperAdminAuthorizer({
        firestore:
            handles.firestore,
      });

  // Adapter for the verification-route contract.
  // Existing Firebase Admin verifier returns a structured result from
  // verifyIdToken(); the route contract expects verify() to either return
  // an identity or reject. This wrapper keeps that translation explicit.
  const idTokenVerifier =
      Object.freeze({
        async verify(idToken) {
          const result =
              await firebaseIdTokenVerifier
                  .verifyIdToken(
                      idToken);

          if (result?.ok !== true ||
              typeof result.uid !== 'string' ||
              result.uid.trim().length === 0) {
            throw new Error(
                'Firebase identity rejected.');
          }

          return Object.freeze({
            uid:
                result.uid.trim(),
            claims:
                result.claims ??
                Object.freeze({}),
          });
        },
      });

  // Existing Super Admin authorizer returns structured authorization.
  // The verification route intentionally consumes only a strict boolean.
  const superAdminAuthorizer =
      Object.freeze({
        async authorize(identity) {
          const result =
              await firebaseSuperAdminAuthorizer
                  .authorize(
                      identity);

          return result?.ok === true &&
              result?.authorized === true &&
              result?.uid === identity?.uid;
        },
      });

  const verificationRuntime =
      readOnlyProviderVerificationEnabled === true
          ? new BrevoVerificationOnlyServerHarness({
              environment,
              fetchImpl,
              expectedSender,
              serverActivationEnabled:
                  true,
            })
          : disabledVerificationRuntime();

  return Object.freeze({
    idTokenVerifier,
    superAdminAuthorizer,
    verificationRuntime,

    readOnlyProviderVerificationEnabled:
        readOnlyProviderVerificationEnabled === true,

    providerReadAllowed:
        readOnlyProviderVerificationEnabled === true,

    providerWriteAllowed:
        false,

    firestoreWriteAllowed:
        false,

    emailSendAllowed:
        false,

    liveSendAllowed:
        false,

    routeMayConsumeEmailApproval:
        false,

    routeMayClaimDeliveryIdempotency:
        false,
  });
}
export const disabledBrevoVerificationRouteRuntime =
    Object.freeze({
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

export const disabledIdentityGate =
    Object.freeze({
      async verify() {
        throw new Error(
            'Verification route identity gate is not activated.');
      },
    });

export const disabledSuperAdminGate =
    Object.freeze({
      async authorize() {
        return false;
      },
    });
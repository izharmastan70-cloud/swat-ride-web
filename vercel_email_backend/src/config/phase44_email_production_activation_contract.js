export const PHASE44_EMAIL_PRODUCTION_ACTIVATION =
    Object.freeze({
      implementationComplete:
          true,

      liveSendDefault:
          false,

      providerReadDefault:
          false,

      providerWriteDefault:
          false,

      verifiedSender:
          'SWAT RIDE <swatrideofficial@gmail.com>',

      provider:
          'brevo',

      draftBindingAlgorithm:
          'CANONICAL_JSON_SHA256_BASE64URL_V2',

      // =========================================================
      // OWNER-CONTROLLED PRODUCTION ACTIVATION CHECKLIST
      // =========================================================
      //
      // DO NOT paste BREVO_API_KEY, Firebase service-account JSON,
      // private keys, passwords or OTPs into source code, Flutter,
      // Firestore, chat, screenshots or logs.
      //
      // When production verification is intentionally activated:
      //
      // 1) Create/review the Brevo API key privately in Brevo.
      // 2) Enter BREVO_API_KEY directly into Vercel as a Sensitive
      //    Environment Variable for the intended Preview/Production
      //    environment. Never commit it.
      // 3) Keep EMAIL LIVE SEND disabled.
      // 4) Wire only the verification-only route to the trusted
      //    Firebase Admin identity/Super Admin runtime.
      // 5) Enable only readOnlyProviderVerificationEnabled.
      // 6) Perform exactly one read-only GET /v3/senders verification.
      // 7) Require exactly one active canonical sender:
      //       SWAT RIDE <swatrideofficial@gmail.com>
      // 8) Duplicate/inactive/name-mismatch stays fail-closed.
      // 9) Only server-authenticated provider evidence may qualify
      //    SERVER_PROVIDER_VERIFIED.
      // 10) Trusted sender Firestore registry may be written only by
      //     a separately reviewed server-only operation.
      //
      // IMPORTANT: local Firestore sender/idempotency rule changes
      // must be explicitly reviewed/deployed before production use.
      // Never deploy rules blindly from an activation script.
      //
      // Live email sending is a separate production rollout decision.
      // Sender verification alone MUST NOT enable email send.
      //
      // Future custom-domain migration:
      // Current Gmail sender is provisional. Preferred future sender:
      // support@swatride.pk / official@swatride.pk / noreply@swatride.pk
      // after owned-domain DNS authentication (SPF/DKIM/DMARC as
      // appropriate for the selected provider).
      //
      // The public website swat-ride-web.vercel.app does NOT prove
      // ownership of an email-sending domain.
      productionVerificationRequiresOwnerAction:
          true,

      realProviderVerificationPerformedNow:
          false,

      realEmailSendPerformedNow:
          false,

      firestoreRulesDeployedNow:
          false,

      vercelDeployedNow:
          false,
    });
import {
  EMAIL_SENDER_BOOTSTRAP_DEFAULTS,
  buildEmailSenderBootstrapConfig,
} from './email_sender_identity_bootstrap_config.js';

export const EMAIL_PROVIDER_SENDER_VERIFICATION_MODE =
    'OWNER_MANUAL_BREVO_UI_6_DIGIT_CODE';

export const EMAIL_PROVIDER_SENDER_VERIFICATION_STATUS =
    Object.freeze({
      preparationReady: 'PREPARATION_READY',
      awaitingOwnerBrevoVerification:
          'AWAITING_OWNER_BREVO_VERIFICATION',
      providerVerificationConfirmed:
          'PROVIDER_VERIFICATION_CONFIRMED',
      blocked: 'BLOCKED',
    });

export const EMAIL_PROVIDER_SENDER_VERIFICATION_POLICY =
    Object.freeze({
      // Owner must perform verification directly in the Brevo UI.
      ownerMustVerifyInProviderUi: true,

      // The 6-digit sender verification code is sensitive transient data.
      // Never ask the app/agent to collect it.
      // Never store it in Flutter, Firestore, source, logs, audit metadata,
      // Vercel env vars, or ChatGPT/project notes.
      verificationCodeMayBeCollectedByApp: false,
      verificationCodeMayBeStored: false,
      verificationCodeMayBeLogged: false,

      // This phase prepares the provider verification only.
      providerApiKeyRequiredNow: false,
      providerNetworkAllowedNow: false,
      liveSendAllowedNow: false,
      emailSendAllowedNow: false,

      // A future server step must independently confirm trusted provider
      // verification before writing SERVER_PROVIDER_VERIFIED evidence.
      ownerUiConfirmationAloneMayCreateTrustedVerificationEvidence: false,

      // Current Gmail sender is provisional and changeable later.
      senderIdentityIsPermanent: false,
      customDomainMigrationRequiredForPreferredProductionSetup: true,
    });

export const BREVO_MANUAL_SENDER_UI_STEPS = Object.freeze([
  'Open Brevo account settings.',
  'Open Senders, Domains, IPs.',
  'Open the Senders tab.',
  'Choose Add a sender.',
  'Set From name to SWAT RIDE.',
  'Set From email to swatrideofficial@gmail.com.',
  'Save the sender.',
  'Brevo sends a 6-digit verification code to the sender mailbox when the sender domain is not authenticated.',
  'Owner opens swatrideofficial@gmail.com and reads the code privately.',
  'Owner enters the code directly in Brevo and selects Verify sender.',
  'Do not paste or store the verification code in SWAT RIDE source, logs, Firestore, or AI prompts.',
]);

export const EMAIL_PROVIDER_SENDER_FUTURE_COMMENTS = Object.freeze([
  // FUTURE PRODUCTION MIGRATION:
  // Gmail is only the current provisional sender.
  // When SWAT RIDE owns a domain, switch to an owned sender such as:
  //   support@swatride.pk
  //   official@swatride.pk
  // and authenticate that domain with provider-provided DNS records.
  'Replace provisional Gmail with an owned authenticated custom-domain sender when available.',

  // FUTURE SERVER VERIFICATION:
  // Do not trust a client/owner boolean such as "I verified it".
  // After provider credentials are configured server-side, independently
  // verify sender status with the provider before storing trusted
  // verificationSource = SERVER_PROVIDER_VERIFIED.
  'Server must independently confirm provider verification before trusted sender evidence is written.',

  // FUTURE SECRET HANDLING:
  // BREVO_API_KEY belongs only in Vercel sensitive environment configuration.
  // It must never be stored in Flutter, Firestore, sender records, or source.
  'Keep provider API credentials server-side only.',

  // FUTURE LIVE SEND:
  // Verifying a sender does NOT enable Email Agent live-send.
  // Live send still requires Phase 44/66 production activation controls.
  'Sender verification never enables live-send by itself.',
]);

export function buildBrevoSenderVerificationPreparation(
  environment = {},
) {
  const sender =
      buildEmailSenderBootstrapConfig(environment);

  const matchesCurrentBootstrap =
      sender.providerId ===
          EMAIL_SENDER_BOOTSTRAP_DEFAULTS.providerId &&
      sender.fromAddress.length > 0 &&
      sender.displayName.length > 0;

  if (!matchesCurrentBootstrap) {
    return Object.freeze({
      ok: false,
      status:
          EMAIL_PROVIDER_SENDER_VERIFICATION_STATUS.blocked,
      ownerActionRequired: false,
      verificationMode:
          EMAIL_PROVIDER_SENDER_VERIFICATION_MODE,
      sender: null,
      providerExecutionAllowed: false,
      liveSendAllowed: false,
      code:
          'PROVISIONAL_SENDER_BOOTSTRAP_INVALID',
    });
  }

  return Object.freeze({
    ok: true,
    status:
        EMAIL_PROVIDER_SENDER_VERIFICATION_STATUS
            .awaitingOwnerBrevoVerification,
    ownerActionRequired: true,
    verificationMode:
        EMAIL_PROVIDER_SENDER_VERIFICATION_MODE,
    sender: Object.freeze({
      senderIdentityId:
          sender.senderIdentityId,
      providerId:
          sender.providerId,
      fromAddress:
          sender.fromAddress,
      displayName:
          sender.displayName,
      publicWebsiteUrl:
          sender.publicWebsiteUrl,
      ownsSendingDomain:
          sender.ownsSendingDomain,
    }),
    providerExecutionAllowed: false,
    liveSendAllowed: false,
    mayStoreVerificationCode: false,
    mayCreateTrustedVerificationEvidence: false,
    code:
        'BREVO_OWNER_MANUAL_SENDER_VERIFICATION_REQUIRED',
  });
}
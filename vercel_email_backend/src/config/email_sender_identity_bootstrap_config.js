export const EMAIL_SENDER_IDENTITY_ENV_NAMES = Object.freeze({
  senderAddress: 'EMAIL_SENDER_ADDRESS',
  senderDisplayName: 'EMAIL_SENDER_DISPLAY_NAME',
  publicWebsiteUrl: 'EMAIL_PUBLIC_WEBSITE_URL',
});

export const EMAIL_SENDER_BOOTSTRAP_DEFAULTS = Object.freeze({
  senderIdentityId: 'primary_official_sender',
  providerId: 'brevo',

  // CURRENT TEMPORARY / PROVISIONAL SENDER
  // This Gmail address is intentionally treated as changeable setup data,
  // not as a permanent SWAT RIDE production identity.
  fromAddress: 'swatrideofficial@gmail.com',

  // Display name is also intentionally changeable later without changing
  // the Email Agent security architecture.
  displayName: 'SWAT RIDE',

  // This is the current PUBLIC WEBSITE URL only.
  // IMPORTANT: swat-ride-web.vercel.app is NOT an owned email-sending domain.
  // Do not treat this Vercel hostname as a DKIM/DMARC sender-authentication domain.
  publicWebsiteUrl: 'https://swat-ride-web.vercel.app/',

  // Gmail is a public mailbox domain. It is acceptable as the current
  // provisional sender identity for setup/testing, but it is NOT the
  // preferred long-term production sender identity.
  ownsSendingDomain: false,

  // Do not mark this true until the provider/server-side verification
  // workflow has actually completed.
  providerVerified: false,

  // Do not allow this bootstrap object itself to enable live transport.
  liveSendAllowed: false,
});

export const EMAIL_SENDER_FUTURE_MIGRATION_NOTES = Object.freeze([
  // FUTURE: When SWAT RIDE buys/owns a custom domain, migrate the sender
  // from the temporary Gmail address to an address such as:
  //   support@swatride.pk
  //   official@swatride.pk
  //   noreply@swatride.pk
  // The exact address can be chosen later by Super Admin.
  'Migrate provisional Gmail sender to an owned custom-domain sender when available.',

  // FUTURE: Authenticate the owned domain with the selected provider using
  // the provider-required DNS records such as DKIM/DMARC/SPF-related setup.
  // Exact DNS values must come from the provider at that future time.
  'Authenticate the future owned sending domain before production live-send activation.',

  // FUTURE: Sender display name remains editable, for example:
  //   SWAT RIDE
  //   SWAT RIDE Support
  //   SWAT RIDE Official
  'Keep sender display name changeable by configuration.',

  // FUTURE: Website URL and email-sending domain are separate concepts.
  // The public website may remain on Vercel while email later uses an owned
  // custom domain. Never infer sender-domain ownership from a Vercel URL.
  'Keep public website URL separate from email sender-domain ownership.',

  // FUTURE: Never place provider API keys, passwords, OTPs, Firebase Admin
  // credentials, or other secrets in this sender identity config.
  'Keep all provider/Firebase secrets server-side and outside sender identity records.',
]);

function nonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

export function buildEmailSenderBootstrapConfig(environment = {}) {
  const fromAddress =
      nonEmptyString(
          environment[
              EMAIL_SENDER_IDENTITY_ENV_NAMES.senderAddress])
          ? environment[
              EMAIL_SENDER_IDENTITY_ENV_NAMES.senderAddress].trim()
          : EMAIL_SENDER_BOOTSTRAP_DEFAULTS.fromAddress;

  const displayName =
      nonEmptyString(
          environment[
              EMAIL_SENDER_IDENTITY_ENV_NAMES.senderDisplayName])
          ? environment[
              EMAIL_SENDER_IDENTITY_ENV_NAMES.senderDisplayName].trim()
          : EMAIL_SENDER_BOOTSTRAP_DEFAULTS.displayName;

  const publicWebsiteUrl =
      nonEmptyString(
          environment[
              EMAIL_SENDER_IDENTITY_ENV_NAMES.publicWebsiteUrl])
          ? environment[
              EMAIL_SENDER_IDENTITY_ENV_NAMES.publicWebsiteUrl].trim()
          : EMAIL_SENDER_BOOTSTRAP_DEFAULTS.publicWebsiteUrl;

  return Object.freeze({
    senderIdentityId:
        EMAIL_SENDER_BOOTSTRAP_DEFAULTS.senderIdentityId,
    providerId:
        EMAIL_SENDER_BOOTSTRAP_DEFAULTS.providerId,
    fromAddress,
    displayName,
    publicWebsiteUrl,

    // These safety states are NOT overrideable by this bootstrap config.
    // Verified/enabled state must come from the trusted server-side sender
    // verification workflow / trusted sender registry.
    providerVerified: false,
    liveSendAllowed: false,

    // Gmail is the current provisional identity. A future custom-domain
    // migration must be explicit and must not silently infer ownership.
    ownsSendingDomain: false,

    mutableConfiguration: true,
    hardCodedProductionDependency: false,
  });
}
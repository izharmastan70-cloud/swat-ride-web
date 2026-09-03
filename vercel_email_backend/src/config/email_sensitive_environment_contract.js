export const EMAIL_SENSITIVE_ENV_NAMES = Object.freeze({
  firebaseServiceAccountJson: 'FIREBASE_SERVICE_ACCOUNT_JSON',
  firebaseProjectId: 'SWAT_RIDE_FIREBASE_PROJECT_ID',
  providerApiKey: 'BREVO_API_KEY',
  liveSendEnabled: 'EMAIL_LIVE_SEND_ENABLED',
});

function nonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function parseBoolean(value) {
  return String(value ?? '').trim().toLowerCase() === 'true';
}

export function readEmailSensitiveEnvironment(
  environment,
  {
    requireFirebaseAdmin = true,
    requireProviderSecret = false,
  } = {},
) {
  if (!environment || typeof environment !== 'object') {
    return Object.freeze({
      ok: false,
      code: 'EMAIL_ENVIRONMENT_MISSING',
      secretMaterial: null,
      safeMetadata: Object.freeze({
        firebaseAdminCredentialPresent: false,
        firebaseProjectIdPresent: false,
        providerApiKeyPresent: false,
        liveSendRequested: false,
        secretValuesIncluded: false,
      }),
    });
  }

  const serviceAccountJson =
      String(
          environment[
              EMAIL_SENSITIVE_ENV_NAMES.firebaseServiceAccountJson] ?? '')
          .trim();

  const firebaseProjectId =
      String(
          environment[
              EMAIL_SENSITIVE_ENV_NAMES.firebaseProjectId] ?? '')
          .trim();

  const providerApiKey =
      String(
          environment[
              EMAIL_SENSITIVE_ENV_NAMES.providerApiKey] ?? '')
          .trim();

  const liveSendRequested =
      parseBoolean(
          environment[
              EMAIL_SENSITIVE_ENV_NAMES.liveSendEnabled]);

  const firebaseAdminReady =
      nonEmptyString(serviceAccountJson) &&
      nonEmptyString(firebaseProjectId);

  const providerReady =
      nonEmptyString(providerApiKey);

  if (requireFirebaseAdmin && !firebaseAdminReady) {
    return Object.freeze({
      ok: false,
      code: 'FIREBASE_ADMIN_SENSITIVE_ENV_MISSING',
      secretMaterial: null,
      safeMetadata: Object.freeze({
        firebaseAdminCredentialPresent:
            nonEmptyString(serviceAccountJson),
        firebaseProjectIdPresent:
            nonEmptyString(firebaseProjectId),
        providerApiKeyPresent:
            providerReady,
        liveSendRequested,
        secretValuesIncluded: false,
      }),
    });
  }

  if (requireProviderSecret && !providerReady) {
    return Object.freeze({
      ok: false,
      code: 'EMAIL_PROVIDER_SENSITIVE_ENV_MISSING',
      secretMaterial: null,
      safeMetadata: Object.freeze({
        firebaseAdminCredentialPresent:
            nonEmptyString(serviceAccountJson),
        firebaseProjectIdPresent:
            nonEmptyString(firebaseProjectId),
        providerApiKeyPresent: false,
        liveSendRequested,
        secretValuesIncluded: false,
      }),
    });
  }

  return Object.freeze({
    ok: true,
    code: 'EMAIL_SENSITIVE_ENV_READY',
    secretMaterial: Object.freeze({
      serviceAccountJson,
      firebaseProjectId,
      providerApiKey,
    }),
    safeMetadata: Object.freeze({
      firebaseAdminCredentialPresent:
          nonEmptyString(serviceAccountJson),
      firebaseProjectIdPresent:
          nonEmptyString(firebaseProjectId),
      providerApiKeyPresent:
          providerReady,
      liveSendRequested,
      secretValuesIncluded: false,
    }),
  });
}

export function readEmailSensitiveEnvironmentFromProcess(options) {
  return readEmailSensitiveEnvironment(
      process.env,
      options);
}
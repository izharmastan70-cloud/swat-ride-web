import {
  BrevoApiKeySecret,
} from '../security/brevo_api_key_secret.js';

export const BREVO_PROVIDER_SECRET_ENV_NAME =
    'BREVO_API_KEY';

export const BREVO_PROVIDER_SECRET_POLICY =
    Object.freeze({
      serverOnly:
          true,
      mayAppearInClientPayload:
          false,
      mayAppearInLogs:
          false,
      mayAppearInFirestore:
          false,
      mayAppearInSourceControl:
          false,
      mayBePastedIntoChat:
          false,
      requiredForLiveSend:
          false,
      requiredForSenderStatusReadOnlyCheck:
          true,

      // VERCEL PRODUCTION NOTE:
      // Add BREVO_API_KEY directly in Vercel Project Settings >
      // Environment Variables. Mark it Sensitive for Preview/Production.
      // Never place the real key in source, Flutter, Firestore, screenshots,
      // chat, shell history, or committed .env files.
      //
      // Changing a Vercel environment variable does not retroactively change
      // an already-created deployment. A new deployment/redeploy is needed
      // when we intentionally activate the server-side integration later.
      //
      // This B6-E step does not read the host runtime environment directly
      // and does not activate provider network access. Runtime wiring is a
      // later gated step.
      vercelSensitivePreviewProduction:
          true,
      runtimeWiringNow:
          false,
      liveSendNow:
          false,
      providerNetworkNow:
          false,
    });

function sanitizeEnvironmentMetadata({
  present,
  source,
}) {
  return Object.freeze({
    name:
        BREVO_PROVIDER_SECRET_ENV_NAME,
    present:
        present === true,
    source:
        source,
    value:
        '[REDACTED]',
    serverOnly:
        true,
    liveSendAllowed:
        false,
    providerNetworkAllowed:
        false,
  });
}

export function prepareBrevoProviderSecretFromEnvironment(
  environment,
) {
  if (!environment ||
      typeof environment !== 'object') {
    return Object.freeze({
      ok:
          false,
      secret:
          null,
      metadata:
          sanitizeEnvironmentMetadata({
            present:
                false,
            source:
                'NO_ENVIRONMENT_OBJECT',
          }),
      code:
          'BREVO_PROVIDER_ENV_OBJECT_MISSING',
    });
  }

  const raw =
      environment[
          BREVO_PROVIDER_SECRET_ENV_NAME];

  if (typeof raw !== 'string' ||
      raw.trim().length < 8) {
    return Object.freeze({
      ok:
          false,
      secret:
          null,
      metadata:
          sanitizeEnvironmentMetadata({
            present:
                false,
            source:
                'ENVIRONMENT_KEY_MISSING_OR_INVALID',
          }),
      code:
          'BREVO_PROVIDER_SECRET_MISSING',
    });
  }

  const secret =
      new BrevoApiKeySecret(
          raw);

  return Object.freeze({
    ok:
        true,
    secret,
    metadata:
        sanitizeEnvironmentMetadata({
          present:
              true,
          source:
              'SERVER_ENVIRONMENT_INJECTED',
        }),
    code:
        'BREVO_PROVIDER_SECRET_READY_FOR_READ_ONLY_ADAPTER',
  });
}
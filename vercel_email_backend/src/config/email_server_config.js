export const EMAIL_SERVER_BOUNDARY_ID = 'vercel_serverless';
export const INITIAL_PROVIDER_ID = 'brevo';

export const REQUIRED_SECRET_REFERENCE_NAMES = Object.freeze([
  'BREVO_API_KEY',
  'FIREBASE_SERVICE_ACCOUNT_JSON',
  'SWAT_RIDE_FIREBASE_PROJECT_ID',
]);

export function buildPhase44F3dcServerConfig() {
  return Object.freeze({
    serverBoundaryId: EMAIL_SERVER_BOUNDARY_ID,
    providerId: INITIAL_PROVIDER_ID,
    liveSendEnabled: false,
    deploymentAllowed: false,
    firebaseIdTokenVerificationRequired: true,
    serverConsumedApprovalRecheckRequired: true,
    verifiedSenderRequired: true,
    antiReplayRequired: true,
    providerSecretReadableByClient: false,
    firebaseAdminCredentialReadableByClient: false,
    requiredSecretReferenceNames: REQUIRED_SECRET_REFERENCE_NAMES,
  });
}
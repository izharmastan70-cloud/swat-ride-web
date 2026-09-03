export const EMAIL_SENDER_SETUP_STATUS = Object.freeze({
  notConfigured: 'NOT_CONFIGURED',
  pendingProviderVerification: 'PENDING_PROVIDER_VERIFICATION',
  verifiedDisabled: 'VERIFIED_DISABLED',
  verifiedEnabled: 'VERIFIED_ENABLED',
});

export const EMAIL_SENDER_SETUP_POLICY = Object.freeze({
  clientMayCreateVerifiedSender: false,
  clientMayUpdateVerifiedSender: false,
  verificationServerOnly: true,
  providerSecretMayBeStoredWithSender: false,
  sourceTestsRequireRealSender: false,
  sourceTestsRequireProviderSecret: false,
  sourceTestsMaySendEmail: false,
  liveSendMustRemainOffDuringSetup: true,
});

export function classifyEmailSenderSetup(record) {
  if (!record ||
      typeof record !== 'object' ||
      Array.isArray(record)) {
    return EMAIL_SENDER_SETUP_STATUS.notConfigured;
  }

  const verified =
      record.verifiedAt != null &&
      record.verificationSource ===
          'SERVER_PROVIDER_VERIFIED';

  if (!verified) {
    return EMAIL_SENDER_SETUP_STATUS
        .pendingProviderVerification;
  }

  if (record.enabled === true) {
    return EMAIL_SENDER_SETUP_STATUS.verifiedEnabled;
  }

  return EMAIL_SENDER_SETUP_STATUS.verifiedDisabled;
}

export function mayRequestRealSenderSetup({
  exactApprovalScopeValidatorReady,
  masterToggleRecheckerReady,
  firebaseAdminAdaptersReady,
  liveSendEnabled,
}) {
  return exactApprovalScopeValidatorReady === true &&
    masterToggleRecheckerReady === true &&
    firebaseAdminAdaptersReady === true &&
    liveSendEnabled === false;
}
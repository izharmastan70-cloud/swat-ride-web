class AgentPrivacyConsentStatus {
  AgentPrivacyConsentStatus._();
  static const String granted = 'GRANTED';
  static const String denied = 'DENIED';
  static const String revoked = 'REVOKED';
  static const Set<String> values = <String>{granted, denied, revoked};
}

class AgentPrivacyConsentPurpose {
  AgentPrivacyConsentPurpose._();
  static const String trainingEligibilityReview = 'TRAINING_ELIGIBILITY_REVIEW';
}

class AgentPrivacyRedactionStatus {
  AgentPrivacyRedactionStatus._();
  static const String verified = 'VERIFIED';
  static const String failed = 'FAILED';
  static const String incomplete = 'INCOMPLETE';
  static const Set<String> values = <String>{verified, failed, incomplete};
}

class AgentPrivacyTrainingEligibilityStatus {
  AgentPrivacyTrainingEligibilityStatus._();

  static const String eligibleRealData = 'ELIGIBLE_REAL_DATA';
  static const String eligibleSyntheticOnly = 'ELIGIBLE_SYNTHETIC_ONLY';
  static const String blockedConsent = 'BLOCKED_CONSENT';
  static const String blockedRedaction = 'BLOCKED_REDACTION';
  static const String blockedSensitive = 'BLOCKED_SENSITIVE';
  static const String blockedSecret = 'BLOCKED_SECRET';
  static const String blockedMismatch = 'BLOCKED_MISMATCH';
  static const String blockedExpired = 'BLOCKED_EXPIRED';
  static const String blockedInvalidInput = 'BLOCKED_INVALID_INPUT';

  static const Set<String> values = <String>{
    eligibleRealData,
    eligibleSyntheticOnly,
    blockedConsent,
    blockedRedaction,
    blockedSensitive,
    blockedSecret,
    blockedMismatch,
    blockedExpired,
    blockedInvalidInput,
  };
}

class AgentPrivacyConsentLimits {
  AgentPrivacyConsentLimits._();
  static const Duration maximumConsentValidity = Duration(days: 90);
  static const Duration maximumFutureClockSkew = Duration(minutes: 5);
  static const Duration maximumRedactionEvidenceAge = Duration(hours: 24);
  static const int opaqueIdMaxLength = 220;
}

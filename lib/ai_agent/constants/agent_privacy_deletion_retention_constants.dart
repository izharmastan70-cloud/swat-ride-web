class AgentPrivacyDeletionRecordClass {
  AgentPrivacyDeletionRecordClass._();

  static const String transientContent = 'TRANSIENT_CONTENT';
  static const String operationalMetadata = 'OPERATIONAL_METADATA';
  static const String auditEvidence = 'AUDIT_EVIDENCE';
  static const String securityEvidence = 'SECURITY_EVIDENCE';
  static const String financeEvidence = 'FINANCE_EVIDENCE';

  static const Set<String> values = <String>{
    transientContent,
    operationalMetadata,
    auditEvidence,
    securityEvidence,
    financeEvidence,
  };

  static bool isProtected(String value) {
    return value == auditEvidence ||
        value == securityEvidence ||
        value == financeEvidence;
  }
}

class AgentPrivacyDeletionStatus {
  AgentPrivacyDeletionStatus._();

  static const String eligibleTransientReview = 'ELIGIBLE_TRANSIENT_REVIEW';

  static const String blockedProtectedEvidence = 'BLOCKED_PROTECTED_EVIDENCE';

  static const String blockedRetentionNotExpired =
      'BLOCKED_RETENTION_NOT_EXPIRED';

  static const String blockedLegalOrSecurityHold =
      'BLOCKED_LEGAL_OR_SECURITY_HOLD';

  static const String blockedRestrictedCritical = 'BLOCKED_RESTRICTED_CRITICAL';

  static const String blockedMismatch = 'BLOCKED_MISMATCH';

  static const String blockedInvalidInput = 'BLOCKED_INVALID_INPUT';

  static const Set<String> values = <String>{
    eligibleTransientReview,
    blockedProtectedEvidence,
    blockedRetentionNotExpired,
    blockedLegalOrSecurityHold,
    blockedRestrictedCritical,
    blockedMismatch,
    blockedInvalidInput,
  };
}

class AgentPrivacyRetentionOverrideStatus {
  AgentPrivacyRetentionOverrideStatus._();

  static const String eligibleFoundationOverride =
      'ELIGIBLE_FOUNDATION_OVERRIDE';

  static const String blockedRole = 'BLOCKED_ROLE';
  static const String blockedChannelCap = 'BLOCKED_CHANNEL_CAP';
  static const String blockedProtectedEvidence = 'BLOCKED_PROTECTED_EVIDENCE';
  static const String blockedInvalidInput = 'BLOCKED_INVALID_INPUT';

  static const Set<String> values = <String>{
    eligibleFoundationOverride,
    blockedRole,
    blockedChannelCap,
    blockedProtectedEvidence,
    blockedInvalidInput,
  };
}

class AgentPrivacyRetentionOverrideRole {
  AgentPrivacyRetentionOverrideRole._();

  static const String owner = 'OWNER';
  static const String superAdmin = 'SUPER_ADMIN';

  static const Set<String> values = <String>{owner, superAdmin};
}

class AgentPrivacyDeletionLimits {
  AgentPrivacyDeletionLimits._();

  static const int opaqueIdMaxLength = 220;

  static const Duration maximumFutureClockSkew = Duration(minutes: 5);
}

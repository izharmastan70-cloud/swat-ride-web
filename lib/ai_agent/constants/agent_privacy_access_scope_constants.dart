class AgentPrivacyAccessDomain {
  AgentPrivacyAccessDomain._();

  static const String general = 'GENERAL';
  static const String student = 'STUDENT';
  static const String safety = 'SAFETY';
  static const String financial = 'FINANCIAL';

  static const Set<String> values = <String>{
    general,
    student,
    safety,
    financial,
  };
}

class AgentPrivacyAccessPurpose {
  AgentPrivacyAccessPurpose._();

  static const String supportStatus = 'SUPPORT_STATUS';
  static const String ownerReport = 'OWNER_REPORT';
  static const String qualityReview = 'QUALITY_REVIEW';
  static const String emergencySupport = 'EMERGENCY_SUPPORT';

  static const Set<String> values = <String>{
    supportStatus,
    ownerReport,
    qualityReview,
    emergencySupport,
  };
}

class AgentPrivacyProjectionMode {
  AgentPrivacyProjectionMode._();

  static const String minimumNecessaryMetadata = 'MINIMUM_NECESSARY_METADATA';

  static const String verifiedProjectionOnly = 'VERIFIED_PROJECTION_ONLY';

  static const String blocked = 'BLOCKED';

  static const Set<String> values = <String>{
    minimumNecessaryMetadata,
    verifiedProjectionOnly,
    blocked,
  };
}

class AgentPrivacyDataAccessStatus {
  AgentPrivacyDataAccessStatus._();

  static const String grantedMinimumNecessary = 'GRANTED_MINIMUM_NECESSARY';

  static const String grantedVerifiedProjectionOnly =
      'GRANTED_VERIFIED_PROJECTION_ONLY';

  static const String blockedScope = 'BLOCKED_SCOPE';
  static const String blockedSensitivity = 'BLOCKED_SENSITIVITY';
  static const String blockedRestrictedCritical = 'BLOCKED_RESTRICTED_CRITICAL';
  static const String blockedDomain = 'BLOCKED_DOMAIN';
  static const String blockedExpired = 'BLOCKED_EXPIRED';
  static const String blockedAgentMismatch = 'BLOCKED_AGENT_MISMATCH';
  static const String blockedInvalidInput = 'BLOCKED_INVALID_INPUT';

  static const Set<String> values = <String>{
    grantedMinimumNecessary,
    grantedVerifiedProjectionOnly,
    blockedScope,
    blockedSensitivity,
    blockedRestrictedCritical,
    blockedDomain,
    blockedExpired,
    blockedAgentMismatch,
    blockedInvalidInput,
  };
}

class AgentPrivacyAccessScopeLimits {
  AgentPrivacyAccessScopeLimits._();

  static const int opaqueIdMaxLength = 220;

  static const Duration maximumFutureClockSkew = Duration(minutes: 5);

  static const int maximumRequestedDataKinds = 12;
}

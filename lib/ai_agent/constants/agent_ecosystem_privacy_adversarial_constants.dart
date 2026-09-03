class AgentEcosystemPrivacyAttackType {
  AgentEcosystemPrivacyAttackType._();

  static const String none = 'NONE';
  static const String promptInjection = 'PROMPT_INJECTION';
  static const String secretExtraction = 'SECRET_EXTRACTION';
  static const String stolenSession = 'STOLEN_SESSION';
  static const String crossCustomerData = 'CROSS_CUSTOMER_DATA';

  static const Set<String> values = <String>{
    none,
    promptInjection,
    secretExtraction,
    stolenSession,
    crossCustomerData,
  };
}

class AgentEcosystemPrivacyDomain {
  AgentEcosystemPrivacyDomain._();

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

class AgentEcosystemPrivacyDecisionStatus {
  AgentEcosystemPrivacyDecisionStatus._();

  static const String blockPromptInjection = 'BLOCK_PROMPT_INJECTION';
  static const String blockSecretExtraction = 'BLOCK_SECRET_EXTRACTION';
  static const String blockUntrustedSession = 'BLOCK_UNTRUSTED_SESSION';
  static const String blockStaleSession = 'BLOCK_STALE_SESSION';
  static const String blockSessionSubjectMismatch =
      'BLOCK_SESSION_SUBJECT_MISMATCH';
  static const String blockCrossCustomer = 'BLOCK_CROSS_CUSTOMER';
  static const String blockScope = 'BLOCK_SCOPE';
  static const String blockMinimumNecessary = 'BLOCK_MINIMUM_NECESSARY';
  static const String blockRedaction = 'BLOCK_REDACTION';
  static const String blockSensitiveDomain = 'BLOCK_SENSITIVE_DOMAIN';
  static const String blockProviderPrivacyProjection =
      'BLOCK_PROVIDER_PRIVACY_PROJECTION';
  static const String safeProjectionEligible = 'SAFE_PROJECTION_ELIGIBLE';

  static const Set<String> values = <String>{
    blockPromptInjection,
    blockSecretExtraction,
    blockUntrustedSession,
    blockStaleSession,
    blockSessionSubjectMismatch,
    blockCrossCustomer,
    blockScope,
    blockMinimumNecessary,
    blockRedaction,
    blockSensitiveDomain,
    blockProviderPrivacyProjection,
    safeProjectionEligible,
  };
}

class AgentEcosystemPrivacyRoute {
  AgentEcosystemPrivacyRoute._();

  static const String blocked = 'BLOCKED';
  static const String trustedSessionGate = 'TRUSTED_SESSION_GATE';
  static const String privacyScopeGate = 'PRIVACY_SCOPE_GATE';
  static const String sensitiveDomainGate = 'SENSITIVE_DOMAIN_GATE';
  static const String providerPrivacyGate = 'PROVIDER_PRIVACY_GATE';
  static const String safeProjection = 'SAFE_PROJECTION';
}

class AgentUnifiedContextSensitivity {
  AgentUnifiedContextSensitivity._();

  static const String publicData = 'PUBLIC_DATA';
  static const String internalData = 'INTERNAL_DATA';
  static const String personalData = 'PERSONAL_DATA';
  static const String sensitiveData = 'SENSITIVE_DATA';
  static const String restrictedData = 'RESTRICTED_DATA';

  static const Set<String> values = <String>{
    publicData,
    internalData,
    personalData,
    sensitiveData,
    restrictedData,
  };
}

class AgentUnifiedContextSourceTrust {
  AgentUnifiedContextSourceTrust._();

  /// Information quality / provenance only. This never grants action authority.
  static const String verifiedSystem = 'VERIFIED_SYSTEM';
  static const String verifiedIdentityBound = 'VERIFIED_IDENTITY_BOUND';
  static const String userAsserted = 'USER_ASSERTED';
  static const String derivedSummary = 'DERIVED_SUMMARY';
  static const String untrustedExternal = 'UNTRUSTED_EXTERNAL';

  static const Set<String> values = <String>{
    verifiedSystem,
    verifiedIdentityBound,
    userAsserted,
    derivedSummary,
    untrustedExternal,
  };
}

class AgentUnifiedContextSourceType {
  AgentUnifiedContextSourceType._();

  static const String domainServiceRead = 'DOMAIN_SERVICE_READ';
  static const String verifiedChannelIdentity = 'VERIFIED_CHANNEL_IDENTITY';
  static const String userStatement = 'USER_STATEMENT';
  static const String agentDerivedSummary = 'AGENT_DERIVED_SUMMARY';
  static const String emergencyTriageSignal = 'EMERGENCY_TRIAGE_SIGNAL';
  static const String externalProviderMetadata = 'EXTERNAL_PROVIDER_METADATA';

  static const Set<String> values = <String>{
    domainServiceRead,
    verifiedChannelIdentity,
    userStatement,
    agentDerivedSummary,
    emergencyTriageSignal,
    externalProviderMetadata,
  };
}

class AgentUnifiedContextPurpose {
  AgentUnifiedContextPurpose._();

  static const String generalSupport = 'GENERAL_SUPPORT';
  static const String bookingAssistance = 'BOOKING_ASSISTANCE';
  static const String statusRead = 'STATUS_READ';
  static const String safetyTriage = 'SAFETY_TRIAGE';
  static const String ownerOperations = 'OWNER_OPERATIONS';

  static const Set<String> values = <String>{
    generalSupport,
    bookingAssistance,
    statusRead,
    safetyTriage,
    ownerOperations,
  };
}

class AgentUnifiedContextDataKind {
  AgentUnifiedContextDataKind._();

  static const String preference = 'PREFERENCE';
  static const String bookingFact = 'BOOKING_FACT';
  static const String statusFact = 'STATUS_FACT';
  static const String identityAttribute = 'IDENTITY_ATTRIBUTE';
  static const String safetyNeed = 'SAFETY_NEED';
  static const String ownerOperationalFact = 'OWNER_OPERATIONAL_FACT';
  static const String conversationSummary = 'CONVERSATION_SUMMARY';

  static const Set<String> values = <String>{
    preference,
    bookingFact,
    statusFact,
    identityAttribute,
    safetyNeed,
    ownerOperationalFact,
    conversationSummary,
  };
}

class AgentUnifiedContextDecisionStatus {
  AgentUnifiedContextDecisionStatus._();

  static const String allowed = 'ALLOWED';
  static const String blocked = 'BLOCKED';

  static const Set<String> values = <String>{allowed, blocked};
}

class AgentUnifiedContextReason {
  AgentUnifiedContextReason._();

  static const String allowed = 'context_item_allowed';
  static const String invalidStructure = 'invalid_context_structure';
  static const String rawSecretBlocked = 'raw_secret_blocked';
  static const String paymentCredentialBlocked = 'payment_credential_blocked';
  static const String authTokenBlocked = 'auth_token_blocked';
  static const String rawHistoryBlocked = 'raw_message_history_blocked';
  static const String expiredBlocked = 'expired_context_blocked';
  static const String purposeMismatchBlocked = 'purpose_mismatch_blocked';
  static const String subjectMismatchBlocked = 'subject_mismatch_blocked';
  static const String restrictedSensitivityBlocked =
      'restricted_sensitivity_blocked';
  static const String ownerPrivateLeakBlocked = 'owner_private_leak_blocked';
  static const String sourceTrustMismatchBlocked =
      'source_trust_mismatch_blocked';
}

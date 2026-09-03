class AgentProviderExpansionTier {
  AgentProviderExpansionTier._();

  static const String freeOnline = 'FREE_ONLINE';
  static const String localOptional = 'LOCAL_OPTIONAL';
  static const String paidLastEscalation = 'PAID_LAST_ESCALATION';

  static const Set<String> values = <String>{
    freeOnline,
    localOptional,
    paidLastEscalation,
  };
}

class AgentProviderExpansionCapability {
  AgentProviderExpansionCapability._();

  static const String textReasoning = 'TEXT_REASONING';
  static const String structuredJson = 'STRUCTURED_JSON';
  static const String summarization = 'SUMMARIZATION';
  static const String classification = 'CLASSIFICATION';
  static const String translation = 'TRANSLATION';
  static const String visionInput = 'VISION_INPUT';
  static const String codeReasoning = 'CODE_REASONING';
  static const String embeddings = 'EMBEDDINGS';

  static const Set<String> values = <String>{
    textReasoning,
    structuredJson,
    summarization,
    classification,
    translation,
    visionInput,
    codeReasoning,
    embeddings,
  };
}

class AgentProviderExpansionActivationStatus {
  AgentProviderExpansionActivationStatus._();

  static const String eligibleForTrustedBackendActivation =
      'ELIGIBLE_FOR_TRUSTED_BACKEND_ACTIVATION';

  static const String blockedInvalidContract = 'BLOCKED_INVALID_CONTRACT';

  static const String blockedDisabled = 'BLOCKED_DISABLED';

  static const String blockedSecretBoundary = 'BLOCKED_SECRET_BOUNDARY';

  static const String blockedCapabilityMismatch = 'BLOCKED_CAPABILITY_MISMATCH';

  static const String blockedPaidControl = 'BLOCKED_PAID_CONTROL';

  static const String blockedUnsafeAuthorityRequest =
      'BLOCKED_UNSAFE_AUTHORITY_REQUEST';

  static const Set<String> values = <String>{
    eligibleForTrustedBackendActivation,
    blockedInvalidContract,
    blockedDisabled,
    blockedSecretBoundary,
    blockedCapabilityMismatch,
    blockedPaidControl,
    blockedUnsafeAuthorityRequest,
  };
}

class AgentProviderExpansionLimits {
  AgentProviderExpansionLimits._();

  static const int idMax = 160;
  static const int displayNameMax = 100;
  static const int modelRefMax = 180;
  static const int secretRefMax = 220;
  static const int maxCapabilities = 8;
}

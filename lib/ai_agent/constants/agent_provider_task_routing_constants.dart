class AgentProviderTaskType {
  AgentProviderTaskType._();

  static const String generalReasoning = 'GENERAL_REASONING';
  static const String structuredResponse = 'STRUCTURED_RESPONSE';
  static const String summarization = 'SUMMARIZATION';
  static const String classification = 'CLASSIFICATION';
  static const String translation = 'TRANSLATION';
  static const String visionUnderstanding = 'VISION_UNDERSTANDING';
  static const String codeReasoning = 'CODE_REASONING';
  static const String embeddingGeneration = 'EMBEDDING_GENERATION';
  static const String contentDraft = 'CONTENT_DRAFT';
  static const String knowledgeAnswer = 'KNOWLEDGE_ANSWER';

  static const Set<String> values = <String>{
    generalReasoning,
    structuredResponse,
    summarization,
    classification,
    translation,
    visionUnderstanding,
    codeReasoning,
    embeddingGeneration,
    contentDraft,
    knowledgeAnswer,
  };
}

class AgentProviderTaskRouteStatus {
  AgentProviderTaskRouteStatus._();

  static const String eligibleForResilientRouting =
      'ELIGIBLE_FOR_RESILIENT_ROUTING';

  static const String blockedInvalidRequest = 'BLOCKED_INVALID_REQUEST';

  static const String blockedUnsupportedTask = 'BLOCKED_UNSUPPORTED_TASK';

  static const String blockedModelDisabled = 'BLOCKED_MODEL_DISABLED';

  static const String blockedBackendBoundary = 'BLOCKED_BACKEND_BOUNDARY';

  static const String blockedCapabilityMismatch = 'BLOCKED_CAPABILITY_MISMATCH';

  static const String blockedModelFeatureMismatch =
      'BLOCKED_MODEL_FEATURE_MISMATCH';

  static const String blockedMinimumContextPolicy =
      'BLOCKED_MINIMUM_CONTEXT_POLICY';

  static const String blockedContextBudget = 'BLOCKED_CONTEXT_BUDGET';

  static const Set<String> values = <String>{
    eligibleForResilientRouting,
    blockedInvalidRequest,
    blockedUnsupportedTask,
    blockedModelDisabled,
    blockedBackendBoundary,
    blockedCapabilityMismatch,
    blockedModelFeatureMismatch,
    blockedMinimumContextPolicy,
    blockedContextBudget,
  };
}

class AgentProviderTaskRoutingLimits {
  AgentProviderTaskRoutingLimits._();

  static const int idMax = 180;
  static const int modelRefMax = 180;

  /// Conservative metadata validation only, not a provider-specific limit.
  static const int absoluteMaxContextTokens = 2000000;

  static const int absoluteMaxOutputTokens = 200000;

  /// Small reserve to avoid exact-window edge routing.
  static const int defaultSafetyReserveTokens = 256;

  static const int maxReasonCodes = 16;
}

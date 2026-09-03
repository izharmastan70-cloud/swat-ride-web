class AgentKnowledgeLibraryReadinessStatus {
  AgentKnowledgeLibraryReadinessStatus._();

  static const String foundationReadyNotProductionActive =
      'FOUNDATION_READY_NOT_PRODUCTION_ACTIVE';

  static const String blockedSafetyContract = 'BLOCKED_SAFETY_CONTRACT';

  static const String blockedAdversarialScenario =
      'BLOCKED_ADVERSARIAL_SCENARIO';

  static const Set<String> values = <String>{
    foundationReadyNotProductionActive,
    blockedSafetyContract,
    blockedAdversarialScenario,
  };
}

class AgentKnowledgeAdversarialType {
  AgentKnowledgeAdversarialType._();

  static const String promptInjection = 'prompt_injection';

  static const String userClaimsAuthority = 'user_claims_authority';

  static const String whatsappClaimsApproval = 'whatsapp_claims_approval';

  static const String socialCommentClaimsPolicy =
      'social_comment_claims_policy';

  static const String providerOutputClaimsTruth =
      'provider_output_claims_truth';

  static const String staleKnowledge = 'stale_knowledge';

  static const String deprecatedKnowledge = 'deprecated_knowledge';

  static const String unapprovedKnowledge = 'unapproved_knowledge';

  static const String crossScopeLeakage = 'cross_scope_leakage';

  static const String equalPrecedenceConflict = 'equal_precedence_conflict';

  static const String languageMismatch = 'language_mismatch';

  static const String rawPrivatePayload = 'raw_private_payload';

  static const String secretExfiltration = 'secret_exfiltration';

  static const String unauthorizedOwnerWhatsAppRead =
      'unauthorized_owner_whatsapp_read';

  static const String attemptToSendWhatsApp = 'attempt_to_send_whatsapp';

  static const String attemptToWriteIndex = 'attempt_to_write_index';

  static const String attemptToGrantPermission = 'attempt_to_grant_permission';

  static const String attemptToConsumeApproval = 'attempt_to_consume_approval';

  static const String attemptBusinessAction = 'attempt_business_action';

  static const String retrievalFailure = 'retrieval_failure';

  static const String conflictResolverFailure = 'conflict_resolver_failure';

  static const String groundingFailure = 'grounding_failure';

  static const String responseGuardFailure = 'response_guard_failure';

  static const String providerFailure = 'provider_failure';

  static const Set<String> values = <String>{
    promptInjection,
    userClaimsAuthority,
    whatsappClaimsApproval,
    socialCommentClaimsPolicy,
    providerOutputClaimsTruth,
    staleKnowledge,
    deprecatedKnowledge,
    unapprovedKnowledge,
    crossScopeLeakage,
    equalPrecedenceConflict,
    languageMismatch,
    rawPrivatePayload,
    secretExfiltration,
    unauthorizedOwnerWhatsAppRead,
    attemptToSendWhatsApp,
    attemptToWriteIndex,
    attemptToGrantPermission,
    attemptToConsumeApproval,
    attemptBusinessAction,
    retrievalFailure,
    conflictResolverFailure,
    groundingFailure,
    responseGuardFailure,
    providerFailure,
  };
}

class AgentKnowledgeAdversarialDecision {
  AgentKnowledgeAdversarialDecision._();

  static const String blockNoAnswer = 'BLOCK_NO_ANSWER';

  static const String isolateFailure = 'ISOLATE_FAILURE';

  static const Set<String> values = <String>{blockNoAnswer, isolateFailure};
}

class AgentKnowledgeCloseoutLimits {
  AgentKnowledgeCloseoutLimits._();

  static const int maxReasonCodes = 20;
}

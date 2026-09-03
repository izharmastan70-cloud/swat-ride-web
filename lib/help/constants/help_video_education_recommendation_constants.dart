class HelpVideoEducationRecommendationStatus {
  HelpVideoEducationRecommendationStatus._();

  static const String recommended = 'RECOMMENDED';

  static const String recommendedLanguageFallback =
      'RECOMMENDED_LANGUAGE_FALLBACK';

  static const String blockedInvalidRequest = 'BLOCKED_INVALID_REQUEST';

  static const String blockedCatalog = 'BLOCKED_CATALOG';

  static const String blockedAudienceMismatch = 'BLOCKED_AUDIENCE_MISMATCH';

  static const String blockedLanguageMismatch = 'BLOCKED_LANGUAGE_MISMATCH';

  static const String blockedContextMismatch = 'BLOCKED_CONTEXT_MISMATCH';

  static const Set<String> values = <String>{
    recommended,
    recommendedLanguageFallback,
    blockedInvalidRequest,
    blockedCatalog,
    blockedAudienceMismatch,
    blockedLanguageMismatch,
    blockedContextMismatch,
  };
}

class HelpVideoEducationRecommendationReason {
  HelpVideoEducationRecommendationReason._();

  static const String existingContextualRankingReused =
      'existing_contextual_ranking_reused';

  static const String candidateCatalogEligible = 'candidate_catalog_eligible';

  static const String audienceMatched = 'audience_matched';

  static const String languageMatched = 'language_matched';

  static const String languageFallbackUsed = 'language_fallback_used';

  static const String moduleMatched = 'module_matched';

  static const String featureMatched = 'feature_matched';

  static const String intentMatched = 'intent_matched';

  static const String invalidRequest = 'invalid_request';

  static const String catalogBlocked = 'catalog_blocked';

  static const String audienceMismatch = 'audience_mismatch';

  static const String languageMismatch = 'language_mismatch';

  static const String contextMismatch = 'context_mismatch';

  static const String recommendationOnly = 'recommendation_only';

  static const String nonAuthoritativeContent = 'non_authoritative_content';

  static const Set<String> values = <String>{
    existingContextualRankingReused,
    candidateCatalogEligible,
    audienceMatched,
    languageMatched,
    languageFallbackUsed,
    moduleMatched,
    featureMatched,
    intentMatched,
    invalidRequest,
    catalogBlocked,
    audienceMismatch,
    languageMismatch,
    contextMismatch,
    recommendationOnly,
    nonAuthoritativeContent,
  };
}

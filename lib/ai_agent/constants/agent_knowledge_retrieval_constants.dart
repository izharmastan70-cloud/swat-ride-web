class AgentKnowledgeRetrievalStatus {
  AgentKnowledgeRetrievalStatus._();

  static const String readyWithGroundedReferences =
      'READY_WITH_GROUNDED_REFERENCES';

  static const String noAnswerInvalidRequest = 'NO_ANSWER_INVALID_REQUEST';

  static const String noAnswerScopeAuthorizationUnverified =
      'NO_ANSWER_SCOPE_AUTHORIZATION_UNVERIFIED';

  static const String noAnswerUntrustedOrStale = 'NO_ANSWER_UNTRUSTED_OR_STALE';

  static const String noAnswerNoTopicMatch = 'NO_ANSWER_NO_TOPIC_MATCH';

  static const String noAnswerLanguageMismatch = 'NO_ANSWER_LANGUAGE_MISMATCH';

  static const String noAnswerScopeMismatch = 'NO_ANSWER_SCOPE_MISMATCH';

  static const String noAnswerLowConfidence = 'NO_ANSWER_LOW_CONFIDENCE';

  static const Set<String> values = <String>{
    readyWithGroundedReferences,
    noAnswerInvalidRequest,
    noAnswerScopeAuthorizationUnverified,
    noAnswerUntrustedOrStale,
    noAnswerNoTopicMatch,
    noAnswerLanguageMismatch,
    noAnswerScopeMismatch,
    noAnswerLowConfidence,
  };
}

class AgentKnowledgeRetrievalLimits {
  AgentKnowledgeRetrievalLimits._();

  static const int idMax = 180;
  static const int moduleMax = 120;
  static const int topicMax = 180;
  static const int maxAllowedScopes = 16;
  static const int maxCandidateInput = 100;
  static const int maxResults = 8;
  static const int maxReasonCodes = 16;

  static const double defaultMinimumScore = 0.65;
}

class AgentKnowledgeRetrievalRanking {
  AgentKnowledgeRetrievalRanking._();

  static const double relevanceWeight = 0.60;
  static const double authorityWeight = 0.25;
  static const double freshnessWeight = 0.15;
}

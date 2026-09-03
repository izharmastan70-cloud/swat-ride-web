class AgentKnowledgeAnswerContextStatus {
  AgentKnowledgeAnswerContextStatus._();

  static const String readyForGroundedAnswer = 'READY_FOR_GROUNDED_ANSWER';

  static const String noContextConflictNotReady =
      'NO_CONTEXT_CONFLICT_NOT_READY';

  static const String noContextInvalidRequest = 'NO_CONTEXT_INVALID_REQUEST';

  static const String noContextLanguageMismatch =
      'NO_CONTEXT_LANGUAGE_MISMATCH';

  static const String noContextScopeAuthorizationUnverified =
      'NO_CONTEXT_SCOPE_AUTHORIZATION_UNVERIFIED';

  static const String noContextPrivacyBlocked = 'NO_CONTEXT_PRIVACY_BLOCKED';

  static const String noContextCitationMissing = 'NO_CONTEXT_CITATION_MISSING';

  static const Set<String> values = <String>{
    readyForGroundedAnswer,
    noContextConflictNotReady,
    noContextInvalidRequest,
    noContextLanguageMismatch,
    noContextScopeAuthorizationUnverified,
    noContextPrivacyBlocked,
    noContextCitationMissing,
  };
}

class AgentKnowledgeAnswerPrivacyRisk {
  AgentKnowledgeAnswerPrivacyRisk._();

  static const String rawConversation = 'raw_conversation';
  static const String rawPrompt = 'raw_prompt';
  static const String phone = 'phone';
  static const String email = 'email';
  static const String cnic = 'cnic';
  static const String authToken = 'auth_token';
  static const String password = 'password';
  static const String paymentCard = 'payment_card';
  static const String cvv = 'cvv';
  static const String pin = 'pin';
  static const String preciseSensitiveLocation = 'precise_sensitive_location';
  static const String privateComplaintEvidence = 'private_complaint_evidence';
  static const String secret = 'secret';

  static const Set<String> blocked = <String>{
    rawConversation,
    rawPrompt,
    phone,
    email,
    cnic,
    authToken,
    password,
    paymentCard,
    cvv,
    pin,
    preciseSensitiveLocation,
    privateComplaintEvidence,
    secret,
  };
}

class AgentKnowledgeOwnerWhatsAppReadRole {
  AgentKnowledgeOwnerWhatsAppReadRole._();

  static const String owner = 'owner';
  static const String admin = 'admin';
  static const String superAdmin = 'super_admin';

  static const Set<String> values = <String>{owner, admin, superAdmin};
}

class AgentKnowledgeAnswerContextLimits {
  AgentKnowledgeAnswerContextLimits._();

  static const int idMax = 256;
  static const int maxPrivacyFlags = 16;
  static const int maxCitationReferences = 6;
  static const int maxReasonCodes = 16;
}

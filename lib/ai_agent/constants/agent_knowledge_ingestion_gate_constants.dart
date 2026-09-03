class AgentKnowledgeIngestionReviewerRole {
  AgentKnowledgeIngestionReviewerRole._();

  static const String owner = 'owner';
  static const String admin = 'admin';
  static const String superAdmin = 'super_admin';

  static const Set<String> values = <String>{owner, admin, superAdmin};
}

class AgentKnowledgeIngestionStatus {
  AgentKnowledgeIngestionStatus._();

  static const String eligibleForTrustedIndexWrite =
      'ELIGIBLE_FOR_TRUSTED_INDEX_WRITE';
  static const String blockedStep1BContract = 'BLOCKED_STEP1B_CONTRACT';
  static const String blockedInvalidReviewEvidence =
      'BLOCKED_INVALID_REVIEW_EVIDENCE';
  static const String blockedUnverifiedReviewer = 'BLOCKED_UNVERIFIED_REVIEWER';
  static const String blockedUnauthorizedReviewer =
      'BLOCKED_UNAUTHORIZED_REVIEWER';
  static const String blockedApprovalMissing = 'BLOCKED_APPROVAL_MISSING';
  static const String blockedApprovalStale = 'BLOCKED_APPROVAL_STALE';
  static const String blockedRevisionMismatch = 'BLOCKED_REVISION_MISMATCH';
  static const String blockedSourceVersionMismatch =
      'BLOCKED_SOURCE_VERSION_MISMATCH';
  static const String blockedContentBindingMismatch =
      'BLOCKED_CONTENT_BINDING_MISMATCH';
  static const String blockedSupersessionInvalid =
      'BLOCKED_SUPERSESSION_INVALID';
  static const String blockedDeprecationAcknowledgement =
      'BLOCKED_DEPRECATION_ACKNOWLEDGEMENT';
  static const String blockedDuplicateCandidate = 'BLOCKED_DUPLICATE_CANDIDATE';

  static const Set<String> values = <String>{
    eligibleForTrustedIndexWrite,
    blockedStep1BContract,
    blockedInvalidReviewEvidence,
    blockedUnverifiedReviewer,
    blockedUnauthorizedReviewer,
    blockedApprovalMissing,
    blockedApprovalStale,
    blockedRevisionMismatch,
    blockedSourceVersionMismatch,
    blockedContentBindingMismatch,
    blockedSupersessionInvalid,
    blockedDeprecationAcknowledgement,
    blockedDuplicateCandidate,
  };
}

class AgentKnowledgeIngestionLimits {
  AgentKnowledgeIngestionLimits._();

  static const int idMax = 180;
  static const int bindingMax = 256;
  static const int maxReasonCodes = 16;
  static const Duration maxApprovalAge = Duration(days: 30);
}

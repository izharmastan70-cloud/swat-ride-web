class AgentCrossAgentSupervisorAttentionLevel {
  AgentCrossAgentSupervisorAttentionLevel._();

  static const String none = 'NONE';
  static const String ownerAdminReview = 'OWNER_ADMIN_REVIEW';
  static const String urgentSecurity = 'URGENT_SECURITY';

  static const Set<String> values = <String>{
    none,
    ownerAdminReview,
    urgentSecurity,
  };
}

class AgentCrossAgentSupervisorAttentionReason {
  AgentCrossAgentSupervisorAttentionReason._();

  static const String missingOwnerAdminAuthority =
      'MISSING_OWNER_ADMIN_AUTHORITY';
  static const String conflictOrWrongWork = 'CONFLICT_OR_WRONG_WORK';
  static const String ambiguousOwner = 'AMBIGUOUS_OWNER';
  static const String noEligibleOwner = 'NO_ELIGIBLE_OWNER';
  static const String repeatedFailure = 'REPEATED_FAILURE';
  static const String suspiciousActivity = 'SUSPICIOUS_ACTIVITY';
  static const String unsafeAction = 'UNSAFE_ACTION';
  static const String unclearAuthority = 'UNCLEAR_AUTHORITY';

  static const Set<String> values = <String>{
    missingOwnerAdminAuthority,
    conflictOrWrongWork,
    ambiguousOwner,
    noEligibleOwner,
    repeatedFailure,
    suspiciousActivity,
    unsafeAction,
    unclearAuthority,
  };
}

class AgentCrossAgentSupervisorAttentionLimits {
  AgentCrossAgentSupervisorAttentionLimits._();

  static const int opaqueIdMaxLength = 220;
  static const int maxReasons = 16;
  static const int repeatedFailureAttentionThreshold = 3;
}

class AgentSecurityIncidentResponsePlanStatus {
  AgentSecurityIncidentResponsePlanStatus._();

  static const String readyForAuthoritativeReview =
      'READY_FOR_AUTHORITATIVE_REVIEW';

  static const String failClosedReviewRequired = 'FAIL_CLOSED_REVIEW_REQUIRED';

  static const String blockedInsufficientHumanReview =
      'BLOCKED_INSUFFICIENT_HUMAN_REVIEW';

  static const Set<String> values = <String>{
    readyForAuthoritativeReview,
    failClosedReviewRequired,
    blockedInsufficientHumanReview,
  };
}

class AgentSecurityIncidentRecommendationType {
  AgentSecurityIncidentRecommendationType._();

  static const String preserveSafeEvidence = 'PRESERVE_SAFE_EVIDENCE';

  static const String requireHumanSecurityReview =
      'REQUIRE_HUMAN_SECURITY_REVIEW';

  static const String requireFreshIdentityVerification =
      'REQUIRE_FRESH_IDENTITY_VERIFICATION';

  static const String restrictSensitiveActionPath =
      'RESTRICT_SENSITIVE_ACTION_PATH';

  static const String requirePermissionRecheck = 'REQUIRE_PERMISSION_RECHECK';

  static const String requireApprovalRecheck = 'REQUIRE_APPROVAL_RECHECK';

  static const String requireRuntimeGateRecheck =
      'REQUIRE_RUNTIME_GATE_RECHECK';

  static const String requireEmergencySecurityReview =
      'REQUIRE_EMERGENCY_SECURITY_REVIEW';

  static const String monitorRecoveryBeforeClosure =
      'MONITOR_RECOVERY_BEFORE_CLOSURE';

  static const Set<String> values = <String>{
    preserveSafeEvidence,
    requireHumanSecurityReview,
    requireFreshIdentityVerification,
    restrictSensitiveActionPath,
    requirePermissionRecheck,
    requireApprovalRecheck,
    requireRuntimeGateRecheck,
    requireEmergencySecurityReview,
    monitorRecoveryBeforeClosure,
  };
}

class AgentSecurityIncidentAuthoritativeHandoffStatus {
  AgentSecurityIncidentAuthoritativeHandoffStatus._();

  static const String prepared = 'PREPARED';
  static const String blocked = 'BLOCKED';

  static const Set<String> values = <String>{prepared, blocked};
}

class AgentSecurityIncidentResponseReason {
  AgentSecurityIncidentResponseReason._();

  static const String incidentTriageBound = 'incident_triage_bound';

  static const String humanAcknowledgementVerified =
      'human_acknowledgement_verified';

  static const String authoritativeChecksRequired =
      'authoritative_checks_required';

  static const String highRiskReview = 'high_risk_review';

  static const String criticalRiskReview = 'critical_risk_review';

  static const String failClosedReview = 'fail_closed_review';

  static const String recommendationOnly = 'recommendation_only';

  static const String noExecutionAuthority = 'no_execution_authority';

  static const Set<String> values = <String>{
    incidentTriageBound,
    humanAcknowledgementVerified,
    authoritativeChecksRequired,
    highRiskReview,
    criticalRiskReview,
    failClosedReview,
    recommendationOnly,
    noExecutionAuthority,
  };
}

class AgentSecurityIncidentRecoveryEvidenceSource {
  AgentSecurityIncidentRecoveryEvidenceSource._();

  static const String verifiedSecurityControl = 'VERIFIED_SECURITY_CONTROL';

  static const String trustedHumanReview = 'TRUSTED_HUMAN_REVIEW';

  static const String trustedSystem = 'TRUSTED_SYSTEM';

  static const Set<String> values = <String>{
    verifiedSecurityControl,
    trustedHumanReview,
    trustedSystem,
  };
}

class AgentSecurityIncidentClosureAssessmentStatus {
  AgentSecurityIncidentClosureAssessmentStatus._();

  static const String readyForAuthoritativeClosureReview =
      'READY_FOR_AUTHORITATIVE_CLOSURE_REVIEW';

  static const String recoveryMonitoringRequired =
      'RECOVERY_MONITORING_REQUIRED';

  static const String blockedIncidentNotResolved =
      'BLOCKED_INCIDENT_NOT_RESOLVED';

  static const String blockedResponsePlanOrHandoff =
      'BLOCKED_RESPONSE_PLAN_OR_HANDOFF';

  static const String blockedMissingRequiredVerification =
      'BLOCKED_MISSING_REQUIRED_VERIFICATION';

  static const Set<String> values = <String>{
    readyForAuthoritativeClosureReview,
    recoveryMonitoringRequired,
    blockedIncidentNotResolved,
    blockedResponsePlanOrHandoff,
    blockedMissingRequiredVerification,
  };
}

class AgentSecurityIncidentClosureReason {
  AgentSecurityIncidentClosureReason._();

  static const String incidentResolvedStateRequired =
      'incident_resolved_state_required';

  static const String responsePlanAndHandoffBound =
      'response_plan_and_handoff_bound';

  static const String recoveryStableVerified = 'recovery_stable_verified';

  static const String containmentEvidenceVerified =
      'containment_evidence_verified';

  static const String remediationEvidenceVerified =
      'remediation_evidence_verified';

  static const String requiredAuthoritativeReviewsVerified =
      'required_authoritative_reviews_verified';

  static const String requiredVerificationMissing =
      'required_verification_missing';

  static const String recoveryMonitoringStillRequired =
      'recovery_monitoring_still_required';

  static const String closureRecommendationOnly = 'closure_recommendation_only';

  static const String finalClosureAuthorityExternal =
      'final_closure_authority_external';

  static const Set<String> values = <String>{
    incidentResolvedStateRequired,
    responsePlanAndHandoffBound,
    recoveryStableVerified,
    containmentEvidenceVerified,
    remediationEvidenceVerified,
    requiredAuthoritativeReviewsVerified,
    requiredVerificationMissing,
    recoveryMonitoringStillRequired,
    closureRecommendationOnly,
    finalClosureAuthorityExternal,
  };
}

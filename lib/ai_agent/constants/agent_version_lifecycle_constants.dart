class AgentVersionEvaluationGate {
  AgentVersionEvaluationGate._();

  static const double minimumPassPercent = 95;
  static const double minimumWeightedScorePercent = 95;
}

class AgentVersionTransitionDecisionStatus {
  AgentVersionTransitionDecisionStatus._();

  static const String allowed = 'ALLOWED';
  static const String blockedInvalidInput = 'BLOCKED_INVALID_INPUT';
  static const String blockedIllegalTransition = 'BLOCKED_ILLEGAL_TRANSITION';
  static const String blockedEvidenceMissing = 'BLOCKED_EVIDENCE_MISSING';
  static const String blockedEvidenceMismatch = 'BLOCKED_EVIDENCE_MISMATCH';
  static const String blockedEvaluationFailure = 'BLOCKED_EVALUATION_FAILURE';
  static const String blockedHumanApproval = 'BLOCKED_HUMAN_APPROVAL';
  static const String blockedSecurityReview = 'BLOCKED_SECURITY_REVIEW';
  static const String blockedLaterPhase = 'BLOCKED_LATER_PHASE';

  static const Set<String> values = <String>{
    allowed,
    blockedInvalidInput,
    blockedIllegalTransition,
    blockedEvidenceMissing,
    blockedEvidenceMismatch,
    blockedEvaluationFailure,
    blockedHumanApproval,
    blockedSecurityReview,
    blockedLaterPhase,
  };
}

class AgentVersionTransitionReason {
  AgentVersionTransitionReason._();

  static const String offlineEvaluationPassed = 'offline_evaluation_passed';
  static const String testReadinessApproved = 'test_readiness_approved';
  static const String invalidInput = 'invalid_input';
  static const String illegalTransition = 'illegal_transition';
  static const String evidenceMissing = 'evaluation_evidence_missing';
  static const String evidenceMismatch = 'evaluation_evidence_mismatch';
  static const String thresholdFailed = 'evaluation_threshold_failed';
  static const String criticalFailure = 'critical_failure_detected';
  static const String safetyViolation = 'safety_violation_detected';
  static const String blockedCases = 'blocked_evaluation_cases_detected';
  static const String runFailClosed = 'evaluation_run_fail_closed';
  static const String humanReviewNotEligible = 'human_review_not_eligible';
  static const String humanApprovalMissing = 'human_approval_missing';
  static const String securityReviewMissing = 'security_review_missing';
  static const String laterPhaseRequired = 'later_phase_required';
}

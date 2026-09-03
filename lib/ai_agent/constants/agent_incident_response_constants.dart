class AgentSecurityIncidentStatus {
  AgentSecurityIncidentStatus._();

  static const String detected = 'DETECTED';
  static const String open = 'OPEN';
  static const String acknowledged = 'ACKNOWLEDGED';
  static const String triaged = 'TRIAGED';
  static const String containmentRecommended = 'CONTAINMENT_RECOMMENDED';
  static const String remediationRecommended = 'REMEDIATION_RECOMMENDED';
  static const String recoveryMonitoring = 'RECOVERY_MONITORING';
  static const String resolved = 'RESOLVED';
  static const String closed = 'CLOSED';

  static const Set<String> values = <String>{
    detected,
    open,
    acknowledged,
    triaged,
    containmentRecommended,
    remediationRecommended,
    recoveryMonitoring,
    resolved,
    closed,
  };

  static bool isTerminal(String value) => value == closed;
}

class AgentSecurityIncidentSource {
  AgentSecurityIncidentSource._();

  static const String guardian = 'GUARDIAN';
  static const String securityControl = 'SECURITY_CONTROL';
  static const String humanReport = 'HUMAN_REPORT';
  static const String trustedSystem = 'TRUSTED_SYSTEM';

  static const Set<String> values = <String>{
    guardian,
    securityControl,
    humanReport,
    trustedSystem,
  };
}

class AgentSecurityIncidentTriageStatus {
  AgentSecurityIncidentTriageStatus._();

  static const String readyForResponsePlanning = 'READY_FOR_RESPONSE_PLANNING';

  static const String humanReviewRequired = 'HUMAN_REVIEW_REQUIRED';

  static const String failClosedReviewRequired = 'FAIL_CLOSED_REVIEW_REQUIRED';

  static const Set<String> values = <String>{
    readyForResponsePlanning,
    humanReviewRequired,
    failClosedReviewRequired,
  };
}

class AgentSecurityIncidentReason {
  AgentSecurityIncidentReason._();

  static const String guardianSeverityInherited = 'guardian_severity_inherited';

  static const String guardianAggregateBlocked = 'guardian_aggregate_blocked';

  static const String highRiskHumanReview = 'high_risk_human_review';

  static const String criticalRiskHumanReview = 'critical_risk_human_review';

  static const String blockLikeGuardianDisposition =
      'block_like_guardian_disposition';

  static const String escalationLikeGuardianDisposition =
      'escalation_like_guardian_disposition';

  static const String authoritativeChecksStillRequired =
      'authoritative_checks_still_required';

  static const String privacyMinimizedEvidence = 'privacy_minimized_evidence';

  static const String responsePlanningOnly = 'response_planning_only';

  static const Set<String> values = <String>{
    guardianSeverityInherited,
    guardianAggregateBlocked,
    highRiskHumanReview,
    criticalRiskHumanReview,
    blockLikeGuardianDisposition,
    escalationLikeGuardianDisposition,
    authoritativeChecksStillRequired,
    privacyMinimizedEvidence,
    responsePlanningOnly,
  };
}

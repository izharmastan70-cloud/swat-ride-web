class AgentGuardianRiskCategory {
  AgentGuardianRiskCategory._();

  static const String suspiciousInputPattern = 'SUSPICIOUS_INPUT_PATTERN';

  static const String promptInjectionAttempt = 'PROMPT_INJECTION_ATTEMPT';

  static const String permissionBypassAttempt = 'PERMISSION_BYPASS_ATTEMPT';

  static const String approvalBypassAttempt = 'APPROVAL_BYPASS_ATTEMPT';

  static const String runtimeGateBypassAttempt = 'RUNTIME_GATE_BYPASS_ATTEMPT';

  static const String emergencyStopBypassAttempt =
      'EMERGENCY_STOP_BYPASS_ATTEMPT';

  static const String identityMismatch = 'IDENTITY_MISMATCH';

  static const String replayOrContinuityViolation =
      'REPLAY_OR_CONTINUITY_VIOLATION';

  static const String crossSubjectContextAttempt =
      'CROSS_SUBJECT_CONTEXT_ATTEMPT';

  static const String ownerCustomerBoundaryViolation =
      'OWNER_CUSTOMER_BOUNDARY_VIOLATION';

  static const String emergencyContextIsolationViolation =
      'EMERGENCY_CONTEXT_ISOLATION_VIOLATION';

  static const String secretOrCredentialExposureAttempt =
      'SECRET_OR_CREDENTIAL_EXPOSURE_ATTEMPT';

  static const String unauthorizedProviderExecutionAttempt =
      'UNAUTHORIZED_PROVIDER_EXECUTION_ATTEMPT';

  static const String unauthorizedBusinessWriteAttempt =
      'UNAUTHORIZED_BUSINESS_WRITE_ATTEMPT';

  static const String securityControlTamperAttempt =
      'SECURITY_CONTROL_TAMPER_ATTEMPT';

  static const Set<String> values = <String>{
    suspiciousInputPattern,
    promptInjectionAttempt,
    permissionBypassAttempt,
    approvalBypassAttempt,
    runtimeGateBypassAttempt,
    emergencyStopBypassAttempt,
    identityMismatch,
    replayOrContinuityViolation,
    crossSubjectContextAttempt,
    ownerCustomerBoundaryViolation,
    emergencyContextIsolationViolation,
    secretOrCredentialExposureAttempt,
    unauthorizedProviderExecutionAttempt,
    unauthorizedBusinessWriteAttempt,
    securityControlTamperAttempt,
  };
}

class AgentGuardianEvidenceTrust {
  AgentGuardianEvidenceTrust._();

  static const String verifiedSecurityControl = 'VERIFIED_SECURITY_CONTROL';

  static const String verifiedSystem = 'VERIFIED_SYSTEM';

  static const String verifiedIdentityBound = 'VERIFIED_IDENTITY_BOUND';

  static const String heuristic = 'HEURISTIC';

  static const String userReported = 'USER_REPORTED';

  static const String untrustedExternal = 'UNTRUSTED_EXTERNAL';

  static const Set<String> values = <String>{
    verifiedSecurityControl,
    verifiedSystem,
    verifiedIdentityBound,
    heuristic,
    userReported,
    untrustedExternal,
  };
}

class AgentGuardianSeverity {
  AgentGuardianSeverity._();

  static const String low = 'LOW';
  static const String medium = 'MEDIUM';
  static const String high = 'HIGH';
  static const String critical = 'CRITICAL';

  static const Set<String> values = <String>{low, medium, high, critical};
}

class AgentGuardianEvidenceConfidence {
  AgentGuardianEvidenceConfidence._();

  static const String low = 'LOW';
  static const String medium = 'MEDIUM';
  static const String high = 'HIGH';

  static const Set<String> values = <String>{low, medium, high};
}

class AgentGuardianRecommendedDisposition {
  AgentGuardianRecommendedDisposition._();

  static const String observe = 'OBSERVE';

  static const String review = 'REVIEW';

  static const String reviewAndEscalate = 'REVIEW_AND_ESCALATE';

  static const String blockRecommended = 'BLOCK_RECOMMENDED';

  static const String blockAndEscalateRecommended =
      'BLOCK_AND_ESCALATE_RECOMMENDED';

  static const Set<String> values = <String>{
    observe,
    review,
    reviewAndEscalate,
    blockRecommended,
    blockAndEscalateRecommended,
  };
}

class AgentGuardianRiskReason {
  AgentGuardianRiskReason._();

  static const String baseCategorySeverity = 'base_category_severity';

  static const String highImpactTargetElevation =
      'high_impact_target_elevation';

  static const String repeatedPatternElevation = 'repeated_pattern_elevation';

  static const String activeExploitElevation = 'active_exploit_elevation';

  static const String multipleStrongIndicatorsElevation =
      'multiple_strong_indicators_elevation';

  static const String verifiedEvidence = 'verified_evidence';

  static const String heuristicEvidence = 'heuristic_evidence';

  static const String unverifiedEvidence = 'unverified_evidence';

  static const String invalidEvent = 'invalid_guardian_event';
}

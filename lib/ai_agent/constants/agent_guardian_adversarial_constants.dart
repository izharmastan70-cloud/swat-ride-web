class AgentGuardianAdversarialScenarioId {
  AgentGuardianAdversarialScenarioId._();

  static const String promptInjection = 'PROMPT_INJECTION';

  static const String permissionBypass = 'PERMISSION_BYPASS';

  static const String approvalBypass = 'APPROVAL_BYPASS';

  static const String runtimeGateBypass = 'RUNTIME_GATE_BYPASS';

  static const String emergencyStopBypass = 'EMERGENCY_STOP_BYPASS';

  static const String crossSubjectContext = 'CROSS_SUBJECT_CONTEXT';

  static const String replayStorm = 'REPLAY_STORM';

  static const String secretExposure = 'SECRET_EXPOSURE';

  static const String unauthorizedProviderExecution =
      'UNAUTHORIZED_PROVIDER_EXECUTION';

  static const String unauthorizedBusinessWrite = 'UNAUTHORIZED_BUSINESS_WRITE';

  static const String securityControlTamper = 'SECURITY_CONTROL_TAMPER';

  static const String requiredControlUnhealthy = 'REQUIRED_CONTROL_UNHEALTHY';

  static const String requiredControlUnknown = 'REQUIRED_CONTROL_UNKNOWN';

  static const String observerFailureIsolation = 'OBSERVER_FAILURE_ISOLATION';

  static const Set<String> lockedCoverage = <String>{
    promptInjection,
    permissionBypass,
    approvalBypass,
    runtimeGateBypass,
    emergencyStopBypass,
    crossSubjectContext,
    replayStorm,
    secretExposure,
    unauthorizedProviderExecution,
    unauthorizedBusinessWrite,
    securityControlTamper,
    requiredControlUnhealthy,
    requiredControlUnknown,
    observerFailureIsolation,
  };
}

class AgentGuardianAdversarialExpectation {
  AgentGuardianAdversarialExpectation._();

  static const String classified = 'CLASSIFIED';

  static const String failClosed = 'FAIL_CLOSED';

  static const String replaySuppressed = 'REPLAY_SUPPRESSED';

  static const String crossSubjectSuppressed = 'CROSS_SUBJECT_SUPPRESSED';

  static const String invalidSignalFailClosed = 'INVALID_SIGNAL_FAIL_CLOSED';

  static const String failureIsolated = 'FAILURE_ISOLATED';

  static const Set<String> values = <String>{
    classified,
    failClosed,
    replaySuppressed,
    crossSubjectSuppressed,
    invalidSignalFailClosed,
    failureIsolated,
  };
}

class AgentGuardianAdversarialVerificationStatus {
  AgentGuardianAdversarialVerificationStatus._();

  static const String passed = 'PASSED';
  static const String failed = 'FAILED';
}

class AgentProviderQualityReadinessStatus {
  AgentProviderQualityReadinessStatus._();

  static const String foundationReadyNotProductionActive =
      'FOUNDATION_READY_NOT_PRODUCTION_ACTIVE';

  static const String blockedFoundationIncomplete =
      'BLOCKED_FOUNDATION_INCOMPLETE';

  static const String blockedAdversarialFailure = 'BLOCKED_ADVERSARIAL_FAILURE';

  static const Set<String> values = <String>{
    foundationReadyNotProductionActive,
    blockedFoundationIncomplete,
    blockedAdversarialFailure,
  };
}

class AgentProviderQualityAdversarialDisposition {
  AgentProviderQualityAdversarialDisposition._();

  static const String pass = 'PASS';
  static const String failClosed = 'FAIL_CLOSED';

  static const Set<String> values = <String>{pass, failClosed};
}

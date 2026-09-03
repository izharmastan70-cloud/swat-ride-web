class AgentVersioningCloseoutContract {
  AgentVersioningCloseoutContract._();

  static const String contractVersion = 'phase62_versioning_closeout_v1';

  static const String foundationReadyNotProductionActive =
      'FOUNDATION_READY_NOT_PRODUCTION_ACTIVE';

  static const String blockedFoundation = 'BLOCKED_FOUNDATION';

  static const String blockedSecurity = 'BLOCKED_SECURITY';

  static const String blockedProductionActivation =
      'BLOCKED_PRODUCTION_ACTIVATION';

  static const Set<String> statuses = <String>{
    foundationReadyNotProductionActive,
    blockedFoundation,
    blockedSecurity,
    blockedProductionActivation,
  };
}

class AgentCrossAgentCoordinationPriority {
  AgentCrossAgentCoordinationPriority._();

  static const String criticalEmergencySecurity = 'CRITICAL_EMERGENCY_SECURITY';
  static const String highApprovedSensitive = 'HIGH_APPROVED_SENSITIVE';
  static const String mediumCustomerSupport = 'MEDIUM_CUSTOMER_SUPPORT';
  static const String normalOperational = 'NORMAL_OPERATIONAL';
  static const String lowBackground = 'LOW_BACKGROUND';

  static const List<String> orderedHighestFirst = <String>[
    criticalEmergencySecurity,
    highApprovedSensitive,
    mediumCustomerSupport,
    normalOperational,
    lowBackground,
  ];

  static const Set<String> values = <String>{
    criticalEmergencySecurity,
    highApprovedSensitive,
    mediumCustomerSupport,
    normalOperational,
    lowBackground,
  };
}

class AgentCrossAgentOwnershipStatus {
  AgentCrossAgentOwnershipStatus._();

  static const String ownerRecommended = 'OWNER_RECOMMENDED';
  static const String holdConflict = 'HOLD_CONFLICT';
  static const String holdSecurity = 'HOLD_SECURITY';
  static const String holdUntrustedPriority = 'HOLD_UNTRUSTED_PRIORITY';
  static const String holdNoEligibleOwner = 'HOLD_NO_ELIGIBLE_OWNER';
  static const String holdAmbiguousOwner = 'HOLD_AMBIGUOUS_OWNER';

  static const Set<String> values = <String>{
    ownerRecommended,
    holdConflict,
    holdSecurity,
    holdUntrustedPriority,
    holdNoEligibleOwner,
    holdAmbiguousOwner,
  };
}

class AgentCrossAgentSupervisorCoordinationLimits {
  AgentCrossAgentSupervisorCoordinationLimits._();

  static const int opaqueIdMaxLength = 220;
  static const int maxOwnerCandidates = 20;
  static const int maxReasonCodes = 20;
}

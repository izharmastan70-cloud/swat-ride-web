class AgentProductionRolloutOperationalObservation {
  const AgentProductionRolloutOperationalObservation({
    required this.observedAtUtc,
    required this.rolloutActivatedAtUtc,
    required this.auditEventsObserved,
    required this.highAuditEvents,
    required this.criticalAuditEvents,
    required this.knownRecoveryControlAuditEvents,
    required this.unclassifiedCriticalAuditEvents,
    required this.failureAuditEvents,
    required this.securityAuditSignals,
    required this.openCrashEvents,
    required this.highCrashEvents,
    required this.criticalCrashEvents,
    required this.repeatedCrashEvents,
    required this.ownerAttentionObserved,
    required this.unresolvedOwnerAttention,
    required this.criticalOwnerAttention,
    required this.emergencyOwnerAttention,
    required this.securityOwnerAttention,
    required this.crashOwnerAttention,
    required this.fraudOwnerAttention,
    required this.emergencyCaseOwnerAttention,
    required this.dedicatedSecurityIncidentStoreAvailable,
    required this.failureCodes,
  });

  final DateTime observedAtUtc;
  final DateTime? rolloutActivatedAtUtc;

  final int auditEventsObserved;
  final int highAuditEvents;
  final int criticalAuditEvents;
  final int knownRecoveryControlAuditEvents;
  final int unclassifiedCriticalAuditEvents;
  final int failureAuditEvents;
  final int securityAuditSignals;

  final int openCrashEvents;
  final int highCrashEvents;
  final int criticalCrashEvents;
  final int repeatedCrashEvents;

  final int ownerAttentionObserved;
  final int unresolvedOwnerAttention;
  final int criticalOwnerAttention;
  final int emergencyOwnerAttention;
  final int securityOwnerAttention;
  final int crashOwnerAttention;
  final int fraudOwnerAttention;
  final int emergencyCaseOwnerAttention;

  final bool dedicatedSecurityIncidentStoreAvailable;
  final List<String> failureCodes;

  bool get hardSafetySignalDetected =>
      unclassifiedCriticalAuditEvents > 0 ||
      criticalCrashEvents > 0 ||
      emergencyOwnerAttention > 0 ||
      securityOwnerAttention > 0 ||
      fraudOwnerAttention > 0 ||
      emergencyCaseOwnerAttention > 0;

  bool get operationallyClear =>
      failureCodes.isEmpty && !hardSafetySignalDetected;

  bool get dedicatedIncidentObservabilityComplete =>
      dedicatedSecurityIncidentStoreAvailable;

  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
  bool get changesProductionState => false;
  bool get writesFirestore => false;
}

class AgentProductionRolloutOperationalObservationDecision {
  const AgentProductionRolloutOperationalObservationDecision({
    required this.failureCodes,
  });

  final List<String> failureCodes;

  bool get clear => failureCodes.isEmpty;
}

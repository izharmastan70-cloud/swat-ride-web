class AgentProductionRolloutMonitorObservation {
  const AgentProductionRolloutMonitorObservation({
    required this.observedAtUtc,
    required this.rolloutActivatedAtUtc,
    required this.activationId,
    required this.guardRevision,
    required this.roleCount,
    required this.enabledAutoRoleCount,
    required this.stage,
    required this.autoTrafficPercent,
    required this.businessWriteTrafficPercent,
    required this.externalChannelsEnabled,
    required this.masterEnabled,
    required this.emergencyReadOnly,
    required this.freeAiEnabled,
    required this.localAiEnabled,
    required this.paidCodeAiEnabled,
    required this.paidReasoningEnabled,
    required this.callAgentEnabled,
    required this.emailAgentEnabled,
    required this.customerWhatsAppAgentEnabled,
    required this.ownerWhatsAppAgentEnabled,
    required this.emergencyWhatsAppAgentEnabled,
    required this.approvalEngineEnabled,
    required this.auditLoggingEnabled,
    required this.askBeforePaid,
    required this.runtimeGuardClean,
    required this.activationReceiptClean,
    required this.armingTokenClean,
    required this.revisionBindingClean,
    required this.roleCountBindingClean,
    required this.controlBindingClean,
    required this.planBindingClean,
    required this.actorBindingClean,
    required this.approvalBindingClean,
    required this.failureCodes,
  });

  final DateTime observedAtUtc;
  final DateTime? rolloutActivatedAtUtc;
  final String activationId;
  final int guardRevision;
  final int roleCount;
  final int enabledAutoRoleCount;

  final String stage;
  final int autoTrafficPercent;
  final int businessWriteTrafficPercent;
  final bool externalChannelsEnabled;

  final bool masterEnabled;
  final bool emergencyReadOnly;
  final bool freeAiEnabled;
  final bool localAiEnabled;
  final bool paidCodeAiEnabled;
  final bool paidReasoningEnabled;
  final bool callAgentEnabled;
  final bool emailAgentEnabled;
  final bool customerWhatsAppAgentEnabled;
  final bool ownerWhatsAppAgentEnabled;
  final bool emergencyWhatsAppAgentEnabled;
  final bool approvalEngineEnabled;
  final bool auditLoggingEnabled;
  final bool askBeforePaid;

  final bool runtimeGuardClean;
  final bool activationReceiptClean;
  final bool armingTokenClean;
  final bool revisionBindingClean;
  final bool roleCountBindingClean;
  final bool controlBindingClean;
  final bool planBindingClean;
  final bool actorBindingClean;
  final bool approvalBindingClean;

  final List<String> failureCodes;

  bool get stable => failureCodes.isEmpty;

  Duration? get timeSinceActivation {
    final DateTime? activatedAt = rolloutActivatedAtUtc;

    if (activatedAt == null || observedAtUtc.isBefore(activatedAt)) {
      return null;
    }

    return observedAtUtc.difference(activatedAt);
  }

  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
  bool get changesProductionState => false;
  bool get writesFirestore => false;
}

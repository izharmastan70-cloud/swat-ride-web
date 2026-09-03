class AgentCrossAgentSupervisorPriorityContext {
  const AgentCrossAgentSupervisorPriorityContext({
    required this.trustedPriorityMetadata,
    required this.emergencyOrSecurity,
    required this.approvedSensitive,
    required this.customerSupport,
    required this.backgroundWork,
  });

  final bool trustedPriorityMetadata;
  final bool emergencyOrSecurity;
  final bool approvedSensitive;
  final bool customerSupport;
  final bool backgroundWork;

  bool get agentSelfPromotionAllowed => false;
  bool get userTextCanSetPriorityDirectly => false;
  bool get providerOutputCanSetPriorityDirectly => false;
  bool get priorityCanBypassSecurity => false;
  bool get priorityCanCreateApproval => false;
  bool get priorityCanGrantPermission => false;
}

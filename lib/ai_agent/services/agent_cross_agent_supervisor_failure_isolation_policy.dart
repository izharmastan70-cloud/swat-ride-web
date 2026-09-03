class AgentCrossAgentSupervisorFailureIsolationPolicy {
  const AgentCrossAgentSupervisorFailureIsolationPolicy();

  bool get providerFailureStopsCoreApp => false;
  bool get supervisorFailureStopsCoreApp => false;
  bool get conflictDetectorFailureStopsCoreApp => false;
  bool get attentionLayerFailureStopsCoreApp => false;

  bool get providerFailureMayHoldAiCoordination => true;
  bool get supervisorFailureMayHoldAiCoordination => true;

  bool get fallbackMayBypassSecurity => false;
  bool get fallbackMayBypassPermission => false;
  bool get fallbackMayBypassApproval => false;
  bool get fallbackMayBypassRuntimeGate => false;
  bool get fallbackMayBypassGuardianSecurity => false;
  bool get fallbackMayBypassEmergencyStop => false;
  bool get fallbackMayBypassCostBudget => false;
  bool get fallbackMayBypassMandatoryAudit => false;

  bool get autoProviderActivationImplementedHere => false;
  bool get autoPaidEscalationImplementedHere => false;
  bool get budgetIncreaseImplementedHere => false;
  bool get securityOverrideImplementedHere => false;
  bool get businessExecutionImplementedHere => false;
  bool get persistenceImplementedHere => false;
}

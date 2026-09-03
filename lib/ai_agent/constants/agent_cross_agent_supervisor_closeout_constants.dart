class AgentCrossAgentSupervisorCloseoutStatus {
  AgentCrossAgentSupervisorCloseoutStatus._();

  static const String readyNotProductionActive =
      'FOUNDATION_READY_NOT_PRODUCTION_ACTIVE';
  static const String blockedFoundation = 'BLOCKED_FOUNDATION';
  static const String blockedAdversarial = 'BLOCKED_ADVERSARIAL';
  static const String blockedInvalidMetadata = 'BLOCKED_INVALID_METADATA';

  static const Set<String> values = <String>{
    readyNotProductionActive,
    blockedFoundation,
    blockedAdversarial,
    blockedInvalidMetadata,
  };
}

class AgentCrossAgentSupervisorAdversarialScenarioId {
  AgentCrossAgentSupervisorAdversarialScenarioId._();

  static const String agentImpersonation = 'AGENT_IMPERSONATION';
  static const String fakeApproval = 'FAKE_APPROVAL';
  static const String privilegeEscalation = 'PRIVILEGE_ESCALATION';
  static const String conflictingAgentInstructions =
      'CONFLICTING_AGENT_INSTRUCTIONS';
  static const String duplicateExecution = 'DUPLICATE_EXECUTION';
  static const String supervisorAuthorityAbuse = 'SUPERVISOR_AUTHORITY_ABUSE';
  static const String emergencyStopBypass = 'EMERGENCY_STOP_BYPASS';
  static const String providerGeneratedAuthority =
      'PROVIDER_GENERATED_FAKE_AUTHORITY';
  static const String ownerAdminBypass = 'OWNER_ADMIN_BYPASS';
  static const String permissionBypass = 'PERMISSION_ENGINE_BYPASS';
  static const String approvalBypass = 'APPROVAL_ENGINE_BYPASS';
  static const String runtimeGateBypass = 'RUNTIME_GATE_BYPASS';
  static const String guardianBypass = 'GUARDIAN_SECURITY_BYPASS';
  static const String masterAiBypass = 'MASTER_AI_CONTROL_BYPASS';
  static const String costBudgetBypass = 'COST_BUDGET_BYPASS';
  static const String mandatoryAuditBypass = 'MANDATORY_AUDIT_BYPASS';
  static const String loopRetryStorm = 'LOOP_OR_RETRY_STORM';
  static const String businessExecution = 'SUPERVISOR_BUSINESS_EXECUTION';
  static const String securityControlWeakening = 'SECURITY_CONTROL_WEAKENING';

  static const Set<String> values = <String>{
    agentImpersonation,
    fakeApproval,
    privilegeEscalation,
    conflictingAgentInstructions,
    duplicateExecution,
    supervisorAuthorityAbuse,
    emergencyStopBypass,
    providerGeneratedAuthority,
    ownerAdminBypass,
    permissionBypass,
    approvalBypass,
    runtimeGateBypass,
    guardianBypass,
    masterAiBypass,
    costBudgetBypass,
    mandatoryAuditBypass,
    loopRetryStorm,
    businessExecution,
    securityControlWeakening,
  };
}

class AgentCrossAgentSupervisorCloseoutLimits {
  AgentCrossAgentSupervisorCloseoutLimits._();

  static const int opaqueIdMaxLength = 220;
  static const int maxScenarios = 32;
  static const int maxReasonCodes = 32;
}

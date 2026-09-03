class AgentCrossAgentSupervisorDecisionStatus {
  AgentCrossAgentSupervisorDecisionStatus._();

  static const String observeOnly = 'OBSERVE_ONLY';
  static const String recommendHold = 'RECOMMEND_HOLD';
  static const String recommendStop = 'RECOMMEND_STOP';
  static const String escalateOwnerAdmin = 'ESCALATE_OWNER_ADMIN';
  static const String recommendHoldAndEscalate = 'RECOMMEND_HOLD_AND_ESCALATE';
  static const String recommendStopAndEscalate = 'RECOMMEND_STOP_AND_ESCALATE';

  static const Set<String> values = <String>{
    observeOnly,
    recommendHold,
    recommendStop,
    escalateOwnerAdmin,
    recommendHoldAndEscalate,
    recommendStopAndEscalate,
  };
}

class AgentCrossAgentSupervisorSecurityAuthority {
  AgentCrossAgentSupervisorSecurityAuthority._();

  static const String permissionEngine = 'PERMISSION_ENGINE';
  static const String approvalEngine = 'APPROVAL_ENGINE';
  static const String runtimeGate = 'RUNTIME_GATE';
  static const String guardianSecurity = 'GUARDIAN_SECURITY';
  static const String ownerSuperAdminControls = 'OWNER_SUPER_ADMIN_CONTROLS';
  static const String masterAiControls = 'MASTER_AI_CONTROLS';
  static const String emergencyStopControls = 'EMERGENCY_STOP_CONTROLS';
  static const String costBudgetControls = 'COST_BUDGET_CONTROLS';
  static const String mandatoryAuditRequirements =
      'MANDATORY_AUDIT_REQUIREMENTS';

  static const Set<String> values = <String>{
    permissionEngine,
    approvalEngine,
    runtimeGate,
    guardianSecurity,
    ownerSuperAdminControls,
    masterAiControls,
    emergencyStopControls,
    costBudgetControls,
    mandatoryAuditRequirements,
  };
}

class AgentCrossAgentSupervisorContractLimits {
  AgentCrossAgentSupervisorContractLimits._();

  static const int opaqueIdMaxLength = 220;
  static const int maxReasonCodes = 20;
}

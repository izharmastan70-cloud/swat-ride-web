import '../constants/agent_cross_agent_supervisor_contract_constants.dart';

class AgentCrossAgentSupervisorAuthorityContract {
  const AgentCrossAgentSupervisorAuthorityContract();

  Set<String> get securityAuthoritiesAboveSupervisor =>
      AgentCrossAgentSupervisorSecurityAuthority.values;

  bool get supervisorIsSuperAdmin => false;
  bool get supervisorIsSecurityAuthority => false;
  bool get securityAuthorityAlwaysAboveSupervisor => true;

  bool get mayBypassPermissionEngine => false;
  bool get mayDisablePermissionEngine => false;
  bool get mayWeakenPermissionEngine => false;
  bool get mayOverridePermissionEngine => false;
  bool get mayModifyPermissionEngine => false;

  bool get mayBypassApprovalEngine => false;
  bool get mayDisableApprovalEngine => false;
  bool get mayWeakenApprovalEngine => false;
  bool get mayOverrideApprovalEngine => false;
  bool get mayModifyApprovalEngine => false;

  bool get mayBypassRuntimeGate => false;
  bool get mayDisableRuntimeGate => false;
  bool get mayWeakenRuntimeGate => false;
  bool get mayOverrideRuntimeGate => false;
  bool get mayModifyRuntimeGate => false;

  bool get mayBypassGuardianSecurity => false;
  bool get mayDisableGuardianSecurity => false;
  bool get mayWeakenGuardianSecurity => false;
  bool get mayOverrideGuardianSecurity => false;
  bool get mayModifyGuardianSecurity => false;

  bool get mayBypassOwnerSuperAdminControls => false;
  bool get mayDisableOwnerSuperAdminControls => false;
  bool get mayWeakenOwnerSuperAdminControls => false;
  bool get mayOverrideOwnerSuperAdminControls => false;
  bool get mayModifyOwnerSuperAdminControls => false;

  bool get mayBypassMasterAiControls => false;
  bool get mayDisableMasterAiControls => false;
  bool get mayWeakenMasterAiControls => false;
  bool get mayOverrideMasterAiControls => false;
  bool get mayModifyMasterAiControls => false;

  bool get mayBypassEmergencyStopControls => false;
  bool get mayDisableEmergencyStopControls => false;
  bool get mayWeakenEmergencyStopControls => false;
  bool get mayOverrideEmergencyStopControls => false;
  bool get mayModifyEmergencyStopControls => false;

  bool get mayBypassCostBudgetControls => false;
  bool get mayDisableCostBudgetControls => false;
  bool get mayWeakenCostBudgetControls => false;
  bool get mayOverrideCostBudgetControls => false;
  bool get mayModifyCostBudgetControls => false;

  bool get mayBypassMandatoryAudit => false;
  bool get mayDisableMandatoryAudit => false;
  bool get mayWeakenMandatoryAudit => false;
  bool get mayOverrideMandatoryAudit => false;
  bool get mayModifyMandatoryAudit => false;

  bool get mayGrantSelfPermission => false;
  bool get mayGrantOtherAgentPermission => false;
  bool get mayGrantSelfAuthority => false;
  bool get mayGrantOtherAgentAuthority => false;
  bool get mayCreateApproval => false;
  bool get mayConsumeApproval => false;
  bool get mayExpandScope => false;
  bool get mayAssignPrivilegedRole => false;
  bool get mayExecuteBusinessAction => false;

  bool get mayRecommendHold => true;
  bool get mayRecommendStop => true;
  bool get mayEscalateOwnerAdmin => true;
  bool get mayObserveCoordinationState => true;

  bool get duplicatesPermissionEngine => false;
  bool get duplicatesApprovalEngine => false;
  bool get duplicatesRuntimeGate => false;
  bool get duplicatesGuardianSecurity => false;
  bool get usesAuthoritativeSecurityOutcomesOnly => true;

  bool get actualEnforcementOwnedBySecurityLayer => true;
  bool get ownerAdminRestrictedWorkRequiresAuthority => true;
  bool get mandatoryAuditCannotBeSkipped => true;
  bool get coreAppFailureIsolationRequired => true;
}

import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_cross_agent_supervisor_contract_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_cross_agent_supervisor_authority_contract.dart';
import 'package:swat_ride/ai_agent/models/agent_cross_agent_supervisor_request.dart';
import 'package:swat_ride/ai_agent/models/agent_cross_agent_supervisor_security_snapshot.dart';
import 'package:swat_ride/ai_agent/services/agent_cross_agent_supervisor_contract_service.dart';
import 'package:swat_ride/ai_agent/services/agent_cross_agent_supervisor_security_authority_policy.dart';

void main() {
  const AgentCrossAgentSupervisorAuthorityContract contract =
      AgentCrossAgentSupervisorAuthorityContract();

  const AgentCrossAgentSupervisorSecurityAuthorityPolicy policy =
      AgentCrossAgentSupervisorSecurityAuthorityPolicy();

  const AgentCrossAgentSupervisorContractService service =
      AgentCrossAgentSupervisorContractService();

  AgentCrossAgentSupervisorSecuritySnapshot snapshot({
    bool permission = true,
    bool approval = true,
    bool runtime = true,
    bool guardian = true,
    bool ownerControl = true,
    bool masterAi = true,
    bool emergencyClear = true,
    bool costBudget = true,
    bool audit = true,
    bool restrictedAction = false,
    bool ownerAdminAuthority = true,
  }) {
    return AgentCrossAgentSupervisorSecuritySnapshot(
      permissionDecisionRef: 'permission:decision:1',
      approvalDecisionRef: 'approval:decision:1',
      runtimeGateDecisionRef: 'runtime:decision:1',
      guardianSecurityDecisionRef: 'guardian:decision:1',
      ownerSuperAdminControlRef: 'owner:control:1',
      masterAiControlRef: 'master:ai:control:1',
      emergencyStopDecisionRef: 'emergency:stop:1',
      costBudgetDecisionRef: 'cost:budget:1',
      mandatoryAuditDecisionRef: 'audit:decision:1',
      permissionSatisfied: permission,
      approvalSatisfied: approval,
      runtimeGateSatisfied: runtime,
      guardianSecuritySatisfied: guardian,
      ownerSuperAdminControlSatisfied: ownerControl,
      masterAiControlSatisfied: masterAi,
      emergencyStopClear: emergencyClear,
      costBudgetSatisfied: costBudget,
      mandatoryAuditSatisfied: audit,
      restrictedAction: restrictedAction,
      ownerAdminAuthorityPresent: ownerAdminAuthority,
    );
  }

  AgentCrossAgentSupervisorRequest request(
    AgentCrossAgentSupervisorSecuritySnapshot securitySnapshot,
  ) {
    return AgentCrossAgentSupervisorRequest(
      requestId: 'supervisor:req:1',
      taskId: 'task:1',
      sourceAgentId: 'ride_agent',
      targetAgentId: 'finance_agent',
      actionId: 'action:test',
      securitySnapshot: securitySnapshot,
    );
  }

  group('Phase 60 Step 1B contract/security authority boundary', () {
    test('6 recommendation-only decision states are locked', () {
      expect(AgentCrossAgentSupervisorDecisionStatus.values.length, 6);
    });

    test('9 authoritative security layers are locked', () {
      expect(AgentCrossAgentSupervisorSecurityAuthority.values.length, 9);
    });

    test('Supervisor is never Super Admin/security authority', () {
      expect(contract.supervisorIsSuperAdmin, false);
      expect(contract.supervisorIsSecurityAuthority, false);
      expect(contract.securityAuthorityAlwaysAboveSupervisor, true);
    });

    test('Permission Engine can never be weakened or overridden', () {
      expect(contract.mayBypassPermissionEngine, false);
      expect(contract.mayDisablePermissionEngine, false);
      expect(contract.mayWeakenPermissionEngine, false);
      expect(contract.mayOverridePermissionEngine, false);
      expect(contract.mayModifyPermissionEngine, false);
    });

    test('Approval Engine can never be weakened or overridden', () {
      expect(contract.mayBypassApprovalEngine, false);
      expect(contract.mayDisableApprovalEngine, false);
      expect(contract.mayWeakenApprovalEngine, false);
      expect(contract.mayOverrideApprovalEngine, false);
      expect(contract.mayModifyApprovalEngine, false);
    });

    test('Runtime Gate can never be weakened or overridden', () {
      expect(contract.mayBypassRuntimeGate, false);
      expect(contract.mayDisableRuntimeGate, false);
      expect(contract.mayWeakenRuntimeGate, false);
      expect(contract.mayOverrideRuntimeGate, false);
      expect(contract.mayModifyRuntimeGate, false);
    });

    test('Guardian Security can never be weakened or overridden', () {
      expect(contract.mayBypassGuardianSecurity, false);
      expect(contract.mayDisableGuardianSecurity, false);
      expect(contract.mayWeakenGuardianSecurity, false);
      expect(contract.mayOverrideGuardianSecurity, false);
      expect(contract.mayModifyGuardianSecurity, false);
    });

    test('Owner/Super Admin controls remain above Supervisor', () {
      expect(contract.mayBypassOwnerSuperAdminControls, false);
      expect(contract.mayDisableOwnerSuperAdminControls, false);
      expect(contract.mayWeakenOwnerSuperAdminControls, false);
      expect(contract.mayOverrideOwnerSuperAdminControls, false);
      expect(contract.mayModifyOwnerSuperAdminControls, false);
    });

    test('Master AI controls remain above Supervisor', () {
      expect(contract.mayBypassMasterAiControls, false);
      expect(contract.mayDisableMasterAiControls, false);
      expect(contract.mayWeakenMasterAiControls, false);
      expect(contract.mayOverrideMasterAiControls, false);
      expect(contract.mayModifyMasterAiControls, false);
    });

    test('Emergency Stop remains above Supervisor', () {
      expect(contract.mayBypassEmergencyStopControls, false);
      expect(contract.mayDisableEmergencyStopControls, false);
      expect(contract.mayWeakenEmergencyStopControls, false);
      expect(contract.mayOverrideEmergencyStopControls, false);
      expect(contract.mayModifyEmergencyStopControls, false);
    });

    test('Cost/budget controls remain above Supervisor', () {
      expect(contract.mayBypassCostBudgetControls, false);
      expect(contract.mayDisableCostBudgetControls, false);
      expect(contract.mayWeakenCostBudgetControls, false);
      expect(contract.mayOverrideCostBudgetControls, false);
      expect(contract.mayModifyCostBudgetControls, false);
    });

    test('Mandatory audit can never be skipped/modified', () {
      expect(contract.mayBypassMandatoryAudit, false);
      expect(contract.mayDisableMandatoryAudit, false);
      expect(contract.mayWeakenMandatoryAudit, false);
      expect(contract.mayOverrideMandatoryAudit, false);
      expect(contract.mayModifyMandatoryAudit, false);
    });

    test('Supervisor cannot grant itself or other Agent authority', () {
      expect(contract.mayGrantSelfPermission, false);
      expect(contract.mayGrantOtherAgentPermission, false);
      expect(contract.mayGrantSelfAuthority, false);
      expect(contract.mayGrantOtherAgentAuthority, false);
      expect(contract.mayCreateApproval, false);
      expect(contract.mayConsumeApproval, false);
      expect(contract.mayExpandScope, false);
      expect(contract.mayAssignPrivilegedRole, false);
      expect(contract.mayExecuteBusinessAction, false);
    });

    test('Supervisor may only coordinate/recommend/escalate', () {
      expect(contract.mayRecommendHold, true);
      expect(contract.mayRecommendStop, true);
      expect(contract.mayEscalateOwnerAdmin, true);
      expect(contract.mayObserveCoordinationState, true);
    });

    test('existing security engines are reused not duplicated', () {
      expect(contract.duplicatesPermissionEngine, false);
      expect(contract.duplicatesApprovalEngine, false);
      expect(contract.duplicatesRuntimeGate, false);
      expect(contract.duplicatesGuardianSecurity, false);
      expect(contract.usesAuthoritativeSecurityOutcomesOnly, true);
      expect(contract.actualEnforcementOwnedBySecurityLayer, true);
    });

    test('all authoritative outcomes satisfied => observe only', () {
      final result = service.evaluate(request(snapshot()));

      expect(
        result.status,
        AgentCrossAgentSupervisorDecisionStatus.observeOnly,
      );
      expect(result.recommendHold, false);
      expect(result.recommendStop, false);
      expect(result.escalateOwnerAdmin, false);
      expect(result.authorizesExecution, false);
    });

    test('Permission failure => STOP recommendation + escalation', () {
      final result = service.evaluate(request(snapshot(permission: false)));

      expect(
        result.status,
        AgentCrossAgentSupervisorDecisionStatus.recommendStopAndEscalate,
      );
      expect(result.recommendStop, true);
      expect(result.escalateOwnerAdmin, true);
    });

    test('Runtime Gate failure => STOP recommendation + escalation', () {
      final result = service.evaluate(request(snapshot(runtime: false)));

      expect(result.recommendStop, true);
      expect(result.escalateOwnerAdmin, true);
    });

    test('Guardian failure => STOP recommendation + escalation', () {
      final result = service.evaluate(request(snapshot(guardian: false)));

      expect(result.recommendStop, true);
      expect(result.escalateOwnerAdmin, true);
    });

    test('Emergency Stop active => STOP recommendation + escalation', () {
      final result = service.evaluate(request(snapshot(emergencyClear: false)));

      expect(result.recommendStop, true);
      expect(result.escalateOwnerAdmin, true);
    });

    test('Master AI control failure => HOLD + escalation', () {
      final result = service.evaluate(request(snapshot(masterAi: false)));

      expect(
        result.status,
        AgentCrossAgentSupervisorDecisionStatus.recommendHoldAndEscalate,
      );
      expect(result.recommendHold, true);
      expect(result.escalateOwnerAdmin, true);
    });

    test('Cost/budget failure => HOLD + escalation', () {
      final result = service.evaluate(request(snapshot(costBudget: false)));

      expect(result.recommendHold, true);
      expect(result.escalateOwnerAdmin, true);
    });

    test('Mandatory audit failure => HOLD + escalation', () {
      final result = service.evaluate(request(snapshot(audit: false)));

      expect(result.recommendHold, true);
      expect(result.escalateOwnerAdmin, true);
    });

    test('restricted work without Approval => HOLD + escalation', () {
      final result = service.evaluate(
        request(snapshot(restrictedAction: true, approval: false)),
      );

      expect(result.recommendHold, true);
      expect(result.escalateOwnerAdmin, true);
    });

    test('restricted work without Owner/Admin authority => HOLD', () {
      final result = service.evaluate(
        request(snapshot(restrictedAction: true, ownerAdminAuthority: false)),
      );

      expect(result.recommendHold, true);
      expect(result.escalateOwnerAdmin, true);
    });

    test('security snapshot stores only opaque authority refs', () {
      final value = snapshot();

      expect(value.containsRawPermissionToken, false);
      expect(value.containsRawApprovalToken, false);
      expect(value.containsAuthSecret, false);
      expect(value.containsPrivatePayload, false);
      expect(value.supervisorComputedPermission, false);
      expect(value.supervisorComputedApproval, false);
      expect(value.supervisorComputedRuntimeAuthority, false);
      expect(value.supervisorComputedGuardianAuthority, false);
    });

    test('decision remains recommendation only', () {
      final result = service.evaluate(request(snapshot()));

      expect(result.recommendationOnly, true);
      expect(result.authorizesExecution, false);
      expect(result.actualEnforcementPerformedHere, false);
      expect(result.securityAuthorityAlwaysAboveSupervisor, true);
    });

    test('decision has no Permission/Approval/Business authority', () {
      final result = service.evaluate(request(snapshot()));

      expect(result.grantsPermission, false);
      expect(result.createsApproval, false);
      expect(result.consumesApproval, false);
      expect(result.expandsScope, false);
      expect(result.assignsPrivilegedRole, false);
      expect(result.executesBusinessAction, false);
    });

    test('decision cannot bypass any authoritative security layer', () {
      final result = service.evaluate(request(snapshot()));

      expect(result.bypassesPermissionEngine, false);
      expect(result.bypassesApprovalEngine, false);
      expect(result.bypassesRuntimeGate, false);
      expect(result.bypassesGuardianSecurity, false);
      expect(result.bypassesOwnerSuperAdminControls, false);
      expect(result.bypassesMasterAiControls, false);
      expect(result.bypassesEmergencyStopControls, false);
      expect(result.bypassesCostBudgetControls, false);
      expect(result.bypassesMandatoryAudit, false);
    });

    test('decision cannot mutate security/routing/provider/budget', () {
      final result = service.evaluate(request(snapshot()));

      expect(result.modifiesSecurityEngine, false);
      expect(result.mutatesRouting, false);
      expect(result.mutatesProviderState, false);
      expect(result.mutatesBudget, false);
      expect(result.changesSecret, false);
      expect(result.persistsDecision, false);
    });

    test('security policy consumes existing authority only', () {
      expect(policy.consumesAuthoritativeOutcomesOnly, true);
      expect(policy.recomputesPermissionAuthority, false);
      expect(policy.recomputesApprovalAuthority, false);
      expect(policy.recomputesRuntimeAuthority, false);
      expect(policy.recomputesGuardianAuthority, false);
      expect(policy.securityFailureFailsClosed, true);
    });

    test('all security authorities explicitly outrank Supervisor', () {
      expect(policy.permissionEngineOutranksSupervisor, true);
      expect(policy.approvalEngineOutranksSupervisor, true);
      expect(policy.runtimeGateOutranksSupervisor, true);
      expect(policy.guardianSecurityOutranksSupervisor, true);
      expect(policy.ownerSuperAdminControlsOutrankSupervisor, true);
      expect(policy.masterAiControlsOutrankSupervisor, true);
      expect(policy.emergencyStopOutranksSupervisor, true);
      expect(policy.costBudgetControlsOutrankSupervisor, true);
      expect(policy.mandatoryAuditOutranksSupervisor, true);
    });

    test('policy adds no execution/write authority', () {
      expect(policy.providerInvocationImplementedHere, false);
      expect(policy.businessExecutionImplementedHere, false);
      expect(policy.routingMutationImplementedHere, false);
      expect(policy.securityMutationImplementedHere, false);
      expect(policy.persistenceImplementedHere, false);
    });

    test('service permanent security hierarchy is locked', () {
      expect(service.supervisorIsCoordinationWatchdogOnly, true);
      expect(service.supervisorIsNotSuperAdmin, true);
      expect(service.securityAuthorityAlwaysAboveSupervisor, true);
      expect(service.supervisorCanGrantItselfAuthority, false);
      expect(service.supervisorCanGrantOtherAgentAuthority, false);
      expect(service.supervisorCanBypassSecurityEngine, false);
      expect(service.supervisorCanModifySecurityEngine, false);
      expect(service.supervisorCanExecuteBusinessAction, false);
    });

    test('service explicitly reuses every authority foundation', () {
      expect(service.reusesExistingPermissionAuthority, true);
      expect(service.reusesExistingApprovalAuthority, true);
      expect(service.reusesExistingRuntimeGateAuthority, true);
      expect(service.reusesExistingGuardianSecurityAuthority, true);
      expect(service.reusesExistingOwnerSuperAdminControls, true);
      expect(service.reusesExistingMasterAiControls, true);
      expect(service.reusesExistingEmergencyStopControls, true);
      expect(service.reusesExistingCostBudgetControls, true);
      expect(service.reusesExistingMandatoryAuditRequirements, true);
    });

    test('later Phase 60 responsibilities remain separate', () {
      expect(service.step1CConflictDetectionSeparate, true);
      expect(service.step1DTaskOwnershipSeparate, true);
      expect(service.step1EOwnerAdminAttentionSeparate, true);
      expect(service.step1FLoopFailureIsolationSeparate, true);
      expect(service.step1GFinalAdversarialSeparate, true);
    });

    test('core app failure isolation remains mandatory', () {
      expect(service.coreAppContinuesIfSupervisorFails, true);
      expect(
        service.ownerAdminRestrictedWorkCannotContinueWithoutAuthority,
        true,
      );
      expect(service.holdStopAreRecommendationsNotSecurityOverrides, true);
    });
  });
}

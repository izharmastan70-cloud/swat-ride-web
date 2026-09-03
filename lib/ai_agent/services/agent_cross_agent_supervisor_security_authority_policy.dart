import '../constants/agent_cross_agent_supervisor_contract_constants.dart';
import '../models/agent_cross_agent_supervisor_security_snapshot.dart';

class AgentCrossAgentSupervisorSecurityAuthorityPolicy {
  const AgentCrossAgentSupervisorSecurityAuthorityPolicy();

  String recommendationFor(AgentCrossAgentSupervisorSecuritySnapshot snapshot) {
    snapshot.validateStructure();

    if (!snapshot.emergencyStopClear ||
        !snapshot.guardianSecuritySatisfied ||
        !snapshot.permissionSatisfied ||
        !snapshot.runtimeGateSatisfied) {
      return AgentCrossAgentSupervisorDecisionStatus.recommendStopAndEscalate;
    }

    if (!snapshot.masterAiControlSatisfied ||
        !snapshot.costBudgetSatisfied ||
        !snapshot.mandatoryAuditSatisfied) {
      return AgentCrossAgentSupervisorDecisionStatus.recommendHoldAndEscalate;
    }

    if (snapshot.restrictedAction &&
        (!snapshot.approvalSatisfied ||
            !snapshot.ownerSuperAdminControlSatisfied ||
            !snapshot.ownerAdminAuthorityPresent)) {
      return AgentCrossAgentSupervisorDecisionStatus.recommendHoldAndEscalate;
    }

    if (!snapshot.approvalSatisfied ||
        !snapshot.ownerSuperAdminControlSatisfied) {
      return AgentCrossAgentSupervisorDecisionStatus.recommendHoldAndEscalate;
    }

    return AgentCrossAgentSupervisorDecisionStatus.observeOnly;
  }

  bool get consumesAuthoritativeOutcomesOnly => true;
  bool get recomputesPermissionAuthority => false;
  bool get recomputesApprovalAuthority => false;
  bool get recomputesRuntimeAuthority => false;
  bool get recomputesGuardianAuthority => false;

  bool get securityFailureFailsClosed => true;
  bool get restrictedWorkRequiresOwnerAdminAuthority => true;
  bool get emergencyStopOutranksSupervisor => true;
  bool get guardianSecurityOutranksSupervisor => true;
  bool get permissionEngineOutranksSupervisor => true;
  bool get approvalEngineOutranksSupervisor => true;
  bool get runtimeGateOutranksSupervisor => true;
  bool get ownerSuperAdminControlsOutrankSupervisor => true;
  bool get masterAiControlsOutrankSupervisor => true;
  bool get costBudgetControlsOutrankSupervisor => true;
  bool get mandatoryAuditOutranksSupervisor => true;

  bool get providerInvocationImplementedHere => false;
  bool get businessExecutionImplementedHere => false;
  bool get routingMutationImplementedHere => false;
  bool get securityMutationImplementedHere => false;
  bool get persistenceImplementedHere => false;
}

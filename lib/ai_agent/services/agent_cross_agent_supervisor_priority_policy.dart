import '../constants/agent_cross_agent_supervisor_coordination_constants.dart';
import '../models/agent_cross_agent_supervisor_priority_context.dart';

class AgentCrossAgentSupervisorPriorityPolicy {
  const AgentCrossAgentSupervisorPriorityPolicy();

  String classify(AgentCrossAgentSupervisorPriorityContext context) {
    if (!context.trustedPriorityMetadata) {
      return AgentCrossAgentCoordinationPriority.lowBackground;
    }

    if (context.emergencyOrSecurity) {
      return AgentCrossAgentCoordinationPriority.criticalEmergencySecurity;
    }

    if (context.approvedSensitive) {
      return AgentCrossAgentCoordinationPriority.highApprovedSensitive;
    }

    if (context.customerSupport) {
      return AgentCrossAgentCoordinationPriority.mediumCustomerSupport;
    }

    if (context.backgroundWork) {
      return AgentCrossAgentCoordinationPriority.lowBackground;
    }

    return AgentCrossAgentCoordinationPriority.normalOperational;
  }

  bool get trustedMetadataRequired => true;
  bool get highestRiskPriorityWins => true;

  bool get emergencySecurityAboveApprovedSensitive => true;
  bool get approvedSensitiveAboveCustomerSupport => true;
  bool get customerSupportAboveNormalOperational => true;
  bool get normalOperationalAboveBackground => true;

  bool get agentSelfPromotionForbidden => true;
  bool get rawUserTextPriorityAuthorityForbidden => true;
  bool get providerOutputPriorityAuthorityForbidden => true;

  bool get priorityCanBypassPermission => false;
  bool get priorityCanBypassApproval => false;
  bool get priorityCanBypassRuntimeGate => false;
  bool get priorityCanBypassGuardianSecurity => false;
  bool get priorityCanBypassEmergencyStop => false;
  bool get priorityCanBypassOwnerAdminControls => false;
  bool get priorityCanBypassMasterAiControls => false;
  bool get priorityCanBypassCostBudget => false;
  bool get priorityCanBypassMandatoryAudit => false;

  bool get queueMutationImplementedHere => false;
  bool get persistenceImplementedHere => false;
}

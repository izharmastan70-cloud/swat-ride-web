import '../models/agent_cross_agent_supervisor_attention_assessment.dart';
import '../models/agent_cross_agent_supervisor_attention_request.dart';
import '../models/agent_cross_agent_supervisor_owner_admin_escalation_handoff.dart';

class AgentCrossAgentSupervisorOwnerAdminEscalationPolicy {
  const AgentCrossAgentSupervisorOwnerAdminEscalationPolicy();

  AgentCrossAgentSupervisorOwnerAdminEscalationHandoff? prepare({
    required AgentCrossAgentSupervisorAttentionRequest request,
    required AgentCrossAgentSupervisorAttentionAssessment assessment,
  }) {
    if (!assessment.ownerAdminAttentionRequired) {
      return null;
    }

    final AgentCrossAgentSupervisorOwnerAdminEscalationHandoff handoff =
        AgentCrossAgentSupervisorOwnerAdminEscalationHandoff(
          handoffId: 'supervisor_attention:${request.requestId}',
          taskId: request.taskId,
          sourceAgentId: request.sourceAgentId,
          attentionLevel: assessment.level,
          securityDecisionReference: 'security_snapshot:${request.requestId}',
          conflictAssessmentReference:
              'conflict_assessment:${request.requestId}',
          coordinationDecisionReference:
              'coordination_decision:${request.requestId}',
          reasonCodes: assessment.reasons,
        );

    handoff.validateStructure();
    return handoff;
  }

  bool get opaqueMetadataOnly => true;
  bool get handoffCannotActAsApproval => true;
  bool get handoffCannotActAsPermission => true;
  bool get handoffCannotAuthorizeExecution => true;
  bool get ownerAdminMustActThroughAuthoritativeControls => true;

  bool get sendsNotificationHere => false;
  bool get persistsHandoffHere => false;
  bool get mutatesTaskHere => false;
  bool get executesBusinessActionHere => false;
  bool get modifiesSecurityEngineHere => false;
}

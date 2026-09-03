import '../models/agent_cross_agent_supervisor_attention_assessment.dart';
import '../models/agent_cross_agent_supervisor_attention_request.dart';
import '../models/agent_cross_agent_supervisor_owner_admin_escalation_handoff.dart';
import 'agent_cross_agent_supervisor_attention_policy.dart';
import 'agent_cross_agent_supervisor_owner_admin_escalation_policy.dart';

class AgentCrossAgentSupervisorAttentionResult {
  const AgentCrossAgentSupervisorAttentionResult({
    required this.assessment,
    required this.handoff,
  });

  final AgentCrossAgentSupervisorAttentionAssessment assessment;
  final AgentCrossAgentSupervisorOwnerAdminEscalationHandoff? handoff;
}

class AgentCrossAgentSupervisorAttentionService {
  const AgentCrossAgentSupervisorAttentionService({
    this.attentionPolicy = const AgentCrossAgentSupervisorAttentionPolicy(),
    this.escalationPolicy =
        const AgentCrossAgentSupervisorOwnerAdminEscalationPolicy(),
  });

  final AgentCrossAgentSupervisorAttentionPolicy attentionPolicy;
  final AgentCrossAgentSupervisorOwnerAdminEscalationPolicy escalationPolicy;

  AgentCrossAgentSupervisorAttentionResult evaluate(
    AgentCrossAgentSupervisorAttentionRequest request,
  ) {
    AgentCrossAgentSupervisorAttentionAssessment assessment;

    try {
      assessment = attentionPolicy.assess(request);
    } catch (_) {
      assessment = AgentCrossAgentSupervisorAttentionAssessment(
        level: 'OWNER_ADMIN_REVIEW',
        recommendHold: true,
        recommendStop: false,
        ownerAdminAttentionRequired: true,
        reasons: const <String>['invalid_attention_metadata', 'fail_closed'],
      );
      assessment.validateStructure();
    }

    final AgentCrossAgentSupervisorOwnerAdminEscalationHandoff? handoff =
        escalationPolicy.prepare(request: request, assessment: assessment);

    return AgentCrossAgentSupervisorAttentionResult(
      assessment: assessment,
      handoff: handoff,
    );
  }

  bool get attentionRecommendationOnly => true;
  bool get escalationMetadataOnly => true;

  bool get securityAuthorityAlwaysAboveSupervisor => true;
  bool get supervisorNeverBecomesOwnerAdmin => true;
  bool get supervisorCannotManufactureAuthority => true;
  bool get supervisorCannotGrantPermission => true;
  bool get supervisorCannotCreateOrConsumeApproval => true;
  bool get supervisorCannotExpandScope => true;
  bool get supervisorCannotExecuteBusinessAction => true;
  bool get supervisorCannotModifySecurityEngine => true;

  bool get notificationDeliveryImplementedHere => false;
  bool get persistenceImplementedHere => false;
  bool get taskMutationImplementedHere => false;

  bool get coreAppContinuesIfAttentionLayerFails => true;

  bool get step1FRetryLoopFailureIsolationSeparate => true;
  bool get step1GFinalAdversarialSeparate => true;
}

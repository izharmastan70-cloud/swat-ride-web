import '../constants/agent_cross_agent_supervisor_coordination_constants.dart';
import '../models/agent_cross_agent_supervisor_coordination_decision.dart';
import '../models/agent_cross_agent_supervisor_coordination_request.dart';
import 'agent_cross_agent_supervisor_priority_policy.dart';
import 'agent_cross_agent_supervisor_safe_ownership_policy.dart';

class AgentCrossAgentSupervisorCoordinationService {
  const AgentCrossAgentSupervisorCoordinationService({
    this.priorityPolicy = const AgentCrossAgentSupervisorPriorityPolicy(),
    this.ownershipPolicy = const AgentCrossAgentSupervisorSafeOwnershipPolicy(),
  });

  final AgentCrossAgentSupervisorPriorityPolicy priorityPolicy;
  final AgentCrossAgentSupervisorSafeOwnershipPolicy ownershipPolicy;

  AgentCrossAgentSupervisorCoordinationDecision coordinate(
    AgentCrossAgentSupervisorCoordinationRequest request,
  ) {
    try {
      request.validateStructure();
    } catch (_) {
      return _decision(
        status: AgentCrossAgentOwnershipStatus.holdSecurity,
        taskId: request.taskId.trim().isEmpty ? 'invalid_task' : request.taskId,
        priorityClass: AgentCrossAgentCoordinationPriority.lowBackground,
        owner: null,
        hold: true,
        escalate: true,
        reasons: const <String>['invalid_coordination_metadata', 'fail_closed'],
      );
    }

    final String priorityClass = priorityPolicy.classify(
      request.priorityContext,
    );

    if (!request.priorityContext.trustedPriorityMetadata) {
      return _decision(
        status: AgentCrossAgentOwnershipStatus.holdUntrustedPriority,
        taskId: request.taskId,
        priorityClass: priorityClass,
        owner: null,
        hold: true,
        escalate: true,
        reasons: const <String>[
          'untrusted_priority_metadata',
          'priority_self_promotion_forbidden',
          'fail_closed',
        ],
      );
    }

    if (!request.securitySnapshot.allMandatorySecuritySatisfied) {
      return _decision(
        status: AgentCrossAgentOwnershipStatus.holdSecurity,
        taskId: request.taskId,
        priorityClass: priorityClass,
        owner: null,
        hold: true,
        escalate: true,
        reasons: const <String>[
          'authoritative_security_outcome_unsatisfied',
          'priority_cannot_bypass_security',
          'security_authority_above_supervisor',
        ],
      );
    }

    if (!request.conflictAssessment.clean ||
        request.conflictAssessment.recommendHold ||
        request.conflictAssessment.recommendStop) {
      return _decision(
        status: AgentCrossAgentOwnershipStatus.holdConflict,
        taskId: request.taskId,
        priorityClass: priorityClass,
        owner: null,
        hold: true,
        escalate: true,
        reasons: const <String>[
          'step1c_conflict_or_wrong_work_not_clear',
          'ownership_recommendation_blocked',
          'fail_closed',
        ],
      );
    }

    final AgentCrossAgentSupervisorOwnershipEvaluation ownership =
        ownershipPolicy.evaluate(request);

    if (ownership.status != AgentCrossAgentOwnershipStatus.ownerRecommended) {
      return _decision(
        status: ownership.status,
        taskId: request.taskId,
        priorityClass: priorityClass,
        owner: null,
        hold: true,
        escalate: true,
        reasons: <String>[
          ownership.reasonCode,
          'safe_owner_not_uniquely_resolved',
          'step1e_attention_may_be_required',
        ],
      );
    }

    return _decision(
      status: AgentCrossAgentOwnershipStatus.ownerRecommended,
      taskId: request.taskId,
      priorityClass: priorityClass,
      owner: ownership.recommendedOwnerAgentId,
      hold: false,
      escalate: false,
      reasons: <String>[
        ownership.reasonCode,
        'owner_recommendation_only',
        'no_task_or_security_mutation',
      ],
    );
  }

  AgentCrossAgentSupervisorCoordinationDecision _decision({
    required String status,
    required String taskId,
    required String priorityClass,
    required String? owner,
    required bool hold,
    required bool escalate,
    required List<String> reasons,
  }) {
    final AgentCrossAgentSupervisorCoordinationDecision result =
        AgentCrossAgentSupervisorCoordinationDecision(
          status: status,
          taskId: taskId,
          priorityClass: priorityClass,
          recommendedOwnerAgentId: owner,
          recommendHold: hold,
          escalationRecommended: escalate,
          reasonCodes: reasons,
        );

    result.validateStructure();
    return result;
  }

  bool get ownerRecommendationOnly => true;
  bool get taskOwnerMutationImplementedHere => false;
  bool get queueMutationImplementedHere => false;
  bool get priorityMutationImplementedHere => false;

  bool get securityAuthorityAlwaysAboveSupervisor => true;
  bool get priorityCanNeverBypassSecurity => true;
  bool get conflictMustBeClearBeforeOwnership => true;
  bool get authoritativeEligibilityRequired => true;

  bool get supervisorCanGrantPermission => false;
  bool get supervisorCanCreateApproval => false;
  bool get supervisorCanExpandScope => false;
  bool get supervisorCanAssignPrivilegedRole => false;
  bool get supervisorCanExecuteBusinessAction => false;
  bool get supervisorCanModifySecurityEngine => false;

  bool get coreAppContinuesIfCoordinationFails => true;

  bool get step1EOwnerAdminAttentionSeparate => true;
  bool get step1FLoopFailureIsolationSeparate => true;
  bool get step1GFinalAdversarialSeparate => true;
}

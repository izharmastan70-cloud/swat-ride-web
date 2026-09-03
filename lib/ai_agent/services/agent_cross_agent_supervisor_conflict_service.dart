import '../constants/agent_cross_agent_supervisor_contract_constants.dart';
import '../constants/agent_cross_agent_supervisor_conflict_constants.dart';
import '../models/agent_cross_agent_supervisor_conflict_assessment.dart';
import '../models/agent_cross_agent_supervisor_conflict_finding.dart';
import '../models/agent_cross_agent_supervisor_conflict_input.dart';
import 'agent_cross_agent_supervisor_conflict_detection_policy.dart';

class AgentCrossAgentSupervisorConflictService {
  const AgentCrossAgentSupervisorConflictService({
    this.detectionPolicy =
        const AgentCrossAgentSupervisorConflictDetectionPolicy(),
  });

  final AgentCrossAgentSupervisorConflictDetectionPolicy detectionPolicy;

  AgentCrossAgentSupervisorConflictAssessment assess(
    AgentCrossAgentSupervisorConflictInput input,
  ) {
    List<AgentCrossAgentSupervisorConflictFinding> findings;

    try {
      findings = detectionPolicy.detect(input);
    } catch (_) {
      return _assessment(
        status:
            AgentCrossAgentSupervisorDecisionStatus.recommendHoldAndEscalate,
        findings: const <AgentCrossAgentSupervisorConflictFinding>[],
        hold: true,
        stop: false,
        escalate: true,
        reasons: const <String>[
          'invalid_conflict_detection_metadata',
          'fail_closed',
        ],
      );
    }

    if (findings.isEmpty) {
      return _assessment(
        status: AgentCrossAgentSupervisorDecisionStatus.observeOnly,
        findings: findings,
        hold: false,
        stop: false,
        escalate: false,
        reasons: const <String>[
          'no_conflict_wrong_work_or_duplicate_detected',
          'observation_only',
        ],
      );
    }

    final bool hasWrongWork = findings.any(
      (AgentCrossAgentSupervisorConflictFinding finding) =>
          finding.type == AgentCrossAgentConflictType.unauthorizedRoleWork ||
          finding.type == AgentCrossAgentConflictType.wrongModule ||
          finding.type == AgentCrossAgentConflictType.wrongScope,
    );

    final bool hasConflict = findings.any(
      (AgentCrossAgentSupervisorConflictFinding finding) =>
          finding.type == AgentCrossAgentConflictType.conflictingOutcome,
    );

    final bool hasDuplicateOrReplay = findings.any(
      (AgentCrossAgentSupervisorConflictFinding finding) =>
          finding.type == AgentCrossAgentConflictType.duplicateWork ||
          finding.type == AgentCrossAgentConflictType.staleOrReplayWork,
    );

    if (hasWrongWork) {
      return _assessment(
        status:
            AgentCrossAgentSupervisorDecisionStatus.recommendStopAndEscalate,
        findings: findings,
        hold: false,
        stop: true,
        escalate: true,
        reasons: const <String>[
          'wrong_work_or_authoritative_eligibility_failure',
          'recommend_stop_and_owner_admin_escalation',
          'security_authority_remains_above_supervisor',
        ],
      );
    }

    if (hasConflict) {
      return _assessment(
        status:
            AgentCrossAgentSupervisorDecisionStatus.recommendHoldAndEscalate,
        findings: findings,
        hold: true,
        stop: false,
        escalate: true,
        reasons: const <String>[
          'cross_agent_conflicting_outcomes_detected',
          'recommend_hold_and_owner_admin_escalation',
          'task_ownership_not_assigned_here',
        ],
      );
    }

    if (hasDuplicateOrReplay) {
      return _assessment(
        status: AgentCrossAgentSupervisorDecisionStatus.recommendHold,
        findings: findings,
        hold: true,
        stop: false,
        escalate: false,
        reasons: const <String>[
          'duplicate_or_stale_replay_work_detected',
          'recommend_hold_to_prevent_duplicate_execution',
        ],
      );
    }

    return _assessment(
      status: AgentCrossAgentSupervisorDecisionStatus.recommendHoldAndEscalate,
      findings: findings,
      hold: true,
      stop: false,
      escalate: true,
      reasons: const <String>[
        'unclassified_coordination_conflict',
        'fail_closed',
      ],
    );
  }

  AgentCrossAgentSupervisorConflictAssessment _assessment({
    required String status,
    required List<AgentCrossAgentSupervisorConflictFinding> findings,
    required bool hold,
    required bool stop,
    required bool escalate,
    required List<String> reasons,
  }) {
    final AgentCrossAgentSupervisorConflictAssessment result =
        AgentCrossAgentSupervisorConflictAssessment(
          status: status,
          findings: findings,
          recommendHold: hold,
          recommendStop: stop,
          escalateOwnerAdmin: escalate,
          reasonCodes: reasons,
        );

    result.validateStructure();
    return result;
  }

  bool get detectsBeforeBusinessExecution => true;
  bool get duplicateExecutionPreventionRecommendationOnly => true;
  bool get conflictResolutionAuthorityImplementedHere => false;
  bool get taskOwnershipAssignmentImplementedHere => false;
  bool get securityAuthorityAlwaysAboveSupervisor => true;

  bool get supervisorCanGrantPermission => false;
  bool get supervisorCanCreateApproval => false;
  bool get supervisorCanExpandScope => false;
  bool get supervisorCanExecuteBusinessAction => false;
  bool get supervisorCanModifySecurityEngine => false;

  bool get coreAppContinuesIfConflictDetectorFails => true;

  bool get step1DTaskOwnershipSeparate => true;
  bool get step1EOwnerAdminAttentionSeparate => true;
  bool get step1FLoopFailureIsolationSeparate => true;
  bool get step1GFinalAdversarialSeparate => true;
}

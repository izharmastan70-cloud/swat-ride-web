import '../constants/agent_cross_agent_supervisor_contract_constants.dart';
import '../models/agent_cross_agent_supervisor_authority_contract.dart';
import '../models/agent_cross_agent_supervisor_decision.dart';
import '../models/agent_cross_agent_supervisor_request.dart';
import 'agent_cross_agent_supervisor_security_authority_policy.dart';

class AgentCrossAgentSupervisorContractService {
  const AgentCrossAgentSupervisorContractService({
    this.authorityContract = const AgentCrossAgentSupervisorAuthorityContract(),
    this.securityPolicy =
        const AgentCrossAgentSupervisorSecurityAuthorityPolicy(),
  });

  final AgentCrossAgentSupervisorAuthorityContract authorityContract;
  final AgentCrossAgentSupervisorSecurityAuthorityPolicy securityPolicy;

  AgentCrossAgentSupervisorDecision evaluate(
    AgentCrossAgentSupervisorRequest request,
  ) {
    try {
      request.validateStructure();
    } catch (_) {
      return _decision(
        status:
            AgentCrossAgentSupervisorDecisionStatus.recommendHoldAndEscalate,
        requestId: request.requestId.trim().isEmpty
            ? 'invalid_request'
            : request.requestId,
        hold: true,
        stop: false,
        escalate: true,
        reasons: const <String>[
          'invalid_supervisor_request_metadata',
          'fail_closed',
        ],
      );
    }

    final String recommendation = securityPolicy.recommendationFor(
      request.securitySnapshot,
    );

    return switch (recommendation) {
      AgentCrossAgentSupervisorDecisionStatus.observeOnly => _decision(
        status: recommendation,
        requestId: request.requestId,
        hold: false,
        stop: false,
        escalate: false,
        reasons: const <String>[
          'authoritative_security_outcomes_satisfied',
          'supervisor_observation_only',
          'no_execution_authority_granted',
        ],
      ),
      AgentCrossAgentSupervisorDecisionStatus.recommendStopAndEscalate =>
        _decision(
          status: recommendation,
          requestId: request.requestId,
          hold: false,
          stop: true,
          escalate: true,
          reasons: const <String>[
            'authoritative_security_stop_condition',
            'recommend_stop_and_owner_admin_escalation',
            'actual_enforcement_remains_with_security_layer',
          ],
        ),
      _ => _decision(
        status:
            AgentCrossAgentSupervisorDecisionStatus.recommendHoldAndEscalate,
        requestId: request.requestId,
        hold: true,
        stop: false,
        escalate: true,
        reasons: const <String>[
          'authoritative_security_or_owner_admin_requirement_unsatisfied',
          'recommend_hold_and_owner_admin_escalation',
          'actual_enforcement_remains_with_security_layer',
        ],
      ),
    };
  }

  AgentCrossAgentSupervisorDecision _decision({
    required String status,
    required String requestId,
    required bool hold,
    required bool stop,
    required bool escalate,
    required List<String> reasons,
  }) {
    final AgentCrossAgentSupervisorDecision result =
        AgentCrossAgentSupervisorDecision(
          status: status,
          requestId: requestId,
          recommendHold: hold,
          recommendStop: stop,
          escalateOwnerAdmin: escalate,
          reasonCodes: reasons,
        );

    result.validateStructure();
    return result;
  }

  bool get supervisorIsCoordinationWatchdogOnly => true;
  bool get supervisorIsNotSuperAdmin => true;
  bool get securityAuthorityAlwaysAboveSupervisor => true;

  bool get reusesExistingPermissionAuthority => true;
  bool get reusesExistingApprovalAuthority => true;
  bool get reusesExistingRuntimeGateAuthority => true;
  bool get reusesExistingGuardianSecurityAuthority => true;
  bool get reusesExistingOwnerSuperAdminControls => true;
  bool get reusesExistingMasterAiControls => true;
  bool get reusesExistingEmergencyStopControls => true;
  bool get reusesExistingCostBudgetControls => true;
  bool get reusesExistingMandatoryAuditRequirements => true;

  bool get supervisorCanGrantItselfAuthority => false;
  bool get supervisorCanGrantOtherAgentAuthority => false;
  bool get supervisorCanBypassSecurityEngine => false;
  bool get supervisorCanModifySecurityEngine => false;
  bool get supervisorCanExecuteBusinessAction => false;

  bool get holdStopAreRecommendationsNotSecurityOverrides => true;
  bool get ownerAdminRestrictedWorkCannotContinueWithoutAuthority => true;
  bool get coreAppContinuesIfSupervisorFails => true;

  bool get step1CConflictDetectionSeparate => true;
  bool get step1DTaskOwnershipSeparate => true;
  bool get step1EOwnerAdminAttentionSeparate => true;
  bool get step1FLoopFailureIsolationSeparate => true;
  bool get step1GFinalAdversarialSeparate => true;
}

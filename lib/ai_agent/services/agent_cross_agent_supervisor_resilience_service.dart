import '../constants/agent_cross_agent_supervisor_resilience_constants.dart';
import '../models/agent_cross_agent_supervisor_resilience_assessment.dart';
import '../models/agent_cross_agent_supervisor_resilience_input.dart';
import 'agent_cross_agent_supervisor_failure_isolation_policy.dart';
import 'agent_cross_agent_supervisor_loop_deadlock_detection_policy.dart';

class AgentCrossAgentSupervisorResilienceService {
  const AgentCrossAgentSupervisorResilienceService({
    this.detectionPolicy =
        const AgentCrossAgentSupervisorLoopDeadlockDetectionPolicy(),
    this.failureIsolationPolicy =
        const AgentCrossAgentSupervisorFailureIsolationPolicy(),
  });

  final AgentCrossAgentSupervisorLoopDeadlockDetectionPolicy detectionPolicy;

  final AgentCrossAgentSupervisorFailureIsolationPolicy failureIsolationPolicy;

  AgentCrossAgentSupervisorResilienceAssessment assess(
    AgentCrossAgentSupervisorResilienceInput input,
  ) {
    try {
      input.validateStructure();
    } catch (_) {
      return _result(
        status: AgentCrossAgentSupervisorResilienceStatus.holdInvalidMetadata,
        hold: true,
        stop: false,
        escalate: true,
        degraded: true,
        reasons: const <String>['invalid_resilience_metadata', 'fail_closed'],
      );
    }

    if (!input.authoritativeSecuritySatisfied) {
      return _result(
        status: AgentCrossAgentSupervisorResilienceStatus.holdSecurity,
        hold: true,
        stop: false,
        escalate: true,
        degraded: false,
        reasons: const <String>[
          'authoritative_security_unsatisfied',
          'resilience_logic_cannot_override_security',
        ],
      );
    }

    if (!input.supervisorHealthy) {
      return _result(
        status:
            AgentCrossAgentSupervisorResilienceStatus.degradedSupervisorFailure,
        hold: true,
        stop: false,
        escalate: true,
        degraded: true,
        reasons: const <String>[
          'supervisor_coordination_unhealthy',
          'ai_coordination_degraded',
          'core_app_continues',
        ],
      );
    }

    if (detectionPolicy.hasAgentFighting(input)) {
      return _result(
        status: AgentCrossAgentSupervisorResilienceStatus.stopAgentFighting,
        hold: false,
        stop: true,
        escalate: true,
        degraded: false,
        reasons: const <String>[
          'anti_agent_fighting_threshold_reached',
          'recommend_stop_and_owner_admin_escalation',
          'no_automatic_rollback_execution',
        ],
      );
    }

    if (detectionPolicy.hasAgentLoop(input)) {
      return _result(
        status: AgentCrossAgentSupervisorResilienceStatus.holdLoop,
        hold: true,
        stop: false,
        escalate: true,
        degraded: false,
        reasons: const <String>[
          'cross_agent_handoff_loop_detected',
          'recommend_hold_and_owner_admin_escalation',
        ],
      );
    }

    if (detectionPolicy.hasDeadlock(input)) {
      return _result(
        status: AgentCrossAgentSupervisorResilienceStatus.holdDeadlock,
        hold: true,
        stop: false,
        escalate: true,
        degraded: false,
        reasons: const <String>[
          'no_progress_or_excessive_handoff_deadlock',
          'recommend_hold_and_owner_admin_escalation',
        ],
      );
    }

    if (detectionPolicy.hasRetryStorm(input)) {
      return _result(
        status: AgentCrossAgentSupervisorResilienceStatus.holdRetryStorm,
        hold: true,
        stop: false,
        escalate: true,
        degraded: false,
        reasons: const <String>[
          'retry_or_repeated_failure_storm_detected',
          'recommend_hold_and_owner_admin_escalation',
        ],
      );
    }

    if (!input.providerAvailable) {
      return _result(
        status:
            AgentCrossAgentSupervisorResilienceStatus.degradedProviderFailure,
        hold: true,
        stop: false,
        escalate: false,
        degraded: true,
        reasons: const <String>[
          'provider_unavailable',
          'ai_coordination_degraded',
          'core_app_continues',
          'no_auto_paid_or_provider_activation',
        ],
      );
    }

    return _result(
      status: AgentCrossAgentSupervisorResilienceStatus.clean,
      hold: false,
      stop: false,
      escalate: false,
      degraded: false,
      reasons: const <String>[
        'no_loop_deadlock_retry_storm_or_agent_fighting',
        'failure_isolation_clear',
      ],
    );
  }

  AgentCrossAgentSupervisorResilienceAssessment _result({
    required String status,
    required bool hold,
    required bool stop,
    required bool escalate,
    required bool degraded,
    required List<String> reasons,
  }) {
    final AgentCrossAgentSupervisorResilienceAssessment result =
        AgentCrossAgentSupervisorResilienceAssessment(
          status: status,
          recommendHold: hold,
          recommendStop: stop,
          escalationRecommended: escalate,
          aiCoordinationDegraded: degraded,
          coreAppContinues: true,
          reasonCodes: reasons,
        );

    result.validateStructure();
    return result;
  }

  bool get recommendationOnly => true;
  bool get securityAuthorityAlwaysAboveSupervisor => true;

  bool get detectsLoopsBeforeFurtherCoordination => true;
  bool get detectsDeadlockBeforeFurtherCoordination => true;
  bool get detectsRetryStormBeforeFurtherCoordination => true;
  bool get detectsAgentFightingBeforeFurtherCoordination => true;

  bool get providerFailureIsolatedFromCoreApp => true;
  bool get supervisorFailureIsolatedFromCoreApp => true;
  bool get coreAppAlwaysContinues => true;

  bool get supervisorCanGrantPermission => false;
  bool get supervisorCanCreateApproval => false;
  bool get supervisorCanExpandScope => false;
  bool get supervisorCanExecuteRollback => false;
  bool get supervisorCanSwitchProvider => false;
  bool get supervisorCanActivatePaidAi => false;
  bool get supervisorCanIncreaseBudget => false;
  bool get supervisorCanExecuteBusinessAction => false;
  bool get supervisorCanModifySecurityEngine => false;

  bool get queueMutationImplementedHere => false;
  bool get taskOwnerMutationImplementedHere => false;
  bool get persistenceImplementedHere => false;

  bool get step1GFinalAdversarialSeparate => true;
}

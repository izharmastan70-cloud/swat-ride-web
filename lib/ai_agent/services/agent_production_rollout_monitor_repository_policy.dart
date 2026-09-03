import '../constants/agent_production_rollout_repository_constants.dart';
import '../models/agent_production_rollout_repository_models.dart';
import 'agent_production_rollout_monitor_plan_binding_service.dart';

class AgentProductionRolloutRepositoryPrecheckDecision {
  const AgentProductionRolloutRepositoryPrecheckDecision({
    required this.allowed,
    required this.status,
    required this.reasonCode,
  });

  final bool allowed;
  final String status;
  final String reasonCode;
}

class AgentProductionRolloutMonitorRepositoryPolicy {
  const AgentProductionRolloutMonitorRepositoryPolicy({
    this.bindingService =
        const AgentProductionRolloutMonitorPlanBindingService(),
  });

  final AgentProductionRolloutMonitorPlanBindingService bindingService;

  AgentProductionRolloutRepositoryPrecheckDecision evaluate({
    required AgentProductionRolloutMonitorExecutionRequest request,
    required DateTime nowUtc,
    required bool executionArmed,
  }) {
    try {
      request.validate();
    } on FormatException {
      return const AgentProductionRolloutRepositoryPrecheckDecision(
        allowed: false,
        status: AgentProductionRolloutRepositoryStatus.blockedInvalidPlan,
        reasonCode: 'execution_request_validation_failed',
      );
    }

    if (!executionArmed) {
      return const AgentProductionRolloutRepositoryPrecheckDecision(
        allowed: false,
        status: AgentProductionRolloutRepositoryStatus.blockedNotArmed,
        reasonCode:
            'phase66_monitor_repository_is_not_armed_for_live_execution',
      );
    }

    final String expectedPlanFingerprint = bindingService.fingerprint(
      request.plan,
    );

    final String expectedIdempotencyKey = bindingService.idempotencyKey(
      request.plan,
    );

    if (request.planFingerprintSha256.toLowerCase() !=
            expectedPlanFingerprint ||
        request.idempotencyKeySha256.toLowerCase() != expectedIdempotencyKey) {
      return const AgentProductionRolloutRepositoryPrecheckDecision(
        allowed: false,
        status: AgentProductionRolloutRepositoryStatus.blockedInvalidPlan,
        reasonCode: 'plan_or_idempotency_sha256_binding_mismatch',
      );
    }

    final DateTime now = nowUtc.toUtc();

    if (now.isBefore(request.plan.precondition.createdAtUtc) ||
        !now.isBefore(request.plan.precondition.expiresAtUtc)) {
      return const AgentProductionRolloutRepositoryPrecheckDecision(
        allowed: false,
        status:
            AgentProductionRolloutRepositoryStatus.blockedExpiredPrecondition,
        reasonCode: 'atomic_precondition_not_current',
      );
    }

    if (request.plan.autoTrafficPercent != 0 ||
        request.plan.businessWriteTrafficPercent != 0 ||
        !request.plan.channelsRemainDisabledExceptAppChat ||
        request.plan.targetLocalAiEnabled ||
        request.plan.targetPaidCodeAiEnabled ||
        request.plan.targetPaidReasoningEnabled ||
        request.plan.targetCallAgentEnabled) {
      return const AgentProductionRolloutRepositoryPrecheckDecision(
        allowed: false,
        status: AgentProductionRolloutRepositoryStatus.blockedInvalidPlan,
        reasonCode: 'initial_monitor_only_plan_contains_forbidden_authority',
      );
    }

    return const AgentProductionRolloutRepositoryPrecheckDecision(
      allowed: true,
      status: 'PRECHECK_ALLOWED',
      reasonCode:
          'exact_monitor_only_plan_is_eligible_for_transactional_guard_checks',
    );
  }

  bool get policyOnly => true;
  bool get writesFirestore => false;
  bool get activatesProduction => false;
}

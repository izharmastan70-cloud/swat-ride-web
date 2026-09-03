import '../constants/agent_ecosystem_resilience_safety_constants.dart';
import '../models/agent_ecosystem_resilience_safety_decision.dart';
import '../models/agent_ecosystem_resilience_safety_request.dart';

class AgentEcosystemResilienceSafetyPolicy {
  const AgentEcosystemResilienceSafetyPolicy();

  AgentEcosystemResilienceSafetyDecision evaluate(
    AgentEcosystemResilienceSafetyRequest request,
  ) {
    if (request.rawConversationSelfTrainingRequested ||
        request.directProductionPromptReplacementRequested) {
      return _decision(
        status:
            AgentEcosystemResilienceDecisionStatus.blockUnrestrictedTraining,
        routeTo: AgentEcosystemResilienceRoute.blocked,
        reasonCode:
            'training_data_is_not_authority_and_direct_production_replacement_is_forbidden',
      );
    }

    if (!request.coreSwatRideIsolationVerified) {
      return _decision(
        status:
            AgentEcosystemResilienceDecisionStatus.blockCoreIsolationFailure,
        routeTo: AgentEcosystemResilienceRoute.blocked,
        reasonCode: 'core_swat_ride_failure_isolation_not_verified',
      );
    }

    if (!request.auditReady) {
      return _decision(
        status: AgentEcosystemResilienceDecisionStatus.blockAuditUnavailable,
        routeTo: AgentEcosystemResilienceRoute.auditGate,
        reasonCode: 'critical_transition_audit_not_ready',
      );
    }

    if (!request.evaluationPassed) {
      return _decision(
        status: AgentEcosystemResilienceDecisionStatus.blockEvaluationRequired,
        routeTo: AgentEcosystemResilienceRoute.evaluationGate,
        reasonCode: 'offline_evaluation_required',
      );
    }

    if (!request.ownerApprovalVerified) {
      return _decision(
        status:
            AgentEcosystemResilienceDecisionStatus.blockOwnerApprovalRequired,
        routeTo: AgentEcosystemResilienceRoute.ownerApprovalGate,
        reasonCode: 'owner_approval_required_for_meaningful_change',
      );
    }

    if (!request.exactVersionIdentityBound) {
      return _decision(
        status: AgentEcosystemResilienceDecisionStatus.blockVersionBinding,
        routeTo: AgentEcosystemResilienceRoute.versionGate,
        reasonCode: 'exact_immutable_version_identity_required',
      );
    }

    if (!request.testEnvironmentPassed) {
      return _decision(
        status: AgentEcosystemResilienceDecisionStatus.blockTestEnvironment,
        routeTo: AgentEcosystemResilienceRoute.testEnvironmentGate,
        reasonCode: 'test_environment_must_pass_before_rollout',
      );
    }

    final rollbackNeeded =
        request.rollbackRequested || !request.monitoringHealthy;

    if (rollbackNeeded) {
      if (!request.knownGoodRollbackTargetExact) {
        return _decision(
          status:
              AgentEcosystemResilienceDecisionStatus.blockRollbackTargetUnknown,
          routeTo: AgentEcosystemResilienceRoute.rollbackReview,
          reasonCode: 'known_good_rollback_target_must_be_exact_no_guessing',
        );
      }

      if (!request.rollbackReadinessVerified) {
        return _decision(
          status: AgentEcosystemResilienceDecisionStatus.blockRollbackNotReady,
          routeTo: AgentEcosystemResilienceRoute.rollbackReview,
          reasonCode: 'rollback_readiness_must_be_verified',
        );
      }

      return _decision(
        status: AgentEcosystemResilienceDecisionStatus.rollbackRequestEligible,
        routeTo: AgentEcosystemResilienceRoute.rollbackReview,
        reasonCode: 'rollback_request_eligible_no_automatic_rollback_execution',
      );
    }

    if (!request.primaryProviderAvailable) {
      if (request.fallbackProviderAvailable && request.fallbackPolicyAllows) {
        return _decision(
          status: AgentEcosystemResilienceDecisionStatus
              .safeProviderFallbackEligible,
          routeTo: AgentEcosystemResilienceRoute.providerFallbackReview,
          reasonCode:
              'fallback_eligible_under_existing_provider_privacy_cost_security_policy',
        );
      }

      return _decision(
        status:
            AgentEcosystemResilienceDecisionStatus.aiUnavailableCoreContinues,
        routeTo: AgentEcosystemResilienceRoute.aiUnavailable,
        reasonCode: 'ai_provider_unavailable_core_swat_ride_continues',
      );
    }

    return _decision(
      status: AgentEcosystemResilienceDecisionStatus.monitoredHandoffEligible,
      routeTo: AgentEcosystemResilienceRoute.monitoredHandoff,
      reasonCode:
          'safety_evidence_ready_handoff_only_phase66_activation_still_required',
    );
  }

  AgentEcosystemResilienceSafetyDecision _decision({
    required String status,
    required String routeTo,
    required String reasonCode,
  }) {
    return AgentEcosystemResilienceSafetyDecision(
      status: status,
      routeTo: routeTo,
      reasonCode: reasonCode,
      auditRequired: true,
    );
  }

  bool get coordinationOnly => true;
  bool get trainsModel => false;
  bool get replacesProductionPrompt => false;
  bool get activatesVersion => false;
  bool get deploysProduction => false;
  bool get executesRollback => false;
  bool get callsProvider => false;
  bool get changesProviderPolicy => false;
  bool get changesCostLimits => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get readsFirestore => false;
  bool get writesFirestore => false;
  bool get writesBusinessData => false;
  bool get activatesProduction => false;
}

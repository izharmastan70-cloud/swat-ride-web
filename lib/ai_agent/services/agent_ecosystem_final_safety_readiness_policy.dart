import '../constants/agent_ecosystem_final_safety_readiness_constants.dart';
import '../models/agent_ecosystem_final_safety_readiness_request.dart';
import '../models/agent_ecosystem_final_safety_readiness_result.dart';

class AgentEcosystemFinalSafetyReadinessPolicy {
  const AgentEcosystemFinalSafetyReadinessPolicy();

  AgentEcosystemFinalSafetyReadinessResult assess(
    AgentEcosystemFinalSafetyReadinessRequest request,
  ) {
    request.validate();

    final allStepEvidence =
        request.step1BVerified &&
        request.step1CVerified &&
        request.step1DVerified &&
        request.step1EVerified &&
        request.step1FVerified;

    if (!allStepEvidence) {
      return _blocked(
        AgentEcosystemFinalSafetyReadinessStatus.blockedStepEvidence,
        'phase65_step_evidence_incomplete',
      );
    }

    if (request.channelCoverageCount !=
        AgentEcosystemFinalSafetyReadinessCounts.requiredChannels) {
      return _blocked(
        AgentEcosystemFinalSafetyReadinessStatus.blockedChannelCoverage,
        'exactly_5_channel_families_required',
      );
    }

    if (request.agentSafetyCoverageCount !=
        AgentEcosystemFinalSafetyReadinessCounts.requiredAgentSafetyAreas) {
      return _blocked(
        AgentEcosystemFinalSafetyReadinessStatus.blockedAgentControlCoverage,
        'exactly_10_agent_safety_control_areas_required',
      );
    }

    if (request.attackCoverageCount !=
        AgentEcosystemFinalSafetyReadinessCounts.requiredAttackCases) {
      return _blocked(
        AgentEcosystemFinalSafetyReadinessStatus.blockedAttackCoverage,
        'exactly_9_attack_security_cases_required',
      );
    }

    if (!request.permanentRulesVerified ||
        !request.callAgentExactFourVerified) {
      return _blocked(
        AgentEcosystemFinalSafetyReadinessStatus.blockedPermanentRules,
        'permanent_safety_rules_or_call_agent_exact_four_not_verified',
      );
    }

    if (!request.coreSwatRideFailureIsolationVerified) {
      return _blocked(
        AgentEcosystemFinalSafetyReadinessStatus.blockedCoreFailureIsolation,
        'core_swat_ride_failure_isolation_required',
      );
    }

    if (request.productionRuntimeActivated ||
        request.anyAgentAutoEnabledByPhase65 ||
        request.providerExecutionActivatedByPhase65 ||
        request.businessExecutionActivatedByPhase65 ||
        !request.phase66ControlledRolloutRequired) {
      return _blocked(
        AgentEcosystemFinalSafetyReadinessStatus
            .blockedUnexpectedProductionActivation,
        'phase65_must_not_activate_runtime_or_bypass_phase66',
      );
    }

    return AgentEcosystemFinalSafetyReadinessResult(
      status: AgentEcosystemFinalSafetyReadinessStatus
          .readyForPhase66ControlledRollout,
      reasonCode:
          'phase65_complete_foundation_ready_for_phase66_controlled_rollout_not_production_active',
      phase66HandoffEligible: true,
    );
  }

  AgentEcosystemFinalSafetyReadinessResult _blocked(
    String status,
    String reasonCode,
  ) {
    return AgentEcosystemFinalSafetyReadinessResult(
      status: status,
      reasonCode: reasonCode,
      phase66HandoffEligible: false,
    );
  }

  bool get auditOnly => true;
  bool get activatesProductionRuntime => false;
  bool get changesAgentMode => false;
  bool get enablesAuto => false;
  bool get callsProvider => false;
  bool get sendsMessage => false;
  bool get movesMoney => false;
  bool get readsFirestore => false;
  bool get writesFirestore => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get overridesRuntimeGate => false;
  bool get changesEmergencyStop => false;
  bool get changesKillSwitch => false;
  bool get deploysPromptOrModel => false;
  bool get executesRollback => false;
  bool get writesBusinessData => false;
}

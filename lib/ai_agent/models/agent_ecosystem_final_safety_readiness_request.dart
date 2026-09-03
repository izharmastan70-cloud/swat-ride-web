import '../constants/agent_ecosystem_final_safety_readiness_constants.dart';

class AgentEcosystemFinalSafetyReadinessRequest {
  AgentEcosystemFinalSafetyReadinessRequest({
    required this.step1BVerified,
    required this.step1CVerified,
    required this.step1DVerified,
    required this.step1EVerified,
    required this.step1FVerified,
    required this.channelCoverageCount,
    required this.agentSafetyCoverageCount,
    required this.attackCoverageCount,
    required this.permanentRulesVerified,
    required this.coreSwatRideFailureIsolationVerified,
    required this.callAgentExactFourVerified,
    required this.productionRuntimeActivated,
    required this.anyAgentAutoEnabledByPhase65,
    required this.providerExecutionActivatedByPhase65,
    required this.businessExecutionActivatedByPhase65,
    required this.phase66ControlledRolloutRequired,
  }) {
    validate();
  }

  final bool step1BVerified;
  final bool step1CVerified;
  final bool step1DVerified;
  final bool step1EVerified;
  final bool step1FVerified;

  final int channelCoverageCount;
  final int agentSafetyCoverageCount;
  final int attackCoverageCount;

  final bool permanentRulesVerified;
  final bool coreSwatRideFailureIsolationVerified;
  final bool callAgentExactFourVerified;

  final bool productionRuntimeActivated;
  final bool anyAgentAutoEnabledByPhase65;
  final bool providerExecutionActivatedByPhase65;
  final bool businessExecutionActivatedByPhase65;

  final bool phase66ControlledRolloutRequired;

  bool get phase65IsAuditOnly => true;

  void validate() {
    if (channelCoverageCount < 0 ||
        agentSafetyCoverageCount < 0 ||
        attackCoverageCount < 0) {
      throw const FormatException('Negative Phase 65 safety coverage count.');
    }

    if (channelCoverageCount >
            AgentEcosystemFinalSafetyReadinessCounts.requiredChannels ||
        agentSafetyCoverageCount >
            AgentEcosystemFinalSafetyReadinessCounts.requiredAgentSafetyAreas ||
        attackCoverageCount >
            AgentEcosystemFinalSafetyReadinessCounts.requiredAttackCases) {
      throw const FormatException(
        'Phase 65 safety coverage exceeds locked roadmap count.',
      );
    }
  }
}

import '../constants/agent_ecosystem_final_safety_readiness_constants.dart';

class AgentEcosystemFinalSafetyReadinessResult {
  AgentEcosystemFinalSafetyReadinessResult({
    required this.status,
    required this.reasonCode,
    required this.phase66HandoffEligible,
  }) {
    validate();
  }

  final String status;
  final String reasonCode;
  final bool phase66HandoffEligible;

  bool get phase65Complete =>
      status ==
      AgentEcosystemFinalSafetyReadinessStatus.readyForPhase66ControlledRollout;

  bool get productionRuntimeActivated => false;
  bool get anyAgentAutoEnabled => false;
  bool get providerExecutionActivated => false;
  bool get businessExecutionActivated => false;

  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayOverrideRuntimeGate => false;
  bool get mayDisableEmergencyStop => false;
  bool get mayChangeKillSwitch => false;
  bool get mayDeployPromptOrModel => false;
  bool get mayExecuteRollback => false;
  bool get mayCallProvider => false;
  bool get maySendMessage => false;
  bool get mayMoveMoney => false;
  bool get mayReadPrivateData => false;
  bool get mayWriteBusinessData => false;
  bool get mayChangeRolloutStage => false;

  void validate() {
    if (!AgentEcosystemFinalSafetyReadinessStatus.values.contains(status) ||
        reasonCode.trim().isEmpty ||
        (phase66HandoffEligible &&
            status !=
                AgentEcosystemFinalSafetyReadinessStatus
                    .readyForPhase66ControlledRollout)) {
      throw const FormatException(
        'Invalid final ecosystem safety readiness result.',
      );
    }
  }
}

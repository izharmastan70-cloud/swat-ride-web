class AgentEcosystemFinalSafetyReadinessStatus {
  AgentEcosystemFinalSafetyReadinessStatus._();

  static const String blockedStepEvidence = 'BLOCKED_STEP_EVIDENCE';
  static const String blockedChannelCoverage = 'BLOCKED_CHANNEL_COVERAGE';
  static const String blockedAgentControlCoverage =
      'BLOCKED_AGENT_CONTROL_COVERAGE';
  static const String blockedAttackCoverage = 'BLOCKED_ATTACK_COVERAGE';
  static const String blockedPermanentRules = 'BLOCKED_PERMANENT_RULES';
  static const String blockedCoreFailureIsolation =
      'BLOCKED_CORE_FAILURE_ISOLATION';
  static const String blockedUnexpectedProductionActivation =
      'BLOCKED_UNEXPECTED_PRODUCTION_ACTIVATION';
  static const String readyForPhase66ControlledRollout =
      'READY_FOR_PHASE66_CONTROLLED_ROLLOUT';

  static const Set<String> values = <String>{
    blockedStepEvidence,
    blockedChannelCoverage,
    blockedAgentControlCoverage,
    blockedAttackCoverage,
    blockedPermanentRules,
    blockedCoreFailureIsolation,
    blockedUnexpectedProductionActivation,
    readyForPhase66ControlledRollout,
  };
}

class AgentEcosystemFinalSafetyReadinessCounts {
  AgentEcosystemFinalSafetyReadinessCounts._();

  static const int requiredChannels = 5;
  static const int requiredAgentSafetyAreas = 10;
  static const int requiredAttackCases = 9;
  static const int requiredPhase65ImplementationSteps = 5;
}

class AgentEcosystemPhase66RolloutStage {
  AgentEcosystemPhase66RolloutStage._();

  static const String off = 'OFF';
  static const String monitorOnly = 'MONITOR_ONLY';
  static const String suggestOnly = 'SUGGEST_ONLY';
  static const String askFirst = 'ASK_FIRST';
  static const String limitedAuto = 'LIMITED_AUTO';
  static const String fullSafeAuto = 'FULL_SAFE_AUTO';

  static const List<String> controlledOrder = <String>[
    off,
    monitorOnly,
    suggestOnly,
    askFirst,
    limitedAuto,
    fullSafeAuto,
  ];
}

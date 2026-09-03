class AgentVersionContract {
  AgentVersionContract._();

  static const String contractVersion = 'phase62_agent_version_v1';

  static const int opaqueIdMaxLength = 220;
  static const int changeCodeMaxLength = 120;
  static const int sha256HexLength = 64;
}

class AgentVersionLifecycleStatus {
  AgentVersionLifecycleStatus._();

  static const String proposed = 'PROPOSED';
  static const String offlineEvaluated = 'OFFLINE_EVALUATED';
  static const String testReady = 'TEST_READY';
  static const String limitedRolloutReady = 'LIMITED_ROLLOUT_READY';
  static const String monitored = 'MONITORED';
  static const String fullRolloutEligible = 'FULL_ROLLOUT_ELIGIBLE';
  static const String rollbackEligible = 'ROLLBACK_ELIGIBLE';
  static const String retired = 'RETIRED';

  static const Set<String> values = <String>{
    proposed,
    offlineEvaluated,
    testReady,
    limitedRolloutReady,
    monitored,
    fullRolloutEligible,
    rollbackEligible,
    retired,
  };
}

class AgentVersionChangeType {
  AgentVersionChangeType._();

  static const String behaviorPrompt = 'BEHAVIOR_PROMPT';
  static const String modelOrProvider = 'MODEL_OR_PROVIDER';
  static const String orchestrationStrategy = 'ORCHESTRATION_STRATEGY';
  static const String toolSelectionPolicy = 'TOOL_SELECTION_POLICY';
  static const String knowledgeReference = 'KNOWLEDGE_REFERENCE';
  static const String outputFormatting = 'OUTPUT_FORMATTING';

  static const String protectedSystemSecurityRules =
      'PROTECTED_SYSTEM_SECURITY_RULES';
  static const String protectedPermissions = 'PROTECTED_PERMISSIONS';
  static const String protectedApprovals = 'PROTECTED_APPROVALS';
  static const String protectedProviderPolicy = 'PROTECTED_PROVIDER_POLICY';
  static const String protectedCostLimits = 'PROTECTED_COST_LIMITS';
  static const String protectedProductionAuthority =
      'PROTECTED_PRODUCTION_AUTHORITY';

  static const Set<String> versionableValues = <String>{
    behaviorPrompt,
    modelOrProvider,
    orchestrationStrategy,
    toolSelectionPolicy,
    knowledgeReference,
    outputFormatting,
  };

  static const Set<String> protectedAuthorityValues = <String>{
    protectedSystemSecurityRules,
    protectedPermissions,
    protectedApprovals,
    protectedProviderPolicy,
    protectedCostLimits,
    protectedProductionAuthority,
  };

  static const Set<String> values = <String>{
    ...versionableValues,
    ...protectedAuthorityValues,
  };
}

class AgentVersionChangeRisk {
  AgentVersionChangeRisk._();

  static const String low = 'LOW';
  static const String medium = 'MEDIUM';
  static const String high = 'HIGH';
  static const String blockedProtectedAuthority = 'BLOCKED_PROTECTED_AUTHORITY';

  static const Set<String> values = <String>{
    low,
    medium,
    high,
    blockedProtectedAuthority,
  };
}

import '../constants/agent_provider_task_routing_constants.dart';

class AgentProviderContextTokenBudget {
  const AgentProviderContextTokenBudget({
    required this.estimatedInputTokens,
    required this.requestedMaxOutputTokens,
    this.safetyReserveTokens =
        AgentProviderTaskRoutingLimits.defaultSafetyReserveTokens,
  });

  /// Metadata estimate produced elsewhere. Raw prompt is not stored here.
  final int estimatedInputTokens;
  final int requestedMaxOutputTokens;
  final int safetyReserveTokens;

  int get totalReservedTokens =>
      estimatedInputTokens + requestedMaxOutputTokens + safetyReserveTokens;

  bool fits({
    required int modelMaxContextTokens,
    required int modelMaxOutputTokens,
  }) {
    return estimatedInputTokens >= 0 &&
        requestedMaxOutputTokens > 0 &&
        safetyReserveTokens >= 0 &&
        requestedMaxOutputTokens <= modelMaxOutputTokens &&
        totalReservedTokens <= modelMaxContextTokens;
  }

  bool get rawPromptStored => false;
  bool get rawConversationStored => false;
  bool get tokenizerImplementedHere => false;
  bool get automaticTruncationImplementedHere => false;
  bool get tokenChargeImplementedHere => false;
  bool get costChargeImplementedHere => false;
  bool get mutatesBudget => false;
  bool get invokesProvider => false;
  bool get persistsBudget => false;

  void validateStructure() {
    if (estimatedInputTokens < 0 ||
        estimatedInputTokens >
            AgentProviderTaskRoutingLimits.absoluteMaxContextTokens ||
        requestedMaxOutputTokens <= 0 ||
        requestedMaxOutputTokens >
            AgentProviderTaskRoutingLimits.absoluteMaxOutputTokens ||
        safetyReserveTokens < 0 ||
        safetyReserveTokens >
            AgentProviderTaskRoutingLimits.absoluteMaxContextTokens) {
      throw const FormatException('Invalid provider context token budget.');
    }
  }
}

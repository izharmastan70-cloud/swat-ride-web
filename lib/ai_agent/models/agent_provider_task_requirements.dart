import '../constants/agent_provider_expansion_contract_constants.dart';
import '../constants/agent_provider_task_routing_constants.dart';

class AgentProviderTaskRequirements {
  AgentProviderTaskRequirements({
    required this.requestId,
    required this.taskType,
    required Set<String> requiredCapabilities,
    required this.requiresStructuredOutput,
    required this.requiresVisionInput,
    required this.minimumNecessaryContextConfirmed,
  }) : requiredCapabilities = Set<String>.unmodifiable(requiredCapabilities);

  final String requestId;
  final String taskType;
  final Set<String> requiredCapabilities;
  final bool requiresStructuredOutput;
  final bool requiresVisionInput;

  /// Caller confirms context has already been minimized to what is
  /// reasonably necessary for the task.
  final bool minimumNecessaryContextConfirmed;

  bool get containsRawPrompt => false;
  bool get containsRawConversation => false;
  bool get containsRawUserMessage => false;
  bool get tokenizerRunsHere => false;
  bool get truncatesContentHere => false;
  bool get invokesProvider => false;
  bool get chargesTokens => false;
  bool get mutatesBudget => false;
  bool get grantsPermission => false;
  bool get executesBusinessAction => false;
  bool get persistsRequest => false;

  void validateStructure() {
    if (!_validId(requestId) ||
        !AgentProviderTaskType.values.contains(taskType) ||
        requiredCapabilities.isEmpty ||
        requiredCapabilities.any(
          (String capability) =>
              !AgentProviderExpansionCapability.values.contains(capability),
        )) {
      throw const FormatException('Invalid provider task requirements.');
    }
  }

  bool _validId(String value) {
    final String trimmed = value.trim();

    return trimmed.isNotEmpty &&
        trimmed.length <= AgentProviderTaskRoutingLimits.idMax &&
        RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
  }
}

import '../constants/agent_provider_expansion_contract_constants.dart';
import '../constants/agent_provider_task_routing_constants.dart';

class AgentProviderTaskCapabilityMatrix {
  const AgentProviderTaskCapabilityMatrix();

  Set<String> requiredCapabilitiesFor(String taskType) {
    switch (taskType) {
      case AgentProviderTaskType.generalReasoning:
        return const <String>{AgentProviderExpansionCapability.textReasoning};

      case AgentProviderTaskType.structuredResponse:
        return const <String>{
          AgentProviderExpansionCapability.textReasoning,
          AgentProviderExpansionCapability.structuredJson,
        };

      case AgentProviderTaskType.summarization:
        return const <String>{AgentProviderExpansionCapability.summarization};

      case AgentProviderTaskType.classification:
        return const <String>{AgentProviderExpansionCapability.classification};

      case AgentProviderTaskType.translation:
        return const <String>{AgentProviderExpansionCapability.translation};

      case AgentProviderTaskType.visionUnderstanding:
        return const <String>{
          AgentProviderExpansionCapability.visionInput,
          AgentProviderExpansionCapability.textReasoning,
        };

      case AgentProviderTaskType.codeReasoning:
        return const <String>{AgentProviderExpansionCapability.codeReasoning};

      case AgentProviderTaskType.embeddingGeneration:
        return const <String>{AgentProviderExpansionCapability.embeddings};

      case AgentProviderTaskType.contentDraft:
        return const <String>{
          AgentProviderExpansionCapability.textReasoning,
          AgentProviderExpansionCapability.structuredJson,
        };

      case AgentProviderTaskType.knowledgeAnswer:
        return const <String>{
          AgentProviderExpansionCapability.textReasoning,
          AgentProviderExpansionCapability.structuredJson,
        };

      default:
        return const <String>{};
    }
  }

  bool requiresStructuredOutput(String taskType) {
    return taskType == AgentProviderTaskType.structuredResponse ||
        taskType == AgentProviderTaskType.contentDraft ||
        taskType == AgentProviderTaskType.knowledgeAnswer;
  }

  bool requiresVisionInput(String taskType) {
    return taskType == AgentProviderTaskType.visionUnderstanding;
  }

  bool get mappingIsDeterministicMetadata => true;
  bool get providerRankingOwnedHere => false;
  bool get qualityScoringOwnedHere => false;
  bool get invokesProvider => false;
  bool get grantsAuthority => false;
  bool get persistsMatrix => false;
}

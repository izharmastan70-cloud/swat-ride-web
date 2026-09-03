import '../constants/agent_provider_expansion_contract_constants.dart';
import '../constants/agent_provider_task_routing_constants.dart';

class AgentProviderModelCompatibilityProfile {
  AgentProviderModelCompatibilityProfile({
    required this.providerId,
    required this.modelReference,
    required this.enabled,
    required this.backendOnly,
    required Set<String> supportedCapabilities,
    required this.maxContextTokens,
    required this.maxOutputTokens,
    required this.supportsStructuredOutput,
    required this.supportsVisionInput,
  }) : supportedCapabilities = Set<String>.unmodifiable(supportedCapabilities);

  final String providerId;
  final String modelReference;
  final bool enabled;
  final bool backendOnly;
  final Set<String> supportedCapabilities;
  final int maxContextTokens;
  final int maxOutputTokens;
  final bool supportsStructuredOutput;
  final bool supportsVisionInput;

  bool get metadataOnly => true;
  bool get containsRawApiKey => false;
  bool get containsRawToken => false;
  bool get containsRawSecret => false;
  bool get clientMayExecuteModel => false;
  bool get qualityScoreOwnedHere => false;
  bool get providerRankingOwnedHere => false;
  bool get invokesProvider => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get persistsProfile => false;

  void validateStructure() {
    if (providerId.trim().isEmpty ||
        modelReference.trim().isEmpty ||
        modelReference.length > AgentProviderTaskRoutingLimits.modelRefMax ||
        supportedCapabilities.isEmpty ||
        supportedCapabilities.any(
          (String capability) =>
              !AgentProviderExpansionCapability.values.contains(capability),
        ) ||
        maxContextTokens <= 0 ||
        maxContextTokens >
            AgentProviderTaskRoutingLimits.absoluteMaxContextTokens ||
        maxOutputTokens <= 0 ||
        maxOutputTokens >
            AgentProviderTaskRoutingLimits.absoluteMaxOutputTokens ||
        maxOutputTokens > maxContextTokens) {
      throw const FormatException(
        'Invalid provider model compatibility profile.',
      );
    }
  }
}

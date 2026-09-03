import '../constants/agent_provider_expansion_contract_constants.dart';

class AgentProviderCapabilityDescriptor {
  const AgentProviderCapabilityDescriptor({
    required this.providerId,
    required this.capability,
    required this.supported,
    required this.requiresBackend,
    required this.requiresPaidBudget,
  });

  final String providerId;
  final String capability;
  final bool supported;
  final bool requiresBackend;
  final bool requiresPaidBudget;

  bool get metadataOnly => true;
  bool get qualityScoreOwnedHere => false;
  bool get providerRankingOwnedHere => false;
  bool get grantsAuthority => false;
  bool get executesBusinessAction => false;
  bool get invokesProvider => false;

  void validateStructure() {
    if (providerId.trim().isEmpty ||
        !AgentProviderExpansionCapability.values.contains(capability)) {
      throw const FormatException('Invalid provider capability descriptor.');
    }
  }
}

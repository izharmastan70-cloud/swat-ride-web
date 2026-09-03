import '../models/agent_provider_capability_descriptor.dart';
import '../models/agent_provider_expansion_contract.dart';

class AgentProviderCapabilityRegistry {
  const AgentProviderCapabilityRegistry();

  List<AgentProviderCapabilityDescriptor> describe(
    AgentProviderExpansionContract contract,
  ) {
    contract.validateStructure();

    final List<AgentProviderCapabilityDescriptor> result =
        contract.capabilities
            .map(
              (String capability) => AgentProviderCapabilityDescriptor(
                providerId: contract.providerId,
                capability: capability,
                supported: true,
                requiresBackend: true,
                requiresPaidBudget: contract.tier == 'PAID_LAST_ESCALATION',
              ),
            )
            .toList()
          ..sort(
            (
              AgentProviderCapabilityDescriptor a,
              AgentProviderCapabilityDescriptor b,
            ) => a.capability.compareTo(b.capability),
          );

    return List<AgentProviderCapabilityDescriptor>.unmodifiable(result);
  }

  bool supports(AgentProviderExpansionContract contract, String capability) {
    contract.validateStructure();
    return contract.capabilities.contains(capability);
  }

  bool get registryIsMetadataOnly => true;
  bool get qualityEvaluationOwnedHere => false;
  bool get rankingOwnedHere => false;
  bool get activatesProvider => false;
  bool get invokesProvider => false;
  bool get grantsPermission => false;
  bool get executesBusinessAction => false;
  bool get persistsRegistry => false;
}

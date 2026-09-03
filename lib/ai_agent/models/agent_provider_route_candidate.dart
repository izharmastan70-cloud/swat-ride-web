import '../constants/agent_provider_expansion_contract_constants.dart';
import '../constants/agent_provider_routing_resilience_constants.dart';

class AgentProviderRouteCandidate {
  const AgentProviderRouteCandidate({
    required this.providerId,
    required this.tier,
    required this.enabled,
    required this.backendEligible,
    required this.capabilitySupported,
    required this.healthy,
    required this.circuitStatus,
    required this.consecutiveFailures,
    required this.paidControlsSatisfied,
  });

  final String providerId;
  final String tier;
  final bool enabled;
  final bool backendEligible;
  final bool capabilitySupported;
  final bool healthy;
  final String circuitStatus;
  final int consecutiveFailures;

  /// For paid tier only. Must already represent existing paid ON/OFF,
  /// Ask Before Paid and budget controls. This model never approves/spends.
  final bool paidControlsSatisfied;

  bool get routableBase =>
      providerId.trim().isNotEmpty &&
      enabled &&
      backendEligible &&
      capabilitySupported &&
      healthy &&
      circuitStatus != AgentProviderCircuitStatus.open &&
      consecutiveFailures < AgentProviderResilienceLimits.failureThreshold;

  bool get routable =>
      routableBase &&
      (tier != AgentProviderExpansionTier.paidLastEscalation ||
          paidControlsSatisfied);

  bool get metadataOnly => true;
  bool get invokesProvider => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get mutatesBudget => false;
  bool get persistsCandidate => false;

  void validateStructure() {
    if (providerId.trim().isEmpty ||
        !AgentProviderExpansionTier.values.contains(tier) ||
        !AgentProviderCircuitStatus.values.contains(circuitStatus) ||
        consecutiveFailures < 0) {
      throw const FormatException('Invalid provider route candidate.');
    }
  }
}

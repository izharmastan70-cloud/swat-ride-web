import '../constants/agent_provider_routing_resilience_constants.dart';

class AgentProviderCircuitState {
  const AgentProviderCircuitState({
    required this.providerId,
    required this.status,
    required this.consecutiveFailures,
    required this.cooldownSeconds,
  });

  final String providerId;
  final String status;
  final int consecutiveFailures;
  final int cooldownSeconds;

  bool get open => status == AgentProviderCircuitStatus.open;

  bool get retryAllowed =>
      status == AgentProviderCircuitStatus.closed ||
      status == AgentProviderCircuitStatus.halfOpen;

  bool get timerImplementedHere => false;
  bool get schedulerImplementedHere => false;
  bool get persistsState => false;
  bool get invokesProvider => false;
  bool get executesBusinessAction => false;

  void validateStructure() {
    if (providerId.trim().isEmpty ||
        !AgentProviderCircuitStatus.values.contains(status) ||
        consecutiveFailures < 0 ||
        cooldownSeconds < 0) {
      throw const FormatException('Invalid provider circuit state.');
    }
  }
}

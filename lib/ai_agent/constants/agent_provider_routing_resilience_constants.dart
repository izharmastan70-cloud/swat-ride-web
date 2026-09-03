import 'agent_provider_expansion_contract_constants.dart';

class AgentProviderCircuitStatus {
  AgentProviderCircuitStatus._();

  static const String closed = 'CLOSED';
  static const String open = 'OPEN';
  static const String halfOpen = 'HALF_OPEN';

  static const Set<String> values = <String>{closed, open, halfOpen};
}

class AgentProviderResilientRouteStatus {
  AgentProviderResilientRouteStatus._();

  static const String routeFreeOnline = 'ROUTE_FREE_ONLINE';
  static const String routeLocalOptional = 'ROUTE_LOCAL_OPTIONAL';
  static const String routePaidLast = 'ROUTE_PAID_LAST';

  static const String noProviderRoute = 'NO_PROVIDER_ROUTE';

  static const String blockedInvalidInput = 'BLOCKED_INVALID_INPUT';

  static const Set<String> values = <String>{
    routeFreeOnline,
    routeLocalOptional,
    routePaidLast,
    noProviderRoute,
    blockedInvalidInput,
  };
}

class AgentProviderResilienceLimits {
  AgentProviderResilienceLimits._();

  static const int maxCandidates = 24;

  /// Consecutive failures required before circuit opens.
  static const int failureThreshold = 3;

  /// Metadata-only cooldown contract. No timer/scheduler is implemented here.
  static const int openCooldownSeconds = 60;

  static const int maxReasonCodes = 16;
}

class AgentProviderRoutingTierOrder {
  AgentProviderRoutingTierOrder._();

  static const Map<String, int> priority = <String, int>{
    AgentProviderExpansionTier.freeOnline: 100,
    AgentProviderExpansionTier.localOptional: 200,
    AgentProviderExpansionTier.paidLastEscalation: 300,
  };
}

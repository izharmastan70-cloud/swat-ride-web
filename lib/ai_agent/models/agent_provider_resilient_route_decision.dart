import '../constants/agent_provider_routing_resilience_constants.dart';

class AgentProviderResilientRouteDecision {
  AgentProviderResilientRouteDecision({
    required this.status,
    required this.selectedProviderId,
    required this.selectedTier,
    required List<String> skippedProviderIds,
    required List<String> reasonCodes,
  }) : skippedProviderIds = List<String>.unmodifiable(skippedProviderIds),
       reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String selectedProviderId;
  final String selectedTier;
  final List<String> skippedProviderIds;
  final List<String> reasonCodes;

  bool get hasRoute =>
      status == AgentProviderResilientRouteStatus.routeFreeOnline ||
      status == AgentProviderResilientRouteStatus.routeLocalOptional ||
      status == AgentProviderResilientRouteStatus.routePaidLast;

  bool get noProviderRoute =>
      status == AgentProviderResilientRouteStatus.noProviderRoute;

  bool get policyDecisionOnly => true;
  bool get invokesProvider => false;
  bool get activatesProvider => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get chargesCost => false;
  bool get mutatesBudget => false;
  bool get persistsDecision => false;

  bool get coreAppMustContinueOnNoRoute => true;
  bool get aiMustFailClosedOnNoRoute => true;

  void validateStructure() {
    if (!AgentProviderResilientRouteStatus.values.contains(status) ||
        reasonCodes.isEmpty ||
        reasonCodes.length > AgentProviderResilienceLimits.maxReasonCodes) {
      throw const FormatException('Invalid resilient provider route decision.');
    }

    if (hasRoute &&
        (selectedProviderId.trim().isEmpty || selectedTier.trim().isEmpty)) {
      throw const FormatException(
        'Provider route requires selected provider/tier.',
      );
    }

    if (!hasRoute &&
        (selectedProviderId.isNotEmpty || selectedTier.isNotEmpty)) {
      throw const FormatException(
        'No-route decision cannot expose selected provider.',
      );
    }
  }
}

import '../constants/agent_provider_expansion_contract_constants.dart';

class AgentProviderActivationDecision {
  const AgentProviderActivationDecision({
    required this.status,
    required this.providerId,
    required this.requiredCapability,
    required this.reason,
  });

  final String status;
  final String providerId;
  final String requiredCapability;
  final String reason;

  bool get eligible =>
      status ==
      AgentProviderExpansionActivationStatus
          .eligibleForTrustedBackendActivation;

  bool get policyDecisionOnly => true;
  bool get activatesProviderHere => false;
  bool get invokesProvider => false;
  bool get containsSecret => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get persistsDecision => false;
}

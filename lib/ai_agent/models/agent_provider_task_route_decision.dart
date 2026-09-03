import '../constants/agent_provider_task_routing_constants.dart';

class AgentProviderTaskRouteDecision {
  AgentProviderTaskRouteDecision({
    required this.status,
    required this.requestId,
    required this.providerId,
    required this.modelReference,
    required List<String> requiredCapabilities,
    required this.totalReservedTokens,
    required List<String> reasonCodes,
  }) : requiredCapabilities = List<String>.unmodifiable(requiredCapabilities),
       reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String requestId;
  final String providerId;
  final String modelReference;
  final List<String> requiredCapabilities;
  final int totalReservedTokens;
  final List<String> reasonCodes;

  bool get eligible =>
      status == AgentProviderTaskRouteStatus.eligibleForResilientRouting;

  bool get decisionOnly => true;
  bool get preservesStep1CRoutingOrder => true;
  bool get invokesProvider => false;
  bool get activatesProvider => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get chargesTokens => false;
  bool get chargesCost => false;
  bool get mutatesBudget => false;
  bool get persistsDecision => false;

  void validateStructure() {
    if (!AgentProviderTaskRouteStatus.values.contains(status) ||
        requestId.trim().isEmpty ||
        reasonCodes.isEmpty ||
        reasonCodes.length > AgentProviderTaskRoutingLimits.maxReasonCodes ||
        totalReservedTokens < 0) {
      throw const FormatException('Invalid provider task route decision.');
    }

    if (eligible &&
        (providerId.trim().isEmpty ||
            modelReference.trim().isEmpty ||
            requiredCapabilities.isEmpty)) {
      throw const FormatException(
        'Eligible task route requires provider/model/capability metadata.',
      );
    }

    if (!eligible &&
        (providerId.isNotEmpty ||
            modelReference.isNotEmpty ||
            requiredCapabilities.isNotEmpty ||
            totalReservedTokens != 0)) {
      throw const FormatException(
        'Blocked task route cannot expose selected provider/model.',
      );
    }
  }
}

import '../constants/agent_content_provider_privacy_safety_constants.dart';

class AgentContentProviderRouteDecision {
  AgentContentProviderRouteDecision({
    required this.status,
    required this.requestId,
    required this.providerClass,
    required this.humanReviewRequired,
    required this.paidApprovalRequired,
    required this.costLoggingRequired,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String requestId;
  final String providerClass;
  final bool humanReviewRequired;
  final bool paidApprovalRequired;
  final bool costLoggingRequired;
  final List<String> reasonCodes;

  bool get mayGenerateDraft =>
      status == AgentContentProviderRouteStatus.useTemplateOrCode ||
      status == AgentContentProviderRouteStatus.useFreeOnline ||
      status == AgentContentProviderRouteStatus.useLocalOptional ||
      status == AgentContentProviderRouteStatus.usePaid;

  bool get draftOnly => true;
  bool get providerGetsAuthority => false;
  bool get providerMayPublish => false;
  bool get providerMaySendWhatsApp => false;
  bool get providerMaySendEmail => false;
  bool get providerMayPostSocial => false;
  bool get providerMayApprove => false;
  bool get providerMayExecuteBusinessAction => false;
  bool get providerMayChangeBudget => false;
  bool get providerMayChangePermissions => false;
  bool get providerMaySelfTrain => false;
  bool get providerMayPersistRawPrivateData => false;
  bool get invokesProviderHere => false;
  bool get executesPaymentHere => false;
  bool get publishesHere => false;
  bool get persistsDecision => false;

  void validateStructure() {
    if (!AgentContentProviderRouteStatus.values.contains(status)) {
      throw const FormatException('Invalid provider route status.');
    }

    if (!AgentContentProviderClass.values.contains(providerClass)) {
      throw const FormatException('Invalid provider class.');
    }

    if (requestId.trim().isEmpty ||
        requestId.length > AgentContentCostLimits.maxRequestIdLength) {
      throw const FormatException('Invalid provider route request ID.');
    }

    if (reasonCodes.isEmpty ||
        reasonCodes.length > AgentContentCostLimits.maxReasonCodes) {
      throw const FormatException('Invalid provider route reasons.');
    }

    if (mayGenerateDraft && !humanReviewRequired) {
      throw const FormatException(
        'Generated content must require human review.',
      );
    }
  }
}

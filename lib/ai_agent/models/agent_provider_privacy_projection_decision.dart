import '../constants/agent_provider_privacy_projection_constants.dart';
import 'agent_provider_privacy_safe_projection.dart';

class AgentProviderPrivacyProjectionDecision {
  AgentProviderPrivacyProjectionDecision({
    required this.status,
    required this.requestId,
    required this.projection,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String requestId;
  final AgentProviderPrivacySafeProjection? projection;
  final List<String> reasonCodes;

  bool get eligible =>
      status ==
          AgentProviderPrivacyProjectionStatus.eligibleForProviderRouting &&
      projection != null;

  bool get failClosed => !eligible;
  bool get policyDecisionOnly => true;
  bool get providerInvocationAllowedHere => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get chargesCost => false;
  bool get mutatesBudget => false;
  bool get persistsDecision => false;

  void validateStructure() {
    if (!AgentProviderPrivacyProjectionStatus.values.contains(status) ||
        requestId.trim().isEmpty ||
        reasonCodes.isEmpty ||
        reasonCodes.length >
            AgentProviderPrivacyProjectionLimits.maxReasonCodes) {
      throw const FormatException(
        'Invalid provider privacy projection decision.',
      );
    }

    if (eligible && projection == null) {
      throw const FormatException(
        'Eligible privacy decision requires projection.',
      );
    }

    if (!eligible && projection != null) {
      throw const FormatException(
        'Blocked privacy decision cannot expose projection.',
      );
    }
  }
}

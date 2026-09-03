import '../constants/agent_owner_attention_sla_constants.dart';

class AgentOwnerAttentionNotificationRequest {
  AgentOwnerAttentionNotificationRequest({
    required this.attentionId,
    required this.category,
    required this.priority,
    required this.status,
    required this.safeTitle,
    required this.notificationReason,
    required this.createdAtUtc,
  }) {
    validate();
  }

  final String attentionId;
  final String category;
  final String priority;
  final String status;
  final String safeTitle;
  final String notificationReason;
  final DateTime createdAtUtc;

  bool get minimumNecessaryOnly => true;
  bool get safeSummaryIncluded => false;
  bool get rawBodyIncluded => false;
  bool get rawTranscriptIncluded => false;
  bool get rawRecordingIncluded => false;
  bool get rawSourceIdentifierIncluded => false;
  bool get secretIncluded => false;
  bool get authTokenIncluded => false;
  bool get approvalTokenIncluded => false;
  bool get permissionTokenIncluded => false;
  bool get apiKeyIncluded => false;
  bool get paymentCredentialIncluded => false;

  bool get deliveryRequestOnly => true;
  bool get notificationSent => false;
  bool get providerCalled => false;
  bool get approvalConsumed => false;
  bool get permissionGranted => false;
  bool get runtimeGateOverridden => false;
  bool get sourceActionExecuted => false;
  bool get businessWritePerformed => false;

  void validate() {
    if (attentionId.trim().isEmpty ||
        category.trim().isEmpty ||
        priority.trim().isEmpty ||
        status.trim().isEmpty ||
        safeTitle.trim().isEmpty ||
        safeTitle.length >
            AgentOwnerAttentionSlaLimits.notificationTitleMaxLength ||
        !AgentOwnerAttentionNotificationReason.values.contains(
          notificationReason,
        ) ||
        !createdAtUtc.isUtc) {
      throw const FormatException(
        'Invalid Owner Attention notification request.',
      );
    }
  }
}

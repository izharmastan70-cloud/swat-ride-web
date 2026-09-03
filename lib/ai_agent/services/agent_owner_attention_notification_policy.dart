import '../models/agent_owner_attention_inbox_record.dart';
import '../models/agent_owner_attention_notification_request.dart';
import '../models/agent_owner_attention_sla_assessment.dart';

class AgentOwnerAttentionNotificationPolicy {
  const AgentOwnerAttentionNotificationPolicy();

  AgentOwnerAttentionNotificationRequest? buildRequest({
    required AgentOwnerAttentionInboxRecord record,
    required AgentOwnerAttentionSlaAssessment assessment,
    required DateTime createdAtUtc,
  }) {
    record.validate();
    assessment.validate();

    final exactSnapshotMatch =
        assessment.attentionId == record.event.attentionId &&
        assessment.sourceReferenceSha256 ==
            record.event.source.sourceReferenceSha256 &&
        assessment.eventCreatedAtUtc.isAtSameMomentAs(
          record.event.createdAtUtc,
        ) &&
        assessment.reviewVersion == record.reviewVersion;

    if (!createdAtUtc.isUtc ||
        !exactSnapshotMatch ||
        !assessment.notificationEligible ||
        assessment.notificationReason == null ||
        assessment.terminal) {
      return null;
    }

    final request = AgentOwnerAttentionNotificationRequest(
      attentionId: record.event.attentionId,
      category: record.event.category,
      priority: record.event.priority,
      status: record.event.status,
      safeTitle: record.event.payload.safeTitle,
      notificationReason: assessment.notificationReason!,
      createdAtUtc: createdAtUtc,
    );

    request.validate();
    return request;
  }

  bool get exactAssessmentBindingRequired => true;
  bool get staleAssessmentReuseAllowed => false;

  bool get requestOnly => true;
  bool get sendsPush => false;
  bool get sendsSms => false;
  bool get sendsEmail => false;
  bool get sendsWhatsApp => false;
  bool get callsTelephonyProvider => false;
  bool get callsAiProvider => false;
  bool get writesFirestore => false;
  bool get mutatesInbox => false;
  bool get mutatesSourceRecord => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get overridesRuntimeGate => false;
  bool get executesBusinessAction => false;
}

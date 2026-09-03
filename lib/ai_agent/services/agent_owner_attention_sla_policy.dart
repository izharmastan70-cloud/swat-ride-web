import '../constants/agent_owner_attention_constants.dart';
import '../constants/agent_owner_attention_sla_constants.dart';
import '../models/agent_owner_attention_inbox_record.dart';
import '../models/agent_owner_attention_sla_assessment.dart';

class AgentOwnerAttentionSlaPolicy {
  const AgentOwnerAttentionSlaPolicy();

  Duration thresholdForPriority(String priority) {
    switch (priority) {
      case AgentOwnerAttentionPriority.normal:
        return AgentOwnerAttentionSlaLimits.normal;

      case AgentOwnerAttentionPriority.high:
        return AgentOwnerAttentionSlaLimits.high;

      case AgentOwnerAttentionPriority.critical:
        return AgentOwnerAttentionSlaLimits.critical;

      case AgentOwnerAttentionPriority.emergency:
        return AgentOwnerAttentionSlaLimits.emergency;

      default:
        throw const FormatException('Unknown Owner Attention priority.');
    }
  }

  AgentOwnerAttentionSlaAssessment assess({
    required AgentOwnerAttentionInboxRecord record,
    required DateTime evaluatedAtUtc,
  }) {
    record.validate();

    if (!evaluatedAtUtc.isUtc) {
      throw const FormatException(
        'Owner Attention SLA evaluation time must be UTC.',
      );
    }

    final event = record.event;
    final threshold = thresholdForPriority(event.priority);

    AgentOwnerAttentionSlaAssessment build({
      required String state,
      required Duration age,
      required bool notificationEligible,
      required String? notificationReason,
    }) {
      return AgentOwnerAttentionSlaAssessment(
        attentionId: event.attentionId,
        sourceReferenceSha256: event.source.sourceReferenceSha256,
        eventCreatedAtUtc: event.createdAtUtc,
        reviewVersion: record.reviewVersion,
        state: state,
        age: age,
        threshold: threshold,
        notificationEligible: notificationEligible,
        notificationReason: notificationReason,
      );
    }

    if (event.status == AgentOwnerAttentionStatus.resolved ||
        event.status == AgentOwnerAttentionStatus.dismissed) {
      return build(
        state: AgentOwnerAttentionSlaState.terminal,
        age: Duration.zero,
        notificationEligible: false,
        notificationReason: null,
      );
    }

    final activityAt = record.reviewUpdatedAtUtc ?? event.createdAtUtc;

    if (activityAt.isAfter(
      evaluatedAtUtc.add(AgentOwnerAttentionSlaLimits.maximumFutureClockSkew),
    )) {
      throw const FormatException(
        'Owner Attention activity time is too far in the future.',
      );
    }

    final age = evaluatedAtUtc.isBefore(activityAt)
        ? Duration.zero
        : evaluatedAtUtc.difference(activityAt);

    if (event.priority == AgentOwnerAttentionPriority.emergency) {
      return build(
        state: AgentOwnerAttentionSlaState.immediateEscalation,
        age: age,
        notificationEligible: true,
        notificationReason: AgentOwnerAttentionNotificationReason.emergencyOpen,
      );
    }

    if (event.priority == AgentOwnerAttentionPriority.critical) {
      return build(
        state: age >= threshold
            ? AgentOwnerAttentionSlaState.stale
            : AgentOwnerAttentionSlaState.immediateEscalation,
        age: age,
        notificationEligible: true,
        notificationReason: AgentOwnerAttentionNotificationReason.criticalOpen,
      );
    }

    if (age >= threshold) {
      return build(
        state: AgentOwnerAttentionSlaState.stale,
        age: age,
        notificationEligible: true,
        notificationReason: event.priority == AgentOwnerAttentionPriority.high
            ? AgentOwnerAttentionNotificationReason.staleHigh
            : AgentOwnerAttentionNotificationReason.staleNormal,
      );
    }

    return build(
      state: AgentOwnerAttentionSlaState.withinSla,
      age: age,
      notificationEligible: false,
      notificationReason: null,
    );
  }

  bool get assessmentOnly => true;
  bool get writesInbox => false;
  bool get mutatesSourceRecord => false;
  bool get sendsNotification => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get overridesRuntimeGate => false;
  bool get callsProvider => false;
  bool get executesBusinessAction => false;
}

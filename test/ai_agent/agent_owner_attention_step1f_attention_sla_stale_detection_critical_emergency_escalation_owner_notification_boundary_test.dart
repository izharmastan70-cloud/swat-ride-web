import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_owner_attention_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_owner_attention_sla_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_event.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_inbox_record.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_safe_payload.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_source_identity.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_attention_notification_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_attention_sla_policy.dart';

void main() {
  const sla = AgentOwnerAttentionSlaPolicy();
  const notification = AgentOwnerAttentionNotificationPolicy();

  const sourceHash =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  AgentOwnerAttentionInboxRecord record({
    required String priority,
    String status = AgentOwnerAttentionStatus.pendingReview,
    DateTime? createdAtUtc,
    int reviewVersion = 0,
    DateTime? reviewUpdatedAtUtc,
  }) {
    final event = AgentOwnerAttentionEvent(
      attentionId: 'attention:sla:$priority:$status',
      category: AgentOwnerAttentionCategory.securityAlert,
      priority: priority,
      status: status,
      source: AgentOwnerAttentionSourceIdentity(
        sourceType: AgentOwnerAttentionSourceType.security,
        sourceEventId: 'security:sla:$priority:$status',
        sourceReferenceSha256: sourceHash,
      ),
      payload: AgentOwnerAttentionSafePayload(
        safeTitle: 'Safe Owner Attention alert',
        safeSummary: 'Redacted minimum-necessary source summary.',
        reasonCodes: const <String>['sla_test'],
        redactionVerified: true,
        minimumNecessaryVerified: true,
      ),
      createdAtUtc: createdAtUtc ?? DateTime.utc(2026, 8, 24, 10),
    );

    if (reviewVersion == 0) {
      return AgentOwnerAttentionInboxRecord.initial(event);
    }

    return AgentOwnerAttentionInboxRecord(
      event: event,
      reviewVersion: reviewVersion,
      reviewedByRole: 'SUPER_ADMIN',
      reviewerRef: 'admin:1',
      reviewUpdatedAtUtc: reviewUpdatedAtUtc,
    );
  }

  test('SLA thresholds are 24h / 4h / 15m / 5m', () {
    expect(
      sla.thresholdForPriority(AgentOwnerAttentionPriority.normal),
      const Duration(hours: 24),
    );
    expect(
      sla.thresholdForPriority(AgentOwnerAttentionPriority.high),
      const Duration(hours: 4),
    );
    expect(
      sla.thresholdForPriority(AgentOwnerAttentionPriority.critical),
      const Duration(minutes: 15),
    );
    expect(
      sla.thresholdForPriority(AgentOwnerAttentionPriority.emergency),
      const Duration(minutes: 5),
    );
  });

  test('NORMAL within SLA does not notify', () {
    final value = sla.assess(
      record: record(priority: AgentOwnerAttentionPriority.normal),
      evaluatedAtUtc: DateTime.utc(2026, 8, 24, 20),
    );

    expect(value.state, AgentOwnerAttentionSlaState.withinSla);
    expect(value.notificationEligible, false);
  });

  test('NORMAL stale after 24 hours becomes notification eligible', () {
    final value = sla.assess(
      record: record(priority: AgentOwnerAttentionPriority.normal),
      evaluatedAtUtc: DateTime.utc(2026, 8, 25, 10),
    );

    expect(value.state, AgentOwnerAttentionSlaState.stale);
    expect(value.notificationEligible, true);
    expect(
      value.notificationReason,
      AgentOwnerAttentionNotificationReason.staleNormal,
    );
  });

  test('HIGH becomes stale at 4 hours', () {
    final value = sla.assess(
      record: record(priority: AgentOwnerAttentionPriority.high),
      evaluatedAtUtc: DateTime.utc(2026, 8, 24, 14),
    );

    expect(value.state, AgentOwnerAttentionSlaState.stale);
    expect(value.notificationEligible, true);
    expect(
      value.notificationReason,
      AgentOwnerAttentionNotificationReason.staleHigh,
    );
  });

  test('CRITICAL is immediately Owner-notification eligible', () {
    final value = sla.assess(
      record: record(priority: AgentOwnerAttentionPriority.critical),
      evaluatedAtUtc: DateTime.utc(2026, 8, 24, 10, 1),
    );

    expect(value.state, AgentOwnerAttentionSlaState.immediateEscalation);
    expect(value.notificationEligible, true);
    expect(
      value.notificationReason,
      AgentOwnerAttentionNotificationReason.criticalOpen,
    );
  });

  test(
    'CRITICAL becomes stale after 15 minutes but remains notify eligible',
    () {
      final value = sla.assess(
        record: record(priority: AgentOwnerAttentionPriority.critical),
        evaluatedAtUtc: DateTime.utc(2026, 8, 24, 10, 15),
      );

      expect(value.state, AgentOwnerAttentionSlaState.stale);
      expect(value.notificationEligible, true);
    },
  );

  test('EMERGENCY is immediately escalated while open', () {
    final value = sla.assess(
      record: record(priority: AgentOwnerAttentionPriority.emergency),
      evaluatedAtUtc: DateTime.utc(2026, 8, 24, 10),
    );

    expect(value.state, AgentOwnerAttentionSlaState.immediateEscalation);
    expect(value.notificationEligible, true);
    expect(
      value.notificationReason,
      AgentOwnerAttentionNotificationReason.emergencyOpen,
    );
  });

  test('last review activity resets stale-age clock', () {
    final value = sla.assess(
      record: record(
        priority: AgentOwnerAttentionPriority.high,
        status: AgentOwnerAttentionStatus.inReview,
        reviewVersion: 2,
        reviewUpdatedAtUtc: DateTime.utc(2026, 8, 24, 12),
      ),
      evaluatedAtUtc: DateTime.utc(2026, 8, 24, 14),
    );

    expect(value.state, AgentOwnerAttentionSlaState.withinSla);
    expect(value.age, const Duration(hours: 2));
  });

  test('RESOLVED and DISMISSED never stale or notify', () {
    for (final status in <String>[
      AgentOwnerAttentionStatus.resolved,
      AgentOwnerAttentionStatus.dismissed,
    ]) {
      final value = sla.assess(
        record: record(
          priority: AgentOwnerAttentionPriority.emergency,
          status: status,
          reviewVersion: 3,
          reviewUpdatedAtUtc: DateTime.utc(2026, 8, 24, 12),
        ),
        evaluatedAtUtc: DateTime.utc(2026, 8, 25, 12),
      );

      expect(value.state, AgentOwnerAttentionSlaState.terminal);
      expect(value.stale, false);
      expect(value.notificationEligible, false);
    }
  });

  test('notification request is minimum-necessary metadata only', () {
    final item = record(priority: AgentOwnerAttentionPriority.critical);

    final assessment = sla.assess(
      record: item,
      evaluatedAtUtc: DateTime.utc(2026, 8, 24, 10, 1),
    );

    final request = notification.buildRequest(
      record: item,
      assessment: assessment,
      createdAtUtc: DateTime.utc(2026, 8, 24, 10, 1),
    );

    expect(request, isNotNull);
    expect(request!.minimumNecessaryOnly, true);
    expect(request.safeSummaryIncluded, false);
    expect(request.rawBodyIncluded, false);
    expect(request.rawTranscriptIncluded, false);
    expect(request.rawRecordingIncluded, false);
    expect(request.rawSourceIdentifierIncluded, false);
    expect(request.secretIncluded, false);
    expect(request.authTokenIncluded, false);
    expect(request.approvalTokenIncluded, false);
    expect(request.permissionTokenIncluded, false);
    expect(request.apiKeyIncluded, false);
    expect(request.paymentCredentialIncluded, false);
  });

  test('within-SLA lower-priority item produces no notification request', () {
    final item = record(priority: AgentOwnerAttentionPriority.high);

    final assessment = sla.assess(
      record: item,
      evaluatedAtUtc: DateTime.utc(2026, 8, 24, 11),
    );

    expect(
      notification.buildRequest(
        record: item,
        assessment: assessment,
        createdAtUtc: DateTime.utc(2026, 8, 24, 11),
      ),
      isNull,
    );
  });

  test('mismatched assessment cannot build notification request', () {
    final first = record(priority: AgentOwnerAttentionPriority.critical);

    final second = record(
      priority: AgentOwnerAttentionPriority.critical,
      createdAtUtc: DateTime.utc(2026, 8, 24, 9),
    );

    final assessment = sla.assess(
      record: first,
      evaluatedAtUtc: DateTime.utc(2026, 8, 24, 10, 1),
    );

    expect(
      notification.buildRequest(
        record: second,
        assessment: assessment,
        createdAtUtc: DateTime.utc(2026, 8, 24, 10, 1),
      ),
      isNull,
    );
  });

  test('SLA policy has zero mutation/execution authority', () {
    expect(sla.assessmentOnly, true);
    expect(sla.writesInbox, false);
    expect(sla.mutatesSourceRecord, false);
    expect(sla.sendsNotification, false);
    expect(sla.consumesApproval, false);
    expect(sla.grantsPermission, false);
    expect(sla.overridesRuntimeGate, false);
    expect(sla.callsProvider, false);
    expect(sla.executesBusinessAction, false);
  });

  test('notification policy sends nothing and grants no authority', () {
    expect(notification.requestOnly, true);
    expect(notification.sendsPush, false);
    expect(notification.sendsSms, false);
    expect(notification.sendsEmail, false);
    expect(notification.sendsWhatsApp, false);
    expect(notification.callsTelephonyProvider, false);
    expect(notification.callsAiProvider, false);
    expect(notification.writesFirestore, false);
    expect(notification.mutatesInbox, false);
    expect(notification.mutatesSourceRecord, false);
    expect(notification.consumesApproval, false);
    expect(notification.grantsPermission, false);
    expect(notification.overridesRuntimeGate, false);
    expect(notification.executesBusinessAction, false);
  });
}

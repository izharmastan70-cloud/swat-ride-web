import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_owner_attention_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_event.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_inbox_record.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_safe_payload.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_source_identity.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_attention_drilldown_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_attention_inbox_view_policy.dart';

void main() {
  const viewPolicy = AgentOwnerAttentionInboxViewPolicy();
  const drilldownPolicy = AgentOwnerAttentionDrilldownPolicy();

  const sourceHash =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  AgentOwnerAttentionInboxRecord record({
    required String id,
    required String category,
    required String priority,
    required String status,
    required String sourceType,
  }) {
    final event = AgentOwnerAttentionEvent(
      attentionId: id,
      category: category,
      priority: priority,
      status: status,
      source: AgentOwnerAttentionSourceIdentity(
        sourceType: sourceType,
        sourceEventId: 'source:$id',
        sourceReferenceSha256: sourceHash,
      ),
      payload: AgentOwnerAttentionSafePayload(
        safeTitle: 'Safe Owner Attention title',
        safeSummary: 'Redacted minimum-necessary summary.',
        reasonCodes: const <String>['owner_review'],
        redactionVerified: true,
        minimumNecessaryVerified: true,
      ),
      createdAtUtc: DateTime.utc(2026, 8, 24, 10),
    );

    if (status == AgentOwnerAttentionStatus.pendingReview) {
      return AgentOwnerAttentionInboxRecord.initial(event);
    }

    return AgentOwnerAttentionInboxRecord(
      event: event,
      reviewVersion: 1,
      reviewedByRole: 'SUPER_ADMIN',
      reviewerRef: 'admin:1',
      reviewUpdatedAtUtc: DateTime.utc(2026, 8, 24, 10, 5),
    );
  }

  final records = <AgentOwnerAttentionInboxRecord>[
    record(
      id: 'a1',
      category: AgentOwnerAttentionCategory.seriousComplaint,
      priority: AgentOwnerAttentionPriority.high,
      status: AgentOwnerAttentionStatus.pendingReview,
      sourceType: AgentOwnerAttentionSourceType.feedback,
    ),
    record(
      id: 'a2',
      category: AgentOwnerAttentionCategory.securityAlert,
      priority: AgentOwnerAttentionPriority.critical,
      status: AgentOwnerAttentionStatus.inReview,
      sourceType: AgentOwnerAttentionSourceType.security,
    ),
    record(
      id: 'a3',
      category: AgentOwnerAttentionCategory.emergencyCase,
      priority: AgentOwnerAttentionPriority.emergency,
      status: AgentOwnerAttentionStatus.acknowledged,
      sourceType: AgentOwnerAttentionSourceType.emergency,
    ),
    record(
      id: 'a4',
      category: AgentOwnerAttentionCategory.fraudFinding,
      priority: AgentOwnerAttentionPriority.critical,
      status: AgentOwnerAttentionStatus.resolved,
      sourceType: AgentOwnerAttentionSourceType.fraud,
    ),
  ];

  test('badges count pending, urgent open, in-review and total open', () {
    final badges = viewPolicy.buildBadges(records);

    expect(badges.pendingReview, 1);
    expect(badges.criticalOrEmergency, 2);
    expect(badges.inReview, 1);
    expect(badges.totalOpen, 3);
    expect(badges.hasUrgentAttention, true);
  });

  test('priority filter returns only requested priority', () {
    final filtered = viewPolicy.filter(
      records: records,
      priority: AgentOwnerAttentionPriority.critical,
    );

    expect(filtered.length, 2);
    expect(
      filtered.every(
        (item) => item.event.priority == AgentOwnerAttentionPriority.critical,
      ),
      true,
    );
  });

  test('status filter returns only requested status', () {
    final filtered = viewPolicy.filter(
      records: records,
      status: AgentOwnerAttentionStatus.pendingReview,
    );

    expect(filtered.length, 1);
    expect(filtered.single.event.attentionId, 'a1');
  });

  test('category filter returns only requested category', () {
    final filtered = viewPolicy.filter(
      records: records,
      category: AgentOwnerAttentionCategory.emergencyCase,
    );

    expect(filtered.length, 1);
    expect(filtered.single.event.attentionId, 'a3');
  });

  test('combined filters fail safely to empty when no match', () {
    final filtered = viewPolicy.filter(
      records: records,
      category: AgentOwnerAttentionCategory.seriousComplaint,
      priority: AgentOwnerAttentionPriority.emergency,
    );

    expect(filtered, isEmpty);
  });

  test('allowed review actions mirror Step 1D lifecycle', () {
    expect(viewPolicy.allowedNextStatuses(records[0]), <String>[
      AgentOwnerAttentionStatus.acknowledged,
    ]);

    expect(viewPolicy.allowedNextStatuses(records[2]), <String>[
      AgentOwnerAttentionStatus.inReview,
      AgentOwnerAttentionStatus.dismissed,
    ]);

    expect(viewPolicy.allowedNextStatuses(records[1]), <String>[
      AgentOwnerAttentionStatus.resolved,
      AgentOwnerAttentionStatus.dismissed,
    ]);

    expect(viewPolicy.allowedNextStatuses(records[3]), isEmpty);
  });

  test('safe drill-down descriptor never executes source action', () {
    for (final item in records) {
      final descriptor = drilldownPolicy.descriptorFor(item);

      expect(descriptor.sourceLabel, isNotEmpty);
      expect(descriptor.routeKey, isNotEmpty);
      expect(descriptor.reviewInstruction, isNotEmpty);
      expect(descriptor.informationalOnly, true);
      expect(descriptor.rawSourcePayloadIncluded, false);
      expect(descriptor.sourceActionExecuted, false);
      expect(descriptor.approvalConsumed, false);
      expect(descriptor.permissionGranted, false);
      expect(descriptor.businessWritePerformed, false);
    }
  });

  test('Email attention drill-down remains informational only', () {
    final emailRecord = record(
      id: 'email1',
      category: AgentOwnerAttentionCategory.pendingSensitiveApproval,
      priority: AgentOwnerAttentionPriority.high,
      status: AgentOwnerAttentionStatus.pendingReview,
      sourceType: AgentOwnerAttentionSourceType.emailAttention,
    );

    final descriptor = drilldownPolicy.descriptorFor(emailRecord);

    expect(descriptor.routeKey, 'email_admin_review');
    expect(descriptor.sourceActionExecuted, false);
  });

  test('view and drill-down policies grant zero consequential authority', () {
    expect(viewPolicy.viewCoordinationOnly, true);
    expect(viewPolicy.sourceActionExecutionAllowed, false);
    expect(viewPolicy.approvalConsumptionAllowed, false);
    expect(viewPolicy.permissionGrantAllowed, false);
    expect(viewPolicy.providerExecutionAllowed, false);
    expect(viewPolicy.businessWriteAllowed, false);

    expect(drilldownPolicy.descriptorOnly, true);
    expect(drilldownPolicy.navigatesAutomatically, false);
    expect(drilldownPolicy.sourceActionExecutionAllowed, false);
    expect(drilldownPolicy.approvalConsumptionAllowed, false);
    expect(drilldownPolicy.businessWriteAllowed, false);
  });
}

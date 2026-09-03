import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_owner_attention_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_owner_attention_review_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_event.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_inbox_record.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_safe_payload.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_source_identity.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_status_transition.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_attention_status_transition_policy.dart';

void main() {
  const policy = AgentOwnerAttentionStatusTransitionPolicy();

  const sourceHash =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  AgentOwnerAttentionEvent event({
    String status = AgentOwnerAttentionStatus.pendingReview,
  }) {
    return AgentOwnerAttentionEvent(
      attentionId: 'attention:phase64:step1d',
      category: AgentOwnerAttentionCategory.securityAlert,
      priority: AgentOwnerAttentionPriority.critical,
      status: status,
      source: AgentOwnerAttentionSourceIdentity(
        sourceType: AgentOwnerAttentionSourceType.security,
        sourceEventId: 'security:123',
        sourceReferenceSha256: sourceHash,
      ),
      payload: AgentOwnerAttentionSafePayload(
        safeTitle: 'Security alert',
        safeSummary: 'Redacted security alert requires Owner review.',
        reasonCodes: const <String>['security_review'],
        redactionVerified: true,
        minimumNecessaryVerified: true,
      ),
      createdAtUtc: DateTime.utc(2026, 8, 24, 9, 30),
    );
  }

  AgentOwnerAttentionStatusTransition transition({
    required String from,
    required String to,
    int version = 0,
    String role = AgentOwnerAttentionReviewRole.owner,
  }) {
    return AgentOwnerAttentionStatusTransition(
      attentionId: 'attention:phase64:step1d',
      expectedStatus: from,
      nextStatus: to,
      expectedReviewVersion: version,
      reviewerRole: role,
      reviewerRef: 'reviewer:owner:1',
      reviewedAtUtc: DateTime.utc(2026, 8, 24, 9, 45),
    );
  }

  test('initial inbox record is immutable PENDING_REVIEW version zero', () {
    final record = AgentOwnerAttentionInboxRecord.initial(event());

    expect(record.event.status, AgentOwnerAttentionStatus.pendingReview);
    expect(record.reviewVersion, 0);
    expect(record.reviewedByRole, isNull);
    expect(record.reviewerRef, isNull);
    expect(record.immutableSourcePayload, true);
    expect(record.sourceRecordMutated, false);
    expect(record.approvalConsumed, false);
    expect(record.businessActionExecuted, false);
  });

  test('initial ingestion cannot start in RESOLVED state', () {
    expect(
      () => AgentOwnerAttentionInboxRecord.initial(
        event(status: AgentOwnerAttentionStatus.resolved),
      ),
      throwsFormatException,
    );
  });

  test('PENDING_REVIEW can only move to ACKNOWLEDGED', () {
    expect(
      policy.isAllowed(
        transition(
          from: AgentOwnerAttentionStatus.pendingReview,
          to: AgentOwnerAttentionStatus.acknowledged,
        ),
      ),
      true,
    );

    expect(
      policy.isAllowed(
        transition(
          from: AgentOwnerAttentionStatus.pendingReview,
          to: AgentOwnerAttentionStatus.resolved,
        ),
      ),
      false,
    );
  });

  test('ACKNOWLEDGED can move to IN_REVIEW or DISMISSED', () {
    expect(
      policy.isAllowed(
        transition(
          from: AgentOwnerAttentionStatus.acknowledged,
          to: AgentOwnerAttentionStatus.inReview,
          version: 1,
        ),
      ),
      true,
    );

    expect(
      policy.isAllowed(
        transition(
          from: AgentOwnerAttentionStatus.acknowledged,
          to: AgentOwnerAttentionStatus.dismissed,
          version: 1,
        ),
      ),
      true,
    );
  });

  test('IN_REVIEW can move to RESOLVED or DISMISSED', () {
    expect(
      policy.isAllowed(
        transition(
          from: AgentOwnerAttentionStatus.inReview,
          to: AgentOwnerAttentionStatus.resolved,
          version: 2,
        ),
      ),
      true,
    );

    expect(
      policy.isAllowed(
        transition(
          from: AgentOwnerAttentionStatus.inReview,
          to: AgentOwnerAttentionStatus.dismissed,
          version: 2,
        ),
      ),
      true,
    );
  });

  test('RESOLVED and DISMISSED are terminal', () {
    for (final status in <String>[
      AgentOwnerAttentionStatus.resolved,
      AgentOwnerAttentionStatus.dismissed,
    ]) {
      expect(
        policy.isAllowed(
          transition(
            from: status,
            to: AgentOwnerAttentionStatus.inReview,
            version: 3,
          ),
        ),
        false,
      );
    }
  });

  test('only OWNER or SUPER_ADMIN can be reviewer roles', () {
    expect(
      () => transition(
        from: AgentOwnerAttentionStatus.pendingReview,
        to: AgentOwnerAttentionStatus.acknowledged,
        role: 'AGENT',
      ),
      throwsFormatException,
    );

    expect(
      policy.isAllowed(
        transition(
          from: AgentOwnerAttentionStatus.pendingReview,
          to: AgentOwnerAttentionStatus.acknowledged,
          role: AgentOwnerAttentionReviewRole.superAdmin,
        ),
      ),
      true,
    );
  });

  test('review transition is workflow-only and grants no source authority', () {
    final value = transition(
      from: AgentOwnerAttentionStatus.inReview,
      to: AgentOwnerAttentionStatus.resolved,
      version: 2,
    );

    expect(value.workflowOnly, true);
    expect(value.consumesApproval, false);
    expect(value.grantsPermission, false);
    expect(value.resolvesSourceRecord, false);
    expect(value.executesBusinessAction, false);

    expect(policy.workflowOnly, true);
    expect(policy.directSourceResolutionAllowed, false);
    expect(policy.approvalConsumptionAllowed, false);
    expect(policy.permissionGrantAllowed, false);
    expect(policy.businessExecutionAllowed, false);
  });

  test('stored record round-trip preserves safe immutable fields', () {
    final initial = AgentOwnerAttentionInboxRecord.initial(event());
    final restored = AgentOwnerAttentionInboxRecord.fromMap(initial.toMap());

    expect(restored.event.attentionId, initial.event.attentionId);
    expect(restored.event.category, initial.event.category);
    expect(restored.event.priority, initial.event.priority);
    expect(restored.event.source.sourceReferenceSha256, sourceHash);
    expect(restored.event.payload.rawBodyIncluded, false);
    expect(restored.reviewVersion, 0);
  });
}

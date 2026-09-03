import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_owner_attention_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_event.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_inbox_record.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_safe_payload.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_source_identity.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_status_transition.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_attention_contract_service.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_attention_final_readiness_service.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_attention_notification_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_attention_sla_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_attention_status_transition_policy.dart';

void main() {
  const readiness = AgentOwnerAttentionFinalReadinessService();
  const contract = AgentOwnerAttentionContractService();
  const sla = AgentOwnerAttentionSlaPolicy();
  const notification = AgentOwnerAttentionNotificationPolicy();
  const transitionPolicy = AgentOwnerAttentionStatusTransitionPolicy();

  const sourceHash =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  AgentOwnerAttentionEvent event({
    String attentionId = 'attention:phase64:final',
    String sourceEventId = 'security:phase64:final',
    String priority = AgentOwnerAttentionPriority.critical,
    String status = AgentOwnerAttentionStatus.pendingReview,
  }) {
    return AgentOwnerAttentionEvent(
      attentionId: attentionId,
      category: AgentOwnerAttentionCategory.securityAlert,
      priority: priority,
      status: status,
      source: AgentOwnerAttentionSourceIdentity(
        sourceType: AgentOwnerAttentionSourceType.security,
        sourceEventId: sourceEventId,
        sourceReferenceSha256: sourceHash,
      ),
      payload: AgentOwnerAttentionSafePayload(
        safeTitle: 'Final safe security alert',
        safeSummary: 'Redacted minimum-necessary final closeout summary.',
        reasonCodes: const <String>['phase64_final_closeout'],
        redactionVerified: true,
        minimumNecessaryVerified: true,
      ),
      createdAtUtc: DateTime.utc(2026, 8, 24, 12),
    );
  }

  test('all 12 readiness pillars are required', () {
    final ready = readiness.evaluate(
      unifiedContractReady: true,
      sourceAdaptersReady: true,
      dedupeGateReady: true,
      repositoryReady: true,
      rulesReady: true,
      reviewUiReady: true,
      privacyBoundaryReady: true,
      slaReady: true,
      exactSnapshotBindingReady: true,
      notificationBoundaryReady: true,
      failureIsolationReady: true,
      runtimeSecurityBoundaryReady: true,
    );

    expect(ready.allSafetyPillarsReady, true);
    expect(ready.phase64FoundationComplete, true);
  });

  test('missing any readiness pillar fails closed', () {
    final notReady = readiness.evaluate(
      unifiedContractReady: true,
      sourceAdaptersReady: true,
      dedupeGateReady: true,
      repositoryReady: true,
      rulesReady: true,
      reviewUiReady: true,
      privacyBoundaryReady: true,
      slaReady: true,
      exactSnapshotBindingReady: false,
      notificationBoundaryReady: true,
      failureIsolationReady: true,
      runtimeSecurityBoundaryReady: true,
    );

    expect(notReady.allSafetyPillarsReady, false);
    expect(notReady.phase64FoundationComplete, false);
  });

  test('final readiness grants no production or security authority', () {
    final ready = readiness.evaluate(
      unifiedContractReady: true,
      sourceAdaptersReady: true,
      dedupeGateReady: true,
      repositoryReady: true,
      rulesReady: true,
      reviewUiReady: true,
      privacyBoundaryReady: true,
      slaReady: true,
      exactSnapshotBindingReady: true,
      notificationBoundaryReady: true,
      failureIsolationReady: true,
      runtimeSecurityBoundaryReady: true,
    );

    expect(ready.productionRuntimeActivated, false);
    expect(ready.automaticSourceIngestionActivated, false);
    expect(ready.automaticNotificationDeliveryActivated, false);
    expect(ready.approvalConsumptionAuthority, false);
    expect(ready.permissionGrantAuthority, false);
    expect(ready.runtimeGateOverrideAuthority, false);
    expect(ready.providerExecutionAuthority, false);
    expect(ready.sourceBusinessExecutionAuthority, false);
    expect(ready.deploymentAuthority, false);
    expect(ready.coreSwatRideDependencyIntroduced, false);
  });

  test('duplicate source identity is detected fail-closed', () {
    final first = event();
    final duplicate = event(attentionId: 'attention:phase64:duplicate');

    expect(
      contract.hasDuplicateSourceIdentity(<AgentOwnerAttentionEvent>[
        first,
      ], duplicate),
      true,
    );
  });

  test('critical priority cannot be downgraded by final contract', () {
    final downgraded = event(priority: AgentOwnerAttentionPriority.high);

    expect(
      contract.validateForCentralInbox(
        downgraded,
        evaluatedAtUtc: DateTime.utc(2026, 8, 24, 12, 1),
      ),
      false,
    );
  });

  test('terminal record produces no notification request', () {
    final terminalEvent = event(status: AgentOwnerAttentionStatus.resolved);

    final terminal = AgentOwnerAttentionInboxRecord(
      event: terminalEvent,
      reviewVersion: 3,
      reviewedByRole: 'SUPER_ADMIN',
      reviewerRef: 'admin:1',
      reviewUpdatedAtUtc: DateTime.utc(2026, 8, 24, 12, 30),
    );

    final assessment = sla.assess(
      record: terminal,
      evaluatedAtUtc: DateTime.utc(2026, 8, 25, 12),
    );

    expect(assessment.terminal, true);
    expect(assessment.notificationEligible, false);

    expect(
      notification.buildRequest(
        record: terminal,
        assessment: assessment,
        createdAtUtc: DateTime.utc(2026, 8, 25, 12),
      ),
      isNull,
    );
  });

  test('stale assessment cannot be reused after reviewVersion changes', () {
    final initial = AgentOwnerAttentionInboxRecord.initial(event());

    final assessment = sla.assess(
      record: initial,
      evaluatedAtUtc: DateTime.utc(2026, 8, 24, 12, 1),
    );

    final acknowledgedEvent = event(
      status: AgentOwnerAttentionStatus.acknowledged,
    );

    final reviewed = AgentOwnerAttentionInboxRecord(
      event: acknowledgedEvent,
      reviewVersion: 1,
      reviewedByRole: 'SUPER_ADMIN',
      reviewerRef: 'admin:1',
      reviewUpdatedAtUtc: DateTime.utc(2026, 8, 24, 12, 2),
    );

    expect(
      notification.buildRequest(
        record: reviewed,
        assessment: assessment,
        createdAtUtc: DateTime.utc(2026, 8, 24, 12, 2),
      ),
      isNull,
    );
  });

  test('terminal workflow states cannot reopen', () {
    for (final status in <String>[
      AgentOwnerAttentionStatus.resolved,
      AgentOwnerAttentionStatus.dismissed,
    ]) {
      final transition = AgentOwnerAttentionStatusTransition(
        attentionId: 'attention:phase64:final',
        expectedStatus: status,
        nextStatus: AgentOwnerAttentionStatus.inReview,
        expectedReviewVersion: 3,
        reviewerRole: 'SUPER_ADMIN',
        reviewerRef: 'admin:1',
        reviewedAtUtc: DateTime.utc(2026, 8, 24, 13),
      );

      expect(transitionPolicy.isAllowed(transition), false);
    }
  });

  test('readiness service is evaluation-only and failure-isolated', () {
    expect(readiness.evaluationOnly, true);
    expect(readiness.activatesRuntime, false);
    expect(readiness.startsBackgroundWorker, false);
    expect(readiness.sendsNotification, false);
    expect(readiness.writesFirestore, false);
    expect(readiness.mutatesInbox, false);
    expect(readiness.mutatesSourceRecord, false);
    expect(readiness.consumesApproval, false);
    expect(readiness.grantsPermission, false);
    expect(readiness.overridesRuntimeGate, false);
    expect(readiness.callsProvider, false);
    expect(readiness.executesBusinessAction, false);
    expect(readiness.deploysApplication, false);
  });
}

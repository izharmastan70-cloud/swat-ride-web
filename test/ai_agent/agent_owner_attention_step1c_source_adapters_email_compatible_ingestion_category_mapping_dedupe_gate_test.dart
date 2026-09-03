import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_owner_attention_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_owner_attention_source_signal_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_email_admin_attention_event.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_source_signal.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_attention_email_adapter.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_attention_ingestion_gate.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_attention_source_adapter.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_attention_source_category_mapping_policy.dart';

void main() {
  const mapping = AgentOwnerAttentionSourceCategoryMappingPolicy();
  const adapter = AgentOwnerAttentionSourceAdapter();
  const emailAdapter = AgentOwnerAttentionEmailAdapter();
  const ingestion = AgentOwnerAttentionIngestionGate();

  const sourceHash =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  final evaluatedAtUtc = DateTime.utc(2026, 8, 24, 9);

  AgentOwnerAttentionSourceSignal signal({
    required String sourceType,
    required String sourceKind,
    String sourceEventId = 'source:123',
    String title = 'Owner review required',
    String summary = 'Redacted minimum-necessary review summary.',
  }) {
    return AgentOwnerAttentionSourceSignal(
      sourceType: sourceType,
      sourceKind: sourceKind,
      sourceEventId: sourceEventId,
      sourceReferenceSha256: sourceHash,
      safeTitle: title,
      safeSummary: summary,
      reasonCodes: const <String>['owner_review_required'],
      redactionVerified: true,
      minimumNecessaryVerified: true,
      occurredAtUtc: DateTime.utc(2026, 8, 24, 8, 59),
    );
  }

  test('all 9 source kinds map to exactly 9 locked categories', () {
    final cases = <(String, String, String)>[
      (
        AgentOwnerAttentionSourceType.feedback,
        AgentOwnerAttentionSourceKind.seriousComplaint,
        AgentOwnerAttentionCategory.seriousComplaint,
      ),
      (
        AgentOwnerAttentionSourceType.payment,
        AgentOwnerAttentionSourceKind.highValuePaymentDispute,
        AgentOwnerAttentionCategory.highValuePaymentDispute,
      ),
      (
        AgentOwnerAttentionSourceType.call,
        AgentOwnerAttentionSourceKind.unresolvedCall,
        AgentOwnerAttentionCategory.unresolvedCall,
      ),
      (
        AgentOwnerAttentionSourceType.security,
        AgentOwnerAttentionSourceKind.securityAlert,
        AgentOwnerAttentionCategory.securityAlert,
      ),
      (
        AgentOwnerAttentionSourceType.crossAgentSupervisor,
        AgentOwnerAttentionSourceKind.agentConflict,
        AgentOwnerAttentionCategory.agentConflict,
      ),
      (
        AgentOwnerAttentionSourceType.approval,
        AgentOwnerAttentionSourceKind.pendingSensitiveApproval,
        AgentOwnerAttentionCategory.pendingSensitiveApproval,
      ),
      (
        AgentOwnerAttentionSourceType.crash,
        AgentOwnerAttentionSourceKind.criticalCrash,
        AgentOwnerAttentionCategory.criticalCrash,
      ),
      (
        AgentOwnerAttentionSourceType.fraud,
        AgentOwnerAttentionSourceKind.fraudFinding,
        AgentOwnerAttentionCategory.fraudFinding,
      ),
      (
        AgentOwnerAttentionSourceType.emergency,
        AgentOwnerAttentionSourceKind.emergencyCase,
        AgentOwnerAttentionCategory.emergencyCase,
      ),
    ];

    for (final item in cases) {
      final result = mapping.map(sourceType: item.$1, sourceKind: item.$2);

      expect(result.category, item.$3);
      expect(result.executionAuthorityGranted, false);
    }

    expect(AgentOwnerAttentionCategory.values.length, 9);
  });

  test('invalid source type/kind combination fails closed', () {
    expect(
      () => mapping.map(
        sourceType: AgentOwnerAttentionSourceType.feedback,
        sourceKind: AgentOwnerAttentionSourceKind.securityAlert,
      ),
      throwsFormatException,
    );
  });

  test('generic adapter creates pending unified event at minimum priority', () {
    final event = adapter.adapt(
      signal(
        sourceType: AgentOwnerAttentionSourceType.security,
        sourceKind: AgentOwnerAttentionSourceKind.securityAlert,
      ),
    );

    expect(event.category, AgentOwnerAttentionCategory.securityAlert);
    expect(event.priority, AgentOwnerAttentionPriority.critical);
    expect(event.status, AgentOwnerAttentionStatus.pendingReview);
    expect(event.requiresHumanReview, true);
    expect(event.mayExecuteBusinessAction, false);
  });

  test('emergency source maps to EMERGENCY priority', () {
    final event = adapter.adapt(
      signal(
        sourceType: AgentOwnerAttentionSourceType.emergency,
        sourceKind: AgentOwnerAttentionSourceKind.emergencyCase,
      ),
    );

    expect(event.category, AgentOwnerAttentionCategory.emergencyCase);
    expect(event.priority, AgentOwnerAttentionPriority.emergency);
  });

  test(
    'Email Admin Attention adapts without copying body/sensitive values',
    () {
      final email = AgentEmailAdminAttentionEvent(
        attentionId: 'email:attention:123',
        draftId: 'draft:123',
        sourceAddressMasked: 'a***@example.com',
        subjectSafe: 'Unusual email needs review',
        safeSummary: 'Redacted unusual email summary.',
        reasonCodes: const <String>['unusual_sender_review'],
        createdAt: DateTime.utc(2026, 8, 24, 8, 50),
      );

      final event = emailAdapter.adapt(email);

      expect(
        event.category,
        AgentOwnerAttentionCategory.pendingSensitiveApproval,
      );
      expect(event.priority, AgentOwnerAttentionPriority.high);
      expect(event.status, AgentOwnerAttentionStatus.pendingReview);
      expect(
        event.source.sourceType,
        AgentOwnerAttentionSourceType.emailAttention,
      );
      expect(event.payload.rawBodyIncluded, false);
      expect(event.payload.secretIncluded, false);
      expect(emailAdapter.bodyCopied, false);
      expect(emailAdapter.sensitiveValueCopied, false);
      expect(emailAdapter.sendsEmail, false);
    },
  );

  test('Email adapter creates stable SHA-256 source reference', () {
    final email = AgentEmailAdminAttentionEvent(
      attentionId: 'email:attention:124',
      draftId: 'draft:124',
      sourceAddressMasked: 'b***@example.com',
      subjectSafe: 'Review email',
      safeSummary: 'Redacted review summary.',
      reasonCodes: const <String>['review'],
      createdAt: DateTime.utc(2026, 8, 24, 8, 51),
    );

    final first = emailAdapter.adapt(email);
    final second = emailAdapter.adapt(email);

    expect(first.source.sourceReferenceSha256.length, 64);
    expect(
      first.source.sourceReferenceSha256,
      second.source.sourceReferenceSha256,
    );
  });

  test('ingestion accepts valid unique candidate but does not persist', () {
    final candidate = adapter.adapt(
      signal(
        sourceType: AgentOwnerAttentionSourceType.fraud,
        sourceKind: AgentOwnerAttentionSourceKind.fraudFinding,
      ),
    );

    final result = ingestion.evaluate(
      existing: const [],
      candidate: candidate,
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(result.accepted, true);
    expect(result.persisted, false);
    expect(result.event, same(candidate));
  });

  test('ingestion blocks duplicate source identity before persistence', () {
    final existing = adapter.adapt(
      signal(
        sourceType: AgentOwnerAttentionSourceType.call,
        sourceKind: AgentOwnerAttentionSourceKind.unresolvedCall,
      ),
    );

    final duplicate = adapter.adapt(
      signal(
        sourceType: AgentOwnerAttentionSourceType.call,
        sourceKind: AgentOwnerAttentionSourceKind.unresolvedCall,
      ),
    );

    final result = ingestion.evaluate(
      existing: <dynamic>[existing].cast(),
      candidate: duplicate,
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(result.status, AgentOwnerAttentionIngestionStatus.blockedDuplicate);
    expect(result.event, isNull);
    expect(result.persisted, false);
  });

  test('source signal carries no raw/private execution payload', () {
    final source = signal(
      sourceType: AgentOwnerAttentionSourceType.payment,
      sourceKind: AgentOwnerAttentionSourceKind.highValuePaymentDispute,
    );

    expect(source.metadataOnly, true);
    expect(source.rawBodyIncluded, false);
    expect(source.rawTranscriptIncluded, false);
    expect(source.rawRecordingIncluded, false);
    expect(source.secretIncluded, false);
    expect(source.tokenIncluded, false);
    expect(source.paymentCredentialIncluded, false);
    expect(source.businessActionIncluded, false);
  });

  test('source adapter has zero execution authority', () {
    expect(adapter.adapterOnly, true);
    expect(adapter.readsFirestore, false);
    expect(adapter.writesFirestore, false);
    expect(adapter.mutatesSource, false);
    expect(adapter.consumesApproval, false);
    expect(adapter.grantsPermission, false);
    expect(adapter.overridesRuntimeGate, false);
    expect(adapter.callsProvider, false);
    expect(adapter.executesBusinessAction, false);
  });

  test('ingestion gate has zero execution authority', () {
    expect(ingestion.gateOnly, true);
    expect(ingestion.persistsInbox, false);
    expect(ingestion.readsFirestore, false);
    expect(ingestion.writesFirestore, false);
    expect(ingestion.consumesApproval, false);
    expect(ingestion.grantsPermission, false);
    expect(ingestion.overridesRuntimeGate, false);
    expect(ingestion.callsProvider, false);
    expect(ingestion.mutatesSource, false);
    expect(ingestion.executesBusinessAction, false);
  });
}

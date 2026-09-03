import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_owner_attention_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_event.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_safe_payload.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_attention_source_identity.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_attention_contract_service.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_attention_priority_policy.dart';

void main() {
  const contract = AgentOwnerAttentionContractService();
  const priorityPolicy = AgentOwnerAttentionPriorityPolicy();

  const sourceHash =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  final evaluatedAtUtc = DateTime.utc(2026, 8, 24, 8);

  AgentOwnerAttentionEvent event({
    String category = AgentOwnerAttentionCategory.seriousComplaint,
    String priority = AgentOwnerAttentionPriority.high,
    String status = AgentOwnerAttentionStatus.pendingReview,
    String sourceType = AgentOwnerAttentionSourceType.feedback,
    String sourceEventId = 'feedback:123',
    String safeTitle = 'Serious customer complaint',
    String safeSummary = 'Redacted complaint summary requires Owner review.',
  }) {
    return AgentOwnerAttentionEvent(
      attentionId: 'attention:phase64:123',
      category: category,
      priority: priority,
      status: status,
      source: AgentOwnerAttentionSourceIdentity(
        sourceType: sourceType,
        sourceEventId: sourceEventId,
        sourceReferenceSha256: sourceHash,
      ),
      payload: AgentOwnerAttentionSafePayload(
        safeTitle: safeTitle,
        safeSummary: safeSummary,
        reasonCodes: const <String>['owner_review_required'],
        redactionVerified: true,
        minimumNecessaryVerified: true,
      ),
      createdAtUtc: DateTime.utc(2026, 8, 24, 7, 59),
    );
  }

  test('exactly 9 locked source categories exist', () {
    expect(AgentOwnerAttentionCategory.values.length, 9);

    expect(
      AgentOwnerAttentionCategory.values,
      containsAll(<String>{
        AgentOwnerAttentionCategory.seriousComplaint,
        AgentOwnerAttentionCategory.highValuePaymentDispute,
        AgentOwnerAttentionCategory.unresolvedCall,
        AgentOwnerAttentionCategory.securityAlert,
        AgentOwnerAttentionCategory.agentConflict,
        AgentOwnerAttentionCategory.pendingSensitiveApproval,
        AgentOwnerAttentionCategory.criticalCrash,
        AgentOwnerAttentionCategory.fraudFinding,
        AgentOwnerAttentionCategory.emergencyCase,
      }),
    );
  });

  test('serious complaint is valid high-priority inbox candidate', () {
    final candidate = event();

    expect(
      contract.validateForCentralInbox(
        candidate,
        evaluatedAtUtc: evaluatedAtUtc,
      ),
      true,
    );

    expect(candidate.requiresHumanReview, true);
    expect(candidate.mayExecuteBusinessAction, false);
  });

  test('security alert minimum priority is critical', () {
    expect(
      priorityPolicy.minimumPriorityFor(
        AgentOwnerAttentionCategory.securityAlert,
      ),
      AgentOwnerAttentionPriority.critical,
    );

    expect(
      priorityPolicy.isPriorityAllowed(
        category: AgentOwnerAttentionCategory.securityAlert,
        priority: AgentOwnerAttentionPriority.high,
      ),
      false,
    );

    expect(
      priorityPolicy.isPriorityAllowed(
        category: AgentOwnerAttentionCategory.securityAlert,
        priority: AgentOwnerAttentionPriority.critical,
      ),
      true,
    );
  });

  test('emergency case minimum priority is emergency', () {
    expect(
      priorityPolicy.minimumPriorityFor(
        AgentOwnerAttentionCategory.emergencyCase,
      ),
      AgentOwnerAttentionPriority.emergency,
    );
  });

  test(
    'critical crash and fraud finding cannot be downgraded below critical',
    () {
      for (final category in <String>[
        AgentOwnerAttentionCategory.criticalCrash,
        AgentOwnerAttentionCategory.fraudFinding,
      ]) {
        expect(
          priorityPolicy.isPriorityAllowed(
            category: category,
            priority: AgentOwnerAttentionPriority.high,
          ),
          false,
        );
      }
    },
  );

  test('duplicate source identity fails candidate acceptance', () {
    final existing = event();
    final duplicate = event();

    expect(
      contract.hasDuplicateSourceIdentity(<AgentOwnerAttentionEvent>[
        existing,
      ], duplicate),
      true,
    );

    expect(
      contract.canAcceptCandidate(
        existing: <AgentOwnerAttentionEvent>[existing],
        candidate: duplicate,
        evaluatedAtUtc: evaluatedAtUtc,
      ),
      false,
    );
  });

  test('different source event is not duplicate', () {
    final existing = event();
    final next = event(sourceEventId: 'feedback:124');

    expect(
      contract.hasDuplicateSourceIdentity(<AgentOwnerAttentionEvent>[
        existing,
      ], next),
      false,
    );
  });

  test('safe payload exposes no raw/private execution fields', () {
    final payload = event().payload;

    expect(payload.rawBodyIncluded, false);
    expect(payload.rawTranscriptIncluded, false);
    expect(payload.rawRecordingIncluded, false);
    expect(payload.secretIncluded, false);
    expect(payload.authTokenIncluded, false);
    expect(payload.approvalTokenIncluded, false);
    expect(payload.permissionTokenIncluded, false);
    expect(payload.apiKeyIncluded, false);
    expect(payload.paymentCredentialIncluded, false);
    expect(payload.fullCardNumberIncluded, false);
    expect(payload.cvvIncluded, false);
  });

  test('password/API/token/CVV-like text fails closed', () {
    for (final unsafeSummary in <String>[
      'password=123456',
      'apiKey=secret-value',
      'authToken=abc',
      'approvalToken=abc',
      'permissionToken=abc',
      'cvv=123',
      'cardNumber=4111111111111111',
    ]) {
      expect(
        () => AgentOwnerAttentionSafePayload(
          safeTitle: 'Unsafe payload',
          safeSummary: unsafeSummary,
          reasonCodes: const <String>['unsafe'],
          redactionVerified: true,
          minimumNecessaryVerified: true,
        ),
        throwsFormatException,
      );
    }
  });

  test('redaction and minimum-necessary flags are mandatory', () {
    expect(
      () => AgentOwnerAttentionSafePayload(
        safeTitle: 'Complaint',
        safeSummary: 'Safe summary',
        reasonCodes: const <String>['review'],
        redactionVerified: false,
        minimumNecessaryVerified: true,
      ),
      throwsFormatException,
    );

    expect(
      () => AgentOwnerAttentionSafePayload(
        safeTitle: 'Complaint',
        safeSummary: 'Safe summary',
        reasonCodes: const <String>['review'],
        redactionVerified: true,
        minimumNecessaryVerified: false,
      ),
      throwsFormatException,
    );
  });

  test('workflow status is attention lifecycle only', () {
    expect(
      AgentOwnerAttentionStatus.values,
      containsAll(<String>{
        AgentOwnerAttentionStatus.pendingReview,
        AgentOwnerAttentionStatus.acknowledged,
        AgentOwnerAttentionStatus.inReview,
        AgentOwnerAttentionStatus.resolved,
        AgentOwnerAttentionStatus.dismissed,
      }),
    );

    final candidate = event(status: AgentOwnerAttentionStatus.inReview);
    expect(candidate.mayResolveSourceRecord, false);
    expect(candidate.mayConsumeApproval, false);
  });

  test(
    'Email Attention is a supported source type without adding a tenth category',
    () {
      expect(
        AgentOwnerAttentionSourceType.values,
        contains(AgentOwnerAttentionSourceType.emailAttention),
      );
      expect(AgentOwnerAttentionCategory.values.length, 9);
    },
  );

  test('unified event grants zero consequential authority', () {
    final candidate = event();

    expect(candidate.mayExecuteBusinessAction, false);
    expect(candidate.mayConsumeApproval, false);
    expect(candidate.mayGrantPermission, false);
    expect(candidate.mayOverrideRuntimeGate, false);
    expect(candidate.mayCallProvider, false);
    expect(candidate.maySendMessage, false);
    expect(candidate.mayTransferMoney, false);
    expect(candidate.mayResolveSourceRecord, false);
    expect(candidate.mayDeleteSourceRecord, false);
  });

  test('contract service grants zero execution authority', () {
    expect(contract.contractValidationOnly, true);
    expect(contract.writesInbox, false);
    expect(contract.readsFirestore, false);
    expect(contract.writesFirestore, false);
    expect(contract.consumesApproval, false);
    expect(contract.grantsPermission, false);
    expect(contract.overridesRuntimeGate, false);
    expect(contract.callsProvider, false);
    expect(contract.executesBusinessAction, false);
    expect(contract.mutatesSourceRecord, false);
    expect(contract.deletesSourceRecord, false);
    expect(priorityPolicy.priorityGrantsAuthority, false);
  });
}

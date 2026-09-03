import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_email_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_conversation_grounding_assessment.dart';
import 'package:swat_ride/ai_agent/models/agent_conversation_quality_decision.dart';
import 'package:swat_ride/ai_agent/models/agent_email_draft.dart';
import 'package:swat_ride/ai_agent/models/agent_email_draft_policy_decision.dart';
import 'package:swat_ride/ai_agent/services/agent_email_draft_builder.dart';

void main() {
  const AgentEmailDraftBuilder builder = AgentEmailDraftBuilder();

  AgentConversationGroundingSource verifiedSource({
    bool fresh = true,
    bool supportsClaim = true,
    bool contradictsClaim = false,
  }) {
    return AgentConversationGroundingSource(
      evidence: const AgentConversationEvidenceRef(
        sourceId: 'synthetic_verified_booking',
        sourceType: 'SYNTHETIC_TEST',
        summary: 'Synthetic verified support fact.',
        verified: true,
      ),
      fresh: fresh,
      supportsClaim: supportsClaim,
      contradictsClaim: contradictsClaim,
    );
  }

  AgentEmailDraftBuildResult build({
    List<AgentConversationGroundingSource> sources =
        const <AgentConversationGroundingSource>[],
    String proposedBody = 'Your booking is confirmed.',
    String fallbackBody =
        'I cannot verify that booking detail yet. Please allow us to confirm it.',
    bool attachment = false,
    int recipientCount = 1,
  }) {
    return builder.build(
      draftId: 'email_builder_test',
      purpose: AgentEmailPurpose.supportReply,
      senderIdentityId: 'verified_sender_identity',
      to: List<AgentEmailAddress>.generate(
        recipientCount,
        (int index) => AgentEmailAddress(address: 'customer$index@example.com'),
      ),
      subject: 'Support update',
      proposedBodyText: proposedBody,
      safeFallbackBodyText: fallbackBody,
      sources: sources,
      attachments: attachment
          ? const <AgentEmailAttachmentRef>[
              AgentEmailAttachmentRef(
                attachmentId: 'att1',
                fileName: 'guide.pdf',
                contentType: 'application/pdf',
                sizeBytes: 100,
              ),
            ]
          : const <AgentEmailAttachmentRef>[],
      createdAt: DateTime.utc(2026, 8, 17),
    );
  }

  test('verified evidence allows proposed body into draft', () {
    final AgentEmailDraftBuildResult result = build(
      sources: <AgentConversationGroundingSource>[verifiedSource()],
    );

    expect(result.blocked, isFalse);
    expect(result.hasReadyDraft, isTrue);
    expect(result.usedSafeFallbackBody, isFalse);
    expect(result.draft!.bodyText, 'Your booking is confirmed.');
    expect(result.draft!.status, AgentEmailDraftStatus.approvalRequired);
    expect(result.requiresSendApproval, isTrue);
    expect(result.maySend, isFalse);
  });

  test('missing evidence blocks proposed body and uses safe fallback', () {
    final AgentEmailDraftBuildResult result = build();

    expect(result.blocked, isFalse);
    expect(result.hasReadyDraft, isTrue);
    expect(result.usedSafeFallbackBody, isTrue);
    expect(
      result.draft!.bodyText,
      'I cannot verify that booking detail yet. Please allow us to confirm it.',
    );
    expect(
      result.draft!.bodyText,
      isNot(contains('Your booking is confirmed.')),
    );
    expect(result.guardResult.visibleAnswerText, isEmpty);
  });

  test('conflicting evidence blocks proposed body and uses fallback', () {
    final AgentEmailDraftBuildResult result = build(
      sources: <AgentConversationGroundingSource>[
        verifiedSource(supportsClaim: false, contradictsClaim: true),
      ],
    );

    expect(result.usedSafeFallbackBody, isTrue);
    expect(result.guardResult.visibleAnswerText, isEmpty);
    expect(
      result.draft!.bodyText,
      isNot(contains('Your booking is confirmed.')),
    );
  });

  test('stale evidence with freshness required uses fallback', () {
    final AgentEmailDraftBuildResult result = builder.build(
      draftId: 'stale_test',
      purpose: AgentEmailPurpose.supportReply,
      senderIdentityId: 'verified_sender_identity',
      to: const <AgentEmailAddress>[
        AgentEmailAddress(address: 'customer@example.com'),
      ],
      subject: 'Support update',
      proposedBodyText: 'Your driver is currently at the pickup point.',
      safeFallbackBodyText:
          'I need to refresh the live status before confirming the driver location.',
      sources: <AgentConversationGroundingSource>[verifiedSource(fresh: false)],
      freshnessRequired: true,
      canVerifyFresh: false,
      createdAt: DateTime.utc(2026, 8, 17),
    );

    expect(result.usedSafeFallbackBody, isTrue);
    expect(
      result.draft!.bodyText,
      isNot(contains('currently at the pickup point')),
    );
  });

  test('missing evidence and empty fallback fails closed', () {
    expect(
      () => build(fallbackBody: '   '),
      throwsA(isA<AgentEmailDraftBuilderException>()),
    );
  });

  test('policy-blocked credential value produces no ready draft', () {
    final AgentEmailDraftBuildResult result = build(
      sources: <AgentConversationGroundingSource>[verifiedSource()],
      proposedBody: 'OTP: 123456',
    );

    expect(result.blocked, isTrue);
    expect(result.hasReadyDraft, isFalse);
    expect(result.draft, isNull);
    expect(
      result.policyDecision.classification,
      AgentEmailDraftPolicyClassification.blocked,
    );
  });

  test('attachment marks final draft as needs review', () {
    final AgentEmailDraftBuildResult result = build(
      sources: <AgentConversationGroundingSource>[verifiedSource()],
      attachment: true,
    );

    expect(result.blocked, isFalse);
    expect(result.draft!.status, AgentEmailDraftStatus.needsReview);
    expect(result.policyDecision.requiresAttachmentReview, isTrue);
  });

  test('bulk recipient policy blocks ready draft', () {
    final AgentEmailDraftBuildResult result = build(
      sources: <AgentConversationGroundingSource>[verifiedSource()],
      recipientCount: 11,
    );

    expect(result.blocked, isTrue);
    expect(result.draft, isNull);
    expect(
      result.policyDecision.reasonCodes,
      contains('BULK_RECIPIENT_LIMIT_EXCEEDED'),
    );
  });

  test('builder exposes zero send/runtime/provider authority', () {
    expect(builder.providerExecutionAllowed, isFalse);
    expect(builder.smtpExecutionAllowed, isFalse);
    expect(builder.firestoreReadAllowed, isFalse);
    expect(builder.firestoreWriteAllowed, isFalse);
    expect(builder.runtimeActionAllowed, isFalse);
    expect(builder.permissionGrantAllowed, isFalse);
    expect(builder.approvalConsumptionAllowed, isFalse);
    expect(builder.mailboxReadAllowed, isFalse);
    expect(builder.mailboxWriteAllowed, isFalse);
    expect(builder.promptMutationAllowed, isFalse);
    expect(builder.modelTrainingAllowed, isFalse);
    expect(builder.deploymentAllowed, isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_email_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_email_draft.dart';
import 'package:swat_ride/ai_agent/models/agent_email_draft_policy_decision.dart';
import 'package:swat_ride/ai_agent/services/agent_email_draft_policy.dart';

void main() {
  const AgentEmailDraftPolicy policy = AgentEmailDraftPolicy();

  AgentEmailDraft draft({
    int recipientCount = 1,
    bool bcc = false,
    bool attachment = false,
    String subject = 'Support update',
    String body = 'Synthetic support information.',
  }) {
    final List<AgentEmailAddress> recipients = List<AgentEmailAddress>.generate(
      recipientCount,
      (int index) => AgentEmailAddress(address: 'user$index@example.com'),
    );

    return AgentEmailDraft(
      draftId: 'policy_test',
      purpose: AgentEmailPurpose.supportReply,
      senderIdentityId: 'verified_sender_identity',
      to: recipients,
      bcc: bcc
          ? const <AgentEmailAddress>[
              AgentEmailAddress(address: 'audit@example.com'),
            ]
          : const <AgentEmailAddress>[],
      subject: subject,
      bodyText: body,
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

  test('simple structured draft is ready for human review', () {
    final AgentEmailDraftPolicyDecision result = policy.assess(draft());

    expect(
      result.classification,
      AgentEmailDraftPolicyClassification.draftReadyForReview,
    );
    expect(result.requiresSendApproval, isTrue);
    expect(result.maySend, isFalse);
    expect(result.mayRemainAsDraft, isTrue);
  });

  test('six recipients require human review', () {
    final AgentEmailDraftPolicyDecision result = policy.assess(
      draft(recipientCount: 6),
    );

    expect(
      result.classification,
      AgentEmailDraftPolicyClassification.needsHumanReview,
    );
    expect(result.reasonCodes, contains('MULTI_RECIPIENT_HUMAN_REVIEW'));
  });

  test('eleven recipients fail closed as bulk outreach', () {
    final AgentEmailDraftPolicyDecision result = policy.assess(
      draft(recipientCount: 11),
    );

    expect(result.classification, AgentEmailDraftPolicyClassification.blocked);
    expect(result.reasonCodes, contains('BULK_RECIPIENT_LIMIT_EXCEEDED'));
    expect(result.mayRemainAsDraft, isFalse);
  });

  test('bcc requires human review', () {
    final AgentEmailDraftPolicyDecision result = policy.assess(
      draft(bcc: true),
    );

    expect(
      result.classification,
      AgentEmailDraftPolicyClassification.needsHumanReview,
    );
    expect(result.reasonCodes, contains('BCC_REQUIRES_HUMAN_REVIEW'));
  });

  test('attachment requires separate review', () {
    final AgentEmailDraftPolicyDecision result = policy.assess(
      draft(attachment: true),
    );

    expect(result.requiresAttachmentReview, isTrue);
    expect(
      result.classification,
      AgentEmailDraftPolicyClassification.needsHumanReview,
    );
  });

  test('embedded password value fails closed', () {
    final AgentEmailDraftPolicyDecision result = policy.assess(
      draft(body: 'Password: super-secret-value'),
    );

    expect(result.classification, AgentEmailDraftPolicyClassification.blocked);
    expect(result.containsSensitiveCredentialPattern, isTrue);
  });

  test('embedded OTP value fails closed', () {
    final AgentEmailDraftPolicyDecision result = policy.assess(
      draft(body: 'OTP: 123456'),
    );

    expect(result.classification, AgentEmailDraftPolicyClassification.blocked);
    expect(result.containsSensitiveCredentialPattern, isTrue);
  });

  test('request to share OTP fails closed', () {
    final AgentEmailDraftPolicyDecision result = policy.assess(
      draft(body: 'Please reply with your OTP so we can continue.'),
    );

    expect(result.classification, AgentEmailDraftPolicyClassification.blocked);
    expect(result.containsSuspiciousRequestPattern, isTrue);
  });

  test('request to send password fails closed', () {
    final AgentEmailDraftPolicyDecision result = policy.assess(
      draft(body: 'Please send your password to support.'),
    );

    expect(result.classification, AgentEmailDraftPolicyClassification.blocked);
    expect(result.containsSuspiciousRequestPattern, isTrue);
  });

  test('do not share password security advice remains draftable', () {
    final AgentEmailDraftPolicyDecision result = policy.assess(
      draft(body: 'For your security, do not share your password with anyone.'),
    );

    expect(
      result.classification,
      AgentEmailDraftPolicyClassification.draftReadyForReview,
    );
    expect(result.containsSensitiveCredentialPattern, isFalse);
    expect(result.containsSuspiciousRequestPattern, isFalse);
  });

  test('never send OTP security advice remains draftable', () {
    final AgentEmailDraftPolicyDecision result = policy.assess(
      draft(
        body: 'Never send your OTP to another person, including support staff.',
      ),
    );

    expect(
      result.classification,
      AgentEmailDraftPolicyClassification.draftReadyForReview,
    );
    expect(result.containsSuspiciousRequestPattern, isFalse);
  });

  test('we will never ask for password remains draftable', () {
    final AgentEmailDraftPolicyDecision result = policy.assess(
      draft(body: 'We will never ask for your password or OTP by email.'),
    );

    expect(
      result.classification,
      AgentEmailDraftPolicyClassification.draftReadyForReview,
    );
    expect(result.containsSuspiciousRequestPattern, isFalse);
  });

  test('policy exposes zero send/runtime/provider authority', () {
    expect(policy.providerExecutionAllowed, isFalse);
    expect(policy.smtpExecutionAllowed, isFalse);
    expect(policy.firestoreReadAllowed, isFalse);
    expect(policy.firestoreWriteAllowed, isFalse);
    expect(policy.runtimeActionAllowed, isFalse);
    expect(policy.permissionGrantAllowed, isFalse);
    expect(policy.approvalConsumptionAllowed, isFalse);
    expect(policy.mailboxReadAllowed, isFalse);
    expect(policy.mailboxWriteAllowed, isFalse);
    expect(policy.promptMutationAllowed, isFalse);
    expect(policy.modelTrainingAllowed, isFalse);
    expect(policy.deploymentAllowed, isFalse);
  });
}

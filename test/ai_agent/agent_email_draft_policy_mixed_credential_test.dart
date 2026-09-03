import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_email_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_email_draft.dart';
import 'package:swat_ride/ai_agent/models/agent_email_draft_policy_decision.dart';
import 'package:swat_ride/ai_agent/services/agent_email_draft_policy.dart';

void main() {
  const AgentEmailDraftPolicy policy = AgentEmailDraftPolicy();

  AgentEmailDraft draft(String body) {
    return AgentEmailDraft(
      draftId: 'phase44_f1_policy_test',
      purpose: AgentEmailPurpose.supportReply,
      senderIdentityId: 'verified_sender_identity',
      to: const <AgentEmailAddress>[
        AgentEmailAddress(address: 'customer@example.com'),
      ],
      subject: 'Security notice',
      bodyText: body,
      createdAt: DateTime.utc(2026, 8, 17),
    );
  }

  test('protective password advice alone remains draftable', () {
    final AgentEmailDraftPolicyDecision result = policy.assess(
      draft('For your security, do not share your password with anyone.'),
    );

    expect(
      result.classification,
      AgentEmailDraftPolicyClassification.draftReadyForReview,
    );
    expect(result.containsSuspiciousRequestPattern, isFalse);
  });

  test('protective never-ask advice alone remains draftable', () {
    final AgentEmailDraftPolicyDecision result = policy.assess(
      draft('We will never ask for your password or OTP by email.'),
    );

    expect(
      result.classification,
      AgentEmailDraftPolicyClassification.draftReadyForReview,
    );
    expect(result.containsSuspiciousRequestPattern, isFalse);
  });

  test('protective password sentence cannot hide OTP request', () {
    final AgentEmailDraftPolicyDecision result = policy.assess(
      draft('Do not share your password. Please send your OTP to support.'),
    );

    expect(result.classification, AgentEmailDraftPolicyClassification.blocked);
    expect(result.containsSuspiciousRequestPattern, isTrue);
    expect(result.reasonCodes, contains('SUSPICIOUS_CREDENTIAL_REQUEST'));
    expect(result.maySend, isFalse);
    expect(result.mayRemainAsDraft, isFalse);
  });

  test('never-ask password sentence cannot hide reply-with-OTP request', () {
    final AgentEmailDraftPolicyDecision result = policy.assess(
      draft('We will never ask for your password. Please reply with your OTP.'),
    );

    expect(result.classification, AgentEmailDraftPolicyClassification.blocked);
    expect(result.containsSuspiciousRequestPattern, isTrue);
    expect(result.reasonCodes, contains('SUSPICIOUS_CREDENTIAL_REQUEST'));
    expect(result.maySend, isFalse);
  });

  test('protective API key advice cannot hide access-token request', () {
    final AgentEmailDraftPolicyDecision result = policy.assess(
      draft(
        'Never share your API key. Please provide your access token to support.',
      ),
    );

    expect(result.classification, AgentEmailDraftPolicyClassification.blocked);
    expect(result.containsSuspiciousRequestPattern, isTrue);
    expect(result.reasonCodes, contains('SUSPICIOUS_CREDENTIAL_REQUEST'));
  });

  test('policy still exposes zero execution authority', () {
    expect(policy.providerExecutionAllowed, isFalse);
    expect(policy.smtpExecutionAllowed, isFalse);
    expect(policy.firestoreReadAllowed, isFalse);
    expect(policy.firestoreWriteAllowed, isFalse);
    expect(policy.runtimeActionAllowed, isFalse);
    expect(policy.permissionGrantAllowed, isFalse);
    expect(policy.approvalConsumptionAllowed, isFalse);
    expect(policy.mailboxReadAllowed, isFalse);
    expect(policy.mailboxWriteAllowed, isFalse);
    expect(policy.deploymentAllowed, isFalse);
  });
}

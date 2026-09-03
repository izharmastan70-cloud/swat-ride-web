import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_email_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_email_draft.dart';

void main() {
  AgentEmailDraft validDraft({
    List<AgentEmailAddress>? to,
    List<AgentEmailAddress> cc = const <AgentEmailAddress>[],
    List<AgentEmailAddress> bcc = const <AgentEmailAddress>[],
    String subject = 'Support update',
    String bodyText = 'This is a structured synthetic email draft.',
    List<AgentEmailAttachmentRef> attachments =
        const <AgentEmailAttachmentRef>[],
  }) {
    return AgentEmailDraft(
      draftId: 'email_draft_test_1',
      purpose: AgentEmailPurpose.supportReply,
      senderIdentityId: 'verified_sender_identity',
      to:
          to ??
          const <AgentEmailAddress>[
            AgentEmailAddress(address: 'customer@example.com'),
          ],
      cc: cc,
      bcc: bcc,
      subject: subject,
      bodyText: bodyText,
      attachments: attachments,
      createdAt: DateTime.utc(2026, 8, 17),
    );
  }

  test('valid structured email draft passes validation', () {
    final AgentEmailDraft draft = validDraft();

    expect(() => draft.validate(), returnsNormally);
    expect(draft.requiresApprovalToSend, isTrue);
    expect(draft.maySend, isFalse);
  });

  test('requires at least one explicit TO recipient', () {
    final AgentEmailDraft draft = validDraft(to: const <AgentEmailAddress>[]);

    expect(draft.validate, throwsA(isA<AgentEmailDraftException>()));
  });

  test('rejects invalid email address', () {
    final AgentEmailDraft draft = validDraft(
      to: const <AgentEmailAddress>[AgentEmailAddress(address: 'not-an-email')],
    );

    expect(draft.validate, throwsA(isA<AgentEmailDraftException>()));
  });

  test('rejects duplicate recipient across TO and CC', () {
    final AgentEmailDraft draft = validDraft(
      to: const <AgentEmailAddress>[
        AgentEmailAddress(address: 'same@example.com'),
      ],
      cc: const <AgentEmailAddress>[
        AgentEmailAddress(address: 'SAME@example.com'),
      ],
    );

    expect(draft.validate, throwsA(isA<AgentEmailDraftException>()));
  });

  test('rejects subject header line breaks', () {
    final AgentEmailDraft draft = validDraft(
      subject: 'Hello\nBcc: attacker@example.com',
    );

    expect(draft.validate, throwsA(isA<AgentEmailDraftException>()));
  });

  test('rejects empty email body', () {
    final AgentEmailDraft draft = validDraft(bodyText: '   ');

    expect(draft.validate, throwsA(isA<AgentEmailDraftException>()));
  });

  test('rejects duplicate attachment ids', () {
    final AgentEmailDraft draft = validDraft(
      attachments: const <AgentEmailAttachmentRef>[
        AgentEmailAttachmentRef(
          attachmentId: 'a1',
          fileName: 'first.pdf',
          contentType: 'application/pdf',
          sizeBytes: 10,
        ),
        AgentEmailAttachmentRef(
          attachmentId: 'a1',
          fileName: 'second.pdf',
          contentType: 'application/pdf',
          sizeBytes: 20,
        ),
      ],
    );

    expect(draft.validate, throwsA(isA<AgentEmailDraftException>()));
  });

  test('serialization preserves draft-only safety state', () {
    final AgentEmailDraft original = validDraft();
    original.validate();

    final AgentEmailDraft restored = AgentEmailDraft.fromMap(original.toMap());

    expect(restored.draftId, original.draftId);
    expect(restored.to.single.address, 'customer@example.com');
    expect(restored.requiresApprovalToSend, isTrue);
    expect(restored.maySend, isFalse);
  });

  test('email draft exposes zero send/runtime/provider authority', () {
    final AgentEmailDraft draft = validDraft();

    expect(draft.maySend, isFalse);
    expect(draft.mayGrantPermission, isFalse);
    expect(draft.mayConsumeApproval, isFalse);
    expect(draft.mayWriteBusinessData, isFalse);
    expect(draft.mayCallProvider, isFalse);
    expect(draft.mayOpenNetworkConnection, isFalse);
    expect(draft.mayReadMailbox, isFalse);
    expect(draft.mayWriteMailbox, isFalse);
    expect(draft.mayChangePrompt, isFalse);
    expect(draft.mayTrainModel, isFalse);
    expect(draft.mayDeploy, isFalse);
  });
}

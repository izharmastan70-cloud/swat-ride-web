import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_conversation_quality_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_email_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_email_draft.dart';
import 'package:swat_ride/ai_agent/models/agent_email_send_authorization_request.dart';
import 'package:swat_ride/ai_agent/services/agent_email_draft_binding_service.dart';

void main() {
  const AgentEmailDraftBindingService bindingService =
      AgentEmailDraftBindingService();

  const AgentEmailSendAuthorizationFactory factory =
      AgentEmailSendAuthorizationFactory();

  AgentEmailDraft draft({
    String senderIdentityId = 'verified_sender_identity',
    String recipient = 'customer@example.com',
    String subject = 'Booking update',
    String body = 'Your verified booking update is ready.',
    String status = AgentEmailDraftStatus.approvalRequired,
    bool attachment = false,
  }) {
    return AgentEmailDraft(
      draftId: 'draft_44_d2',
      purpose: AgentEmailPurpose.supportReply,
      senderIdentityId: senderIdentityId,
      to: <AgentEmailAddress>[AgentEmailAddress(address: recipient)],
      subject: subject,
      bodyText: body,
      attachments: attachment
          ? const <AgentEmailAttachmentRef>[
              AgentEmailAttachmentRef(
                attachmentId: 'att_1',
                fileName: 'guide.pdf',
                contentType: 'application/pdf',
                sizeBytes: 100,
              ),
            ]
          : const <AgentEmailAttachmentRef>[],
      status: status,
      createdAt: DateTime.utc(2026, 8, 17, 1),
    );
  }

  AgentEmailSendAuthorizationRequest requestFor(AgentEmailDraft value) {
    return factory.create(
      authorizationRequestId: 'auth_req_1',
      roleId: 'synthetic_email_agent',
      actionId: 'synthetic.email_send',
      module: 'email',
      requestedBy: 'owner_test',
      risk: AgentConversationRisk.medium,
      draft: value,
      createdAt: DateTime.utc(2026, 8, 17, 1, 5),
    );
  }

  test('same draft produces deterministic exact binding', () {
    final AgentEmailDraft value = draft();

    final AgentEmailDraftBinding first = bindingService.bind(value);
    final AgentEmailDraftBinding second = bindingService.bind(value);

    expect(first.algorithm, AgentEmailDraftBindingService.algorithm);
    expect(first.fingerprint, second.fingerprint);
    expect(first.exactDraftMatchRequired, isTrue);
    expect(bindingService.matches(draft: value, binding: first), isTrue);
  });

  test('authorization request exposes central security requirements only', () {
    final AgentEmailSendAuthorizationRequest request = requestFor(draft());

    expect(request.requiresCentralPermissionEngine, isTrue);
    expect(request.requiresCentralApprovalService, isTrue);
    expect(request.requiresRuntimeGateBeforeSend, isTrue);
    expect(request.requiresOneTimeApprovalConsumption, isTrue);
    expect(request.exactDraftMatchRequired, isTrue);
    expect(request.maySend, isFalse);
    expect(request.mayGrantPermission, isFalse);
    expect(request.mayConsumeApproval, isFalse);
  });

  test('approval action scope binds exact draft fingerprint', () {
    final AgentEmailSendAuthorizationRequest request = requestFor(draft());

    final Map<String, dynamic> scope = request.toApprovalActionScope();

    expect(scope['draftId'], 'draft_44_d2');
    expect(scope['exactDraftMatchRequired'], isTrue);
    expect(scope['oneActionOnly'], isTrue);
    expect(scope['oneTimeConsumptionRequired'], isTrue);

    final Map<String, dynamic> binding = Map<String, dynamic>.from(
      scope['binding'] as Map,
    );

    expect(binding['fingerprint'], request.binding.fingerprint);
  });

  test('body change invalidates approved draft binding', () {
    final AgentEmailDraft original = draft();
    final AgentEmailSendAuthorizationRequest request = requestFor(original);

    final AgentEmailDraft changed = draft(body: 'Different body content.');

    expect(
      factory.stillMatchesApprovedDraft(
        request: request,
        currentDraft: changed,
      ),
      isFalse,
    );
  });

  test('subject change invalidates approved draft binding', () {
    final AgentEmailDraft original = draft();
    final AgentEmailSendAuthorizationRequest request = requestFor(original);

    expect(
      factory.stillMatchesApprovedDraft(
        request: request,
        currentDraft: draft(subject: 'Changed subject'),
      ),
      isFalse,
    );
  });

  test('recipient change invalidates approved draft binding', () {
    final AgentEmailSendAuthorizationRequest request = requestFor(draft());

    expect(
      factory.stillMatchesApprovedDraft(
        request: request,
        currentDraft: draft(recipient: 'other@example.com'),
      ),
      isFalse,
    );
  });

  test('sender identity change invalidates approved draft binding', () {
    final AgentEmailSendAuthorizationRequest request = requestFor(draft());

    expect(
      factory.stillMatchesApprovedDraft(
        request: request,
        currentDraft: draft(senderIdentityId: 'different_sender'),
      ),
      isFalse,
    );
  });

  test('attachment change invalidates approved draft binding', () {
    final AgentEmailSendAuthorizationRequest request = requestFor(draft());

    expect(
      factory.stillMatchesApprovedDraft(
        request: request,
        currentDraft: draft(attachment: true),
      ),
      isFalse,
    );
  });

  test('NEEDS_REVIEW draft cannot create send authorization request', () {
    expect(
      () => requestFor(draft(status: AgentEmailDraftStatus.needsReview)),
      throwsA(isA<AgentEmailSendAuthorizationException>()),
    );
  });

  test('DRAFT status cannot create send authorization request', () {
    expect(
      () => requestFor(draft(status: AgentEmailDraftStatus.draft)),
      throwsA(isA<AgentEmailSendAuthorizationException>()),
    );
  });

  test('binding/factory expose zero transport/runtime/provider authority', () {
    expect(bindingService.providerExecutionAllowed, isFalse);
    expect(bindingService.smtpExecutionAllowed, isFalse);
    expect(bindingService.firestoreReadAllowed, isFalse);
    expect(bindingService.firestoreWriteAllowed, isFalse);
    expect(bindingService.runtimeActionAllowed, isFalse);
    expect(bindingService.permissionGrantAllowed, isFalse);
    expect(bindingService.approvalConsumptionAllowed, isFalse);
    expect(bindingService.mailboxReadAllowed, isFalse);
    expect(bindingService.mailboxWriteAllowed, isFalse);
    expect(bindingService.deploymentAllowed, isFalse);

    expect(factory.providerExecutionAllowed, isFalse);
    expect(factory.smtpExecutionAllowed, isFalse);
    expect(factory.firestoreReadAllowed, isFalse);
    expect(factory.firestoreWriteAllowed, isFalse);
    expect(factory.runtimeActionAllowed, isFalse);
    expect(factory.permissionGrantAllowed, isFalse);
    expect(factory.approvalConsumptionAllowed, isFalse);
    expect(factory.mailboxReadAllowed, isFalse);
    expect(factory.mailboxWriteAllowed, isFalse);
    expect(factory.deploymentAllowed, isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/constants/agent_conversation_quality_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_email_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_approval_request.dart';
import 'package:swat_ride/ai_agent/models/agent_email_delivery_receipt.dart';
import 'package:swat_ride/ai_agent/models/agent_email_draft.dart';
import 'package:swat_ride/ai_agent/models/agent_email_send_authorization_request.dart';
import 'package:swat_ride/ai_agent/models/agent_email_sender_identity.dart';
import 'package:swat_ride/ai_agent/models/agent_email_transport_handoff.dart';
import 'package:swat_ride/ai_agent/services/agent_email_send_execution_boundary.dart';
import 'package:swat_ride/ai_agent/services/agent_email_transport.dart';
import 'package:swat_ride/ai_agent/services/agent_email_transport_handoff_factory.dart';

void main() {
  const AgentEmailSendAuthorizationFactory authorizationFactory =
      AgentEmailSendAuthorizationFactory();

  const AgentEmailTransportHandoffFactory handoffFactory =
      AgentEmailTransportHandoffFactory();

  AgentEmailDraft draft() {
    return AgentEmailDraft(
      draftId: 'draft_f3a',
      purpose: AgentEmailPurpose.supportReply,
      senderIdentityId: 'sender_primary',
      to: const <AgentEmailAddress>[
        AgentEmailAddress(address: 'customer@example.com'),
      ],
      subject: 'Verified update',
      bodyText: 'Your verified update is ready.',
      status: AgentEmailDraftStatus.approvalRequired,
      createdAt: DateTime.utc(2026, 8, 17, 7),
    );
  }

  AgentEmailSendAuthorizationRequest authorization(
    AgentEmailDraft currentDraft,
  ) {
    return authorizationFactory.create(
      authorizationRequestId: 'auth_f3a',
      roleId: 'email_agent',
      actionId: AgentActionId.sendEmail,
      module: 'email',
      requestedBy: 'owner_test',
      risk: AgentConversationRisk.medium,
      draft: currentDraft,
      createdAt: DateTime.utc(2026, 8, 17, 7, 1),
    );
  }

  AgentApprovalRequest consumedApproval(
    AgentEmailSendAuthorizationRequest request,
  ) {
    return AgentApprovalRequest(
      approvalId: 'approval_f3a',
      roleId: request.roleId,
      actionId: request.actionId,
      module: request.module,
      reason: 'Synthetic exact approval.',
      risk: request.risk,
      requestedBy: request.requestedBy,
      actionScope: request.toApprovalActionScope(),
      status: AgentApprovalStatus.consumed,
      createdAt: DateTime.utc(2026, 8, 17, 7, 2),
      expiresAt: DateTime.utc(2026, 8, 17, 7, 20),
      decidedAt: DateTime.utc(2026, 8, 17, 7, 3),
      consumedAt: DateTime.utc(2026, 8, 17, 7, 4),
      decidedBy: 'owner_test',
      decisionNote: 'Synthetic consumed approval.',
    );
  }

  AgentEmailSendBoundaryResult consumedBoundary(
    AgentEmailSendAuthorizationRequest request,
  ) {
    return AgentEmailSendBoundaryResult(
      status: AgentEmailSendBoundaryStatus.approvalConsumed,
      authorizationRequestId: request.authorizationRequestId,
      approvalId: 'approval_f3a',
      preflight: null,
      consumedApproval: consumedApproval(request),
      reason: 'Synthetic transport handoff test.',
    );
  }

  AgentEmailSenderIdentity verifiedIdentity({
    bool enabled = true,
    DateTime? verifiedAt,
    String senderIdentityId = 'sender_primary',
  }) {
    return AgentEmailSenderIdentity(
      senderIdentityId: senderIdentityId,
      providerId: 'future_provider',
      fromAddress: 'support@swatride.example',
      displayName: 'SWAT RIDE Support',
      enabled: enabled,
      verifiedAt: verifiedAt ?? DateTime.utc(2026, 8, 17, 6),
    );
  }

  test('verified identity contains no provider credential material', () {
    final AgentEmailSenderIdentity identity = verifiedIdentity();

    identity.validate();

    expect(identity.isVerified, isTrue);
    expect(identity.mayBeUsedForTransport, isTrue);
    expect(identity.containsCredentialMaterial, isFalse);
    expect(identity.mayStoreProviderSecret, isFalse);
    expect(identity.mayStorePassword, isFalse);
    expect(identity.mayStoreApiKey, isFalse);
  });

  test('consumed approval can create provider-neutral handoff', () {
    final AgentEmailDraft currentDraft = draft();
    final AgentEmailSendAuthorizationRequest request = authorization(
      currentDraft,
    );

    final AgentEmailTransportHandoff handoff = handoffFactory.create(
      handoffId: 'handoff_f3a',
      boundaryResult: consumedBoundary(request),
      authorizationRequest: request,
      currentDraft: currentDraft,
      senderIdentity: verifiedIdentity(),
      createdAt: DateTime.utc(2026, 8, 17, 7, 5),
    );

    expect(handoff.approvalAlreadyConsumed, isTrue);
    expect(handoff.senderIdentityId, 'sender_primary');
    expect(handoff.providerId, 'future_provider');
    expect(handoff.to, <String>['customer@example.com']);
    expect(handoff.maySend, isFalse);
    expect(handoff.mayCallProvider, isFalse);
  });

  test('non-consumed approval boundary cannot create handoff', () {
    final AgentEmailDraft currentDraft = draft();
    final AgentEmailSendAuthorizationRequest request = authorization(
      currentDraft,
    );

    final AgentEmailSendBoundaryResult notConsumed =
        AgentEmailSendBoundaryResult(
          status: AgentEmailSendBoundaryStatus.readyForConsumption,
          authorizationRequestId: request.authorizationRequestId,
          approvalId: 'approval_f3a',
          preflight: null,
          consumedApproval: null,
          reason: 'Not consumed.',
        );

    expect(
      () => handoffFactory.create(
        handoffId: 'handoff_f3a',
        boundaryResult: notConsumed,
        authorizationRequest: request,
        currentDraft: currentDraft,
        senderIdentity: verifiedIdentity(),
      ),
      throwsA(isA<AgentEmailTransportHandoffFactoryException>()),
    );
  });

  test('sender identity mismatch cannot create handoff', () {
    final AgentEmailDraft currentDraft = draft();
    final AgentEmailSendAuthorizationRequest request = authorization(
      currentDraft,
    );

    expect(
      () => handoffFactory.create(
        handoffId: 'handoff_f3a',
        boundaryResult: consumedBoundary(request),
        authorizationRequest: request,
        currentDraft: currentDraft,
        senderIdentity: verifiedIdentity(senderIdentityId: 'different_sender'),
      ),
      throwsA(isA<AgentEmailTransportHandoffFactoryException>()),
    );
  });

  test('unverified sender identity cannot create handoff', () {
    final AgentEmailDraft currentDraft = draft();
    final AgentEmailSendAuthorizationRequest request = authorization(
      currentDraft,
    );

    final AgentEmailSenderIdentity unverified = AgentEmailSenderIdentity(
      senderIdentityId: 'sender_primary',
      providerId: 'future_provider',
      fromAddress: 'support@swatride.example',
      displayName: 'SWAT RIDE Support',
      enabled: true,
      verifiedAt: null,
    );

    expect(
      () => handoffFactory.create(
        handoffId: 'handoff_f3a',
        boundaryResult: consumedBoundary(request),
        authorizationRequest: request,
        currentDraft: currentDraft,
        senderIdentity: unverified,
      ),
      throwsA(isA<AgentEmailTransportHandoffFactoryException>()),
    );
  });

  test(
    'disabled transport returns disabled receipt and performs no live send',
    () async {
      final AgentEmailDraft currentDraft = draft();
      final AgentEmailSendAuthorizationRequest request = authorization(
        currentDraft,
      );

      final AgentEmailTransportHandoff handoff = handoffFactory.create(
        handoffId: 'handoff_f3a',
        boundaryResult: consumedBoundary(request),
        authorizationRequest: request,
        currentDraft: currentDraft,
        senderIdentity: verifiedIdentity(),
      );

      const DisabledAgentEmailTransport transport =
          DisabledAgentEmailTransport();

      final AgentEmailDeliveryReceipt receipt = await transport.deliver(
        handoff,
      );

      expect(transport.enabled, isFalse);
      expect(transport.liveSendCapable, isFalse);
      expect(transport.networkAccessAllowed, isFalse);
      expect(transport.smtpAccessAllowed, isFalse);
      expect(transport.mailboxWriteAllowed, isFalse);
      expect(transport.providerSecretAccessAllowed, isFalse);
      expect(receipt.disabled, isTrue);
      expect(receipt.attempted, isFalse);
      expect(receipt.acceptedOrDelivered, isFalse);
    },
  );

  test('handoff factory exposes zero execution authority', () {
    expect(handoffFactory.maySend, isFalse);
    expect(handoffFactory.mayCallProvider, isFalse);
    expect(handoffFactory.mayReadMailbox, isFalse);
    expect(handoffFactory.mayWriteMailbox, isFalse);
    expect(handoffFactory.mayConsumeApproval, isFalse);
    expect(handoffFactory.mayDeploy, isFalse);
  });
}

import '../constants/agent_action_ids.dart';
import '../models/agent_email_draft.dart';
import '../models/agent_email_send_authorization_request.dart';
import '../models/agent_email_sender_identity.dart';
import '../models/agent_email_transport_handoff.dart';
import 'agent_email_send_execution_boundary.dart';

class AgentEmailTransportHandoffFactory {
  const AgentEmailTransportHandoffFactory({
    this.authorizationFactory = const AgentEmailSendAuthorizationFactory(),
  });

  final AgentEmailSendAuthorizationFactory authorizationFactory;

  bool get maySend => false;
  bool get mayCallProvider => false;
  bool get mayReadMailbox => false;
  bool get mayWriteMailbox => false;
  bool get mayConsumeApproval => false;
  bool get mayDeploy => false;

  AgentEmailTransportHandoff create({
    required String handoffId,
    required AgentEmailSendBoundaryResult boundaryResult,
    required AgentEmailSendAuthorizationRequest authorizationRequest,
    required AgentEmailDraft currentDraft,
    required AgentEmailSenderIdentity senderIdentity,
    DateTime? createdAt,
  }) {
    authorizationRequest.validate();
    currentDraft.validate();
    senderIdentity.validate();

    if (!boundaryResult.approvalConsumed ||
        boundaryResult.consumedApproval == null ||
        !boundaryResult.consumedApproval!.isConsumed ||
        boundaryResult.consumedApproval!.consumedAt == null) {
      throw const AgentEmailTransportHandoffFactoryException(
        'Email transport handoff requires a centrally consumed approval.',
      );
    }

    if (authorizationRequest.actionId != AgentActionId.sendEmail ||
        authorizationRequest.module != 'email') {
      throw const AgentEmailTransportHandoffFactoryException(
        'Email transport handoff only accepts the dedicated email.send action.',
      );
    }

    if (boundaryResult.authorizationRequestId !=
            authorizationRequest.authorizationRequestId ||
        boundaryResult.approvalId !=
            boundaryResult.consumedApproval!.approvalId) {
      throw const AgentEmailTransportHandoffFactoryException(
        'Boundary identifiers do not match the consumed Email approval.',
      );
    }

    if (!authorizationFactory.stillMatchesApprovedDraft(
      request: authorizationRequest,
      currentDraft: currentDraft,
    )) {
      throw const AgentEmailTransportHandoffFactoryException(
        'Current Email Draft does not match the approved fingerprint.',
      );
    }

    if (currentDraft.senderIdentityId != senderIdentity.senderIdentityId) {
      throw const AgentEmailTransportHandoffFactoryException(
        'Draft sender identity does not match the verified sender identity.',
      );
    }

    if (!senderIdentity.mayBeUsedForTransport) {
      throw const AgentEmailTransportHandoffFactoryException(
        'Sender identity must be enabled and verified before transport handoff.',
      );
    }

    final AgentEmailTransportHandoff handoff = AgentEmailTransportHandoff(
      handoffId: handoffId.trim(),
      authorizationRequestId: authorizationRequest.authorizationRequestId
          .trim(),
      approvalId: boundaryResult.approvalId.trim(),
      draftId: currentDraft.draftId.trim(),
      bindingAlgorithm: authorizationRequest.binding.algorithm,
      bindingFingerprint: authorizationRequest.binding.fingerprint,
      senderIdentityId: senderIdentity.senderIdentityId.trim(),
      providerId: senderIdentity.providerId.trim(),
      fromAddress: senderIdentity.fromAddress.trim().toLowerCase(),
      to: currentDraft.to
          .map((AgentEmailAddress value) => value.address.trim().toLowerCase())
          .toList(growable: false),
      cc: currentDraft.cc
          .map((AgentEmailAddress value) => value.address.trim().toLowerCase())
          .toList(growable: false),
      bcc: currentDraft.bcc
          .map((AgentEmailAddress value) => value.address.trim().toLowerCase())
          .toList(growable: false),
      subject: currentDraft.subject,
      bodyText: currentDraft.bodyText,
      attachmentIds: currentDraft.attachments
          .map((AgentEmailAttachmentRef value) => value.attachmentId.trim())
          .toList(growable: false),
      createdAt: createdAt ?? DateTime.now(),
    );

    handoff.validate();
    return handoff;
  }
}

class AgentEmailTransportHandoffFactoryException implements Exception {
  const AgentEmailTransportHandoffFactoryException(this.message);

  final String message;

  @override
  String toString() => 'AgentEmailTransportHandoffFactoryException: $message';
}

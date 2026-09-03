import '../constants/agent_conversation_quality_constants.dart';
import '../constants/agent_email_constants.dart';
import '../services/agent_email_draft_binding_service.dart';
import 'agent_email_draft.dart';

class AgentEmailSendAuthorizationRequest {
  AgentEmailSendAuthorizationRequest({
    required this.authorizationRequestId,
    required this.roleId,
    required this.actionId,
    required this.module,
    required this.requestedBy,
    required this.risk,
    required this.draftId,
    required this.binding,
    required this.createdAt,
  });

  final String authorizationRequestId;
  final String roleId;
  final String actionId;
  final String module;
  final String requestedBy;
  final String risk;
  final String draftId;
  final AgentEmailDraftBinding binding;
  final DateTime createdAt;

  bool get requiresCentralPermissionEngine => true;
  bool get requiresCentralApprovalService => true;
  bool get requiresRuntimeGateBeforeSend => true;
  bool get requiresOneTimeApprovalConsumption => true;
  bool get exactDraftMatchRequired => true;

  bool get maySend => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayCallProvider => false;
  bool get mayOpenNetworkConnection => false;
  bool get mayReadMailbox => false;
  bool get mayWriteMailbox => false;
  bool get mayDeploy => false;

  void validate() {
    if (authorizationRequestId.trim().isEmpty ||
        roleId.trim().isEmpty ||
        actionId.trim().isEmpty ||
        module.trim().isEmpty ||
        requestedBy.trim().isEmpty ||
        draftId.trim().isEmpty) {
      throw const AgentEmailSendAuthorizationException(
        'Email send authorization identity fields cannot be empty.',
      );
    }

    if (!AgentConversationRisk.values.contains(risk)) {
      throw AgentEmailSendAuthorizationException(
        'Invalid email send authorization risk "$risk".',
      );
    }

    binding.validate();

    if (binding.draftId.trim() != draftId.trim()) {
      throw const AgentEmailSendAuthorizationException(
        'Authorization draftId must match binding draftId.',
      );
    }
  }

  Map<String, dynamic> toApprovalActionScope() {
    validate();

    return <String, dynamic>{
      'authorizationRequestId': authorizationRequestId.trim(),
      'draftId': draftId.trim(),
      'binding': binding.toMap(),
      'exactDraftMatchRequired': true,
      'oneActionOnly': true,
      'oneTimeConsumptionRequired': true,
    };
  }
}

class AgentEmailSendAuthorizationFactory {
  const AgentEmailSendAuthorizationFactory({
    this.bindingService = const AgentEmailDraftBindingService(),
  });

  final AgentEmailDraftBindingService bindingService;

  bool get providerExecutionAllowed => false;
  bool get smtpExecutionAllowed => false;
  bool get firestoreReadAllowed => false;
  bool get firestoreWriteAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get mailboxReadAllowed => false;
  bool get mailboxWriteAllowed => false;
  bool get deploymentAllowed => false;

  AgentEmailSendAuthorizationRequest create({
    required String authorizationRequestId,
    required String roleId,
    required String actionId,
    required String module,
    required String requestedBy,
    required String risk,
    required AgentEmailDraft draft,
    DateTime? createdAt,
  }) {
    draft.validate();

    if (draft.status != AgentEmailDraftStatus.approvalRequired) {
      throw AgentEmailSendAuthorizationException(
        'Only APPROVAL_REQUIRED email drafts may create a send authorization request. '
        'Current status: ${draft.status}.',
      );
    }

    if (!draft.requiresApprovalToSend || draft.maySend) {
      throw const AgentEmailSendAuthorizationException(
        'Email draft send-safety invariant is invalid.',
      );
    }

    final AgentEmailDraftBinding binding = bindingService.bind(draft);

    final AgentEmailSendAuthorizationRequest request =
        AgentEmailSendAuthorizationRequest(
          authorizationRequestId: authorizationRequestId,
          roleId: roleId,
          actionId: actionId,
          module: module,
          requestedBy: requestedBy,
          risk: risk,
          draftId: draft.draftId,
          binding: binding,
          createdAt: (createdAt ?? DateTime.now()).toUtc(),
        );

    request.validate();
    return request;
  }

  bool stillMatchesApprovedDraft({
    required AgentEmailSendAuthorizationRequest request,
    required AgentEmailDraft currentDraft,
  }) {
    request.validate();

    if (currentDraft.status != AgentEmailDraftStatus.approvalRequired) {
      return false;
    }

    return bindingService.matches(
      draft: currentDraft,
      binding: request.binding,
    );
  }
}

class AgentEmailSendAuthorizationException implements Exception {
  const AgentEmailSendAuthorizationException(this.message);

  final String message;

  @override
  String toString() => 'AgentEmailSendAuthorizationException: $message';
}

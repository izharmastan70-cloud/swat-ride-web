import '../constants/agent_action_ids.dart';
import '../models/agent_approval_request.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_owner_whatsapp_approval_handoff.dart';
import '../models/agent_owner_whatsapp_foundation.dart';
import '../models/agent_role.dart';
import 'agent_action_registry.dart';
import 'agent_approval_service.dart';
import 'agent_audit_recorder.dart';
import 'agent_owner_whatsapp_authorization_router.dart';

class AgentOwnerWhatsAppApprovalCoordinator {
  final AgentOwnerWhatsAppAuthorizationRouter authorizationRouter;
  final AgentApprovalService approvalService;
  final AgentAuditRecorder auditRecorder;

  const AgentOwnerWhatsAppApprovalCoordinator({
    required this.authorizationRouter,
    required this.approvalService,
    required this.auditRecorder,
  });

  /// Creates one exact central approval request after strong re-auth,
  /// Permission Engine, Runtime Gate and Audit have all passed.
  ///
  /// This method never executes the requested business/admin mutation.
  Future<AgentOwnerWhatsAppApprovalResult> requestConsequentialApproval({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentOwnerWhatsAppControlSettings channelSettings,
    required AgentOwnerWhatsAppSessionBinding session,
    required AgentOwnerWhatsAppAuthorizationRequest authorizationRequest,
    required AgentOwnerWhatsAppApprovalHandoff handoff,
    required DateTime now,
    Duration approvalValidity = const Duration(minutes: 15),
  }) async {
    _validateInvariantInputs(
      role: role,
      authorizationRequest: authorizationRequest,
      handoff: handoff,
    );

    final AgentOwnerWhatsAppAuthorizationResult authorization =
        await authorizationRouter.evaluate(
          settings: settings,
          role: role,
          channelSettings: channelSettings,
          session: session,
          request: authorizationRequest,
          now: now,
        );

    if (authorization.isDenied) {
      return AgentOwnerWhatsAppApprovalResult(
        authorization: authorization,
        approvalRequest: null,
        consumedApproval: null,
        reason: authorization.reason,
      );
    }

    if (!authorization.decision.needsApproval) {
      throw const AgentOwnerWhatsAppApprovalCoordinatorException(
        'Consequential Owner WhatsApp request must remain approval-required.',
      );
    }

    final action = AgentActionRegistry.get(
      AgentActionId.requestOwnerWhatsAppConsequentialAction,
    );

    if (action == null) {
      throw const AgentOwnerWhatsAppApprovalCoordinatorException(
        'Owner WhatsApp consequential request action is missing from the registry.',
      );
    }

    final Map<String, dynamic> exactScope = handoff.toApprovalActionScope();

    final AgentApprovalRequest approvalRequest = await approvalService
        .createRequest(
          roleId: role.roleId,
          actionId: AgentActionId.requestOwnerWhatsAppConsequentialAction,
          module: action.module,
          reason: authorization.decision.reason,
          risk: action.risk,
          requestedBy: authorizationRequest.actorId.trim(),
          actionScope: exactScope,
          validity: approvalValidity,
        );

    await auditRecorder.approvalRequested(
      request: approvalRequest,
      actorId: authorizationRequest.actorId.trim(),
    );

    return AgentOwnerWhatsAppApprovalResult(
      authorization: authorization,
      approvalRequest: approvalRequest,
      consumedApproval: null,
      reason:
          'Strong re-auth + central authorization passed; exact scoped approval requested. No business/admin action executed.',
    );
  }

  /// Re-validates current Owner WhatsApp identity/session + Permission +
  /// Runtime state immediately before one-time central approval consumption.
  ///
  /// The returned consumed approval is only a future handoff boundary.
  /// Phase 46 Step 7 still performs NO business/admin mutation.
  Future<AgentOwnerWhatsAppApprovalResult> consumeApprovedForFutureHandoff({
    required String approvalId,
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentOwnerWhatsAppControlSettings channelSettings,
    required AgentOwnerWhatsAppSessionBinding session,
    required AgentOwnerWhatsAppAuthorizationRequest authorizationRequest,
    required AgentOwnerWhatsAppApprovalHandoff handoff,
    required DateTime now,
  }) async {
    final String normalizedApprovalId = approvalId.trim();

    if (normalizedApprovalId.isEmpty) {
      throw const AgentOwnerWhatsAppApprovalCoordinatorException(
        'Owner WhatsApp approvalId cannot be empty.',
      );
    }

    _validateInvariantInputs(
      role: role,
      authorizationRequest: authorizationRequest,
      handoff: handoff,
    );

    final AgentOwnerWhatsAppAuthorizationResult authorization =
        await authorizationRouter.evaluate(
          settings: settings,
          role: role,
          channelSettings: channelSettings,
          session: session,
          request: authorizationRequest,
          now: now,
        );

    if (authorization.isDenied) {
      throw AgentOwnerWhatsAppApprovalCoordinatorException(
        'Current Owner WhatsApp authorization denied approval consumption: ${authorization.reason}',
      );
    }

    if (!authorization.decision.needsApproval) {
      throw const AgentOwnerWhatsAppApprovalCoordinatorException(
        'Owner WhatsApp consequential request no longer requires approval. Fail closed instead of consuming a stale approval.',
      );
    }

    final action = AgentActionRegistry.get(
      AgentActionId.requestOwnerWhatsAppConsequentialAction,
    );

    if (action == null) {
      throw const AgentOwnerWhatsAppApprovalCoordinatorException(
        'Owner WhatsApp consequential request action is missing from the registry.',
      );
    }

    final Map<String, dynamic> exactScope = handoff.toApprovalActionScope();

    final AgentApprovalRequest consumed = await approvalService
        .consumeApprovedRequest(
          approvalId: normalizedApprovalId,
          expectedRoleId: role.roleId,
          expectedActionId:
              AgentActionId.requestOwnerWhatsAppConsequentialAction,
          expectedModule: action.module,
          expectedActionScope: exactScope,
        );

    await auditRecorder.auditService.recordSystemEvent(
      reason:
          'Owner WhatsApp approval consumed after strong re-auth, exact-scope, permission and runtime revalidation. No business/admin mutation executed.',
      module: 'owner_whatsapp',
      actionId: AgentActionId.requestOwnerWhatsAppConsequentialAction,
      result: 'CONSUMED_FUTURE_HANDOFF_ONLY',
      metadata: <String, dynamic>{
        'approvalId': consumed.approvalId,
        'roleId': role.roleId,
        'requestId': handoff.requestId,
        'targetActionId': handoff.targetActionId,
        'controlArea': handoff.controlArea,
        'businessMutationAuthorized': false,
        'adminMutationAuthorized': false,
        'providerAuthorized': false,
        'whatsappSendAuthorized': false,
        'deploymentAuthorized': false,
      },
    );

    return AgentOwnerWhatsAppApprovalResult(
      authorization: authorization,
      approvalRequest: null,
      consumedApproval: consumed,
      reason:
          'Exact approval consumed once for a future execution boundary. Phase 46 Step 7 still grants no business/admin execution authority.',
    );
  }

  void _validateInvariantInputs({
    required AgentRole role,
    required AgentOwnerWhatsAppAuthorizationRequest authorizationRequest,
    required AgentOwnerWhatsAppApprovalHandoff handoff,
  }) {
    handoff.validate();

    if (role.roleId != AgentOwnerWhatsAppFoundation.roleId ||
        role.module != 'owner_whatsapp') {
      throw const AgentOwnerWhatsAppApprovalCoordinatorException(
        'Only the isolated Owner WhatsApp role may use this approval coordinator.',
      );
    }

    if (authorizationRequest.actionId !=
        AgentActionId.requestOwnerWhatsAppConsequentialAction) {
      throw const AgentOwnerWhatsAppApprovalCoordinatorException(
        'Owner WhatsApp approval coordinator accepts only the consequential request action.',
      );
    }

    if (authorizationRequest.commandPolicy.commandClass !=
        AgentOwnerWhatsAppCommandClass.consequentialAction) {
      throw const AgentOwnerWhatsAppApprovalCoordinatorException(
        'Owner WhatsApp approval coordinator requires a consequential command policy.',
      );
    }

    if (authorizationRequest.expectedConversationId.trim() !=
            handoff.conversationId ||
        authorizationRequest.expectedSenderBindingId.trim() !=
            handoff.senderBindingId ||
        authorizationRequest.expectedSessionId.trim() != handoff.sessionId) {
      throw const AgentOwnerWhatsAppApprovalCoordinatorException(
        'Owner WhatsApp approval handoff does not match the exact authorization session binding.',
      );
    }

    if (authorizationRequest.actorId.trim() != handoff.principalUid) {
      throw const AgentOwnerWhatsAppApprovalCoordinatorException(
        'Owner WhatsApp approval handoff principal does not match actorId.',
      );
    }

    final String expectedArea = authorizationRequest.controlArea.name;
    if (handoff.controlArea != expectedArea) {
      throw const AgentOwnerWhatsAppApprovalCoordinatorException(
        'Owner WhatsApp approval handoff control area mismatch.',
      );
    }
  }
}

class AgentOwnerWhatsAppApprovalResult {
  final AgentOwnerWhatsAppAuthorizationResult authorization;
  final AgentApprovalRequest? approvalRequest;
  final AgentApprovalRequest? consumedApproval;
  final String reason;

  const AgentOwnerWhatsAppApprovalResult({
    required this.authorization,
    required this.approvalRequest,
    required this.consumedApproval,
    required this.reason,
  });

  bool get isDenied => authorization.isDenied;

  bool get isWaitingForApproval =>
      !isDenied &&
      authorization.decision.needsApproval &&
      approvalRequest != null &&
      consumedApproval == null;

  bool get approvalConsumedForFutureHandoff =>
      consumedApproval != null && consumedApproval!.isConsumed;

  bool get mayExecuteBusinessOrAdminWrite => false;
  bool get maySendWhatsApp => false;
  bool get mayCallProvider => false;
  bool get mayDeploy => false;
}

class AgentOwnerWhatsAppApprovalCoordinatorException implements Exception {
  final String message;

  const AgentOwnerWhatsAppApprovalCoordinatorException(this.message);

  @override
  String toString() =>
      'AgentOwnerWhatsAppApprovalCoordinatorException: $message';
}

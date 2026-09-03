import '../constants/agent_action_ids.dart';
import '../models/agent_approval_request.dart';
import '../models/agent_email_draft.dart';
import '../models/agent_email_send_authorization_request.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_role.dart';
import 'agent_email_approval_gateway.dart';
import 'agent_email_send_preflight_coordinator.dart';

class AgentEmailSendBoundaryStatus {
  AgentEmailSendBoundaryStatus._();

  static const String approvalRequested = 'APPROVAL_REQUESTED';
  static const String readyForConsumption = 'READY_FOR_CONSUMPTION';
  static const String approvalConsumed = 'APPROVAL_CONSUMED';
  static const String blocked = 'BLOCKED';

  static const Set<String> values = <String>{
    approvalRequested,
    readyForConsumption,
    approvalConsumed,
    blocked,
  };
}

class AgentEmailSendBoundaryResult {
  const AgentEmailSendBoundaryResult({
    required this.status,
    required this.authorizationRequestId,
    required this.approvalId,
    required this.preflight,
    required this.consumedApproval,
    required this.reason,
  });

  final String status;
  final String authorizationRequestId;
  final String approvalId;
  final AgentEmailSendPreflightResult? preflight;
  final AgentApprovalRequest? consumedApproval;
  final String reason;

  bool get approvalRequested =>
      status == AgentEmailSendBoundaryStatus.approvalRequested;

  bool get readyForConsumption =>
      status == AgentEmailSendBoundaryStatus.readyForConsumption;

  bool get approvalConsumed =>
      status == AgentEmailSendBoundaryStatus.approvalConsumed;

  bool get transportPerformed => false;
  bool get providerExecutionPerformed => false;
  bool get emailSent => false;
  bool get mailboxWritePerformed => false;
  bool get businessDataWritePerformed => false;
  bool get maySend => false;
  bool get mayCallProvider => false;
  bool get mayOpenTransportConnection => false;
  bool get mayDeploy => false;
}

class AgentEmailSendExecutionBoundary {
  AgentEmailSendExecutionBoundary({
    required this.approvalGateway,
    this.preflightCoordinator = const AgentEmailSendPreflightCoordinator(),
  });

  factory AgentEmailSendExecutionBoundary.central({
    AgentEmailSendPreflightCoordinator preflightCoordinator =
        const AgentEmailSendPreflightCoordinator(),
  }) {
    return AgentEmailSendExecutionBoundary(
      approvalGateway: CentralAgentEmailApprovalGateway(),
      preflightCoordinator: preflightCoordinator,
    );
  }

  final AgentEmailApprovalGateway approvalGateway;
  final AgentEmailSendPreflightCoordinator preflightCoordinator;

  bool get centralApprovalCreateIntegrated => true;
  bool get centralApprovalReadIntegrated => true;
  bool get centralApprovalConsumeIntegrated => true;

  bool get transportExecutionAllowed => false;
  bool get providerExecutionAllowed => false;
  bool get smtpExecutionAllowed => false;
  bool get mailboxReadAllowed => false;
  bool get mailboxWriteAllowed => false;
  bool get businessDataWriteAllowed => false;
  bool get deploymentAllowed => false;

  Future<AgentEmailSendBoundaryResult> requestApproval({
    required AgentEmailSendAuthorizationRequest authorizationRequest,
    required String reason,
    Duration validity = const Duration(minutes: 15),
  }) async {
    authorizationRequest.validate();

    if (authorizationRequest.actionId != AgentActionId.sendEmail ||
        authorizationRequest.module != 'email') {
      return _blocked(
        authorizationRequest: authorizationRequest,
        reason:
            'Only the dedicated email.send action may create an Email send approval request.',
      );
    }

    final AgentApprovalRequest approval = await approvalGateway.createRequest(
      roleId: authorizationRequest.roleId,
      actionId: AgentActionId.sendEmail,
      module: 'email',
      reason: reason,
      risk: authorizationRequest.risk,
      requestedBy: authorizationRequest.requestedBy,
      actionScope: authorizationRequest.toApprovalActionScope(),
      validity: validity,
    );

    return AgentEmailSendBoundaryResult(
      status: AgentEmailSendBoundaryStatus.approvalRequested,
      authorizationRequestId: authorizationRequest.authorizationRequestId
          .trim(),
      approvalId: approval.approvalId,
      preflight: null,
      consumedApproval: null,
      reason:
          'Central approval request created for the exact Email authorization scope. No transport was attempted.',
    );
  }

  Future<AgentEmailSendBoundaryResult> preflightApprovedRequest({
    required String approvalId,
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentEmailSendAuthorizationRequest authorizationRequest,
    required AgentEmailDraft currentDraft,
  }) async {
    final AgentApprovalRequest? approvalSnapshot = await approvalGateway
        .getRequest(approvalId);

    final AgentEmailSendPreflightResult preflight = preflightCoordinator
        .evaluate(
          settings: settings,
          role: role,
          authorizationRequest: authorizationRequest,
          currentDraft: currentDraft,
          approvalSnapshot: approvalSnapshot,
        );

    if (!preflight.readyForApprovalConsumption) {
      return AgentEmailSendBoundaryResult(
        status: AgentEmailSendBoundaryStatus.blocked,
        authorizationRequestId: authorizationRequest.authorizationRequestId
            .trim(),
        approvalId: approvalId.trim(),
        preflight: preflight,
        consumedApproval: null,
        reason:
            'Email send execution boundary blocked before approval consumption: ${preflight.reason}',
      );
    }

    return AgentEmailSendBoundaryResult(
      status: AgentEmailSendBoundaryStatus.readyForConsumption,
      authorizationRequestId: authorizationRequest.authorizationRequestId
          .trim(),
      approvalId: approvalId.trim(),
      preflight: preflight,
      consumedApproval: null,
      reason:
          'Exact approval snapshot passed pure preflight. No approval has been consumed yet.',
    );
  }

  Future<AgentEmailSendBoundaryResult> consumeApprovedForTransportHandoff({
    required String approvalId,
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentEmailSendAuthorizationRequest authorizationRequest,
    required AgentEmailDraft currentDraft,
  }) async {
    final AgentEmailSendBoundaryResult preflightBoundary =
        await preflightApprovedRequest(
          approvalId: approvalId,
          settings: settings,
          role: role,
          authorizationRequest: authorizationRequest,
          currentDraft: currentDraft,
        );

    if (!preflightBoundary.readyForConsumption) {
      return preflightBoundary;
    }

    final AgentApprovalRequest consumed = await approvalGateway
        .consumeApprovedRequest(
          approvalId: approvalId,
          expectedRoleId: authorizationRequest.roleId,
          expectedActionId: AgentActionId.sendEmail,
          expectedModule: 'email',
          expectedActionScope: authorizationRequest.toApprovalActionScope(),
        );

    if (!consumed.isConsumed || consumed.consumedAt == null) {
      return AgentEmailSendBoundaryResult(
        status: AgentEmailSendBoundaryStatus.blocked,
        authorizationRequestId: authorizationRequest.authorizationRequestId
            .trim(),
        approvalId: approvalId.trim(),
        preflight: preflightBoundary.preflight,
        consumedApproval: consumed,
        reason:
            'Central approval gateway returned without a consumed one-time approval state.',
      );
    }

    return AgentEmailSendBoundaryResult(
      status: AgentEmailSendBoundaryStatus.approvalConsumed,
      authorizationRequestId: authorizationRequest.authorizationRequestId
          .trim(),
      approvalId: approvalId.trim(),
      preflight: preflightBoundary.preflight,
      consumedApproval: consumed,
      reason:
          'Central approval consumed exactly once for a future transport handoff. Email transport is still disconnected.',
    );
  }

  AgentEmailSendBoundaryResult _blocked({
    required AgentEmailSendAuthorizationRequest authorizationRequest,
    required String reason,
  }) {
    return AgentEmailSendBoundaryResult(
      status: AgentEmailSendBoundaryStatus.blocked,
      authorizationRequestId: authorizationRequest.authorizationRequestId
          .trim(),
      approvalId: '',
      preflight: null,
      consumedApproval: null,
      reason: reason,
    );
  }
}

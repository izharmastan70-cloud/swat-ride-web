import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/constants/agent_conversation_quality_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_email_constants.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_approval_request.dart';
import 'package:swat_ride/ai_agent/models/agent_email_draft.dart';
import 'package:swat_ride/ai_agent/models/agent_email_send_authorization_request.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_email_send_preflight_coordinator.dart';

void main() {
  const AgentEmailSendAuthorizationFactory authorizationFactory =
      AgentEmailSendAuthorizationFactory();

  const AgentEmailSendPreflightCoordinator coordinator =
      AgentEmailSendPreflightCoordinator();

  AgentRole emailRole() {
    return buildInitialAgentRoles().firstWhere(
      (AgentRole role) => role.roleId == 'email_agent',
    );
  }

  AgentMasterSettings enabledSettings() {
    return AgentMasterSettings.safeDefaults().copyWith(
      masterEnabled: true,
      emergencyReadOnly: false,
      freeAiEnabled: true,
      approvalEngineEnabled: true,
      emailAgentEnabled: true,
    );
  }

  AgentEmailDraft draft({
    String body = 'Your verified booking update is ready.',
  }) {
    return AgentEmailDraft(
      draftId: 'draft_e2',
      purpose: AgentEmailPurpose.supportReply,
      senderIdentityId: 'verified_sender_identity',
      to: const <AgentEmailAddress>[
        AgentEmailAddress(address: 'customer@example.com'),
      ],
      subject: 'Booking update',
      bodyText: body,
      status: AgentEmailDraftStatus.approvalRequired,
      createdAt: DateTime.utc(2026, 8, 17, 6),
    );
  }

  AgentEmailSendAuthorizationRequest authorization(AgentEmailDraft value) {
    return authorizationFactory.create(
      authorizationRequestId: 'email_auth_e2',
      roleId: 'email_agent',
      actionId: AgentActionId.sendEmail,
      module: 'email',
      requestedBy: 'owner_test',
      risk: AgentConversationRisk.medium,
      draft: value,
      createdAt: DateTime.utc(2026, 8, 17, 6, 5),
    );
  }

  AgentApprovalRequest approved({
    required AgentEmailSendAuthorizationRequest request,
    Map<String, dynamic>? scope,
    String roleId = 'email_agent',
    String actionId = AgentActionId.sendEmail,
    String module = 'email',
    String status = AgentApprovalStatus.approved,
    DateTime? expiresAt,
    DateTime? consumedAt,
  }) {
    return AgentApprovalRequest(
      approvalId: 'approval_e2',
      roleId: roleId,
      actionId: actionId,
      module: module,
      reason: 'Approve exact Email send.',
      risk: AgentConversationRisk.medium,
      requestedBy: 'owner_test',
      actionScope: scope ?? request.toApprovalActionScope(),
      status: status,
      createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(minutes: 10)),
      decidedAt: DateTime.now(),
      consumedAt: consumedAt,
      decidedBy: 'owner_test',
      decisionNote: 'Synthetic test approval.',
    );
  }

  test(
    'exact approved email request becomes ready for central consumption',
    () {
      final AgentEmailDraft currentDraft = draft();
      final AgentEmailSendAuthorizationRequest request = authorization(
        currentDraft,
      );

      final result = coordinator.evaluate(
        settings: enabledSettings(),
        role: emailRole(),
        authorizationRequest: request,
        currentDraft: currentDraft,
        approvalSnapshot: approved(request: request),
      );

      expect(result.readyForApprovalConsumption, isTrue);
      expect(result.permissionDecision!.needsApproval, isTrue);
      expect(result.runtimeDecision!.needsApproval, isTrue);
      expect(result.approvalConsumptionPerformed, isFalse);
      expect(result.transportPerformed, isFalse);
      expect(result.emailSent, isFalse);
    },
  );

  test('changed draft fingerprint fails closed', () {
    final AgentEmailDraft original = draft();
    final AgentEmailSendAuthorizationRequest request = authorization(original);

    final result = coordinator.evaluate(
      settings: enabledSettings(),
      role: emailRole(),
      authorizationRequest: request,
      currentDraft: draft(body: 'Changed after approval.'),
      approvalSnapshot: approved(request: request),
    );

    expect(result.readyForApprovalConsumption, isFalse);
    expect(result.denied, isTrue);
  });

  test('master OFF fails before approval consumption readiness', () {
    final AgentEmailDraft currentDraft = draft();
    final AgentEmailSendAuthorizationRequest request = authorization(
      currentDraft,
    );

    final result = coordinator.evaluate(
      settings: enabledSettings().copyWith(masterEnabled: false),
      role: emailRole(),
      authorizationRequest: request,
      currentDraft: currentDraft,
      approvalSnapshot: approved(request: request),
    );

    expect(result.readyForApprovalConsumption, isFalse);
    expect(result.runtimeDecision!.isDenied, isTrue);
  });

  test('Emergency Read-Only blocks approval/write path', () {
    final AgentEmailDraft currentDraft = draft();
    final AgentEmailSendAuthorizationRequest request = authorization(
      currentDraft,
    );

    final result = coordinator.evaluate(
      settings: enabledSettings().copyWith(emergencyReadOnly: true),
      role: emailRole(),
      authorizationRequest: request,
      currentDraft: currentDraft,
      approvalSnapshot: approved(request: request),
    );

    expect(result.readyForApprovalConsumption, isFalse);
    expect(result.runtimeDecision!.isDenied, isTrue);
  });

  test('Approval Engine OFF blocks approval path', () {
    final AgentEmailDraft currentDraft = draft();
    final AgentEmailSendAuthorizationRequest request = authorization(
      currentDraft,
    );

    final result = coordinator.evaluate(
      settings: enabledSettings().copyWith(approvalEngineEnabled: false),
      role: emailRole(),
      authorizationRequest: request,
      currentDraft: currentDraft,
      approvalSnapshot: approved(request: request),
    );

    expect(result.readyForApprovalConsumption, isFalse);
    expect(result.runtimeDecision!.isDenied, isTrue);
  });

  test('missing approval snapshot is not ready', () {
    final AgentEmailDraft currentDraft = draft();
    final AgentEmailSendAuthorizationRequest request = authorization(
      currentDraft,
    );

    final result = coordinator.evaluate(
      settings: enabledSettings(),
      role: emailRole(),
      authorizationRequest: request,
      currentDraft: currentDraft,
      approvalSnapshot: null,
    );

    expect(result.readyForApprovalConsumption, isFalse);
    expect(result.status, AgentEmailSendPreflightStatus.approvalUnavailable);
  });

  test('consumed approval is rejected', () {
    final AgentEmailDraft currentDraft = draft();
    final AgentEmailSendAuthorizationRequest request = authorization(
      currentDraft,
    );

    final result = coordinator.evaluate(
      settings: enabledSettings(),
      role: emailRole(),
      authorizationRequest: request,
      currentDraft: currentDraft,
      approvalSnapshot: approved(
        request: request,
        status: AgentApprovalStatus.consumed,
        consumedAt: DateTime.now(),
      ),
    );

    expect(result.readyForApprovalConsumption, isFalse);
    expect(result.status, AgentEmailSendPreflightStatus.approvalUnavailable);
  });

  test('expired approval is rejected', () {
    final AgentEmailDraft currentDraft = draft();
    final AgentEmailSendAuthorizationRequest request = authorization(
      currentDraft,
    );

    final result = coordinator.evaluate(
      settings: enabledSettings(),
      role: emailRole(),
      authorizationRequest: request,
      currentDraft: currentDraft,
      approvalSnapshot: approved(
        request: request,
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      ),
    );

    expect(result.readyForApprovalConsumption, isFalse);
    expect(result.status, AgentEmailSendPreflightStatus.approvalUnavailable);
  });

  test('approval scope mutation is rejected', () {
    final AgentEmailDraft currentDraft = draft();
    final AgentEmailSendAuthorizationRequest request = authorization(
      currentDraft,
    );

    final Map<String, dynamic> changedScope = Map<String, dynamic>.from(
      request.toApprovalActionScope(),
    );
    changedScope['draftId'] = 'different_draft';

    final result = coordinator.evaluate(
      settings: enabledSettings(),
      role: emailRole(),
      authorizationRequest: request,
      currentDraft: currentDraft,
      approvalSnapshot: approved(request: request, scope: changedScope),
    );

    expect(result.readyForApprovalConsumption, isFalse);
    expect(result.status, AgentEmailSendPreflightStatus.approvalMismatch);
  });

  test('wrong approval action is rejected', () {
    final AgentEmailDraft currentDraft = draft();
    final AgentEmailSendAuthorizationRequest request = authorization(
      currentDraft,
    );

    final result = coordinator.evaluate(
      settings: enabledSettings(),
      role: emailRole(),
      authorizationRequest: request,
      currentDraft: currentDraft,
      approvalSnapshot: approved(
        request: request,
        actionId: AgentActionId.sendSupportReply,
      ),
    );

    expect(result.readyForApprovalConsumption, isFalse);
    expect(result.status, AgentEmailSendPreflightStatus.approvalMismatch);
  });

  test('coordinator exposes zero consumption and transport authority', () {
    expect(coordinator.approvalConsumptionAllowed, isFalse);
    expect(coordinator.approvalMutationAllowed, isFalse);
    expect(coordinator.transportExecutionAllowed, isFalse);
    expect(coordinator.providerExecutionAllowed, isFalse);
    expect(coordinator.firestoreReadAllowed, isFalse);
    expect(coordinator.firestoreWriteAllowed, isFalse);
    expect(coordinator.smtpExecutionAllowed, isFalse);
    expect(coordinator.mailboxReadAllowed, isFalse);
    expect(coordinator.mailboxWriteAllowed, isFalse);
    expect(coordinator.deploymentAllowed, isFalse);
  });
}

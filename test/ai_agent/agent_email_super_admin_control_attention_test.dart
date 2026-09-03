import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/constants/agent_email_constants.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_email_draft.dart';
import 'package:swat_ride/ai_agent/models/agent_email_draft_policy_decision.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_email_admin_attention_audit_service.dart';
import 'package:swat_ride/ai_agent/services/agent_permission_engine.dart';
import 'package:swat_ride/ai_agent/services/agent_runtime_gate.dart';

void main() {
  const AgentPermissionEngine permissionEngine = AgentPermissionEngine();

  const AgentRuntimeGate runtimeGate = AgentRuntimeGate();

  AgentRole emailRole() {
    return buildInitialAgentRoles().firstWhere(
      (AgentRole role) => role.roleId == 'email_agent',
    );
  }

  AgentMasterSettings settings({required bool emailEnabled}) {
    return AgentMasterSettings.safeDefaults().copyWith(
      masterEnabled: true,
      emergencyReadOnly: false,
      freeAiEnabled: true,
      approvalEngineEnabled: true,
      emailAgentEnabled: emailEnabled,
    );
  }

  AgentEmailDraft draft({String subject = 'Suspicious request'}) {
    return AgentEmailDraft(
      draftId: 'draft_attention',
      purpose: AgentEmailPurpose.supportReply,
      senderIdentityId: 'verified_sender_identity',
      to: const <AgentEmailAddress>[
        AgentEmailAddress(address: 'customer@example.com'),
      ],
      subject: subject,
      bodyText: 'Body intentionally not copied to Admin Attention metadata.',
      status: AgentEmailDraftStatus.needsReview,
      createdAt: DateTime.utc(2026, 8, 17, 7, 30),
    );
  }

  AgentEmailDraftPolicyDecision reviewDecision() {
    return AgentEmailDraftPolicyDecision(
      classification: AgentEmailDraftPolicyClassification.blocked,
      reasonCodes: <String>['SUSPICIOUS_CREDENTIAL_REQUEST'],
      recipientCount: 1,
      hasBcc: false,
      hasAttachments: false,
      containsSensitiveCredentialPattern: false,
      containsSuspiciousRequestPattern: true,
      bulkRecipientRisk: false,
      requiresHumanReview: true,
      requiresAttachmentReview: false,
      requiresSendApproval: true,
      mayRemainAsDraft: false,
    );
  }

  test('Email Agent is OFF by safe default', () {
    final AgentMasterSettings defaults = AgentMasterSettings.safeDefaults();

    expect(defaults.emailAgentEnabled, isFalse);
  });

  test(
    'runtime gate denies email.send when Super Admin Email switch is OFF',
    () {
      final AgentRole role = emailRole();

      final permission = permissionEngine.evaluate(
        role: role,
        actionId: AgentActionId.sendEmail,
      );

      expect(permission.needsApproval, isTrue);

      final runtime = runtimeGate.apply(
        settings: settings(emailEnabled: false),
        role: role,
        permissionDecision: permission,
      );

      expect(runtime.isDenied, isTrue);
      expect(runtime.reason, contains('Email Agent master switch is OFF'));
    },
  );

  test('runtime gate preserves approval path when Email switch is ON', () {
    final AgentRole role = emailRole();

    final permission = permissionEngine.evaluate(
      role: role,
      actionId: AgentActionId.sendEmail,
    );

    final runtime = runtimeGate.apply(
      settings: settings(emailEnabled: true),
      role: role,
      permissionDecision: permission,
    );

    expect(runtime.needsApproval, isTrue);
    expect(runtime.isDenied, isFalse);
  });

  test('unusual Email Attention redacts subject secret and hides body', () {
    final AgentEmailAdminAttentionAuditService service =
        AgentEmailAdminAttentionAuditService();

    final event = service.buildEvent(
      attentionId: 'attention_1',
      sourceAddress: 'customer@example.com',
      draft: draft(subject: 'OTP: 123456 account issue'),
      policyDecision: reviewDecision(),
      createdAt: DateTime.utc(2026, 8, 17, 7, 31),
    );

    final Map<String, dynamic> metadata = event.toSafeMetadata();

    expect(event.requiresHumanReview, isTrue);
    expect(event.mayAutoSend, isFalse);
    expect(event.phase64OwnerAttentionCompatible, isTrue);
    expect(
      event.reviewActions,
      containsAll(<String>['REVIEW', 'APPROVE', 'REJECT']),
    );

    expect(event.sourceAddressMasked, 'cu***@example.com');
    expect(event.subjectSafe, isNot(contains('123456')));
    expect(metadata['bodyIncluded'], isFalse);
    expect(metadata['sensitiveValueIncluded'], isFalse);
    expect(metadata.toString(), isNot(contains('123456')));
    expect(metadata['attentionType'], 'EMAIL_UNUSUAL_REVIEW');
  });

  test('normal Email policy cannot create unusual Admin Attention', () {
    final AgentEmailAdminAttentionAuditService service =
        AgentEmailAdminAttentionAuditService();

    final AgentEmailDraftPolicyDecision normal = AgentEmailDraftPolicyDecision(
      classification: AgentEmailDraftPolicyClassification.draftReadyForReview,
      reasonCodes: <String>['STRUCTURED_DRAFT_READY_FOR_REVIEW'],
      recipientCount: 1,
      hasBcc: false,
      hasAttachments: false,
      containsSensitiveCredentialPattern: false,
      containsSuspiciousRequestPattern: false,
      bulkRecipientRisk: false,
      requiresHumanReview: false,
      requiresAttachmentReview: false,
      requiresSendApproval: true,
      mayRemainAsDraft: true,
    );

    expect(
      () => service.buildEvent(
        attentionId: 'attention_normal',
        sourceAddress: 'customer@example.com',
        draft: draft(subject: 'Normal update'),
        policyDecision: normal,
      ),
      throwsA(anything),
    );
  });

  test('attention service has zero Email execution authority', () {
    final AgentEmailAdminAttentionAuditService service =
        AgentEmailAdminAttentionAuditService();

    expect(service.maySendEmail, isFalse);
    expect(service.mayApproveEmail, isFalse);
    expect(service.mayRejectEmail, isFalse);
    expect(service.mayConsumeApproval, isFalse);
    expect(service.mayCallProvider, isFalse);
    expect(service.mayStoreRawBodyInAttentionMetadata, isFalse);
    expect(service.mayStoreSensitiveCredentialValue, isFalse);
  });
}

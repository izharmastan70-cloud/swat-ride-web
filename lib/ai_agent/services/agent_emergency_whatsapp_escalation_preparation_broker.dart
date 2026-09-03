import '../constants/agent_action_ids.dart';
import '../models/agent_emergency_whatsapp_foundation.dart';
import '../models/agent_emergency_whatsapp_prepared_escalation.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import 'agent_audit_recorder.dart';
import 'agent_permission_engine.dart';
import 'agent_runtime_gate.dart';

typedef AgentEmergencyWhatsAppEscalationAuditDecision =
    Future<void> Function({
      required AgentRole role,
      required AgentPermissionDecision decision,
      required String actorId,
    });

class AgentEmergencyWhatsAppEscalationPreparationRequest {
  const AgentEmergencyWhatsAppEscalationPreparationRequest({
    required this.userId,
    required this.expectedConversationId,
    required this.expectedSenderBindingId,
    required this.expectedSessionId,
    required this.reasonCode,
  });

  final String userId;
  final String expectedConversationId;
  final String expectedSenderBindingId;
  final String expectedSessionId;
  final String reasonCode;

  String get actionId => AgentActionId.requestEmergencyWhatsAppEscalation;

  bool get isStructurallyValid =>
      userId.trim().isNotEmpty &&
      expectedConversationId.trim().isNotEmpty &&
      expectedSenderBindingId.trim().isNotEmpty &&
      expectedSessionId.trim().isNotEmpty &&
      AgentEmergencyWhatsAppEscalationReasonCode.isValid(reasonCode);
}

class AgentEmergencyWhatsAppEscalationPreparationResult {
  const AgentEmergencyWhatsAppEscalationPreparationResult({
    required this.reachedCentralGate,
    required this.prepared,
    required this.decision,
    required this.reason,
    this.escalation,
  });

  final bool reachedCentralGate;
  final bool prepared;
  final AgentPermissionDecision decision;
  final String reason;
  final AgentEmergencyWhatsAppPreparedEscalation? escalation;

  bool get persistentApprovalCreated => false;
  bool get approvalConsumed => false;
  bool get mayCreateSafetyIncident => false;
  bool get mayMutateSafetyIncident => false;
  bool get maySendSafetyAlert => false;
  bool get maySendWhatsApp => false;
  bool get maySendSms => false;
  bool get mayPlaceEmergencyCall => false;
  bool get mayCallProvider => false;
  bool get mayHandleLiveWebhook => false;
  bool get mayDeploy => false;
}

class AgentEmergencyWhatsAppEscalationPreparationBroker {
  const AgentEmergencyWhatsAppEscalationPreparationBroker({
    required this.permissionEngine,
    required this.runtimeGate,
    required this.auditDecision,
    this.preparationValidity = const Duration(minutes: 5),
  });

  factory AgentEmergencyWhatsAppEscalationPreparationBroker.production({
    required AgentAuditRecorder auditRecorder,
  }) {
    return AgentEmergencyWhatsAppEscalationPreparationBroker(
      permissionEngine: const AgentPermissionEngine(),
      runtimeGate: const AgentRuntimeGate(),
      auditDecision:
          ({
            required AgentRole role,
            required AgentPermissionDecision decision,
            required String actorId,
          }) {
            return auditRecorder.permissionDecision(
              role: role,
              decision: decision,
              actorId: actorId,
            );
          },
    );
  }

  final AgentPermissionEngine permissionEngine;
  final AgentRuntimeGate runtimeGate;
  final AgentEmergencyWhatsAppEscalationAuditDecision auditDecision;
  final Duration preparationValidity;

  Future<AgentEmergencyWhatsAppEscalationPreparationResult> prepare({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentEmergencyWhatsAppSessionBinding session,
    required AgentEmergencyWhatsAppEscalationPreparationRequest request,
    required DateTime now,
  }) async {
    if (role.roleId != AgentEmergencyWhatsAppFoundation.roleId ||
        role.module != AgentEmergencyWhatsAppFoundation.module) {
      return _denyAndAudit(
        role: role,
        request: request,
        reason:
            'Only the isolated Emergency WhatsApp role may prepare an emergency escalation request.',
        reachedCentralGate: false,
      );
    }

    if (!request.isStructurallyValid) {
      return _denyAndAudit(
        role: role,
        request: request,
        reason:
            'Emergency WhatsApp escalation preparation request is incomplete or uses an unsupported reason code.',
        reachedCentralGate: false,
      );
    }

    if (request.actionId != AgentActionId.requestEmergencyWhatsAppEscalation) {
      return _denyAndAudit(
        role: role,
        request: request,
        reason:
            'Emergency escalation preparation accepts only its dedicated approval-gated action.',
        reachedCentralGate: false,
      );
    }

    if (session.principalUid.trim() != request.userId.trim()) {
      return _denyAndAudit(
        role: role,
        request: request,
        reason:
            'Emergency WhatsApp principal does not match the escalation subject.',
        reachedCentralGate: false,
      );
    }

    if (!session.canReadVerifiedSafetyData(
      now: now,
      expectedConversationId: request.expectedConversationId,
      expectedSenderBindingId: request.expectedSenderBindingId,
      expectedSessionId: request.expectedSessionId,
    )) {
      return _denyAndAudit(
        role: role,
        request: request,
        reason:
            'Exact account-verified Emergency WhatsApp session binding is required for escalation preparation.',
        reachedCentralGate: false,
      );
    }

    const AgentEmergencyWhatsAppCommandPolicy policy =
        AgentEmergencyWhatsAppCommandPolicy.prepareEmergencyEscalation();

    if (!policy.requiresAccountVerifiedIdentity ||
        !policy.requiresPermissionEngine ||
        !policy.requiresRuntimeGate ||
        !policy.requiresApprovalEngine ||
        !policy.requiresAudit ||
        policy.requiresExplicitSensitiveDataScope ||
        policy.mayExecuteDirectly ||
        policy.maySendExternalAlert ||
        policy.mayPlaceEmergencyCall) {
      return _denyAndAudit(
        role: role,
        request: request,
        reason:
            'Emergency escalation policy is not in its required approval-bound fail-closed state.',
        reachedCentralGate: false,
      );
    }

    final AgentPermissionDecision permission = permissionEngine.evaluate(
      role: role,
      actionId: request.actionId,
    );

    final AgentPermissionDecision runtime = runtimeGate.apply(
      settings: settings,
      role: role,
      permissionDecision: permission,
    );

    await auditDecision(
      role: role,
      decision: runtime,
      actorId: request.userId.trim(),
    );

    if (runtime.isDenied) {
      return AgentEmergencyWhatsAppEscalationPreparationResult(
        reachedCentralGate: true,
        prepared: false,
        decision: runtime,
        reason: runtime.reason,
      );
    }

    // The only acceptable state for this high-risk preparation is
    // REQUIRE_APPROVAL. An ALLOW result would weaken the locked boundary.
    if (!runtime.needsApproval) {
      final AgentPermissionDecision denied = AgentPermissionDecision.deny(
        roleId: role.roleId,
        actionId: request.actionId,
        reason:
            'Emergency escalation must remain REQUIRE_APPROVAL; direct ALLOW fails closed.',
        effectiveMode: role.mode,
      );

      await auditDecision(
        role: role,
        decision: denied,
        actorId: request.userId.trim(),
      );

      return AgentEmergencyWhatsAppEscalationPreparationResult(
        reachedCentralGate: true,
        prepared: false,
        decision: denied,
        reason: denied.reason,
      );
    }

    final DateTime proposedExpiry = now.add(preparationValidity);
    final DateTime validUntil = session.expiresAt.isBefore(proposedExpiry)
        ? session.expiresAt
        : proposedExpiry;

    if (!validUntil.isAfter(now)) {
      final AgentPermissionDecision denied = AgentPermissionDecision.deny(
        roleId: role.roleId,
        actionId: request.actionId,
        reason:
            'Emergency escalation preparation cannot outlive an expired session.',
        effectiveMode: role.mode,
      );

      await auditDecision(
        role: role,
        decision: denied,
        actorId: request.userId.trim(),
      );

      return AgentEmergencyWhatsAppEscalationPreparationResult(
        reachedCentralGate: true,
        prepared: false,
        decision: denied,
        reason: denied.reason,
      );
    }

    final AgentEmergencyWhatsAppPreparedEscalation escalation =
        AgentEmergencyWhatsAppPreparedEscalation(
          roleId: role.roleId,
          module: role.module,
          actionId: request.actionId,
          principalUid: request.userId.trim(),
          subjectType: session.subjectType.name,
          reasonCode: request.reasonCode,
          preparedAt: now,
          validUntil: validUntil,
        );

    return AgentEmergencyWhatsAppEscalationPreparationResult(
      reachedCentralGate: true,
      prepared: true,
      decision: runtime,
      escalation: escalation,
      reason:
          'Emergency escalation is prepared locally and remains approval-required. No persistent approval, SOS mutation, transport or call was executed.',
    );
  }

  Future<AgentEmergencyWhatsAppEscalationPreparationResult> _denyAndAudit({
    required AgentRole role,
    required AgentEmergencyWhatsAppEscalationPreparationRequest request,
    required String reason,
    required bool reachedCentralGate,
  }) async {
    final AgentPermissionDecision denied = AgentPermissionDecision.deny(
      roleId: role.roleId,
      actionId: request.actionId,
      reason: reason,
      effectiveMode: role.mode,
    );

    await auditDecision(
      role: role,
      decision: denied,
      actorId: request.userId.trim(),
    );

    return AgentEmergencyWhatsAppEscalationPreparationResult(
      reachedCentralGate: reachedCentralGate,
      prepared: false,
      decision: denied,
      reason: denied.reason,
    );
  }
}

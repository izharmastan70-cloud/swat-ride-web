// =========================================================
// PHASE 46 - OWNER WHATSAPP CENTRAL AUTHORIZATION ROUTER
// =========================================================
//
// Purpose:
// 1) Owner WhatsApp channel gate FIRST.
// 2) Exact verified Owner/Super Admin session binding.
// 3) Strong re-auth for consequential requests.
// 4) Existing Permission Engine.
// 5) Existing Runtime Gate.
// 6) Existing Audit Recorder.
//
// NO:
// - provider selection;
// - webhook;
// - WhatsApp send;
// - Firestore mutation;
// - business/admin write;
// - payment;
// - deployment;
// - approval consumption/execution.
//
// IMPORTANT:
// Passing this router only means the request reached the existing
// central authorization/approval boundary. It never executes an action.

import '../models/agent_master_settings.dart';
import '../models/agent_owner_whatsapp_foundation.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import 'agent_audit_recorder.dart';
import 'agent_permission_engine.dart';
import 'agent_runtime_gate.dart';

enum AgentOwnerWhatsAppControlArea {
  report,
  operations,
  financial,
  accountSecurity,
}

class AgentOwnerWhatsAppAuthorizationRequest {
  final String actionId;
  final String actorId;
  final AgentOwnerWhatsAppControlArea controlArea;
  final AgentOwnerWhatsAppCommandPolicy commandPolicy;

  final String expectedConversationId;
  final String expectedSenderBindingId;
  final String expectedSessionId;

  const AgentOwnerWhatsAppAuthorizationRequest({
    required this.actionId,
    required this.actorId,
    required this.controlArea,
    required this.commandPolicy,
    required this.expectedConversationId,
    required this.expectedSenderBindingId,
    required this.expectedSessionId,
  });

  bool get isStructurallyValid =>
      actionId.trim().isNotEmpty &&
      actorId.trim().isNotEmpty &&
      expectedConversationId.trim().isNotEmpty &&
      expectedSenderBindingId.trim().isNotEmpty &&
      expectedSessionId.trim().isNotEmpty;
}

class AgentOwnerWhatsAppLocalPreflightDecision {
  final bool allowedToReachCentralGate;
  final String reason;

  const AgentOwnerWhatsAppLocalPreflightDecision._({
    required this.allowedToReachCentralGate,
    required this.reason,
  });

  const AgentOwnerWhatsAppLocalPreflightDecision.allow()
    : this._(
        allowedToReachCentralGate: true,
        reason:
            'Owner WhatsApp local preflight passed; central authorization is still required.',
      );

  const AgentOwnerWhatsAppLocalPreflightDecision.deny(String reason)
    : this._(allowedToReachCentralGate: false, reason: reason);
}

class AgentOwnerWhatsAppAuthorizationPreflight {
  const AgentOwnerWhatsAppAuthorizationPreflight();

  AgentOwnerWhatsAppLocalPreflightDecision evaluate({
    required AgentOwnerWhatsAppControlSettings channelSettings,
    required AgentOwnerWhatsAppSessionBinding session,
    required AgentOwnerWhatsAppAuthorizationRequest request,
    required DateTime now,
  }) {
    if (!request.isStructurallyValid) {
      return const AgentOwnerWhatsAppLocalPreflightDecision.deny(
        'Owner WhatsApp authorization request is incomplete.',
      );
    }

    if (!channelSettings.enabled) {
      return const AgentOwnerWhatsAppLocalPreflightDecision.deny(
        'Owner WhatsApp Agent master switch is OFF.',
      );
    }

    if (!_controlAreaEnabled(channelSettings, request.controlArea)) {
      return const AgentOwnerWhatsAppLocalPreflightDecision.deny(
        'Requested Owner WhatsApp control area is OFF.',
      );
    }

    if (request.commandPolicy.commandClass ==
        AgentOwnerWhatsAppCommandClass.forbidden) {
      return const AgentOwnerWhatsAppLocalPreflightDecision.deny(
        'Owner WhatsApp command is forbidden/unknown and fails closed.',
      );
    }

    if (request.commandPolicy.commandClass ==
        AgentOwnerWhatsAppCommandClass.readReport) {
      if (!session.canReadOwnerData(
        now: now,
        expectedConversationId: request.expectedConversationId,
        expectedSenderBindingId: request.expectedSenderBindingId,
        expectedSessionId: request.expectedSessionId,
      )) {
        return const AgentOwnerWhatsAppLocalPreflightDecision.deny(
          'Verified Owner/Super Admin session binding is required for report access.',
        );
      }

      return const AgentOwnerWhatsAppLocalPreflightDecision.allow();
    }

    if (request.commandPolicy.commandClass ==
        AgentOwnerWhatsAppCommandClass.consequentialAction) {
      if (!session.canRequestConsequentialAction(
        now: now,
        expectedConversationId: request.expectedConversationId,
        expectedSenderBindingId: request.expectedSenderBindingId,
        expectedSessionId: request.expectedSessionId,
      )) {
        return const AgentOwnerWhatsAppLocalPreflightDecision.deny(
          'Strong re-auth and exact Owner/Super Admin session binding are required.',
        );
      }

      if (!request.commandPolicy.requiresApprovalEngine ||
          !request.commandPolicy.requiresPermissionEngine ||
          !request.commandPolicy.requiresRuntimeGate ||
          !request.commandPolicy.requiresAudit) {
        return const AgentOwnerWhatsAppLocalPreflightDecision.deny(
          'Consequential Owner WhatsApp command is missing mandatory central security requirements.',
        );
      }

      return const AgentOwnerWhatsAppLocalPreflightDecision.allow();
    }

    return const AgentOwnerWhatsAppLocalPreflightDecision.deny(
      'Unsupported Owner WhatsApp command class.',
    );
  }

  bool _controlAreaEnabled(
    AgentOwnerWhatsAppControlSettings settings,
    AgentOwnerWhatsAppControlArea area,
  ) {
    switch (area) {
      case AgentOwnerWhatsAppControlArea.report:
        return settings.reportsEnabled;
      case AgentOwnerWhatsAppControlArea.operations:
        return settings.operationalCommandsEnabled;
      case AgentOwnerWhatsAppControlArea.financial:
        return settings.financialCommandsEnabled;
      case AgentOwnerWhatsAppControlArea.accountSecurity:
        return settings.accountSecurityCommandsEnabled;
    }
  }
}

class AgentOwnerWhatsAppAuthorizationResult {
  final bool reachedCentralGate;
  final AgentPermissionDecision decision;
  final String reason;

  const AgentOwnerWhatsAppAuthorizationResult({
    required this.reachedCentralGate,
    required this.decision,
    required this.reason,
  });

  bool get isDenied => decision.isDenied;

  /// This result never grants execution authority.
  bool get mayExecuteBusinessOrAdminWrite => false;

  /// This result never grants provider/transport authority.
  bool get maySendWhatsApp => false;

  bool get mayDeploy => false;
}

class AgentOwnerWhatsAppAuthorizationRouter {
  final AgentPermissionEngine permissionEngine;
  final AgentRuntimeGate runtimeGate;
  final AgentAuditRecorder auditRecorder;
  final AgentOwnerWhatsAppAuthorizationPreflight preflight;

  const AgentOwnerWhatsAppAuthorizationRouter({
    required this.permissionEngine,
    required this.runtimeGate,
    required this.auditRecorder,
    this.preflight = const AgentOwnerWhatsAppAuthorizationPreflight(),
  });

  Future<AgentOwnerWhatsAppAuthorizationResult> evaluate({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentOwnerWhatsAppControlSettings channelSettings,
    required AgentOwnerWhatsAppSessionBinding session,
    required AgentOwnerWhatsAppAuthorizationRequest request,
    required DateTime now,
  }) async {
    if (role.roleId != AgentOwnerWhatsAppFoundation.roleId) {
      final AgentPermissionDecision denied = AgentPermissionDecision.deny(
        roleId: role.roleId,
        actionId: request.actionId,
        reason:
            'Role mismatch: Customer/Call/Email/Emergency/other role cannot inherit Owner WhatsApp authority.',
        effectiveMode: role.mode,
      );

      await auditRecorder.permissionDecision(
        role: role,
        decision: denied,
        actorId: request.actorId,
      );

      return AgentOwnerWhatsAppAuthorizationResult(
        reachedCentralGate: false,
        decision: denied,
        reason: denied.reason,
      );
    }

    final AgentOwnerWhatsAppLocalPreflightDecision local = preflight.evaluate(
      channelSettings: channelSettings,
      session: session,
      request: request,
      now: now,
    );

    if (!local.allowedToReachCentralGate) {
      final AgentPermissionDecision denied = AgentPermissionDecision.deny(
        roleId: role.roleId,
        actionId: request.actionId,
        reason: local.reason,
        effectiveMode: role.mode,
      );

      await auditRecorder.permissionDecision(
        role: role,
        decision: denied,
        actorId: request.actorId,
      );

      return AgentOwnerWhatsAppAuthorizationResult(
        reachedCentralGate: false,
        decision: denied,
        reason: denied.reason,
      );
    }

    // Existing central Permission Engine remains authoritative.
    final AgentPermissionDecision permission = permissionEngine.evaluate(
      role: role,
      actionId: request.actionId,
    );

    // Existing Runtime Gate re-checks master/emergency/provider class/
    // approval-engine state immediately after permission evaluation.
    final AgentPermissionDecision runtime = runtimeGate.apply(
      settings: settings,
      role: role,
      permissionDecision: permission,
    );

    // Every Owner WhatsApp central authorization decision is audited.
    await auditRecorder.permissionDecision(
      role: role,
      decision: runtime,
      actorId: request.actorId,
    );

    if (runtime.isDenied) {
      return AgentOwnerWhatsAppAuthorizationResult(
        reachedCentralGate: true,
        decision: runtime,
        reason: runtime.reason,
      );
    }

    // Consequential Owner WhatsApp actions MUST remain approval-bound.
    // If central role/action configuration ever returns a non-approval
    // decision for such a request, fail closed instead of executing.
    if (request.commandPolicy.commandClass ==
            AgentOwnerWhatsAppCommandClass.consequentialAction &&
        !runtime.needsApproval) {
      final AgentPermissionDecision denied = AgentPermissionDecision.deny(
        roleId: role.roleId,
        actionId: request.actionId,
        reason:
            'Consequential Owner WhatsApp action must remain approval-required.',
        effectiveMode: role.mode,
      );

      await auditRecorder.permissionDecision(
        role: role,
        decision: denied,
        actorId: request.actorId,
      );

      return AgentOwnerWhatsAppAuthorizationResult(
        reachedCentralGate: true,
        decision: denied,
        reason: denied.reason,
      );
    }

    return AgentOwnerWhatsAppAuthorizationResult(
      reachedCentralGate: true,
      decision: runtime,
      reason:
          'Central Permission Engine + Runtime Gate passed. No action has been executed.',
    );
  }
}

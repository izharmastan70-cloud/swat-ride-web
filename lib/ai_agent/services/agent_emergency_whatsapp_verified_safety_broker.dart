import '../constants/agent_action_ids.dart';
import '../models/agent_emergency_whatsapp_foundation.dart';
import '../models/agent_emergency_whatsapp_verified_safety_snapshot.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import 'agent_audit_recorder.dart';
import 'agent_emergency_whatsapp_verified_safety_source.dart';
import 'agent_master_settings_service.dart';
import 'agent_permission_engine.dart';
import 'agent_role_service.dart';
import 'agent_runtime_gate.dart';

typedef AgentEmergencyWhatsAppAuditPermissionDecision =
    Future<void> Function({
      required AgentRole role,
      required AgentPermissionDecision decision,
      required String actorId,
    });

typedef AgentEmergencyWhatsAppVerifiedSafetyLoader =
    Future<AgentEmergencyWhatsAppVerifiedSafetySnapshot> Function({
      required String userId,
    });

typedef AgentEmergencyWhatsAppSettingsLoader =
    Future<AgentMasterSettings> Function();

typedef AgentEmergencyWhatsAppRoleLoader =
    Future<AgentRole?> Function(String roleId);

class AgentEmergencyWhatsAppVerifiedSafetyRequest {
  const AgentEmergencyWhatsAppVerifiedSafetyRequest({
    required this.userId,
    required this.expectedConversationId,
    required this.expectedSenderBindingId,
    required this.expectedSessionId,
  });

  final String userId;
  final String expectedConversationId;
  final String expectedSenderBindingId;
  final String expectedSessionId;

  String get actionId => AgentActionId.readEmergencyWhatsAppVerifiedSafety;

  bool get isStructurallyValid =>
      userId.trim().isNotEmpty &&
      expectedConversationId.trim().isNotEmpty &&
      expectedSenderBindingId.trim().isNotEmpty &&
      expectedSessionId.trim().isNotEmpty;
}

class AgentEmergencyWhatsAppVerifiedSafetyBrokerResult {
  const AgentEmergencyWhatsAppVerifiedSafetyBrokerResult({
    required this.authorizationReachedCentralGate,
    required this.authorizationPassed,
    required this.decision,
    required this.snapshot,
    required this.reason,
  });

  final bool authorizationReachedCentralGate;
  final bool authorizationPassed;
  final AgentPermissionDecision decision;
  final AgentEmergencyWhatsAppVerifiedSafetySnapshot snapshot;
  final String reason;

  bool get sourceVerified => snapshot.incidentSourceVerified;

  bool get mayWriteSafetyIncident => false;
  bool get mayAcknowledgeIncident => false;
  bool get mayAssignSafetyAgent => false;
  bool get mayResolveIncident => false;
  bool get mayMarkUserSafe => false;
  bool get mayUpdateEmergencyLocation => false;
  bool get mayModifyTrustedContacts => false;
  bool get maySendWhatsApp => false;
  bool get maySendSms => false;
  bool get mayPlaceEmergencyCall => false;
  bool get mayCallProvider => false;
  bool get mayHandleLiveWebhook => false;
  bool get mayDeploy => false;
}

class AgentEmergencyWhatsAppVerifiedSafetyBroker {
  const AgentEmergencyWhatsAppVerifiedSafetyBroker({
    required this.permissionEngine,
    required this.runtimeGate,
    required this.auditPermissionDecision,
    required this.loadVerifiedSafety,
  });

  factory AgentEmergencyWhatsAppVerifiedSafetyBroker.production({
    required AgentAuditRecorder auditRecorder,
    required AgentEmergencyWhatsAppVerifiedSafetySource source,
  }) {
    return AgentEmergencyWhatsAppVerifiedSafetyBroker(
      permissionEngine: const AgentPermissionEngine(),
      runtimeGate: const AgentRuntimeGate(),
      auditPermissionDecision:
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
      loadVerifiedSafety: ({required String userId}) {
        return source.loadForUser(userId: userId);
      },
    );
  }

  final AgentPermissionEngine permissionEngine;
  final AgentRuntimeGate runtimeGate;
  final AgentEmergencyWhatsAppAuditPermissionDecision auditPermissionDecision;
  final AgentEmergencyWhatsAppVerifiedSafetyLoader loadVerifiedSafety;

  Future<AgentEmergencyWhatsAppVerifiedSafetyBrokerResult> read({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentEmergencyWhatsAppSessionBinding session,
    required AgentEmergencyWhatsAppVerifiedSafetyRequest request,
    required DateTime now,
  }) async {
    if (role.roleId != AgentEmergencyWhatsAppFoundation.roleId ||
        role.module != AgentEmergencyWhatsAppFoundation.module) {
      return _denyAndAudit(
        role: role,
        request: request,
        reason:
            'Only the isolated Emergency WhatsApp role may request verified emergency safety status.',
        reachedCentralGate: false,
      );
    }

    if (!request.isStructurallyValid) {
      return _denyAndAudit(
        role: role,
        request: request,
        reason: 'Emergency WhatsApp verified safety request is incomplete.',
        reachedCentralGate: false,
      );
    }

    if (request.actionId != AgentActionId.readEmergencyWhatsAppVerifiedSafety) {
      return _denyAndAudit(
        role: role,
        request: request,
        reason:
            'Emergency verified-safety broker accepts only its dedicated read action.',
        reachedCentralGate: false,
      );
    }

    if (session.principalUid.trim() != request.userId.trim()) {
      return _denyAndAudit(
        role: role,
        request: request,
        reason:
            'Emergency WhatsApp principal does not own the requested user-scoped safety data.',
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
            'Exact account-verified Emergency WhatsApp session binding is required.',
        reachedCentralGate: false,
      );
    }

    const AgentEmergencyWhatsAppCommandPolicy commandPolicy =
        AgentEmergencyWhatsAppCommandPolicy.readVerifiedSafetyStatus();

    if (!commandPolicy.requiresAccountVerifiedIdentity ||
        !commandPolicy.requiresPermissionEngine ||
        !commandPolicy.requiresRuntimeGate ||
        !commandPolicy.requiresAudit ||
        commandPolicy.requiresApprovalEngine ||
        commandPolicy.requiresExplicitSensitiveDataScope) {
      return _denyAndAudit(
        role: role,
        request: request,
        reason:
            'Emergency verified-safety read policy is not in its required fail-closed security state.',
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

    await auditPermissionDecision(
      role: role,
      decision: runtime,
      actorId: request.userId.trim(),
    );

    if (runtime.isDenied) {
      return _resultFromDeniedDecision(
        decision: runtime,
        reachedCentralGate: true,
      );
    }

    // A pure verified read is intentionally non-consequential.
    // If central configuration unexpectedly turns it into an approval path,
    // fail closed before touching the safety source.
    if (runtime.needsApproval) {
      final AgentPermissionDecision denied = AgentPermissionDecision.deny(
        roleId: role.roleId,
        actionId: request.actionId,
        reason:
            'Pure Emergency WhatsApp verified-safety read unexpectedly requires approval; fail closed.',
        effectiveMode: role.mode,
      );

      await auditPermissionDecision(
        role: role,
        decision: denied,
        actorId: request.userId.trim(),
      );

      return _resultFromDeniedDecision(
        decision: denied,
        reachedCentralGate: true,
      );
    }

    if (!runtime.isAllowed) {
      final AgentPermissionDecision denied = AgentPermissionDecision.deny(
        roleId: role.roleId,
        actionId: request.actionId,
        reason:
            'Emergency verified-safety read did not receive an explicit ALLOW decision.',
        effectiveMode: role.mode,
      );

      await auditPermissionDecision(
        role: role,
        decision: denied,
        actorId: request.userId.trim(),
      );

      return _resultFromDeniedDecision(
        decision: denied,
        reachedCentralGate: true,
      );
    }

    final AgentEmergencyWhatsAppVerifiedSafetySnapshot snapshot =
        await loadVerifiedSafety(userId: request.userId.trim());

    return AgentEmergencyWhatsAppVerifiedSafetyBrokerResult(
      authorizationReachedCentralGate: true,
      authorizationPassed: true,
      decision: runtime,
      snapshot: snapshot,
      reason: snapshot.incidentSourceVerified
          ? 'Verified Emergency WhatsApp authorization passed and sanitized user-scoped safety source was read.'
          : 'Authorization passed, but verified user-scoped safety source is unavailable.',
    );
  }

  Future<AgentEmergencyWhatsAppVerifiedSafetyBrokerResult> _denyAndAudit({
    required AgentRole role,
    required AgentEmergencyWhatsAppVerifiedSafetyRequest request,
    required String reason,
    required bool reachedCentralGate,
  }) async {
    final AgentPermissionDecision denied = AgentPermissionDecision.deny(
      roleId: role.roleId,
      actionId: request.actionId,
      reason: reason,
      effectiveMode: role.mode,
    );

    await auditPermissionDecision(
      role: role,
      decision: denied,
      actorId: request.userId.trim(),
    );

    return _resultFromDeniedDecision(
      decision: denied,
      reachedCentralGate: reachedCentralGate,
    );
  }

  AgentEmergencyWhatsAppVerifiedSafetyBrokerResult _resultFromDeniedDecision({
    required AgentPermissionDecision decision,
    required bool reachedCentralGate,
  }) {
    return AgentEmergencyWhatsAppVerifiedSafetyBrokerResult(
      authorizationReachedCentralGate: reachedCentralGate,
      authorizationPassed: false,
      decision: decision,
      snapshot: AgentEmergencyWhatsAppVerifiedSafetySnapshot.unavailable(
        reason: decision.reason,
      ),
      reason: decision.reason,
    );
  }
}

class AgentEmergencyWhatsAppVerifiedSafetyCoordinator {
  const AgentEmergencyWhatsAppVerifiedSafetyCoordinator({
    required this.loadSettings,
    required this.loadRole,
    required this.broker,
  });

  factory AgentEmergencyWhatsAppVerifiedSafetyCoordinator.production({
    required AgentMasterSettingsService settingsService,
    required AgentRoleService roleService,
    required AgentAuditRecorder auditRecorder,
    required AgentEmergencyWhatsAppVerifiedSafetySource source,
  }) {
    return AgentEmergencyWhatsAppVerifiedSafetyCoordinator(
      loadSettings: () => settingsService.getSettings(),
      loadRole: (String roleId) => roleService.getRole(roleId),
      broker: AgentEmergencyWhatsAppVerifiedSafetyBroker.production(
        auditRecorder: auditRecorder,
        source: source,
      ),
    );
  }

  final AgentEmergencyWhatsAppSettingsLoader loadSettings;
  final AgentEmergencyWhatsAppRoleLoader loadRole;
  final AgentEmergencyWhatsAppVerifiedSafetyBroker broker;

  Future<AgentEmergencyWhatsAppVerifiedSafetyBrokerResult> read({
    required AgentEmergencyWhatsAppSessionBinding session,
    required AgentEmergencyWhatsAppVerifiedSafetyRequest request,
    required DateTime now,
  }) async {
    final AgentMasterSettings settings = await loadSettings();
    final AgentRole? role = await loadRole(
      AgentEmergencyWhatsAppFoundation.roleId,
    );

    if (role == null) {
      final AgentPermissionDecision denied = AgentPermissionDecision.deny(
        roleId: AgentEmergencyWhatsAppFoundation.roleId,
        actionId: request.actionId,
        reason:
            'Emergency WhatsApp role configuration is unavailable; fail closed.',
      );

      return AgentEmergencyWhatsAppVerifiedSafetyBrokerResult(
        authorizationReachedCentralGate: false,
        authorizationPassed: false,
        decision: denied,
        snapshot: AgentEmergencyWhatsAppVerifiedSafetySnapshot.unavailable(
          reason: denied.reason,
        ),
        reason: denied.reason,
      );
    }

    return broker.read(
      settings: settings,
      role: role,
      session: session,
      request: request,
      now: now,
    );
  }
}

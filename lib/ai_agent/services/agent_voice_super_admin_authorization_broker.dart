import '../constants/agent_action_ids.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import '../models/agent_voice_super_admin_authorization.dart';
import '../models/agent_voice_super_admin_foundation.dart';
import 'agent_audit_recorder.dart';
import 'agent_permission_engine.dart';
import 'agent_runtime_gate.dart';

/// Small adapter around the existing central AgentAuditRecorder.
///
/// Tests may inject an in-memory implementation, while production uses this
/// adapter. This does not create a second audit authority.
abstract class AgentVoiceSuperAdminAuthorizationAudit {
  Future<void> recordPermissionDecision({
    required AgentRole role,
    required AgentPermissionDecision decision,
    required String actorId,
  });
}

class AgentVoiceSuperAdminCentralAuditAdapter
    implements AgentVoiceSuperAdminAuthorizationAudit {
  const AgentVoiceSuperAdminCentralAuditAdapter({required this.recorder});

  final AgentAuditRecorder recorder;

  @override
  Future<void> recordPermissionDecision({
    required AgentRole role,
    required AgentPermissionDecision decision,
    required String actorId,
  }) {
    return recorder.permissionDecision(
      role: role,
      decision: decision,
      actorId: actorId,
    );
  }
}

class AgentVoiceSuperAdminAuthorizationResult {
  const AgentVoiceSuperAdminAuthorizationResult({
    required this.reachedCentralGate,
    required this.decision,
    required this.reason,
  });

  final bool reachedCentralGate;
  final AgentPermissionDecision decision;
  final String reason;

  bool get isDenied => decision.isDenied;

  /// ALLOW means only that a separately-audited verified source acquisition
  /// layer may be consulted. It never means business/admin execution.
  bool get mayAcquireVerifiedSections =>
      reachedCentralGate && decision.isAllowed;

  bool get mayExecuteBusinessOrAdminWrite => false;
  bool get mayConsumeApproval => false;
  bool get mayMutateSafety => false;
  bool get mayCallProvider => false;
  bool get mayUseSpeechTransport => false;
  bool get mayDeploy => false;
}

/// Phase 48 READ/REPORT authorization boundary.
///
/// Order:
/// 1) isolated Voice Super Admin role/module/action
/// 2) exact linked Owner/Super Admin application session
/// 3) existing Permission Engine
/// 4) existing Runtime Gate (including Voice master switch)
/// 5) existing Audit Recorder via adapter
///
/// This broker does not fetch module data, compose a report, call STT/TTS,
/// create/consume approvals, mutate Safety, or execute a business/admin write.
class AgentVoiceSuperAdminAuthorizationBroker {
  const AgentVoiceSuperAdminAuthorizationBroker({
    this.permissionEngine = const AgentPermissionEngine(),
    this.runtimeGate = const AgentRuntimeGate(),
    required this.audit,
  });

  final AgentPermissionEngine permissionEngine;
  final AgentRuntimeGate runtimeGate;
  final AgentVoiceSuperAdminAuthorizationAudit audit;

  Future<AgentVoiceSuperAdminAuthorizationResult> evaluate({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentVoiceSuperAdminSessionBinding session,
    required AgentVoiceSuperAdminAuthorizationRequest request,
    required DateTime now,
  }) async {
    if (role.roleId != AgentVoiceSuperAdminFoundation.roleId ||
        role.module != AgentVoiceSuperAdminFoundation.module) {
      return _denyAndAudit(
        role: role,
        request: request,
        reachedCentralGate: false,
        reason:
            'Only the isolated Voice Super Admin role/module may request Voice Super Admin reports.',
      );
    }

    if (!request.isStructurallyValid) {
      return _denyAndAudit(
        role: role,
        request: request,
        reachedCentralGate: false,
        reason: 'Voice Super Admin authorization request is incomplete.',
      );
    }

    if (request.actionId != AgentActionId.readVoiceSuperAdminVerifiedReport) {
      return _denyAndAudit(
        role: role,
        request: request,
        reachedCentralGate: false,
        reason:
            'Voice Super Admin broker accepts only the dedicated verified read/report action.',
      );
    }

    if (request.actorId.trim() != session.principalUid.trim()) {
      return _denyAndAudit(
        role: role,
        request: request,
        reachedCentralGate: false,
        reason:
            'Voice Super Admin actor does not match the authenticated Owner/Super Admin session principal.',
      );
    }

    if (!session.canReadOwnerData(
      now: now,
      expectedDeviceBindingId: request.expectedDeviceBindingId,
      expectedSessionId: request.expectedSessionId,
    )) {
      return _denyAndAudit(
        role: role,
        request: request,
        reachedCentralGate: false,
        reason:
            'Exact active linked Owner/Super Admin application session is required for Voice Super Admin report access.',
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

    await audit.recordPermissionDecision(
      role: role,
      decision: runtime,
      actorId: request.actorId,
    );

    if (runtime.isDenied) {
      return AgentVoiceSuperAdminAuthorizationResult(
        reachedCentralGate: true,
        decision: runtime,
        reason: runtime.reason,
      );
    }

    if (runtime.needsApproval) {
      final AgentPermissionDecision denied = AgentPermissionDecision.deny(
        roleId: role.roleId,
        actionId: request.actionId,
        reason:
            'Pure Voice Super Admin verified report read unexpectedly requires approval; fail closed.',
        effectiveMode: role.mode,
      );

      await audit.recordPermissionDecision(
        role: role,
        decision: denied,
        actorId: request.actorId,
      );

      return AgentVoiceSuperAdminAuthorizationResult(
        reachedCentralGate: true,
        decision: denied,
        reason: denied.reason,
      );
    }

    if (!runtime.isAllowed) {
      final AgentPermissionDecision denied = AgentPermissionDecision.deny(
        roleId: role.roleId,
        actionId: request.actionId,
        reason:
            'Voice Super Admin central gate returned an unsupported decision; fail closed.',
        effectiveMode: role.mode,
      );

      await audit.recordPermissionDecision(
        role: role,
        decision: denied,
        actorId: request.actorId,
      );

      return AgentVoiceSuperAdminAuthorizationResult(
        reachedCentralGate: true,
        decision: denied,
        reason: denied.reason,
      );
    }

    return AgentVoiceSuperAdminAuthorizationResult(
      reachedCentralGate: true,
      decision: runtime,
      reason:
          'Exact Owner/Super Admin session + Permission Engine + Runtime Gate passed and were audited. Verified section acquisition may proceed; no action has been executed.',
    );
  }

  Future<AgentVoiceSuperAdminAuthorizationResult> _denyAndAudit({
    required AgentRole role,
    required AgentVoiceSuperAdminAuthorizationRequest request,
    required bool reachedCentralGate,
    required String reason,
  }) async {
    final AgentPermissionDecision denied = AgentPermissionDecision.deny(
      roleId: role.roleId,
      actionId: request.actionId,
      reason: reason,
      effectiveMode: role.mode,
    );

    await audit.recordPermissionDecision(
      role: role,
      decision: denied,
      actorId: request.actorId.trim().isEmpty ? 'unknown' : request.actorId,
    );

    return AgentVoiceSuperAdminAuthorizationResult(
      reachedCentralGate: reachedCentralGate,
      decision: denied,
      reason: denied.reason,
    );
  }
}

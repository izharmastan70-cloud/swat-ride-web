import '../constants/agent_audit_constants.dart';
import '../models/agent_approval_request.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import 'agent_audit_service.dart';

// =========================================================
// AI AGENT — AUDIT RECORDER
// =========================================================
//
// Convenience layer for Phase 1/2/3 events.
// No business tool execution.

class AgentAuditRecorder {
  final AgentAuditService auditService;

  const AgentAuditRecorder({
    required this.auditService,
  });

  Future<void> permissionDecision({
    required AgentRole role,
    required AgentPermissionDecision decision,
    required String actorId,
  }) async {
    await auditService.append(
      eventType: AgentAuditEventType.permissionEvaluated,
      severity: decision.isDenied
          ? AgentAuditSeverity.warning
          : AgentAuditSeverity.info,
      actorType: AgentAuditActorType.agent,
      actorId: actorId,
      roleId: role.roleId,
      module: role.module,
      actionId: decision.actionId,
      result: decision.result,
      reason: decision.reason,
      metadata: <String, dynamic>{
        'effectiveMode': decision.effectiveMode,
        'roleOperational': role.isOperational,
        'failClosed': role.isFailClosed,
      },
    );
  }

  Future<void> approvalRequested({
    required AgentApprovalRequest request,
    required String actorId,
  }) async {
    await auditService.append(
      eventType: AgentAuditEventType.approvalRequested,
      severity: AgentAuditSeverity.info,
      actorType: AgentAuditActorType.agent,
      actorId: actorId,
      roleId: request.roleId,
      module: request.module,
      actionId: request.actionId,
      result: request.status,
      reason: request.reason,
      relatedApprovalId: request.approvalId,
      scope: request.actionScope,
      metadata: <String, dynamic>{
        'risk': request.risk,
        'expiresAt': request.expiresAt.toIso8601String(),
      },
    );
  }

  Future<void> approvalDecision({
    required AgentApprovalRequest request,
    required String eventType,
    required String actorType,
    required String actorId,
    required String result,
    String reason = '',
  }) async {
    await auditService.append(
      eventType: eventType,
      severity: result == 'APPROVED'
          ? AgentAuditSeverity.info
          : AgentAuditSeverity.warning,
      actorType: actorType,
      actorId: actorId,
      roleId: request.roleId,
      module: request.module,
      actionId: request.actionId,
      result: result,
      reason: reason,
      relatedApprovalId: request.approvalId,
      scope: request.actionScope,
    );
  }

  Future<void> roleFailClosed({
    required AgentRole role,
    String reason = 'Invalid/corrupted role configuration.',
  }) async {
    await auditService.append(
      eventType: AgentAuditEventType.roleFailClosed,
      severity: AgentAuditSeverity.high,
      actorType: AgentAuditActorType.system,
      actorId: 'system',
      roleId: role.roleId,
      module: role.module,
      result: 'FORCED_OFF',
      reason: reason,
      metadata: <String, dynamic>{
        'mode': role.mode,
        'enabled': role.enabled,
        'aiClass': role.aiClass,
        'privacyLevel': role.privacyLevel,
      },
    );
  }
}

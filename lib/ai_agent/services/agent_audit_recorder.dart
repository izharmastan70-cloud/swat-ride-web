import '../constants/agent_audit_constants.dart';
import '../models/agent_approval_request.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import '../models/agent_website_deployment_history.dart';
import 'agent_audit_service.dart';

// =========================================================
// AI AGENT â€” AUDIT RECORDER
// =========================================================
//
// Convenience layer for Phase 1/2/3 events.
// No business tool execution.

class AgentAuditRecorder {
  final AgentAuditService auditService;

  const AgentAuditRecorder({required this.auditService});

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

  Future<void> websiteDeploymentLifecycle({
    required AgentWebsiteDeploymentHistory history,
    required String actorId,
    required String actionId,
    required String result,
    required String reason,
    String actorType = AgentAuditActorType.admin,
  }) async {
    history.validate();

    if (actorId.trim().isEmpty ||
        actionId.trim().isEmpty ||
        result.trim().isEmpty ||
        reason.trim().isEmpty) {
      throw ArgumentError(
        'Website deployment audit requires actorId, actionId, result and reason.',
      );
    }

    await auditService.append(
      eventType: AgentAuditEventType.systemEvent,
      severity: history.rollbackRequested || history.rollbackCompleted
          ? AgentAuditSeverity.warning
          : AgentAuditSeverity.info,
      actorType: actorType,
      actorId: actorId.trim(),
      module: 'website',
      actionId: actionId.trim(),
      result: result.trim(),
      reason: reason.trim(),
      relatedApprovalId: history.approvalId,
      scope: <String, dynamic>{
        'deploymentId': history.deploymentId,
        'changeId': history.changeId,
        'target': history.target,
        'decision': history.decision,
        'websiteFilePaths': List<String>.from(history.approvedFilePaths),
      },
      metadata: <String, dynamic>{
        'backupId': history.backupId,
        'deploymentAttempted': history.deploymentAttempted,
        'deploymentSucceeded': history.deploymentSucceeded,
        'ownerKeepConfirmed': history.ownerKeepConfirmed,
        'rollbackRequested': history.rollbackRequested,
        'rollbackCompleted': history.rollbackCompleted,
        'createdAt': history.createdAt.toIso8601String(),
        'deployedAt': history.deployedAt?.toIso8601String(),
        'decidedAt': history.decidedAt?.toIso8601String(),
      },
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

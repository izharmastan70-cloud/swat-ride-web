import '../models/admin_intelligence_execution_boundary_result.dart';
import '../models/admin_intelligence_execution_handoff.dart';
import '../models/admin_intelligence_security_authorization.dart';
import '../models/agent_action_definition.dart';
import '../models/agent_approval_request.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_role.dart';
import 'admin_intelligence_security_handoff_connector.dart';
import 'agent_action_registry.dart';
import 'agent_approval_service.dart';
import 'agent_audit_service.dart';

abstract interface class AdminIntelligenceExecutionBoundary {
  Future<AdminIntelligenceExecutionBoundaryResult> prepare({
    required DateTime now,
    required AgentMasterSettings settings,
    required AgentRole role,
    required String actionId,
    required String actorId,
    required AdminIntelligenceExecutionHandoff handoff,
    String? approvalId,
  });
}

/// Phase 38-H2C execution boundary.
///
/// This is the last mutation-capable preparation layer before any future
/// real provider execution.
///
/// Intended mutations in this layer are ONLY:
/// 1) exact one-time approval consumption through existing Approval Service;
/// 2) append-only audit logging through existing Audit Service.
///
/// It does NOT execute an AI provider.
/// It does NOT write SWAT RIDE business data.
/// It does NOT charge money.
/// It does NOT mutate Admin Intelligence Rs budgets.
class AdminIntelligenceExecutionBoundaryService
  implements AdminIntelligenceExecutionBoundary {
  AdminIntelligenceExecutionBoundaryService({
    AgentApprovalService? approvalService,
    AgentAuditService? auditService,
    AdminIntelligenceSecurityHandoffConnector? securityConnector,
  }) : approvalService = approvalService ?? AgentApprovalService(),
       auditService = auditService ?? AgentAuditService(),
       securityConnector =
           securityConnector ??
           const AdminIntelligenceSecurityHandoffConnector();

  final AgentApprovalService approvalService;
  final AgentAuditService auditService;
  final AdminIntelligenceSecurityHandoffConnector securityConnector;

  @override
  Future<AdminIntelligenceExecutionBoundaryResult> prepare({
    required DateTime now,
    required AgentMasterSettings settings,
    required AgentRole role,
    required String actionId,
    required String actorId,
    required AdminIntelligenceExecutionHandoff handoff,
    String? approvalId,
  }) async {
    final String normalizedActionId = actionId.trim();
    final String normalizedActorId = actorId.trim();

    if (normalizedActionId.isEmpty) {
      throw ArgumentError('Admin Intelligence actionId is required.');
    }

    if (normalizedActorId.isEmpty) {
      throw ArgumentError('Admin Intelligence actorId is required.');
    }

    final AgentActionDefinition? action = AgentActionRegistry.get(
      normalizedActionId,
    );

    if (action == null) {
      return _blockedWithoutAudit(
        role: role,
        actionId: normalizedActionId,
        handoff: handoff,
        reason: 'admin_intelligence_unknown_action_fail_closed',
      );
    }

    // Audit trail is mandatory for this boundary.
    // Fail closed before consuming an approval when logging is disabled.
    if (!settings.auditLoggingEnabled) {
      return _blockedWithoutAudit(
        role: role,
        actionId: normalizedActionId,
        handoff: handoff,
        reason: 'admin_intelligence_audit_logging_disabled_fail_closed',
      );
    }

    AgentApprovalRequest? approvalSnapshot;

    final String normalizedApprovalId = approvalId?.trim() ?? '';

    if (normalizedApprovalId.isNotEmpty) {
      approvalSnapshot = await approvalService.getRequest(normalizedApprovalId);
    }

    // Fresh re-evaluation immediately before any approval consumption.
    final AdminIntelligenceSecurityAuthorization authorization =
        securityConnector.evaluate(
          now: now,
          settings: settings,
          role: role,
          actionId: normalizedActionId,
          handoff: handoff,
          approvalSnapshot: approvalSnapshot,
        );

    if (authorization.denied) {
      await _appendBoundaryAudit(
        actorId: normalizedActorId,
        role: role,
        action: action,
        handoff: handoff,
        result: 'BLOCKED',
        reason: authorization.reason,
        approvalId: normalizedApprovalId,
        authorization: authorization,
      );

      return AdminIntelligenceExecutionBoundaryResult(
        status: AdminIntelligenceExecutionBoundaryStatus.blocked,
        authorization: authorization,
        auditRecorded: true,
        providerExecutionPerformed: false,
        businessDataWritePerformed: false,
        costCharged: false,
        budgetMutated: false,
        reason: authorization.reason,
        approvalId: normalizedApprovalId.isEmpty ? null : normalizedApprovalId,
      );
    }

    if (authorization.waitingForApproval) {
      await _appendBoundaryAudit(
        actorId: normalizedActorId,
        role: role,
        action: action,
        handoff: handoff,
        result: 'WAITING_APPROVAL',
        reason: authorization.reason,
        approvalId: normalizedApprovalId,
        authorization: authorization,
      );

      return AdminIntelligenceExecutionBoundaryResult(
        status: AdminIntelligenceExecutionBoundaryStatus.waitingApproval,
        authorization: authorization,
        auditRecorded: true,
        providerExecutionPerformed: false,
        businessDataWritePerformed: false,
        costCharged: false,
        budgetMutated: false,
        reason: authorization.reason,
        approvalId: normalizedApprovalId.isEmpty ? null : normalizedApprovalId,
      );
    }

    if (authorization.readyForApprovalConsumption) {
      if (approvalSnapshot == null || normalizedApprovalId.isEmpty) {
        throw StateError(
          'Approval consumption was required but no fresh approval snapshot was available.',
        );
      }

      final AgentApprovalRequest consumed = await approvalService
          .consumeApprovedRequest(
            approvalId: normalizedApprovalId,
            expectedRoleId: role.roleId,
            expectedActionId: normalizedActionId,
            expectedModule: action.module,
            expectedActionScope: authorization.approvalScope,
          );

      // If this append fails after approval consumption, this method throws
      // and MUST NOT permit provider execution. A fresh approval will then be
      // required before a later attempt.
      await _appendBoundaryAudit(
        actorId: normalizedActorId,
        role: role,
        action: action,
        handoff: handoff,
        result: 'APPROVAL_CONSUMED_READY',
        reason:
            'Exact approval consumed; handoff prepared. Provider not executed.',
        approvalId: consumed.approvalId,
        authorization: authorization,
      );

      return AdminIntelligenceExecutionBoundaryResult(
        status: AdminIntelligenceExecutionBoundaryStatus.approvalConsumedReady,
        authorization: authorization,
        auditRecorded: true,
        providerExecutionPerformed: false,
        businessDataWritePerformed: false,
        costCharged: false,
        budgetMutated: false,
        reason: 'admin_intelligence_approval_consumed_boundary_ready',
        approvalId: consumed.approvalId,
      );
    }

    if (authorization.readyWithoutApprovalConsumption) {
      await _appendBoundaryAudit(
        actorId: normalizedActorId,
        role: role,
        action: action,
        handoff: handoff,
        result: 'READY_NO_APPROVAL',
        reason:
            'Permission/runtime gates allow preparation without approval consumption. Provider not executed.',
        approvalId: '',
        authorization: authorization,
      );

      return AdminIntelligenceExecutionBoundaryResult(
        status: AdminIntelligenceExecutionBoundaryStatus.readyNoApproval,
        authorization: authorization,
        auditRecorded: true,
        providerExecutionPerformed: false,
        businessDataWritePerformed: false,
        costCharged: false,
        budgetMutated: false,
        reason: 'admin_intelligence_boundary_ready_without_approval',
      );
    }

    await _appendBoundaryAudit(
      actorId: normalizedActorId,
      role: role,
      action: action,
      handoff: handoff,
      result: 'BLOCKED',
      reason: 'Unexpected authorization state; fail closed.',
      approvalId: normalizedApprovalId,
      authorization: authorization,
    );

    return AdminIntelligenceExecutionBoundaryResult(
      status: AdminIntelligenceExecutionBoundaryStatus.blocked,
      authorization: authorization,
      auditRecorded: true,
      providerExecutionPerformed: false,
      businessDataWritePerformed: false,
      costCharged: false,
      budgetMutated: false,
      reason: 'admin_intelligence_unexpected_boundary_state_fail_closed',
      approvalId: normalizedApprovalId.isEmpty ? null : normalizedApprovalId,
    );
  }

  Future<void> _appendBoundaryAudit({
    required String actorId,
    required AgentRole role,
    required AgentActionDefinition action,
    required AdminIntelligenceExecutionHandoff handoff,
    required String result,
    required String reason,
    required String approvalId,
    required AdminIntelligenceSecurityAuthorization authorization,
  }) async {
    await auditService.recordSystemEvent(
      module: action.module,
      actionId: action.actionId,
      result: result,
      reason: reason,
      metadata: <String, dynamic>{
        'requestedActorId': actorId,
        'roleId': role.roleId,
        'handoffId': handoff.handoffId,
        'taskId': handoff.taskId,
        'providerId': handoff.providerId,
        'routingLane': handoff.routingLane,
        'requiredCapability': handoff.requiredCapability,
        'estimatedCostRs': handoff.estimatedCostRs,
        'paidReasoning': handoff.paidReasoning,
        'approvalId': approvalId,
        'permissionResult': authorization.permissionDecision.result,
        'runtimeResult': authorization.runtimeDecision.result,
        'approvalRequired': authorization.approvalRequired,
        'approvalSnapshotValid': authorization.approvalSnapshotValid,
        'approvalConsumptionRequired':
            authorization.approvalConsumptionRequired,
        'providerExecutionPerformed': false,
        'businessDataWritePerformed': false,
        'costCharged': false,
        'budgetMutated': false,
        'handoffExpiresAt': handoff.expiresAt.toIso8601String(),
        'projectContext': handoff.projectContext?.toAuthorizationScope(),
      },
    );
  }

  AdminIntelligenceExecutionBoundaryResult _blockedWithoutAudit({
    required AgentRole role,
    required String actionId,
    required AdminIntelligenceExecutionHandoff handoff,
    required String reason,
  }) {
    final authorization = securityConnector.evaluate(
      now: handoff.expiresAt,
      settings: AgentMasterSettings.safeDefaults(),
      role: role,
      actionId: actionId,
      handoff: handoff,
    );

    return AdminIntelligenceExecutionBoundaryResult(
      status: AdminIntelligenceExecutionBoundaryStatus.blocked,
      authorization: authorization,
      auditRecorded: false,
      providerExecutionPerformed: false,
      businessDataWritePerformed: false,
      costCharged: false,
      budgetMutated: false,
      reason: reason,
    );
  }
}

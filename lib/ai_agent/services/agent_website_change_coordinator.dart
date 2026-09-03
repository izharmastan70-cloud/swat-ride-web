import '../constants/agent_action_ids.dart';
import '../models/agent_approval_request.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import '../models/agent_website_change_request.dart';
import 'agent_approval_service.dart';
import 'agent_audit_recorder.dart';
import 'agent_permission_engine.dart';
import 'agent_runtime_gate.dart';
import 'agent_website_change_policy.dart';

/// Phase 34 controlled website orchestration boundary.
///
/// This coordinator:
/// - validates website proposal scope;
/// - evaluates Permission Engine;
/// - applies Runtime Gate;
/// - records permission/audit events;
/// - creates Owner approval requests when required.
///
/// It deliberately does NOT:
/// - write website files;
/// - run shell commands;
/// - call GitHub;
/// - call Vercel;
/// - access Vercel/GitHub tokens;
/// - mutate DNS/domain settings;
/// - deploy production code.
class AgentWebsiteChangeCoordinator {
  final AgentPermissionEngine permissionEngine;
  final AgentRuntimeGate runtimeGate;
  final AgentApprovalService approvalService;
  final AgentAuditRecorder auditRecorder;
  final AgentWebsiteChangePolicy policy;

  const AgentWebsiteChangeCoordinator({
    required this.permissionEngine,
    required this.runtimeGate,
    required this.approvalService,
    required this.auditRecorder,
    this.policy = const AgentWebsiteChangePolicy(),
  });

  Future<AgentWebsiteChangeCoordinationResult> requestChangeApproval({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentWebsiteChangeRequest request,
    required String actorId,
  }) async {
    request.validate();

    final policyDecision = policy.evaluate(request);

    if (!policyDecision.allowed) {
      return AgentWebsiteChangeCoordinationResult.denied(policyDecision.reason);
    }

    const actionId = AgentActionId.proposeWebsiteChange;

    final initialDecision = permissionEngine.evaluate(
      role: role,
      actionId: actionId,
    );

    final runtimeDecision = runtimeGate.apply(
      settings: settings,
      role: role,
      permissionDecision: initialDecision,
    );

    await auditRecorder.permissionDecision(
      role: role,
      decision: runtimeDecision,
      actorId: actorId,
    );

    if (runtimeDecision.isDenied) {
      return AgentWebsiteChangeCoordinationResult.denied(
        runtimeDecision.reason,
      );
    }

    final scope = <String, dynamic>{
      'changeId': request.changeId,
      'websiteFilePaths': policyDecision.normalizedApprovedPaths,
      'summary': request.summary,
      'productionDeploymentRequested': request.productionDeploymentRequested,
      'websiteSourceMutationAuthorized': false,
      'productionDeploymentAuthorized': false,
      'domainMutationAuthorized': false,
      'dnsMutationAuthorized': false,
      'secretAccessAuthorized': false,
    };

    if (!runtimeDecision.needsApproval) {
      // Website changes remain approval-first even if a role/mode
      // configuration would otherwise permit a non-approval decision.
      return const AgentWebsiteChangeCoordinationResult.denied(
        'Website change proposal must receive explicit Owner approval.',
      );
    }

    final approval = await approvalService.createRequest(
      roleId: role.roleId,
      actionId: actionId,
      module: 'website',
      reason: request.reason,
      risk: 'HIGH',
      actionScope: scope,
      requestedBy: actorId,
    );

    await auditRecorder.approvalRequested(request: approval, actorId: actorId);

    return AgentWebsiteChangeCoordinationResult.approvalRequired(
      approval,
      runtimeDecision,
    );
  }

  /// Consume an already-approved proposal only when every
  /// website scope field still matches exactly.
  ///
  /// Even successful consumption does not authorize file writes
  /// or production deployment.
  Future<AgentApprovalRequest> consumeApprovedChangeProposal({
    required String approvalId,
    required AgentRole role,
    required AgentWebsiteChangeRequest request,
    required String actorId,
  }) async {
    request.validate();

    final policyDecision = policy.evaluate(request);

    if (!policyDecision.allowed) {
      throw StateError(policyDecision.reason);
    }

    final expectedScope = <String, dynamic>{
      'changeId': request.changeId,
      'websiteFilePaths': policyDecision.normalizedApprovedPaths,
      'summary': request.summary,
      'productionDeploymentRequested': request.productionDeploymentRequested,
      'websiteSourceMutationAuthorized': false,
      'productionDeploymentAuthorized': false,
      'domainMutationAuthorized': false,
      'dnsMutationAuthorized': false,
      'secretAccessAuthorized': false,
    };

    return approvalService.consumeApprovedRequest(
      approvalId: approvalId,
      expectedRoleId: role.roleId,
      expectedActionId: AgentActionId.proposeWebsiteChange,
      expectedModule: 'website',
      expectedActionScope: expectedScope,
    );
  }
}

class AgentWebsiteChangeCoordinationResult {
  final bool allowed;
  final bool approvalRequired;
  final String reason;
  final AgentApprovalRequest? approval;
  final AgentPermissionDecision? decision;

  const AgentWebsiteChangeCoordinationResult._({
    required this.allowed,
    required this.approvalRequired,
    required this.reason,
    required this.approval,
    required this.decision,
  });

  const AgentWebsiteChangeCoordinationResult.denied(String reason)
    : this._(
        allowed: false,
        approvalRequired: false,
        reason: reason,
        approval: null,
        decision: null,
      );

  factory AgentWebsiteChangeCoordinationResult.approvalRequired(
    AgentApprovalRequest approval,
    AgentPermissionDecision decision,
  ) {
    return AgentWebsiteChangeCoordinationResult._(
      allowed: false,
      approvalRequired: true,
      reason:
          'Explicit Owner approval is required before any website change can advance.',
      approval: approval,
      decision: decision,
    );
  }
}

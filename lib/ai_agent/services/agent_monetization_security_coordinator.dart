import '../constants/agent_action_ids.dart';
import '../models/agent_approval_request.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_monetization_assessment.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import 'agent_action_registry.dart';
import 'agent_approval_service.dart';
import 'agent_audit_recorder.dart';
import 'agent_permission_engine.dart';
import 'agent_runtime_gate.dart';

/// Security boundary between Phase 33 Monetization Intelligence
/// and the existing Permission / Runtime / Approval / Audit stack.
///
/// This coordinator authorizes a NON-EXECUTING monetization proposal only.
///
/// It does NOT:
/// - change commission;
/// - change pricing;
/// - change promo/reward values;
/// - credit/debit wallets;
/// - execute refunds;
/// - approve withdrawals;
/// - execute settlements;
/// - change sponsored/featured status;
/// - call any SWAT RIDE business mutation service.
///
/// Financial/business execution requires a separate explicitly approved
/// business action and is intentionally outside this Phase 33 coordinator.
class AgentMonetizationSecurityCoordinator {
  final AgentPermissionEngine permissionEngine;
  final AgentRuntimeGate runtimeGate;
  final AgentApprovalService approvalService;
  final AgentAuditRecorder auditRecorder;

  const AgentMonetizationSecurityCoordinator({
    this.permissionEngine = const AgentPermissionEngine(),
    this.runtimeGate = const AgentRuntimeGate(),
    required this.approvalService,
    required this.auditRecorder,
  });

  /// Requests authorization to surface a monetization proposal.
  ///
  /// Monetization review requirements can only make the generic
  /// Permission Engine decision STRICTER, never weaker.
  Future<AgentMonetizationAuthorizationResult> requestProposalAuthorization({
    required AgentMonetizationAssessment assessment,
    required AgentMasterSettings settings,
    required AgentRole role,
    required String actorId,
    required String requestedBy,
    Duration approvalValidity = const Duration(minutes: 15),
  }) async {
    assessment.validate();

    final action = AgentActionRegistry.get(AgentActionId.createSuggestion);

    if (action == null) {
      throw const AgentMonetizationSecurityException(
        'core.create_suggestion is missing from AgentActionRegistry.',
      );
    }

    AgentPermissionDecision decision = permissionEngine.evaluate(
      role: role,
      actionId: AgentActionId.createSuggestion,
    );

    decision = _applyMonetizationReviewRequirement(
      decision: decision,
      assessment: assessment,
      role: role,
    );

    decision = runtimeGate.apply(
      settings: settings,
      role: role,
      permissionDecision: decision,
    );

    await auditRecorder.permissionDecision(
      role: role,
      decision: decision,
      actorId: actorId,
    );

    if (decision.isDenied) {
      return AgentMonetizationAuthorizationResult(
        decision: decision,
        approvalRequest: null,
      );
    }

    if (decision.isAllowed) {
      return AgentMonetizationAuthorizationResult(
        decision: decision,
        approvalRequest: null,
      );
    }

    if (!decision.needsApproval) {
      throw const AgentMonetizationSecurityException(
        'Unexpected permission result for monetization proposal.',
      );
    }

    final scope = _buildApprovalScope(assessment);

    final approvalRequest = await approvalService.createRequest(
      roleId: role.roleId,
      actionId: AgentActionId.createSuggestion,
      module: action.module,
      reason: decision.reason,
      risk: assessment.riskLevel,
      requestedBy: requestedBy,
      actionScope: scope,
      validity: approvalValidity,
    );

    await auditRecorder.approvalRequested(
      request: approvalRequest,
      actorId: actorId,
    );

    return AgentMonetizationAuthorizationResult(
      decision: decision,
      approvalRequest: approvalRequest,
    );
  }

  /// Consumes an already-approved monetization proposal authorization.
  ///
  /// Important:
  /// Permission + Runtime Gate are re-evaluated immediately before
  /// consumption. Therefore an old approval cannot override a later
  /// Emergency Stop, disabled AI master switch, disabled provider,
  /// disabled Approval Engine, role change, or permission change.
  ///
  /// This method still does NOT execute a financial/business mutation.
  Future<AgentApprovalRequest> consumeApprovedProposal({
    required String approvalId,
    required AgentMonetizationAssessment assessment,
    required AgentMasterSettings settings,
    required AgentRole role,
    required String actorId,
  }) async {
    assessment.validate();

    final action = AgentActionRegistry.get(AgentActionId.createSuggestion);

    if (action == null) {
      throw const AgentMonetizationSecurityException(
        'core.create_suggestion is missing from AgentActionRegistry.',
      );
    }

    AgentPermissionDecision decision = permissionEngine.evaluate(
      role: role,
      actionId: AgentActionId.createSuggestion,
    );

    decision = _applyMonetizationReviewRequirement(
      decision: decision,
      assessment: assessment,
      role: role,
    );

    decision = runtimeGate.apply(
      settings: settings,
      role: role,
      permissionDecision: decision,
    );

    await auditRecorder.permissionDecision(
      role: role,
      decision: decision,
      actorId: actorId,
    );

    if (decision.isDenied) {
      throw AgentMonetizationSecurityException(
        'Current runtime/permission state denied approval consumption: '
        '${decision.reason}',
      );
    }

    if (!decision.needsApproval) {
      throw const AgentMonetizationSecurityException(
        'Monetization proposal no longer has an approval-required decision. '
        'Fail closed instead of consuming a stale approval.',
      );
    }

    final scope = _buildApprovalScope(assessment);

    final consumed = await approvalService.consumeApprovedRequest(
      approvalId: approvalId,
      expectedRoleId: role.roleId,
      expectedActionId: AgentActionId.createSuggestion,
      expectedModule: action.module,
      expectedActionScope: scope,
    );

    await auditRecorder.auditService.recordSystemEvent(
      reason:
          'Monetization proposal approval consumed after exact-scope '
          'permission/runtime revalidation.',
      module: 'monetization',
      actionId: AgentActionId.createSuggestion,
      result: 'CONSUMED',
      metadata: <String, dynamic>{
        'approvalId': consumed.approvalId,
        'roleId': role.roleId,
        'sourceModule': assessment.module,
        'requiresAdminReview': assessment.requiresAdminReview,
        'requiresSuperAdminReview': assessment.requiresSuperAdminReview,
        'financialWriteRequested': assessment.financialWriteRequested,
      },
    );

    return consumed;
  }

  AgentPermissionDecision _applyMonetizationReviewRequirement({
    required AgentPermissionDecision decision,
    required AgentMonetizationAssessment assessment,
    required AgentRole role,
  }) {
    if (decision.isDenied) {
      return decision;
    }

    if (!assessment.requiresAdminReview &&
        !assessment.requiresSuperAdminReview &&
        !assessment.financialWriteRequested) {
      return decision;
    }

    if (decision.needsApproval) {
      return decision;
    }

    return AgentPermissionDecision.requireApproval(
      roleId: role.roleId,
      actionId: decision.actionId,
      reason: assessment.requiresSuperAdminReview
          ? 'Monetization proposal requires Super Admin review.'
          : assessment.financialWriteRequested
          ? 'Financial monetization proposal requires human review.'
          : 'Monetization proposal requires Admin review.',
      effectiveMode: role.mode,
    );
  }

  /// Exact approval scope.
  ///
  /// Free-form recommendation/summary text is deliberately excluded
  /// to reduce sensitive or unnecessary data in approval documents.
  Map<String, dynamic> _buildApprovalScope(
    AgentMonetizationAssessment assessment,
  ) {
    return <String, dynamic>{
      'phase': 33,
      'purpose': 'monetization_proposal',
      'sourceModule': assessment.module,
      'subject': assessment.subject,
      'riskLevel': assessment.riskLevel,
      'currentValue': assessment.currentValue,
      'proposedValue': assessment.proposedValue,
      'requiresAdminReview': assessment.requiresAdminReview,
      'requiresSuperAdminReview': assessment.requiresSuperAdminReview,
      'financialWriteRequested': assessment.financialWriteRequested,

      // Explicitly proves this approval is for a proposal,
      // not the underlying business mutation.
      'businessMutationAuthorized': false,
    };
  }
}

class AgentMonetizationAuthorizationResult {
  final AgentPermissionDecision decision;
  final AgentApprovalRequest? approvalRequest;

  const AgentMonetizationAuthorizationResult({
    required this.decision,
    required this.approvalRequest,
  });

  bool get isDenied => decision.isDenied;

  bool get canSurfaceImmediately =>
      decision.isAllowed && approvalRequest == null;

  bool get isWaitingForApproval =>
      decision.needsApproval && approvalRequest != null;
}

class AgentMonetizationSecurityException implements Exception {
  final String message;

  const AgentMonetizationSecurityException(this.message);

  @override
  String toString() => 'AgentMonetizationSecurityException: $message';
}

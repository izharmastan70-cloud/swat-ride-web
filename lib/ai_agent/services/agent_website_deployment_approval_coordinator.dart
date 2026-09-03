import '../constants/agent_action_ids.dart';
import '../models/agent_approval_request.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_permission_decision.dart';
import '../models/agent_role.dart';
import '../models/agent_website_preview.dart';
import 'agent_action_registry.dart';
import 'agent_approval_service.dart';
import 'agent_audit_recorder.dart';
import 'agent_permission_engine.dart';
import 'agent_runtime_gate.dart';

/// Phase 34 Step 3C.
///
/// Enforces a two-stage website release boundary:
///
/// 1. Preview Review approval
/// 2. Separate Production Deployment approval
///
/// A preview approval can never be reused as production approval.
///
/// This coordinator contains NO:
/// - filesystem write;
/// - shell/process runner;
/// - Git push;
/// - Vercel API call;
/// - Vercel/GitHub secret;
/// - DNS/domain mutation;
/// - production deployment implementation.
class AgentWebsiteDeploymentApprovalCoordinator {
  final AgentPermissionEngine permissionEngine;
  final AgentRuntimeGate runtimeGate;
  final AgentApprovalService approvalService;
  final AgentAuditRecorder auditRecorder;

  const AgentWebsiteDeploymentApprovalCoordinator({
    required this.permissionEngine,
    required this.runtimeGate,
    required this.approvalService,
    required this.auditRecorder,
  });

  /// Requests Owner review of an already prepared preview.
  ///
  /// Preview must have passed build/lint and any available tests.
  Future<AgentWebsiteReleaseApprovalResult> requestPreviewReviewApproval({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentWebsitePreview preview,
    required String actorId,
    required String requestedBy,
    Duration approvalValidity = const Duration(minutes: 15),
  }) async {
    preview.validate();

    if (!preview.isReviewReady) {
      return const AgentWebsiteReleaseApprovalResult.denied(
        'Preview is not review-ready. Build/lint/tests must pass first.',
      );
    }

    const actionId = AgentActionId.requestWebsitePreview;

    final decision = await _evaluateApprovalRequiredAction(
      settings: settings,
      role: role,
      actionId: actionId,
      actorId: actorId,
    );

    if (decision.isDenied) {
      return AgentWebsiteReleaseApprovalResult.denied(decision.reason);
    }

    if (!decision.needsApproval) {
      return const AgentWebsiteReleaseApprovalResult.denied(
        'Website preview review must receive explicit Owner approval.',
      );
    }

    final action = AgentActionRegistry.get(actionId);

    if (action == null) {
      return const AgentWebsiteReleaseApprovalResult.denied(
        'Website preview action is missing from AgentActionRegistry.',
      );
    }

    final scope = _buildPreviewReviewScope(preview);

    final approval = await approvalService.createRequest(
      roleId: role.roleId,
      actionId: actionId,
      module: action.module,
      reason:
          'Owner must review the exact website preview before production approval can be requested.',
      risk: action.risk,
      requestedBy: requestedBy,
      actionScope: scope,
      validity: approvalValidity,
    );

    await auditRecorder.approvalRequested(request: approval, actorId: actorId);

    return AgentWebsiteReleaseApprovalResult.approvalRequired(
      approval: approval,
      decision: decision,
      stage: AgentWebsiteReleaseStage.previewReview,
    );
  }

  /// Consumes the Preview Review approval once.
  ///
  /// Permission + Runtime Gate are re-evaluated immediately before
  /// consumption so an old approval cannot bypass Emergency Stop,
  /// Master OFF, role changes, or permission changes.
  Future<AgentApprovalRequest> consumeApprovedPreviewReview({
    required String approvalId,
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentWebsitePreview preview,
    required String actorId,
  }) async {
    preview.validate();

    if (!preview.isReviewReady) {
      throw const AgentWebsiteReleaseApprovalException(
        'Preview is not review-ready.',
      );
    }

    const actionId = AgentActionId.requestWebsitePreview;

    final decision = await _evaluateApprovalRequiredAction(
      settings: settings,
      role: role,
      actionId: actionId,
      actorId: actorId,
    );

    if (decision.isDenied) {
      throw AgentWebsiteReleaseApprovalException(
        'Current runtime/permission state denied preview approval consumption: '
        '${decision.reason}',
      );
    }

    if (!decision.needsApproval) {
      throw const AgentWebsiteReleaseApprovalException(
        'Preview action no longer has an approval-required decision. '
        'Fail closed instead of consuming a stale approval.',
      );
    }

    return approvalService.consumeApprovedRequest(
      approvalId: approvalId,
      expectedRoleId: role.roleId,
      expectedActionId: actionId,
      expectedModule: 'website',
      expectedActionScope: _buildPreviewReviewScope(preview),
    );
  }

  /// Requests a NEW production approval.
  ///
  /// A successfully consumed Preview Review approval is mandatory.
  /// That approval is evidence of review only and cannot itself
  /// authorize production.
  Future<AgentWebsiteReleaseApprovalResult>
  requestProductionDeploymentApproval({
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentWebsitePreview preview,
    required AgentApprovalRequest consumedPreviewApproval,
    required String actorId,
    required String requestedBy,
    Duration approvalValidity = const Duration(minutes: 10),
  }) async {
    preview.validate();

    if (!preview.isReviewReady) {
      return const AgentWebsiteReleaseApprovalResult.denied(
        'Production approval cannot be requested for a failed/unready preview.',
      );
    }

    _validateConsumedPreviewApproval(
      role: role,
      preview: preview,
      consumedPreviewApproval: consumedPreviewApproval,
    );

    const actionId = AgentActionId.deployWebsiteProduction;

    final decision = await _evaluateApprovalRequiredAction(
      settings: settings,
      role: role,
      actionId: actionId,
      actorId: actorId,
    );

    if (decision.isDenied) {
      return AgentWebsiteReleaseApprovalResult.denied(decision.reason);
    }

    if (!decision.needsApproval) {
      return const AgentWebsiteReleaseApprovalResult.denied(
        'Production website deployment always requires a separate explicit Owner approval.',
      );
    }

    final action = AgentActionRegistry.get(actionId);

    if (action == null) {
      return const AgentWebsiteReleaseApprovalResult.denied(
        'Production website action is missing from AgentActionRegistry.',
      );
    }

    final scope = _buildProductionScope(
      preview: preview,
      consumedPreviewApproval: consumedPreviewApproval,
    );

    final approval = await approvalService.createRequest(
      roleId: role.roleId,
      actionId: actionId,
      module: action.module,
      reason:
          'Separate final Owner approval is required before production website deployment.',
      risk: action.risk,
      requestedBy: requestedBy,
      actionScope: scope,
      validity: approvalValidity,
    );

    await auditRecorder.approvalRequested(request: approval, actorId: actorId);

    return AgentWebsiteReleaseApprovalResult.approvalRequired(
      approval: approval,
      decision: decision,
      stage: AgentWebsiteReleaseStage.productionDeployment,
    );
  }

  /// Consumes the separate production approval.
  ///
  /// IMPORTANT:
  /// Successful consumption means the approval boundary passed.
  /// It does NOT deploy anything in Step 3C.
  Future<AgentApprovalRequest> consumeApprovedProductionDeployment({
    required String approvalId,
    required AgentMasterSettings settings,
    required AgentRole role,
    required AgentWebsitePreview preview,
    required AgentApprovalRequest consumedPreviewApproval,
    required String actorId,
  }) async {
    preview.validate();

    if (!preview.isReviewReady) {
      throw const AgentWebsiteReleaseApprovalException(
        'Production approval cannot be consumed for an unready preview.',
      );
    }

    _validateConsumedPreviewApproval(
      role: role,
      preview: preview,
      consumedPreviewApproval: consumedPreviewApproval,
    );

    const actionId = AgentActionId.deployWebsiteProduction;

    final decision = await _evaluateApprovalRequiredAction(
      settings: settings,
      role: role,
      actionId: actionId,
      actorId: actorId,
    );

    if (decision.isDenied) {
      throw AgentWebsiteReleaseApprovalException(
        'Current runtime/permission state denied production approval consumption: '
        '${decision.reason}',
      );
    }

    if (!decision.needsApproval) {
      throw const AgentWebsiteReleaseApprovalException(
        'Production action no longer has an approval-required decision. '
        'Fail closed instead of consuming a stale approval.',
      );
    }

    return approvalService.consumeApprovedRequest(
      approvalId: approvalId,
      expectedRoleId: role.roleId,
      expectedActionId: actionId,
      expectedModule: 'website',
      expectedActionScope: _buildProductionScope(
        preview: preview,
        consumedPreviewApproval: consumedPreviewApproval,
      ),
    );
  }

  Future<AgentPermissionDecision> _evaluateApprovalRequiredAction({
    required AgentMasterSettings settings,
    required AgentRole role,
    required String actionId,
    required String actorId,
  }) async {
    final initial = permissionEngine.evaluate(role: role, actionId: actionId);

    final runtime = runtimeGate.apply(
      settings: settings,
      role: role,
      permissionDecision: initial,
    );

    await auditRecorder.permissionDecision(
      role: role,
      decision: runtime,
      actorId: actorId,
    );

    return runtime;
  }

  Map<String, dynamic> _buildPreviewReviewScope(AgentWebsitePreview preview) {
    return <String, dynamic>{
      'stage': AgentWebsiteReleaseStage.previewReview,
      'changeId': preview.changeId,

      // This is the prior website-change proposal approval identity
      // captured by the preview model.
      'changeProposalApprovalId': preview.approvalId,

      'previewUrl': preview.previewUri.toString(),

      'websiteFilePaths': List<String>.from(preview.approvedFilePaths),

      'buildPassed': preview.buildPassed,

      'lintPassed': preview.lintPassed,

      'testsAvailable': preview.testsAvailable,

      'testsPassed': preview.testsPassed,

      'productionDeploymentAuthorized': false,

      'domainMutationAuthorized': false,

      'dnsMutationAuthorized': false,

      'secretAccessAuthorized': false,
    };
  }

  Map<String, dynamic> _buildProductionScope({
    required AgentWebsitePreview preview,
    required AgentApprovalRequest consumedPreviewApproval,
  }) {
    return <String, dynamic>{
      'stage': AgentWebsiteReleaseStage.productionDeployment,

      'changeId': preview.changeId,

      'changeProposalApprovalId': preview.approvalId,

      // Separate preview review approval is chained into the
      // production approval scope.
      'consumedPreviewReviewApprovalId': consumedPreviewApproval.approvalId,

      'previewUrl': preview.previewUri.toString(),

      'websiteFilePaths': List<String>.from(preview.approvedFilePaths),

      'buildPassed': preview.buildPassed,

      'lintPassed': preview.lintPassed,

      'testsAvailable': preview.testsAvailable,

      'testsPassed': preview.testsPassed,

      // Approval boundary only.
      // No deployment adapter exists in Step 3C.
      'productionExecutionAdapterConnected': false,

      'domainMutationAuthorized': false,

      'dnsMutationAuthorized': false,

      'secretAccessAuthorized': false,
    };
  }

  void _validateConsumedPreviewApproval({
    required AgentRole role,
    required AgentWebsitePreview preview,
    required AgentApprovalRequest consumedPreviewApproval,
  }) {
    if (!consumedPreviewApproval.isConsumed) {
      throw const AgentWebsiteReleaseApprovalException(
        'Preview Review approval must already be consumed before production approval can be requested.',
      );
    }

    if (consumedPreviewApproval.roleId != role.roleId) {
      throw const AgentWebsiteReleaseApprovalException(
        'Consumed Preview Review approval belongs to another role.',
      );
    }

    if (consumedPreviewApproval.actionId !=
        AgentActionId.requestWebsitePreview) {
      throw const AgentWebsiteReleaseApprovalException(
        'Consumed approval is not a Preview Review approval.',
      );
    }

    if (consumedPreviewApproval.module != 'website') {
      throw const AgentWebsiteReleaseApprovalException(
        'Consumed Preview Review approval is outside website module.',
      );
    }

    final expected = _buildPreviewReviewScope(preview);

    if (!_deepMapEquals(consumedPreviewApproval.actionScope, expected)) {
      throw const AgentWebsiteReleaseApprovalException(
        'Consumed Preview Review approval scope does not exactly match the current preview. '
        'A new Preview Review approval is required.',
      );
    }
  }

  static bool _deepMapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) {
      return false;
    }

    for (final key in a.keys) {
      if (!b.containsKey(key)) {
        return false;
      }

      if (!_deepEquals(a[key], b[key])) {
        return false;
      }
    }

    return true;
  }

  static bool _deepEquals(dynamic a, dynamic b) {
    if (a is Map && b is Map) {
      final mapA = a.map<String, dynamic>(
        (key, value) => MapEntry<String, dynamic>(key.toString(), value),
      );

      final mapB = b.map<String, dynamic>(
        (key, value) => MapEntry<String, dynamic>(key.toString(), value),
      );

      return _deepMapEquals(mapA, mapB);
    }

    if (a is Iterable && b is Iterable) {
      final listA = a.toList(growable: false);

      final listB = b.toList(growable: false);

      if (listA.length != listB.length) {
        return false;
      }

      for (var i = 0; i < listA.length; i++) {
        if (!_deepEquals(listA[i], listB[i])) {
          return false;
        }
      }

      return true;
    }

    return a == b;
  }
}

class AgentWebsiteReleaseStage {
  AgentWebsiteReleaseStage._();

  static const String previewReview = 'PREVIEW_REVIEW';

  static const String productionDeployment = 'PRODUCTION_DEPLOYMENT';
}

class AgentWebsiteReleaseApprovalResult {
  final bool allowed;
  final bool approvalRequired;
  final String reason;
  final String? stage;
  final AgentApprovalRequest? approval;
  final AgentPermissionDecision? decision;

  const AgentWebsiteReleaseApprovalResult._({
    required this.allowed,
    required this.approvalRequired,
    required this.reason,
    required this.stage,
    required this.approval,
    required this.decision,
  });

  const AgentWebsiteReleaseApprovalResult.denied(String reason)
    : this._(
        allowed: false,
        approvalRequired: false,
        reason: reason,
        stage: null,
        approval: null,
        decision: null,
      );

  factory AgentWebsiteReleaseApprovalResult.approvalRequired({
    required AgentApprovalRequest approval,
    required AgentPermissionDecision decision,
    required String stage,
  }) {
    return AgentWebsiteReleaseApprovalResult._(
      allowed: false,
      approvalRequired: true,
      reason:
          'Explicit Owner approval required for website release stage: $stage.',
      stage: stage,
      approval: approval,
      decision: decision,
    );
  }
}

class AgentWebsiteReleaseApprovalException implements Exception {
  final String message;

  const AgentWebsiteReleaseApprovalException(this.message);

  @override
  String toString() => 'AgentWebsiteReleaseApprovalException: $message';
}

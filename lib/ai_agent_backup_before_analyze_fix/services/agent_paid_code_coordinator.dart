import '../constants/agent_action_ids.dart';
import '../constants/agent_paid_code_constants.dart';
import '../models/agent_approval_request.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_paid_code_request.dart';
import '../models/agent_paid_code_response.dart';
import '../models/agent_role.dart';
import 'agent_approval_service.dart';
import 'agent_paid_code_router.dart';
import 'agent_paid_code_scope_guard.dart';

// =========================================================
// AI AGENT — PAID CODE COORDINATOR
// =========================================================
//
// Phase 15 performs analysis/proposal ONLY.
//
// Safety order:
// 1) exact approved action/scope is consumed
// 2) Paid Code AI route is checked
// 3) provider returns diagnosis/patch proposal
// 4) scope guard checks proposed files
// 5) NO source file is written in Phase 15
//
// If provider requests extra files, owner must approve again.

class AgentPaidCodeCoordinator {
  final AgentApprovalService approvalService;
  final AgentPaidCodeRouter router;
  final AgentPaidCodeScopeGuard scopeGuard;

  AgentPaidCodeCoordinator({
    AgentApprovalService? approvalService,
    AgentPaidCodeRouter? router,
    AgentPaidCodeScopeGuard? scopeGuard,
  })  : approvalService = approvalService ?? AgentApprovalService(),
        router = router ?? AgentPaidCodeRouter(),
        scopeGuard = scopeGuard ?? const AgentPaidCodeScopeGuard();

  Future<AgentPaidCodeCoordinatorResult> analyzeApproved({
    required AgentMasterSettings settings,
    required AgentRole codeRole,
    required String approvalId,
    required String requestedBy,
    required String requestType,
    required String problemSummary,
    required String errorLog,
    required Map<String, dynamic> sourceContext,
    required List<String> approvedFilePaths,
  }) async {
    final String actionId =
        requestType == AgentPaidCodeRequestType.prepareFix
            ? AgentActionId.prepareCodeFix
            : AgentActionId.analyzeCodeError;

    final Map<String, dynamic> exactScope = <String, dynamic>{
      'requestType': requestType,
      'problemSummary': problemSummary,
      'approvedFilePaths': List<String>.from(approvedFilePaths),
    };

    final AgentApprovalRequest consumed =
        await approvalService.consumeApprovedRequest(
      approvalId: approvalId,
      expectedRoleId: codeRole.roleId,
      expectedActionId: actionId,
      expectedModule: 'code',
      expectedActionScope: exactScope,
    );

    final AgentPaidCodeRequest request = AgentPaidCodeRequest(
      requestId: 'paid_code_${DateTime.now().microsecondsSinceEpoch}',
      roleId: codeRole.roleId,
      requestType: requestType,
      problemSummary: problemSummary,
      errorLog: errorLog,
      sourceContext: Map<String, dynamic>.from(sourceContext),
      approvedFilePaths: List<String>.unmodifiable(approvedFilePaths),
      approvalId: consumed.approvalId,
      createdAt: DateTime.now(),
    );

    final AgentPaidCodeResponse response = await router.route(
      settings: settings,
      codeRole: codeRole,
      request: request,
    );

    if (!response.isSuccess) {
      return AgentPaidCodeCoordinatorResult(
        response: response,
        scopeAllowed: false,
        requiresNewApproval: false,
        scopeMessage: response.message,
      );
    }

    final AgentPaidCodeScopeCheck scope = scopeGuard.checkResponse(
      request: request,
      response: response,
    );

    return AgentPaidCodeCoordinatorResult(
      response: response,
      scopeAllowed: scope.allowed,
      requiresNewApproval: scope.requiresNewApproval,
      scopeMessage: scope.reason,
    );
  }
}

class AgentPaidCodeCoordinatorResult {
  final AgentPaidCodeResponse response;
  final bool scopeAllowed;
  final bool requiresNewApproval;
  final String scopeMessage;

  const AgentPaidCodeCoordinatorResult({
    required this.response,
    required this.scopeAllowed,
    required this.requiresNewApproval,
    required this.scopeMessage,
  });
}

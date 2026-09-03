import '../models/agent_approval_request.dart';
import 'agent_approval_service.dart';

abstract class AgentEmailApprovalGateway {
  Future<AgentApprovalRequest> createRequest({
    required String roleId,
    required String actionId,
    required String module,
    required String reason,
    required String risk,
    required String requestedBy,
    required Map<String, dynamic> actionScope,
    Duration validity = const Duration(minutes: 15),
  });

  Future<AgentApprovalRequest?> getRequest(String approvalId);

  Future<AgentApprovalRequest> consumeApprovedRequest({
    required String approvalId,
    required String expectedRoleId,
    required String expectedActionId,
    required String expectedModule,
    required Map<String, dynamic> expectedActionScope,
  });
}

class CentralAgentEmailApprovalGateway implements AgentEmailApprovalGateway {
  CentralAgentEmailApprovalGateway({AgentApprovalService? approvalService})
    : approvalService = approvalService ?? AgentApprovalService();

  final AgentApprovalService approvalService;

  @override
  Future<AgentApprovalRequest> createRequest({
    required String roleId,
    required String actionId,
    required String module,
    required String reason,
    required String risk,
    required String requestedBy,
    required Map<String, dynamic> actionScope,
    Duration validity = const Duration(minutes: 15),
  }) {
    return approvalService.createRequest(
      roleId: roleId,
      actionId: actionId,
      module: module,
      reason: reason,
      risk: risk,
      requestedBy: requestedBy,
      actionScope: actionScope,
      validity: validity,
    );
  }

  @override
  Future<AgentApprovalRequest?> getRequest(String approvalId) {
    return approvalService.getRequest(approvalId);
  }

  @override
  Future<AgentApprovalRequest> consumeApprovedRequest({
    required String approvalId,
    required String expectedRoleId,
    required String expectedActionId,
    required String expectedModule,
    required Map<String, dynamic> expectedActionScope,
  }) {
    return approvalService.consumeApprovedRequest(
      approvalId: approvalId,
      expectedRoleId: expectedRoleId,
      expectedActionId: expectedActionId,
      expectedModule: expectedModule,
      expectedActionScope: expectedActionScope,
    );
  }
}

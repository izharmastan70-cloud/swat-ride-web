import '../models/agent_approval_request.dart';
import 'agent_approval_service.dart';

abstract interface class AgentSecurityIncidentRoleInventoryMigrationCentralApprovalGateway {
  Stream<List<AgentApprovalRequest>> watchPendingRequests();

  Future<void> approve({required String approvalId, required String decidedBy});

  Future<void> reject({required String approvalId, required String decidedBy});
}

/// Narrow adapter to the existing central Approval Engine.
///
/// Deliberately exposes only:
/// - watch PENDING approvals
/// - APPROVE
/// - REJECT
///
/// It does NOT expose createRequest(), consumeApprovedRequest(), cancellation,
/// Firestore, migration execution, role creation or runtime attachment.
class AgentSecurityIncidentRoleInventoryMigrationCentralApprovalGatewayAdapter
    implements
        AgentSecurityIncidentRoleInventoryMigrationCentralApprovalGateway {
  const AgentSecurityIncidentRoleInventoryMigrationCentralApprovalGatewayAdapter({
    required this.approvalService,
  });

  final AgentApprovalService approvalService;

  @override
  Stream<List<AgentApprovalRequest>> watchPendingRequests() {
    return approvalService.watchPendingRequests();
  }

  @override
  Future<void> approve({
    required String approvalId,
    required String decidedBy,
  }) {
    return approvalService.approve(
      approvalId: approvalId,
      decidedBy: decidedBy,
    );
  }

  @override
  Future<void> reject({required String approvalId, required String decidedBy}) {
    return approvalService.reject(approvalId: approvalId, decidedBy: decidedBy);
  }

  bool get createsCentralApproval => false;
  bool get consumesCentralApproval => false;
  bool get executesMigration => false;
  bool get createsRole => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;
}

import '../models/agent_approval_request.dart';
import 'agent_approval_service.dart';

abstract interface class AgentSecurityIncidentPostMigrationRebindCentralApprovalGateway {
  Stream<List<AgentApprovalRequest>> watchPendingRequests();

  Future<AgentApprovalRequest?> getRequest(String approvalId);

  Future<void> approve({required String approvalId, required String decidedBy});

  Future<void> reject({required String approvalId, required String decidedBy});
}

/// Narrow adapter to the existing central Approval Engine.
///
/// Deliberately exposes only:
/// - PENDING approval watch
/// - exact historical approval read
/// - APPROVE
/// - REJECT
///
/// It does not expose central approval creation/consumption/cancellation,
/// rebind execution, token/receipt creation, role enable or hold release.
class AgentSecurityIncidentPostMigrationRebindCentralApprovalGatewayAdapter
    implements AgentSecurityIncidentPostMigrationRebindCentralApprovalGateway {
  const AgentSecurityIncidentPostMigrationRebindCentralApprovalGatewayAdapter({
    required this.approvalService,
  });

  final AgentApprovalService approvalService;

  @override
  Stream<List<AgentApprovalRequest>> watchPendingRequests() {
    return approvalService.watchPendingRequests();
  }

  @override
  Future<AgentApprovalRequest?> getRequest(String approvalId) {
    return approvalService.getRequest(approvalId);
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
  bool get executesRebind => false;
  bool get createsFreshToken => false;
  bool get createsRebindReceipt => false;
  bool get mutatesAuthorityManifest => false;
  bool get mutatesGuard => false;
  bool get enablesRole => false;
  bool get releasesMigrationHold => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}

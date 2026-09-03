import '../models/agent_approval_request.dart';
import 'agent_approval_service.dart';

abstract interface class AgentSecurityIncidentPostRebindEnableCentralApprovalGateway {
  Stream<List<AgentApprovalRequest>> watchPendingRequests();

  Future<AgentApprovalRequest?> getRequest(String approvalId);

  Future<void> approve({required String approvalId, required String decidedBy});

  Future<void> reject({required String approvalId, required String decidedBy});
}

class AgentSecurityIncidentPostRebindEnableCentralApprovalGatewayAdapter
    implements AgentSecurityIncidentPostRebindEnableCentralApprovalGateway {
  const AgentSecurityIncidentPostRebindEnableCentralApprovalGatewayAdapter({
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
  bool get issuesReplacementToken => false;
  bool get consumesReplacementToken => false;
  bool get enablesRole => false;
  bool get releasesMigrationHold => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get writesIncident => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}

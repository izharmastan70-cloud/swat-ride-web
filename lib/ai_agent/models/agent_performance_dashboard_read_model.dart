import '../constants/agent_performance_dashboard_constants.dart';
import 'agent_performance_dashboard_agent_summary.dart';

class AgentPerformanceDashboardReadModel {
  AgentPerformanceDashboardReadModel({
    required this.status,
    required this.queryId,
    required List<AgentPerformanceDashboardAgentSummary> summaries,
    required this.totalMatchedBeforeLimit,
    required this.truncated,
    required this.reasonCode,
  }) : summaries = List<AgentPerformanceDashboardAgentSummary>.unmodifiable(
         summaries,
       );

  final String status;
  final String queryId;
  final List<AgentPerformanceDashboardAgentSummary> summaries;
  final int totalMatchedBeforeLimit;
  final bool truncated;
  final String reasonCode;

  bool get ready => status == AgentPerformanceDashboardStatus.ready;
  bool get empty => status == AgentPerformanceDashboardStatus.empty;

  bool get readOnlyVisibilityOnly => true;
  bool get sortOrderIsPresentationOnly => true;
  bool get exposesRankNumber => false;
  bool get globalLeaderboardCreated => false;
  bool get permanentRankAssigned => false;
  bool get disciplinaryDecisionMade => false;
  bool get routingDecisionMade => false;
  bool get payDecisionMade => false;
  bool get accessDecisionMade => false;

  bool get grantsPermission => false;
  bool get createsApproval => false;
  bool get authorizesBusinessExecution => false;
  bool get executesBusinessAction => false;
  bool get mutatesAgentState => false;
  bool get mutatesRouting => false;
  bool get mutatesBudget => false;
  bool get persistsReadModel => false;
  bool get securityAuthorityAlwaysAboveDashboard => true;

  void validateStructure() {
    if (!AgentPerformanceDashboardStatus.values.contains(status) ||
        queryId.trim().isEmpty ||
        totalMatchedBeforeLimit < 0 ||
        reasonCode.trim().isEmpty ||
        summaries.length > AgentPerformanceDashboardLimits.maxQueryLimit) {
      throw const FormatException('Invalid dashboard read model.');
    }

    for (final AgentPerformanceDashboardAgentSummary summary in summaries) {
      summary.validateStructure();
    }

    if (ready && summaries.isEmpty) {
      throw const FormatException('READY dashboard cannot be empty.');
    }

    if (empty && summaries.isNotEmpty) {
      throw const FormatException('EMPTY dashboard cannot have summaries.');
    }
  }
}

import '../constants/agent_performance_dashboard_constants.dart';
import '../models/agent_performance_dashboard_agent_summary.dart';
import '../models/agent_performance_dashboard_query.dart';

class AgentPerformanceDashboardFilterSortPolicy {
  const AgentPerformanceDashboardFilterSortPolicy();

  List<AgentPerformanceDashboardAgentSummary> filterAndSort({
    required AgentPerformanceDashboardQuery query,
    required List<AgentPerformanceDashboardAgentSummary> summaries,
  }) {
    final List<AgentPerformanceDashboardAgentSummary> filtered = summaries
        .where((AgentPerformanceDashboardAgentSummary summary) {
          if (query.cohortKey != null && summary.cohortKey != query.cohortKey) {
            return false;
          }

          if (query.windowId != null && summary.windowId != query.windowId) {
            return false;
          }

          if (query.confidence != null &&
              summary.confidence != query.confidence) {
            return false;
          }

          if (query.onlyWithScore && !summary.hasScore) {
            return false;
          }

          if (query.onlyComparisonEligible && !summary.comparisonEligible) {
            return false;
          }

          return true;
        })
        .toList(growable: false);

    final List<AgentPerformanceDashboardAgentSummary> ordered =
        List<AgentPerformanceDashboardAgentSummary>.from(filtered);

    ordered.sort((
      AgentPerformanceDashboardAgentSummary a,
      AgentPerformanceDashboardAgentSummary b,
    ) {
      int comparison;

      switch (query.sortKey) {
        case AgentPerformanceDashboardSortKey.agentId:
          comparison = a.agentId.compareTo(b.agentId);
          break;

        case AgentPerformanceDashboardSortKey.score:
          comparison = a.overallScore!.compareTo(b.overallScore!);
          break;

        default:
          throw const FormatException('Unsupported dashboard sort key.');
      }

      if (query.sortDirection ==
          AgentPerformanceDashboardSortDirection.descending) {
        comparison = -comparison;
      }

      if (comparison != 0) return comparison;
      return a.agentId.compareTo(b.agentId);
    });

    return List<AgentPerformanceDashboardAgentSummary>.unmodifiable(ordered);
  }

  bool get presentationSortOnly => true;
  bool get scoreSortRequiresFairComparisonBoundary => true;
  bool get scoreSortNeverCreatesPermanentRank => true;
  bool get globalLeaderboardImplementedHere => false;
  bool get disciplineImplementedHere => false;
  bool get routingImplementedHere => false;
  bool get payImplementedHere => false;
  bool get accessImplementedHere => false;
  bool get persistenceImplementedHere => false;
}

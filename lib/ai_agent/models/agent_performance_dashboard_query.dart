import '../constants/agent_performance_dashboard_constants.dart';
import '../constants/agent_performance_scoring_constants.dart';

class AgentPerformanceDashboardQuery {
  const AgentPerformanceDashboardQuery({
    required this.queryId,
    required this.cohortKey,
    required this.windowId,
    required this.confidence,
    required this.onlyWithScore,
    required this.onlyComparisonEligible,
    required this.sortKey,
    required this.sortDirection,
    required this.limit,
  });

  final String queryId;
  final String? cohortKey;
  final String? windowId;
  final String? confidence;
  final bool onlyWithScore;
  final bool onlyComparisonEligible;
  final String sortKey;
  final String sortDirection;
  final int limit;

  bool get scoreSortRequested =>
      sortKey == AgentPerformanceDashboardSortKey.score;

  bool get fairScoreSortPreconditionsSatisfied =>
      !scoreSortRequested ||
      (cohortKey != null &&
          windowId != null &&
          confidence == AgentPerformanceScoreConfidence.high &&
          onlyWithScore &&
          onlyComparisonEligible);

  bool get requestsGlobalLeaderboard => false;
  bool get requestsPermanentRank => false;
  bool get requestsDiscipline => false;
  bool get requestsRoutingChange => false;
  bool get requestsPayChange => false;
  bool get requestsAccessChange => false;
  bool get requestsBusinessExecution => false;

  void validateStructure() {
    final String q = queryId.trim();

    if (q.isEmpty ||
        q.length > AgentPerformanceDashboardLimits.opaqueIdMaxLength ||
        !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(q) ||
        !AgentPerformanceDashboardSortKey.values.contains(sortKey) ||
        !AgentPerformanceDashboardSortDirection.values.contains(
          sortDirection,
        ) ||
        limit < 1 ||
        limit > AgentPerformanceDashboardLimits.maxQueryLimit) {
      throw const FormatException('Invalid dashboard query.');
    }

    for (final String? optional in <String?>[cohortKey, windowId]) {
      if (optional == null) continue;
      final String value = optional.trim();

      if (value.isEmpty ||
          value.length > AgentPerformanceDashboardLimits.opaqueIdMaxLength ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(value)) {
        throw const FormatException('Invalid dashboard filter.');
      }
    }

    if (confidence != null &&
        !AgentPerformanceScoreConfidence.values.contains(confidence)) {
      throw const FormatException('Invalid confidence filter.');
    }
  }
}

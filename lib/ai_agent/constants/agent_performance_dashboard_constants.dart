class AgentPerformanceDashboardStatus {
  AgentPerformanceDashboardStatus._();

  static const String ready = 'READY';
  static const String empty = 'EMPTY';
  static const String blockedInvalidInput = 'BLOCKED_INVALID_INPUT';
  static const String blockedDuplicateSummary = 'BLOCKED_DUPLICATE_SUMMARY';
  static const String blockedUnfairScoreSort = 'BLOCKED_UNFAIR_SCORE_SORT';

  static const Set<String> values = <String>{
    ready,
    empty,
    blockedInvalidInput,
    blockedDuplicateSummary,
    blockedUnfairScoreSort,
  };
}

class AgentPerformanceDashboardSortKey {
  AgentPerformanceDashboardSortKey._();

  static const String agentId = 'AGENT_ID';
  static const String score = 'SCORE';

  static const Set<String> values = <String>{agentId, score};
}

class AgentPerformanceDashboardSortDirection {
  AgentPerformanceDashboardSortDirection._();

  static const String ascending = 'ASCENDING';
  static const String descending = 'DESCENDING';

  static const Set<String> values = <String>{ascending, descending};
}

class AgentPerformanceDashboardLimits {
  AgentPerformanceDashboardLimits._();

  static const int opaqueIdMaxLength = 220;
  static const int maxInputSummaries = 500;
  static const int maxQueryLimit = 200;
}

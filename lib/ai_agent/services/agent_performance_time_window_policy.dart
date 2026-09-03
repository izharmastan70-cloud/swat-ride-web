import '../constants/agent_performance_aggregation_constants.dart';
import '../models/agent_performance_metric_time_window.dart';

class AgentPerformanceTimeWindowPolicy {
  const AgentPerformanceTimeWindowPolicy();

  AgentPerformanceMetricTimeWindow buildFixed({
    required String windowId,
    required int endEpochMs,
  }) {
    final int durationMs = _fixedDuration(windowId);

    final AgentPerformanceMetricTimeWindow window =
        AgentPerformanceMetricTimeWindow(
          windowId: windowId,
          startEpochMs: endEpochMs - durationMs,
          endEpochMs: endEpochMs,
        );

    window.validateStructure();
    return window;
  }

  AgentPerformanceMetricTimeWindow buildCustom({
    required int startEpochMs,
    required int endEpochMs,
  }) {
    final AgentPerformanceMetricTimeWindow window =
        AgentPerformanceMetricTimeWindow(
          windowId: AgentPerformanceTimeWindowId.custom,
          startEpochMs: startEpochMs,
          endEpochMs: endEpochMs,
        );

    window.validateStructure();
    return window;
  }

  int _fixedDuration(String windowId) {
    switch (windowId) {
      case AgentPerformanceTimeWindowId.last1Hour:
        return AgentPerformanceAggregationLimits.last1HourMs;
      case AgentPerformanceTimeWindowId.last24Hours:
        return AgentPerformanceAggregationLimits.last24HoursMs;
      case AgentPerformanceTimeWindowId.last7Days:
        return AgentPerformanceAggregationLimits.last7DaysMs;
      case AgentPerformanceTimeWindowId.last30Days:
        return AgentPerformanceAggregationLimits.last30DaysMs;
      case AgentPerformanceTimeWindowId.custom:
        throw const FormatException(
          'CUSTOM must use explicit start/end boundaries.',
        );
    }

    throw const FormatException(
      'Unsupported fixed Agent Performance time window.',
    );
  }

  bool get deterministicCallerSuppliedEpochOnly => true;
  bool get hiddenDateTimeNowUsage => false;
  bool get customWindowBounded => true;
  bool get timeWindowChangesAuthority => false;
  bool get persistenceImplementedHere => false;
}

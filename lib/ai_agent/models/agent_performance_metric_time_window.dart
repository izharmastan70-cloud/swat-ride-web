import '../constants/agent_performance_aggregation_constants.dart';

class AgentPerformanceMetricTimeWindow {
  const AgentPerformanceMetricTimeWindow({
    required this.windowId,
    required this.startEpochMs,
    required this.endEpochMs,
  });

  final String windowId;
  final int startEpochMs;
  final int endEpochMs;

  int get durationMs => endEpochMs - startEpochMs;

  bool containsRange({required int startEpochMs, required int endEpochMs}) {
    return startEpochMs >= this.startEpochMs &&
        endEpochMs <= this.endEpochMs &&
        endEpochMs > startEpochMs;
  }

  bool get callerSuppliedDeterministicTime => true;
  bool get usesHiddenWallClock => false;
  bool get readOnlyWindow => true;

  void validateStructure() {
    if (!AgentPerformanceTimeWindowId.values.contains(windowId) ||
        startEpochMs < 0 ||
        endEpochMs <= startEpochMs) {
      throw const FormatException('Invalid Agent Performance time window.');
    }

    switch (windowId) {
      case AgentPerformanceTimeWindowId.last1Hour:
        if (durationMs != AgentPerformanceAggregationLimits.last1HourMs) {
          throw const FormatException('LAST_1_HOUR duration mismatch.');
        }
        return;

      case AgentPerformanceTimeWindowId.last24Hours:
        if (durationMs != AgentPerformanceAggregationLimits.last24HoursMs) {
          throw const FormatException('LAST_24_HOURS duration mismatch.');
        }
        return;

      case AgentPerformanceTimeWindowId.last7Days:
        if (durationMs != AgentPerformanceAggregationLimits.last7DaysMs) {
          throw const FormatException('LAST_7_DAYS duration mismatch.');
        }
        return;

      case AgentPerformanceTimeWindowId.last30Days:
        if (durationMs != AgentPerformanceAggregationLimits.last30DaysMs) {
          throw const FormatException('LAST_30_DAYS duration mismatch.');
        }
        return;

      case AgentPerformanceTimeWindowId.custom:
        if (durationMs > AgentPerformanceAggregationLimits.maxCustomWindowMs) {
          throw const FormatException('CUSTOM performance window too large.');
        }
        return;
    }

    throw const FormatException('Unsupported Agent Performance time window.');
  }
}

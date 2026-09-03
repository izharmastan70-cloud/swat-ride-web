import '../constants/agent_performance_aggregation_constants.dart';
import '../constants/agent_performance_metric_constants.dart';
import 'agent_performance_metric_observation.dart';
import 'agent_performance_metric_time_window.dart';

class AgentPerformanceMetricAggregationInput {
  AgentPerformanceMetricAggregationInput({
    required this.aggregationId,
    required this.agentId,
    required this.metricId,
    required this.window,
    required List<AgentPerformanceMetricObservation> observations,
  }) : observations = List<AgentPerformanceMetricObservation>.unmodifiable(
         observations,
       );

  final String aggregationId;
  final String agentId;
  final String metricId;
  final AgentPerformanceMetricTimeWindow window;
  final List<AgentPerformanceMetricObservation> observations;

  bool get containsRawPrompt => false;
  bool get containsRawConversation => false;
  bool get containsPrivatePayload => false;
  bool get containsSecret => false;
  bool get containsApprovalToken => false;
  bool get containsPermissionToken => false;

  bool get requestsScoringAuthority => false;
  bool get requestsAgentMutation => false;
  bool get requestsBusinessExecution => false;

  void validateStructure() {
    final List<String> ids = <String>[aggregationId, agentId];

    final bool invalidId = ids.any((String value) {
      final String trimmed = value.trim();

      return trimmed.isEmpty ||
          trimmed.length >
              AgentPerformanceAggregationLimits.opaqueIdMaxLength ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
    });

    if (invalidId ||
        !AgentPerformanceMetricId.values.contains(metricId) ||
        observations.length >
            AgentPerformanceAggregationLimits.maxObservationsPerAggregation) {
      throw const FormatException(
        'Invalid Agent Performance aggregation input.',
      );
    }

    window.validateStructure();

    final Set<String> observationIds = <String>{};

    for (final AgentPerformanceMetricObservation observation in observations) {
      observation.validateStructure();

      if (!observationIds.add(observation.observationId) ||
          observation.agentId != agentId ||
          observation.metricId != metricId ||
          !window.containsRange(
            startEpochMs: observation.windowStartEpochMs,
            endEpochMs: observation.windowEndEpochMs,
          )) {
        throw const FormatException(
          'Invalid Agent Performance aggregation observation.',
        );
      }
    }

    final List<AgentPerformanceMetricObservation> ordered =
        List<AgentPerformanceMetricObservation>.from(observations)..sort(
          (
            AgentPerformanceMetricObservation a,
            AgentPerformanceMetricObservation b,
          ) => a.windowStartEpochMs.compareTo(b.windowStartEpochMs),
        );

    int? previousEnd;

    for (final AgentPerformanceMetricObservation observation in ordered) {
      if (previousEnd != null && observation.windowStartEpochMs < previousEnd) {
        throw const FormatException(
          'Overlapping Agent Performance observations are forbidden.',
        );
      }

      previousEnd = observation.windowEndEpochMs;
    }
  }
}

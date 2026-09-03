import '../constants/agent_performance_scoring_constants.dart';
import 'agent_performance_metric_aggregation_result.dart';

class AgentPerformanceScoreInput {
  AgentPerformanceScoreInput({
    required this.scoreRequestId,
    required this.agentId,
    required this.cohortKey,
    required this.windowId,
    required List<AgentPerformanceMetricAggregationResult> metricResults,
  }) : metricResults =
           List<AgentPerformanceMetricAggregationResult>.unmodifiable(
             metricResults,
           );

  final String scoreRequestId;
  final String agentId;
  final String cohortKey;
  final String windowId;
  final List<AgentPerformanceMetricAggregationResult> metricResults;

  bool get containsRawPrompt => false;
  bool get containsRawConversation => false;
  bool get containsPrivatePayload => false;
  bool get containsSecret => false;
  bool get containsApprovalToken => false;
  bool get containsPermissionToken => false;

  bool get requestsLeaderboard => false;
  bool get requestsDiscipline => false;
  bool get requestsRoutingChange => false;
  bool get requestsPayChange => false;
  bool get requestsAccessChange => false;
  bool get requestsBusinessExecution => false;

  void validateStructure() {
    final List<String> ids = <String>[
      scoreRequestId,
      agentId,
      cohortKey,
      windowId,
    ];

    final bool invalid = ids.any((String value) {
      final String trimmed = value.trim();

      return trimmed.isEmpty ||
          trimmed.length > AgentPerformanceScoringLimits.opaqueIdMaxLength ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed);
    });

    if (invalid || metricResults.length > 32) {
      throw const FormatException('Invalid Agent Performance score input.');
    }

    for (final AgentPerformanceMetricAggregationResult result
        in metricResults) {
      result.validateStructure();

      if (result.agentId != agentId || result.windowId != windowId) {
        throw const FormatException(
          'Mismatched Agent Performance score evidence.',
        );
      }
    }
  }
}

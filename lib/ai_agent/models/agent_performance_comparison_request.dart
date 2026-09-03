import '../constants/agent_performance_scoring_constants.dart';
import 'agent_performance_score_result.dart';

class AgentPerformanceComparisonRequest {
  const AgentPerformanceComparisonRequest({
    required this.comparisonId,
    required this.first,
    required this.second,
  });

  final String comparisonId;
  final AgentPerformanceScoreResult first;
  final AgentPerformanceScoreResult second;

  bool get requestsLeaderboard => false;
  bool get requestsDiscipline => false;
  bool get requestsRoutingChange => false;
  bool get requestsPayChange => false;
  bool get requestsAccessChange => false;
  bool get requestsBusinessExecution => false;

  void validateStructure() {
    final String trimmed = comparisonId.trim();

    if (trimmed.isEmpty ||
        trimmed.length > AgentPerformanceScoringLimits.opaqueIdMaxLength ||
        !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed) ||
        first.agentId == second.agentId) {
      throw const FormatException(
        'Invalid Agent Performance comparison request.',
      );
    }

    first.validateStructure();
    second.validateStructure();
  }
}

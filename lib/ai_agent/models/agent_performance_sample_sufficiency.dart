import '../constants/agent_performance_aggregation_constants.dart';

class AgentPerformanceSampleSufficiency {
  const AgentPerformanceSampleSufficiency({
    required this.level,
    required this.sampleCount,
    required this.minimumRequired,
    required this.strongRequired,
  });

  final String level;
  final int sampleCount;
  final int minimumRequired;
  final int strongRequired;

  bool get sufficientForInterpretation =>
      level == AgentPerformanceSampleSufficiencyLevel.sufficient ||
      level == AgentPerformanceSampleSufficiencyLevel.strong;

  bool get strongEvidence =>
      level == AgentPerformanceSampleSufficiencyLevel.strong;

  bool get mayCreatePerformanceAuthority => false;
  bool get mayDisciplineAgent => false;
  bool get mayChangeRouting => false;
  bool get mayChangeProvider => false;

  void validateStructure() {
    if (!AgentPerformanceSampleSufficiencyLevel.values.contains(level) ||
        sampleCount < 0 ||
        minimumRequired < 1 ||
        strongRequired < minimumRequired) {
      throw const FormatException(
        'Invalid Agent Performance sample sufficiency.',
      );
    }
  }
}

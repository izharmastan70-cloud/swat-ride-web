class AgentPerformanceMetricScoreComponent {
  const AgentPerformanceMetricScoreComponent({
    required this.metricId,
    required this.sourceValue,
    required this.normalizedScore,
    required this.weight,
    required this.weightedScore,
    required this.inverseDirection,
  });

  final String metricId;
  final double sourceValue;
  final double normalizedScore;
  final double weight;
  final double weightedScore;
  final bool inverseDirection;

  bool get readOnlyInterpretationOnly => true;
  bool get changesSourceMetric => false;
  bool get grantsAuthority => false;
  bool get createsDisciplinaryDecision => false;

  void validateStructure() {
    if (metricId.trim().isEmpty ||
        sourceValue < 0 ||
        sourceValue > 100 ||
        normalizedScore < 0 ||
        normalizedScore > 100 ||
        weight <= 0 ||
        weight > 1 ||
        weightedScore < 0 ||
        weightedScore > 100) {
      throw const FormatException('Invalid Agent Performance score component.');
    }
  }
}

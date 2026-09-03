class AgentProviderQualityReadinessInput {
  const AgentProviderQualityReadinessInput({
    required this.signalBoundaryReady,
    required this.multiSignalAggregationReady,
    required this.safetyFirstRecommendationReady,
    required this.taskSpecificComparisonReady,
    required this.antiFlappingReady,
    required this.provenanceReady,
    required this.outlierPoisoningResistanceReady,
    required this.safeCalibrationReady,
    required this.adversarialGateReady,
    required this.failureIsolationReady,
  });

  final bool signalBoundaryReady;
  final bool multiSignalAggregationReady;
  final bool safetyFirstRecommendationReady;
  final bool taskSpecificComparisonReady;
  final bool antiFlappingReady;
  final bool provenanceReady;
  final bool outlierPoisoningResistanceReady;
  final bool safeCalibrationReady;
  final bool adversarialGateReady;
  final bool failureIsolationReady;

  bool get allFoundationReady =>
      signalBoundaryReady &&
      multiSignalAggregationReady &&
      safetyFirstRecommendationReady &&
      taskSpecificComparisonReady &&
      antiFlappingReady &&
      provenanceReady &&
      outlierPoisoningResistanceReady &&
      safeCalibrationReady &&
      adversarialGateReady &&
      failureIsolationReady;
}

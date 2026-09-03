class AgentProviderQualityOutlierAssessment {
  AgentProviderQualityOutlierAssessment({
    required this.medianScore,
    required List<String> acceptedObservationIds,
    required List<String> excludedOutlierObservationIds,
    required List<String> hardSafetyObservationIds,
    required this.poisoningSuspected,
  }) : acceptedObservationIds = List<String>.unmodifiable(
         acceptedObservationIds,
       ),
       excludedOutlierObservationIds = List<String>.unmodifiable(
         excludedOutlierObservationIds,
       ),
       hardSafetyObservationIds = List<String>.unmodifiable(
         hardSafetyObservationIds,
       );

  final double medianScore;
  final List<String> acceptedObservationIds;
  final List<String> excludedOutlierObservationIds;
  final List<String> hardSafetyObservationIds;
  final bool poisoningSuspected;

  int get acceptedCount => acceptedObservationIds.length;
  int get excludedOutlierCount => excludedOutlierObservationIds.length;

  bool get hardSafetyCanBeExcludedAsOutlier => false;
  bool get metadataOnly => true;
  bool get invokesProvider => false;
  bool get mutatesRouting => false;
  bool get changesProviderState => false;
  bool get persistsAssessment => false;

  void validateStructure() {
    if (!medianScore.isFinite || medianScore < 0 || medianScore > 100) {
      throw const FormatException(
        'Invalid provider quality outlier assessment.',
      );
    }
  }
}

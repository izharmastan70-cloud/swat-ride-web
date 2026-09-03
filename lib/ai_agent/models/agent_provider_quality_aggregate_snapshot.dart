import 'agent_provider_quality_confidence.dart';

class AgentProviderQualityAggregateSnapshot {
  AgentProviderQualityAggregateSnapshot({
    required this.providerId,
    required this.modelReference,
    required this.providerTier,
    required this.taskType,
    required this.weightedScore,
    required this.safetyScore,
    required this.reliabilityScore,
    required this.taskFitScore,
    required this.outputQualityScore,
    required this.hardGateClean,
    required this.criticalFamiliesPresent,
    required this.confidence,
    required Map<String, double> familyScores,
  }) : familyScores = Map<String, double>.unmodifiable(familyScores);

  final String providerId;
  final String modelReference;
  final String providerTier;
  final String taskType;

  final double weightedScore;
  final double safetyScore;
  final double reliabilityScore;
  final double taskFitScore;
  final double outputQualityScore;

  final bool hardGateClean;
  final bool criticalFamiliesPresent;

  final AgentProviderQualityConfidence confidence;
  final Map<String, double> familyScores;

  bool get metadataOnly => true;
  bool get invokesProvider => false;
  bool get mutatesRouting => false;
  bool get changesProviderState => false;
  bool get changesBudget => false;
  bool get changesSecret => false;
  bool get deploysModel => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;
  bool get persistsSnapshot => false;

  void validateStructure() {
    confidence.validateStructure();

    final List<double> scores = <double>[
      weightedScore,
      safetyScore,
      reliabilityScore,
      taskFitScore,
      outputQualityScore,
      ...familyScores.values,
    ];

    if (providerId.trim().isEmpty ||
        modelReference.trim().isEmpty ||
        providerTier.trim().isEmpty ||
        taskType.trim().isEmpty ||
        scores.any(
          (double value) => !value.isFinite || value < 0 || value > 100,
        )) {
      throw const FormatException(
        'Invalid provider quality aggregate snapshot.',
      );
    }
  }
}

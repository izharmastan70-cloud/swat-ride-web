import '../constants/agent_provider_quality_aggregation_constants.dart';

class AgentProviderQualityConfidence {
  const AgentProviderQualityConfidence({
    required this.level,
    required this.coveredFamilyCount,
    required this.strongCurrentFamilyCount,
    required this.sufficientFreshFamilyCount,
    required this.staleFamilyCount,
    required this.criticalFamiliesPresent,
  });

  final String level;
  final int coveredFamilyCount;
  final int strongCurrentFamilyCount;
  final int sufficientFreshFamilyCount;
  final int staleFamilyCount;
  final bool criticalFamiliesPresent;

  bool get strongPreferenceAllowed =>
      level == AgentProviderQualityConfidenceLevel.high &&
      criticalFamiliesPresent;

  bool get aggressiveDeprioritizationAllowed =>
      level != AgentProviderQualityConfidenceLevel.low &&
      criticalFamiliesPresent;

  bool get confidenceMetadataOnly => true;
  bool get invokesProvider => false;
  bool get changesRouting => false;
  bool get changesProviderState => false;

  void validateStructure() {
    if (!AgentProviderQualityConfidenceLevel.values.contains(level) ||
        coveredFamilyCount < 0 ||
        strongCurrentFamilyCount < 0 ||
        sufficientFreshFamilyCount < 0 ||
        staleFamilyCount < 0 ||
        strongCurrentFamilyCount > coveredFamilyCount ||
        sufficientFreshFamilyCount > coveredFamilyCount ||
        staleFamilyCount > coveredFamilyCount) {
      throw const FormatException('Invalid provider quality confidence.');
    }
  }
}

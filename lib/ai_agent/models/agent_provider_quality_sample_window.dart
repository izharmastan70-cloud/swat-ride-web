import '../constants/agent_provider_quality_signal_constants.dart';

class AgentProviderQualitySampleWindow {
  const AgentProviderQualitySampleWindow({
    required this.sampleCount,
    required this.ageHours,
  });

  final int sampleCount;
  final int ageHours;

  String get sufficiency {
    if (sampleCount >= AgentProviderQualityLimits.minStrongSamples) {
      return AgentProviderQualitySampleSufficiency.strong;
    }

    if (sampleCount >= AgentProviderQualityLimits.minSufficientSamples) {
      return AgentProviderQualitySampleSufficiency.sufficient;
    }

    return AgentProviderQualitySampleSufficiency.insufficient;
  }

  String get freshness {
    if (ageHours <= AgentProviderQualityLimits.currentMaxAgeHours) {
      return AgentProviderQualityFreshness.current;
    }

    if (ageHours <= AgentProviderQualityLimits.staleAfterHours) {
      return AgentProviderQualityFreshness.aging;
    }

    return AgentProviderQualityFreshness.stale;
  }

  bool get sufficientForAnyPreference =>
      sufficiency != AgentProviderQualitySampleSufficiency.insufficient &&
      freshness != AgentProviderQualityFreshness.stale;

  bool get sufficientForStrongPreference =>
      sufficiency == AgentProviderQualitySampleSufficiency.strong &&
      freshness == AgentProviderQualityFreshness.current;

  bool get staleEvidenceCannotDrivePreference => true;
  bool get smallSampleCannotDriveStrongPreference => true;
}

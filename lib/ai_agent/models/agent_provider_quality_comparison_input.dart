import '../constants/agent_provider_quality_comparison_constants.dart';
import 'agent_provider_quality_comparison_candidate.dart';

class AgentProviderQualityComparisonInput {
  AgentProviderQualityComparisonInput({
    required List<AgentProviderQualityComparisonCandidate> candidates,
  }) : candidates = List<AgentProviderQualityComparisonCandidate>.unmodifiable(
         candidates,
       );

  final List<AgentProviderQualityComparisonCandidate> candidates;

  String get taskType => candidates.first.taskType;
  String get providerTier => candidates.first.providerTier;

  bool get sameTask => candidates.every(
    (AgentProviderQualityComparisonCandidate value) =>
        value.taskType == taskType,
  );

  bool get sameTier => candidates.every(
    (AgentProviderQualityComparisonCandidate value) =>
        value.providerTier == providerTier,
  );

  bool get duplicateProviderModelPair {
    final Set<String> seen = <String>{};

    for (final AgentProviderQualityComparisonCandidate candidate
        in candidates) {
      final String key = '${candidate.providerId}|${candidate.modelReference}';

      if (!seen.add(key)) {
        return true;
      }
    }

    return false;
  }

  void validateStructure() {
    if (candidates.isEmpty ||
        candidates.length >
            AgentProviderQualityCostTradeoffLimits.maxCandidates ||
        !sameTask ||
        duplicateProviderModelPair) {
      throw const FormatException('Invalid provider quality comparison input.');
    }

    for (final AgentProviderQualityComparisonCandidate candidate
        in candidates) {
      candidate.validateStructure();
    }
  }
}

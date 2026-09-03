import '../constants/agent_provider_quality_history_constants.dart';
import '../constants/agent_provider_quality_signal_constants.dart';

class AgentProviderQualityStabilityDecision {
  AgentProviderQualityStabilityDecision({
    required this.status,
    required this.currentRecommendation,
    required this.proposedRecommendation,
    required this.consecutiveProposalCount,
    required this.hoursSinceLastPreferenceChange,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String currentRecommendation;
  final String proposedRecommendation;
  final int consecutiveProposalCount;
  final int hoursSinceLastPreferenceChange;
  final List<String> reasonCodes;

  bool get preferenceChangeAllowed =>
      status == AgentProviderQualityStabilityStatus.allowPreferenceChange;

  bool get metadataOnly => true;
  bool get mayOverrideTierOrder => false;
  bool get mayOverridePaidControls => false;
  bool get mayOverridePrivacyOrCapability => false;
  bool get invokesProvider => false;
  bool get mutatesRouting => false;
  bool get changesProviderState => false;
  bool get mutatesBudget => false;
  bool get changesSecret => false;
  bool get deploysModel => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;
  bool get persistsDecision => false;

  void validateStructure() {
    if (!AgentProviderQualityStabilityStatus.values.contains(status) ||
        !AgentProviderQualityRecommendation.values.contains(
          currentRecommendation,
        ) ||
        !AgentProviderQualityRecommendation.values.contains(
          proposedRecommendation,
        ) ||
        consecutiveProposalCount < 0 ||
        hoursSinceLastPreferenceChange < 0 ||
        reasonCodes.isEmpty ||
        reasonCodes.length > AgentProviderQualityHistoryLimits.maxReasonCodes) {
      throw const FormatException(
        'Invalid provider quality stability decision.',
      );
    }
  }
}

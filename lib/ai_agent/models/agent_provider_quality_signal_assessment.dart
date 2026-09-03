import '../constants/agent_provider_quality_signal_constants.dart';
import 'agent_provider_quality_score_boundary.dart';

class AgentProviderQualitySignalAssessment {
  AgentProviderQualitySignalAssessment({
    required this.signalId,
    required this.boundary,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String signalId;
  final AgentProviderQualityScoreBoundary boundary;
  final List<String> reasonCodes;

  bool get qualityEligible => boundary.qualityEligible;

  bool get failClosed =>
      boundary.recommendation ==
          AgentProviderQualityRecommendation.ineligible ||
      boundary.recommendation ==
          AgentProviderQualityRecommendation.insufficientEvidence;

  bool get metadataOnly => true;
  bool get invokesProvider => false;
  bool get changesProviderState => false;
  bool get mutatesBudget => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;
  bool get persistsAssessment => false;

  void validateStructure() {
    boundary.validateStructure();

    if (signalId.trim().isEmpty ||
        reasonCodes.isEmpty ||
        reasonCodes.length > AgentProviderQualityLimits.maxReasonCodes) {
      throw const FormatException(
        'Invalid provider quality signal assessment.',
      );
    }
  }
}

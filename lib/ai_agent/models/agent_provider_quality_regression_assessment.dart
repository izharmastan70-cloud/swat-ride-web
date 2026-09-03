import '../constants/agent_provider_quality_history_constants.dart';

class AgentProviderQualityRegressionAssessment {
  AgentProviderQualityRegressionAssessment({
    required this.severity,
    required this.regressionDetected,
    required this.scoreDropPoints,
    required this.safetyDropPoints,
    required this.hardGateRegression,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String severity;
  final bool regressionDetected;
  final double scoreDropPoints;
  final double safetyDropPoints;
  final bool hardGateRegression;
  final List<String> reasonCodes;

  bool get metadataOnly => true;
  bool get invokesProvider => false;
  bool get mutatesRouting => false;
  bool get changesProviderState => false;
  bool get persistsRegression => false;

  void validateStructure() {
    if (!AgentProviderQualityRegressionSeverity.values.contains(severity) ||
        !scoreDropPoints.isFinite ||
        !safetyDropPoints.isFinite ||
        scoreDropPoints < 0 ||
        safetyDropPoints < 0 ||
        reasonCodes.isEmpty ||
        reasonCodes.length > AgentProviderQualityHistoryLimits.maxReasonCodes) {
      throw const FormatException(
        'Invalid provider quality regression assessment.',
      );
    }

    if ((severity == AgentProviderQualityRegressionSeverity.none) ==
        regressionDetected) {
      throw const FormatException('Regression severity/detected mismatch.');
    }
  }
}

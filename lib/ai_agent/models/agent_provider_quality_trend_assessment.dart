import '../constants/agent_provider_quality_aggregation_constants.dart';
import '../constants/agent_provider_quality_history_constants.dart';

class AgentProviderQualityTrendAssessment {
  const AgentProviderQualityTrendAssessment({
    required this.trend,
    required this.baselineAverage,
    required this.recentAverage,
    required this.deltaPoints,
    required this.pointsCompared,
    required this.confidenceLevel,
  });

  final String trend;
  final double baselineAverage;
  final double recentAverage;
  final double deltaPoints;
  final int pointsCompared;
  final String confidenceLevel;

  bool get metadataOnly => true;
  bool get changesProviderPreference => false;
  bool get invokesProvider => false;
  bool get mutatesRouting => false;
  bool get persistsTrend => false;

  void validateStructure() {
    if (!AgentProviderQualityTrend.values.contains(trend) ||
        !baselineAverage.isFinite ||
        baselineAverage < 0 ||
        baselineAverage > 100 ||
        !recentAverage.isFinite ||
        recentAverage < 0 ||
        recentAverage > 100 ||
        !deltaPoints.isFinite ||
        pointsCompared < 0 ||
        !AgentProviderQualityConfidenceLevel.values.contains(confidenceLevel)) {
      throw const FormatException('Invalid provider quality trend assessment.');
    }
  }
}

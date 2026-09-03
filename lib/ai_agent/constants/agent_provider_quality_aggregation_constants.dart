import 'agent_provider_quality_signal_constants.dart';

class AgentProviderQualityConfidenceLevel {
  AgentProviderQualityConfidenceLevel._();

  static const String low = 'LOW';
  static const String medium = 'MEDIUM';
  static const String high = 'HIGH';

  static const Set<String> values = <String>{low, medium, high};
}

class AgentProviderQualityAggregationPolicyConfig {
  AgentProviderQualityAggregationPolicyConfig._();

  static const Map<String, double> familyWeights = <String, double>{
    AgentProviderQualitySignalFamily.reliability: 0.20,
    AgentProviderQualitySignalFamily.responsiveness: 0.10,
    AgentProviderQualitySignalFamily.taskFit: 0.20,
    AgentProviderQualitySignalFamily.outputQuality: 0.20,
    AgentProviderQualitySignalFamily.userFeedback: 0.10,
    AgentProviderQualitySignalFamily.costEfficiency: 0.05,
    AgentProviderQualitySignalFamily.stability: 0.05,
    AgentProviderQualitySignalFamily.safety: 0.10,
  };

  static const Set<String> criticalFamilies = <String>{
    AgentProviderQualitySignalFamily.reliability,
    AgentProviderQualitySignalFamily.taskFit,
    AgentProviderQualitySignalFamily.outputQuality,
    AgentProviderQualitySignalFamily.safety,
  };

  static const int highConfidenceFamilyCoverage = 8;
  static const int mediumConfidenceFamilyCoverage = 6;
  static const int minHighStrongCurrentFamilies = 6;

  static const double safetyPreferFloor = 85.0;
  static const double safetyNeutralFloor = 60.0;
  static const double criticalFamilyPreferFloor = 60.0;

  static const int maxReasonCodes = 20;
}

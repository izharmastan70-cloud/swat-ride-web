import '../constants/agent_provider_quality_history_constants.dart';
import 'agent_provider_quality_history_point.dart';

class AgentProviderQualityHistoryWindow {
  AgentProviderQualityHistoryWindow({
    required List<AgentProviderQualityHistoryPoint> points,
  }) : points = List<AgentProviderQualityHistoryPoint>.unmodifiable(points);

  final List<AgentProviderQualityHistoryPoint> points;

  String get providerId => points.first.providerId;
  String get modelReference => points.first.modelReference;
  String get providerTier => points.first.providerTier;
  String get taskType => points.first.taskType;

  bool get sameBinding => points.every(
    (AgentProviderQualityHistoryPoint point) =>
        point.providerId == providerId &&
        point.modelReference == modelReference &&
        point.providerTier == providerTier &&
        point.taskType == taskType,
  );

  bool get chronological {
    for (int index = 1; index < points.length; index += 1) {
      if (points[index].observedAtEpochHour <=
          points[index - 1].observedAtEpochHour) {
        return false;
      }
    }

    return true;
  }

  bool get uniqueObservationIds =>
      points
          .map((AgentProviderQualityHistoryPoint point) => point.observationId)
          .toSet()
          .length ==
      points.length;

  bool get enoughForTrend =>
      points.length >= AgentProviderQualityHistoryLimits.minTrendPoints;

  void validateStructure() {
    if (points.isEmpty ||
        points.length > AgentProviderQualityHistoryLimits.maxHistoryPoints ||
        !sameBinding ||
        !chronological ||
        !uniqueObservationIds) {
      throw const FormatException('Invalid provider quality history window.');
    }

    for (final AgentProviderQualityHistoryPoint point in points) {
      point.validateStructure();
    }
  }
}

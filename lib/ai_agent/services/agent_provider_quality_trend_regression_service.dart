import '../constants/agent_provider_quality_aggregation_constants.dart';
import '../constants/agent_provider_quality_history_constants.dart';
import '../models/agent_provider_quality_history_point.dart';
import '../models/agent_provider_quality_history_window.dart';
import '../models/agent_provider_quality_regression_assessment.dart';
import '../models/agent_provider_quality_trend_assessment.dart';

class AgentProviderQualityTrendRegressionService {
  const AgentProviderQualityTrendRegressionService();

  AgentProviderQualityTrendAssessment assessTrend(
    AgentProviderQualityHistoryWindow window,
  ) {
    window.validateStructure();

    if (!window.enoughForTrend) {
      final double average = _average(
        window.points.map(
          (AgentProviderQualityHistoryPoint point) => point.weightedScore,
        ),
      );

      return _trend(
        trend: AgentProviderQualityTrend.insufficientHistory,
        baselineAverage: average,
        recentAverage: average,
        deltaPoints: 0,
        pointsCompared: window.points.length,
        confidenceLevel: AgentProviderQualityConfidenceLevel.low,
      );
    }

    final List<AgentProviderQualityHistoryPoint> baseline = window.points
        .take(AgentProviderQualityHistoryLimits.baselinePointCount)
        .toList(growable: false);

    final List<AgentProviderQualityHistoryPoint> recent = window.points
        .skip(
          window.points.length -
              AgentProviderQualityHistoryLimits.recentPointCount,
        )
        .toList(growable: false);

    final double baselineAverage = _average(
      baseline.map(
        (AgentProviderQualityHistoryPoint point) => point.weightedScore,
      ),
    );

    final double recentAverage = _average(
      recent.map(
        (AgentProviderQualityHistoryPoint point) => point.weightedScore,
      ),
    );

    final double delta = recentAverage - baselineAverage;

    String trend = AgentProviderQualityTrend.stable;

    if (delta > AgentProviderQualityHistoryLimits.stableDeltaMaxPoints) {
      trend = AgentProviderQualityTrend.improving;
    } else if (delta <
        -AgentProviderQualityHistoryLimits.stableDeltaMaxPoints) {
      trend = AgentProviderQualityTrend.degrading;
    }

    final String confidenceLevel =
        window.points.length >=
            AgentProviderQualityHistoryLimits.highConfidenceHistoryPoints
        ? AgentProviderQualityConfidenceLevel.high
        : AgentProviderQualityConfidenceLevel.medium;

    return _trend(
      trend: trend,
      baselineAverage: baselineAverage,
      recentAverage: recentAverage,
      deltaPoints: delta,
      pointsCompared: baseline.length + recent.length,
      confidenceLevel: confidenceLevel,
    );
  }

  AgentProviderQualityRegressionAssessment detectRegression(
    AgentProviderQualityHistoryWindow window,
  ) {
    window.validateStructure();

    if (window.points.length < 2) {
      return _regression(
        severity: AgentProviderQualityRegressionSeverity.none,
        detected: false,
        scoreDrop: 0,
        safetyDrop: 0,
        hardGateRegression: false,
        reasons: const <String>[
          'insufficient_history_for_regression_comparison',
        ],
      );
    }

    final AgentProviderQualityHistoryPoint previous =
        window.points[window.points.length - 2];

    final AgentProviderQualityHistoryPoint current = window.points.last;

    final double scoreDrop = (previous.weightedScore - current.weightedScore)
        .clamp(0.0, 100.0)
        .toDouble();

    final double safetyDrop = (previous.safetyScore - current.safetyScore)
        .clamp(0.0, 100.0)
        .toDouble();

    final bool hardGateRegression =
        previous.hardGateClean && !current.hardGateClean;

    if (hardGateRegression ||
        current.safetyScore <
            AgentProviderQualityHistoryLimits.safetyCriticalFloor ||
        safetyDrop >=
            AgentProviderQualityHistoryLimits.safetyCriticalDropPoints ||
        scoreDrop >=
            AgentProviderQualityHistoryLimits.criticalRegressionDropPoints) {
      return _regression(
        severity: AgentProviderQualityRegressionSeverity.critical,
        detected: true,
        scoreDrop: scoreDrop,
        safetyDrop: safetyDrop,
        hardGateRegression: hardGateRegression,
        reasons: <String>[
          if (hardGateRegression) 'hard_gate_regression',
          if (current.safetyScore <
              AgentProviderQualityHistoryLimits.safetyCriticalFloor)
            'safety_score_below_critical_floor',
          if (safetyDrop >=
              AgentProviderQualityHistoryLimits.safetyCriticalDropPoints)
            'critical_safety_drop',
          if (scoreDrop >=
              AgentProviderQualityHistoryLimits.criticalRegressionDropPoints)
            'critical_weighted_score_drop',
          'fail_closed_for_aggressive_preference_change',
        ],
      );
    }

    if (scoreDrop >=
        AgentProviderQualityHistoryLimits.significantRegressionDropPoints) {
      return _regression(
        severity: AgentProviderQualityRegressionSeverity.significant,
        detected: true,
        scoreDrop: scoreDrop,
        safetyDrop: safetyDrop,
        hardGateRegression: false,
        reasons: const <String>[
          'significant_weighted_score_drop',
          'preference_change_should_be_held',
        ],
      );
    }

    if (scoreDrop >=
        AgentProviderQualityHistoryLimits.watchRegressionDropPoints) {
      return _regression(
        severity: AgentProviderQualityRegressionSeverity.watch,
        detected: true,
        scoreDrop: scoreDrop,
        safetyDrop: safetyDrop,
        hardGateRegression: false,
        reasons: const <String>[
          'quality_drop_requires_watch',
          'avoid_reactive_preference_change',
        ],
      );
    }

    return _regression(
      severity: AgentProviderQualityRegressionSeverity.none,
      detected: false,
      scoreDrop: scoreDrop,
      safetyDrop: safetyDrop,
      hardGateRegression: false,
      reasons: const <String>['no_material_regression_detected'],
    );
  }

  AgentProviderQualityTrendAssessment _trend({
    required String trend,
    required double baselineAverage,
    required double recentAverage,
    required double deltaPoints,
    required int pointsCompared,
    required String confidenceLevel,
  }) {
    final AgentProviderQualityTrendAssessment result =
        AgentProviderQualityTrendAssessment(
          trend: trend,
          baselineAverage: baselineAverage,
          recentAverage: recentAverage,
          deltaPoints: deltaPoints,
          pointsCompared: pointsCompared,
          confidenceLevel: confidenceLevel,
        );

    result.validateStructure();
    return result;
  }

  AgentProviderQualityRegressionAssessment _regression({
    required String severity,
    required bool detected,
    required double scoreDrop,
    required double safetyDrop,
    required bool hardGateRegression,
    required List<String> reasons,
  }) {
    final AgentProviderQualityRegressionAssessment result =
        AgentProviderQualityRegressionAssessment(
          severity: severity,
          regressionDetected: detected,
          scoreDropPoints: scoreDrop,
          safetyDropPoints: safetyDrop,
          hardGateRegression: hardGateRegression,
          reasonCodes: reasons,
        );

    result.validateStructure();
    return result;
  }

  double _average(Iterable<double> values) {
    final List<double> list = values.toList(growable: false);

    if (list.isEmpty) {
      return 0;
    }

    return list.fold<double>(0, (double total, double value) => total + value) /
        list.length;
  }

  bool get chronologicalHistoryRequired => true;
  bool get sameProviderModelTierTaskBindingRequired => true;
  bool get smallHistoryCannotDriveTrend => true;
  bool get hardGateRegressionIsCritical => true;
  bool get safetyRegressionIsCritical => true;
  bool get historicalAverageCannotHideHardGateFailure => true;

  bool get providerInvocationImplementedHere => false;
  bool get routingMutationImplementedHere => false;
  bool get providerStateMutationImplementedHere => false;
  bool get persistenceImplementedHere => false;
  bool get executesBusinessAction => false;
}

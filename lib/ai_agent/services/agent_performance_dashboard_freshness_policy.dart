import '../constants/agent_performance_dashboard_privacy_constants.dart';

class AgentPerformanceDashboardFreshnessDecision {
  const AgentPerformanceDashboardFreshnessDecision({
    required this.state,
    required this.age,
  });

  final String state;
  final Duration age;

  bool get fresh => state == AgentPerformanceDashboardFreshnessState.fresh;
  bool get stale => state == AgentPerformanceDashboardFreshnessState.stale;
  bool get futureClockSkew =>
      state == AgentPerformanceDashboardFreshnessState.futureClockSkew;
  bool get invalidTimestamp =>
      state == AgentPerformanceDashboardFreshnessState.invalidTimestamp;
}

class AgentPerformanceDashboardFreshnessPolicy {
  const AgentPerformanceDashboardFreshnessPolicy();

  AgentPerformanceDashboardFreshnessDecision evaluate({
    required DateTime snapshotGeneratedAtUtc,
    required DateTime evaluatedAtUtc,
    Duration maxAge =
        AgentPerformanceDashboardPrivacyLimits.defaultMaxSnapshotAge,
  }) {
    if (!snapshotGeneratedAtUtc.isUtc ||
        !evaluatedAtUtc.isUtc ||
        maxAge.inMicroseconds <= 0) {
      return const AgentPerformanceDashboardFreshnessDecision(
        state: AgentPerformanceDashboardFreshnessState.invalidTimestamp,
        age: Duration.zero,
      );
    }

    final Duration age = evaluatedAtUtc.difference(snapshotGeneratedAtUtc);

    if (age.inMicroseconds <
        -AgentPerformanceDashboardPrivacyLimits
            .maxFutureClockSkew
            .inMicroseconds) {
      return AgentPerformanceDashboardFreshnessDecision(
        state: AgentPerformanceDashboardFreshnessState.futureClockSkew,
        age: age,
      );
    }

    if (age > maxAge) {
      return AgentPerformanceDashboardFreshnessDecision(
        state: AgentPerformanceDashboardFreshnessState.stale,
        age: age,
      );
    }

    return AgentPerformanceDashboardFreshnessDecision(
      state: AgentPerformanceDashboardFreshnessState.fresh,
      age: age,
    );
  }

  bool get staleDataFailsClosed => true;
  bool get excessiveFutureClockSkewFailsClosed => true;
  bool get evaluationTimeMustBeExplicit => true;
  bool get hiddenWallClockReadUsed => false;
  bool get networkTimeLookupImplementedHere => false;
  bool get persistenceImplementedHere => false;
}

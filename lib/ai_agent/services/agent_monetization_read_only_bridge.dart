import '../models/agent_monetization_read_only_snapshot.dart';

/// Read-only evidence boundary for Phase 33.
///
/// Existing Ride/Food/Cargo/Hotel/Tour/Rewards/etc. readers may
/// supply already-observed values to this bridge.
///
/// IMPORTANT:
/// - This bridge does not query Firestore.
/// - This bridge does not modify pricing.
/// - This bridge does not modify commission.
/// - This bridge does not modify rewards/promos.
/// - This bridge does not touch wallets/payments.
/// - Missing analytics must NOT be invented.
class AgentMonetizationReadOnlyBridge {
  const AgentMonetizationReadOnlyBridge();

  AgentMonetizationReadOnlySnapshot buildSnapshot({
    required Iterable<AgentMonetizationObservedMetric> observedMetrics,
    DateTime? generatedAt,
  }) {
    final metrics = List<AgentMonetizationObservedMetric>.unmodifiable(
      observedMetrics,
    );

    final snapshot = AgentMonetizationReadOnlySnapshot(
      metrics: metrics,
      generatedAt: generatedAt ?? DateTime.now(),
    );

    snapshot.validate();

    return snapshot;
  }

  AgentMonetizationObservedMetric percentage({
    required String source,
    required String module,
    required String metric,
    required double value,
    DateTime? observedAt,
  }) {
    if (value < 0 || value > 100) {
      throw AgentMonetizationReadOnlyBridgeException(
        'Percentage metric must be between 0 and 100: $metric',
      );
    }

    return _metric(
      source: source,
      module: module,
      metric: metric,
      value: value,
      unit: 'percent',
      observedAt: observedAt,
    );
  }

  AgentMonetizationObservedMetric money({
    required String source,
    required String module,
    required String metric,
    required double value,
    DateTime? observedAt,
  }) {
    if (value < 0) {
      throw AgentMonetizationReadOnlyBridgeException(
        'Money metric cannot be negative: $metric',
      );
    }

    return _metric(
      source: source,
      module: module,
      metric: metric,
      value: value,
      unit: 'PKR',
      observedAt: observedAt,
    );
  }

  AgentMonetizationObservedMetric count({
    required String source,
    required String module,
    required String metric,
    required int value,
    DateTime? observedAt,
  }) {
    if (value < 0) {
      throw AgentMonetizationReadOnlyBridgeException(
        'Count metric cannot be negative: $metric',
      );
    }

    return _metric(
      source: source,
      module: module,
      metric: metric,
      value: value.toDouble(),
      unit: 'count',
      observedAt: observedAt,
    );
  }

  AgentMonetizationObservedMetric _metric({
    required String source,
    required String module,
    required String metric,
    required double value,
    required String unit,
    DateTime? observedAt,
  }) {
    final result = AgentMonetizationObservedMetric(
      source: source.trim(),
      module: module.trim(),
      metric: metric,
      value: value,
      unit: unit,
      observedAt: observedAt ?? DateTime.now(),
    );

    result.validate();

    return result;
  }
}

class AgentMonetizationReadOnlyBridgeException implements Exception {
  final String message;

  const AgentMonetizationReadOnlyBridgeException(this.message);

  @override
  String toString() => 'AgentMonetizationReadOnlyBridgeException: $message';
}

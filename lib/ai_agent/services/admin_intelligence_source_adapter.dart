import '../models/admin_intelligence_health_snapshot.dart';

class AdminIntelligenceSourceBatch {
  const AdminIntelligenceSourceBatch({
    required this.sourceId,
    required this.adminArea,
    required this.collectedAt,
    required this.observations,
    this.readOnly = true,
    this.providerCallUsed = false,
  });

  final String sourceId;
  final String adminArea;
  final DateTime collectedAt;
  final List<AdminIntelligenceHealthObservation> observations;

  /// Every Phase 38-D adapter must stay read-only.
  final bool readOnly;

  /// Source collection must not require AI/provider calls.
  final bool providerCallUsed;

  bool get isSafeCollectionContract => readOnly && !providerCallUsed;
}

/// Pure read-only adapter contract.
///
/// Implementations receive already-authorized source data.
/// They must not perform writes or operational actions.
abstract interface class AdminIntelligenceSourceAdapter<T> {
  String get sourceId;
  String get adminArea;

  AdminIntelligenceSourceBatch collect({
    required T input,
    required DateTime observedAt,
  });
}

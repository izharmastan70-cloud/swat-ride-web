import '../models/admin_intelligence_health_snapshot.dart';
import 'admin_intelligence_report_engine.dart';
import 'admin_intelligence_source_adapter.dart';

class AdminIntelligenceSourceRegistry {
  const AdminIntelligenceSourceRegistry();

  AdminIntelligenceHealthSnapshot buildSnapshot({
    required String snapshotId,
    required DateTime generatedAt,
    required DateTime windowStart,
    required DateTime windowEnd,
    required Iterable<AdminIntelligenceSourceBatch> batches,
  }) {
    final id = snapshotId.trim();

    if (id.isEmpty) {
      throw ArgumentError('Admin Intelligence snapshot ID is required.');
    }

    if (windowEnd.isBefore(windowStart)) {
      throw ArgumentError('Snapshot windowEnd cannot be before windowStart.');
    }

    final areas = <String>{};

    final sources = <String>{};

    final observations = <AdminIntelligenceHealthObservation>[];

    for (final batch in batches) {
      if (!batch.isSafeCollectionContract) {
        throw ArgumentError('Unsafe source batch: ${batch.sourceId}');
      }

      final area = batch.adminArea.trim().toLowerCase();

      if (!AdminIntelligenceReportEngine.discoveredAdminAreas.contains(area)) {
        throw ArgumentError('Unsupported source Admin area: $area');
      }

      final source = batch.sourceId.trim();

      if (source.isEmpty) {
        throw ArgumentError('Source ID cannot be empty.');
      }

      areas.add(area);
      sources.add(source);
      observations.addAll(batch.observations);
    }

    final areaList = areas.toList(growable: false)..sort();

    final sourceList = sources.toList(growable: false)..sort();

    return AdminIntelligenceHealthSnapshot(
      snapshotId: id,
      generatedAt: generatedAt,
      windowStart: windowStart,
      windowEnd: windowEnd,
      adminAreasScanned: List<String>.unmodifiable(areaList),
      sourcesScanned: List<String>.unmodifiable(sourceList),
      observations: List<AdminIntelligenceHealthObservation>.unmodifiable(
        observations,
      ),
      readOnly: true,
      automaticActionAllowed: false,
    );
  }
}

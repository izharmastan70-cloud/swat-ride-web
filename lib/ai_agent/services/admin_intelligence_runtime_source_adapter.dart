import '../models/admin_intelligence_health_snapshot.dart';
import '../models/admin_intelligence_signal.dart';
import 'admin_intelligence_source_adapter.dart';
import 'admin_intelligence_report_engine.dart';

class AdminIntelligenceRuntimeMetricFinding {
  const AdminIntelligenceRuntimeMetricFinding({
    required this.findingId,
    required this.adminArea,
    required this.findingType,
    required this.title,
    required this.summary,
    required this.evidenceSummary,
    required this.recommendation,
    required this.sourceReference,
    required this.evidenceKind,
    required this.evidenceCount,
    required this.deterministicCheckPassed,
    this.severity = AdminIntelligenceSeverity.medium,
    this.confidence = 0.8,
  });

  final String findingId;
  final String adminArea;
  final String findingType;
  final String severity;
  final String title;
  final String summary;
  final String evidenceSummary;
  final String recommendation;
  final String sourceReference;
  final String evidenceKind;
  final int evidenceCount;
  final bool deterministicCheckPassed;
  final double confidence;
}

/// Converts authorized runtime metric/invariant results into observations.
///
/// This adapter does not fetch Firestore itself. A trusted caller supplies
/// already-authorized and privacy-safe runtime findings.
class AdminIntelligenceRuntimeSourceAdapter
    implements
        AdminIntelligenceSourceAdapter<
          Iterable<AdminIntelligenceRuntimeMetricFinding>
        > {
  const AdminIntelligenceRuntimeSourceAdapter({
    required this.adminArea,
    required this.sourceId,
  });

  @override
  final String adminArea;

  @override
  final String sourceId;

  @override
  AdminIntelligenceSourceBatch collect({
    required Iterable<AdminIntelligenceRuntimeMetricFinding> input,
    required DateTime observedAt,
  }) {
    final normalizedArea = adminArea.trim().toLowerCase();

    if (!AdminIntelligenceReportEngine.discoveredAdminAreas.contains(
      normalizedArea,
    )) {
      throw ArgumentError('Unsupported Admin area: $normalizedArea');
    }

    final observations = <AdminIntelligenceHealthObservation>[];

    for (final finding in input) {
      final findingArea = finding.adminArea.trim().toLowerCase();

      if (findingArea != normalizedArea) {
        throw ArgumentError(
          'Runtime finding area mismatch: '
          '$findingArea != $normalizedArea',
        );
      }

      if (!_isRuntimeType(finding.findingType)) {
        throw ArgumentError(
          'Runtime adapter received non-runtime finding type: '
          '${finding.findingType}',
        );
      }

      observations.add(
        AdminIntelligenceHealthObservation(
          observationId: finding.findingId.trim(),
          adminArea: normalizedArea,
          findingType: finding.findingType.trim().toLowerCase(),
          severity: finding.severity.trim().toLowerCase(),
          title: finding.title.trim(),
          summary: finding.summary.trim(),
          evidenceSummary: finding.evidenceSummary.trim(),
          recommendation: finding.recommendation.trim(),
          source: finding.sourceReference.trim(),
          evidenceKind: finding.evidenceKind.trim().toLowerCase(),
          observedAt: observedAt,
          evidenceCount: finding.evidenceCount,
          deterministicCheckPassed: finding.deterministicCheckPassed,
          humanVerified: false,
          confidence: finding.confidence,
        ),
      );
    }

    return AdminIntelligenceSourceBatch(
      sourceId: sourceId.trim(),
      adminArea: normalizedArea,
      collectedAt: observedAt,
      observations: List<AdminIntelligenceHealthObservation>.unmodifiable(
        observations,
      ),
      readOnly: true,
      providerCallUsed: false,
    );
  }

  bool _isRuntimeType(String value) {
    final type = value.trim().toLowerCase();

    return type == AdminIntelligenceFindingType.unusualData ||
        type == AdminIntelligenceFindingType.operationalIssue;
  }
}

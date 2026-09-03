import '../models/admin_intelligence_health_snapshot.dart';
import '../models/admin_intelligence_signal.dart';
import 'admin_intelligence_source_adapter.dart';
import 'admin_intelligence_report_engine.dart';

class AdminIntelligenceStructuralCandidate {
  const AdminIntelligenceStructuralCandidate({
    required this.candidateId,
    required this.adminArea,
    required this.findingType,
    required this.title,
    required this.summary,
    required this.evidenceSummary,
    required this.recommendation,
    required this.sourceReference,
    required this.evidenceKind,
    this.severity = AdminIntelligenceSeverity.low,
    this.evidenceCount = 1,
    this.confidence = 0.5,
    this.humanVerified = false,
  });

  final String candidateId;
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
  final double confidence;
  final bool humanVerified;
}

/// Converts static/project-structure findings into observations.
///
/// Safety rule:
/// structural candidates are not automatically verified.
/// A human must explicitly verify them later.
class AdminIntelligenceStructuralSourceAdapter
    implements
        AdminIntelligenceSourceAdapter<
          Iterable<AdminIntelligenceStructuralCandidate>
        > {
  const AdminIntelligenceStructuralSourceAdapter({
    required this.adminArea,
    required this.sourceId,
  });

  @override
  final String adminArea;

  @override
  final String sourceId;

  @override
  AdminIntelligenceSourceBatch collect({
    required Iterable<AdminIntelligenceStructuralCandidate> input,
    required DateTime observedAt,
  }) {
    final normalizedArea = adminArea.trim().toLowerCase();

    if (!AdminIntelligenceReportEngine.discoveredAdminAreas.contains(
      normalizedArea,
    )) {
      throw ArgumentError('Unsupported Admin area: $normalizedArea');
    }

    final observations = <AdminIntelligenceHealthObservation>[];

    for (final candidate in input) {
      final candidateArea = candidate.adminArea.trim().toLowerCase();

      if (candidateArea != normalizedArea) {
        throw ArgumentError(
          'Structural candidate area mismatch: '
          '$candidateArea != $normalizedArea',
        );
      }

      if (!_isStructuralType(candidate.findingType)) {
        throw ArgumentError(
          'Structural adapter received non-structural finding type: '
          '${candidate.findingType}',
        );
      }

      observations.add(
        AdminIntelligenceHealthObservation(
          observationId: candidate.candidateId.trim(),
          adminArea: normalizedArea,
          findingType: candidate.findingType.trim().toLowerCase(),
          severity: candidate.severity.trim().toLowerCase(),
          title: candidate.title.trim(),
          summary: candidate.summary.trim(),
          evidenceSummary: candidate.evidenceSummary.trim(),
          recommendation: candidate.recommendation.trim(),
          source: candidate.sourceReference.trim(),
          evidenceKind: candidate.evidenceKind.trim().toLowerCase(),
          observedAt: observedAt,
          evidenceCount: candidate.evidenceCount,
          deterministicCheckPassed: false,
          humanVerified: candidate.humanVerified,
          confidence: candidate.confidence,
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

  bool _isStructuralType(String value) {
    final type = value.trim().toLowerCase();

    return type == AdminIntelligenceFindingType.missingControl ||
        type == AdminIntelligenceFindingType.staleScreen ||
        type == AdminIntelligenceFindingType.disconnectedService;
  }
}

import '../models/admin_intelligence_health_snapshot.dart';
import '../models/admin_intelligence_signal.dart';
import 'admin_intelligence_report_engine.dart';

/// Converts authorized read-only Admin health observations into
/// Admin Intelligence signals.
///
/// Important false-positive protection:
/// - structural findings stay CANDIDATE unless explicitly human-verified
/// - runtime invariant/threshold findings may be VERIFIED deterministically
/// - every emitted signal still requires human review
/// - no operational action is executed here
class AdminIntelligenceHealthSignalCollector {
  const AdminIntelligenceHealthSignalCollector();

  List<AdminIntelligenceSignal> collect(
    AdminIntelligenceHealthSnapshot snapshot,
  ) {
    _validateSnapshot(snapshot);

    final signals = <AdminIntelligenceSignal>[];

    for (final original in snapshot.observations) {
      final observation = _normalize(original);

      _validateObservation(observation);

      final verificationStatus = _verificationStatus(observation);

      signals.add(
        AdminIntelligenceSignal(
          signalId: '${snapshot.snapshotId}:${observation.observationId}',
          adminArea: observation.adminArea,
          findingType: observation.findingType,
          severity: observation.severity,
          title: observation.title,
          summary: observation.summary,
          evidenceSummary: observation.evidenceSummary,
          recommendation: observation.recommendation,
          source: 'health_snapshot:${observation.source}',
          observedAt: observation.observedAt,
          verificationStatus: verificationStatus,
          confidence: observation.safeConfidence,
          requiresHumanReview: true,
        ),
      );
    }

    return List<AdminIntelligenceSignal>.unmodifiable(signals);
  }

  String _verificationStatus(AdminIntelligenceHealthObservation observation) {
    if (observation.humanVerified) {
      return AdminIntelligenceVerificationStatus.verified;
    }

    if (observation.isStructuralFinding) {
      return AdminIntelligenceVerificationStatus.candidate;
    }

    if (observation.isRuntimeFinding &&
        observation.deterministicCheckPassed &&
        observation.evidenceCount > 0 &&
        _supportsDeterministicVerification(observation.evidenceKind)) {
      return AdminIntelligenceVerificationStatus.verified;
    }

    return AdminIntelligenceVerificationStatus.candidate;
  }

  bool _supportsDeterministicVerification(String evidenceKind) {
    return evidenceKind ==
            AdminIntelligenceEvidenceKind.dataInvariantViolation ||
        evidenceKind ==
            AdminIntelligenceEvidenceKind.operationalThresholdBreach;
  }

  AdminIntelligenceHealthObservation _normalize(
    AdminIntelligenceHealthObservation observation,
  ) {
    return observation.copyWith(
      observationId: observation.observationId.trim(),
      adminArea: observation.adminArea.trim().toLowerCase(),
      findingType: observation.findingType.trim().toLowerCase(),
      severity: observation.severity.trim().toLowerCase(),
      title: observation.title.trim(),
      summary: observation.summary.trim(),
      evidenceSummary: observation.evidenceSummary.trim(),
      recommendation: observation.recommendation.trim(),
      source: observation.source.trim(),
      evidenceKind: observation.evidenceKind.trim().toLowerCase(),
      confidence: observation.safeConfidence,
    );
  }

  void _validateSnapshot(AdminIntelligenceHealthSnapshot snapshot) {
    if (snapshot.snapshotId.trim().isEmpty) {
      throw ArgumentError('Admin health snapshot ID is required.');
    }

    if (snapshot.windowEnd.isBefore(snapshot.windowStart)) {
      throw ArgumentError('Snapshot windowEnd cannot be before windowStart.');
    }

    if (!snapshot.isSafeReadOnlyContract) {
      throw ArgumentError(
        'Admin health snapshot must remain read-only '
        'with automatic actions disabled.',
      );
    }
  }

  void _validateObservation(AdminIntelligenceHealthObservation observation) {
    if (observation.observationId.isEmpty) {
      throw ArgumentError('Observation ID is required.');
    }

    if (!AdminIntelligenceReportEngine.discoveredAdminAreas.contains(
      observation.adminArea,
    )) {
      throw ArgumentError(
        'Unsupported Admin area: '
        '${observation.adminArea}',
      );
    }

    if (!AdminIntelligenceFindingType.values.contains(
      observation.findingType,
    )) {
      throw ArgumentError(
        'Unsupported finding type: '
        '${observation.findingType}',
      );
    }

    if (!AdminIntelligenceSeverity.values.contains(observation.severity)) {
      throw ArgumentError(
        'Unsupported severity: '
        '${observation.severity}',
      );
    }

    if (!AdminIntelligenceEvidenceKind.values.contains(
      observation.evidenceKind,
    )) {
      throw ArgumentError(
        'Unsupported evidence kind: '
        '${observation.evidenceKind}',
      );
    }

    if (observation.title.isEmpty ||
        observation.summary.isEmpty ||
        observation.evidenceSummary.isEmpty ||
        observation.recommendation.isEmpty ||
        observation.source.isEmpty) {
      throw ArgumentError(
        'Observation title, summary, evidence, '
        'recommendation and source are required.',
      );
    }

    if (observation.evidenceCount < 0) {
      throw ArgumentError('Evidence count cannot be negative.');
    }
  }
}

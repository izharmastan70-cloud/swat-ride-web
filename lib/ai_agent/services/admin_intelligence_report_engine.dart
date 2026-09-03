import '../models/admin_intelligence_report.dart';
import '../models/admin_intelligence_signal.dart';

class AdminIntelligenceReportEngine {
  const AdminIntelligenceReportEngine();

  static const Set<String> discoveredAdminAreas = <String>{
    'admin_rewards',
    'cargo',
    'feedback',
    'food',
    'hotel_admin',
    'ride_admin',
    'student_ride',
    'super_admin',
    'tourism_admin',
  };

  AdminIntelligenceReport buildReport({
    required String reportId,
    required DateTime generatedAt,
    required DateTime windowStart,
    required DateTime windowEnd,
    required Iterable<AdminIntelligenceSignal> signals,
    Iterable<String> adminAreasScanned = discoveredAdminAreas,
    Iterable<String> sourcesScanned = const <String>[],
  }) {
    final normalizedReportId = reportId.trim();

    if (normalizedReportId.isEmpty) {
      throw ArgumentError('Admin Intelligence report ID is required.');
    }

    if (windowEnd.isBefore(windowStart)) {
      throw ArgumentError('Report windowEnd cannot be before windowStart.');
    }

    final findings = <AdminIntelligenceSignal>[];
    final fingerprints = <String>{};

    var candidateCount = 0;
    var dismissedCount = 0;
    var duplicateCount = 0;

    for (final original in signals) {
      final signal = _normalize(original);

      _validate(signal);

      if (signal.isDismissed) {
        dismissedCount++;
        continue;
      }

      if (signal.isCandidate) {
        candidateCount++;
        continue;
      }

      if (!signal.isVerified) {
        candidateCount++;
        continue;
      }

      if (!fingerprints.add(signal.fingerprint)) {
        duplicateCount++;
        continue;
      }

      findings.add(signal);
    }

    findings.sort(_compareFindings);

    final areas =
        adminAreasScanned
            .map((area) => area.trim().toLowerCase())
            .where((area) => area.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();

    final sources =
        sourcesScanned
            .map((source) => source.trim())
            .where((source) => source.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();

    return AdminIntelligenceReport(
      reportId: normalizedReportId,
      generatedAt: generatedAt,
      windowStart: windowStart,
      windowEnd: windowEnd,
      adminAreasScanned: List<String>.unmodifiable(areas),
      sourcesScanned: List<String>.unmodifiable(sources),
      findings: List<AdminIntelligenceSignal>.unmodifiable(findings),
      candidateCount: candidateCount,
      dismissedCount: dismissedCount,
      duplicateCount: duplicateCount,
      readOnly: true,
      automaticActionAllowed: false,
    );
  }

  AdminIntelligenceSignal _normalize(AdminIntelligenceSignal signal) {
    return signal.copyWith(
      signalId: signal.signalId.trim(),
      adminArea: signal.adminArea.trim().toLowerCase(),
      findingType: signal.findingType.trim().toLowerCase(),
      severity: signal.severity.trim().toLowerCase(),
      title: signal.title.trim(),
      summary: signal.summary.trim(),
      evidenceSummary: signal.evidenceSummary.trim(),
      recommendation: signal.recommendation.trim(),
      source: signal.source.trim(),
      verificationStatus: signal.verificationStatus.trim().toLowerCase(),
      confidence: signal.safeConfidence,
      requiresHumanReview: true,
    );
  }

  void _validate(AdminIntelligenceSignal signal) {
    if (signal.signalId.isEmpty) {
      throw ArgumentError('Admin Intelligence signal ID is required.');
    }

    if (signal.adminArea.isEmpty) {
      throw ArgumentError('Admin area is required.');
    }

    if (!signal.isValidType) {
      throw ArgumentError(
        'Unsupported Admin Intelligence finding type: '
        '${signal.findingType}',
      );
    }

    if (!signal.isValidSeverity) {
      throw ArgumentError(
        'Unsupported Admin Intelligence severity: '
        '${signal.severity}',
      );
    }

    if (!AdminIntelligenceVerificationStatus.values.contains(
      signal.verificationStatus,
    )) {
      throw ArgumentError(
        'Unsupported verification status: '
        '${signal.verificationStatus}',
      );
    }

    if (signal.title.isEmpty) {
      throw ArgumentError('Finding title is required.');
    }

    if (signal.summary.isEmpty) {
      throw ArgumentError('Finding summary is required.');
    }

    if (signal.evidenceSummary.isEmpty) {
      throw ArgumentError('Evidence summary is required.');
    }

    if (signal.recommendation.isEmpty) {
      throw ArgumentError('Recommendation is required.');
    }

    if (signal.source.isEmpty) {
      throw ArgumentError('Finding source is required.');
    }

    if (!signal.requiresHumanReview) {
      throw ArgumentError('Phase 38 findings must require human review.');
    }
  }

  int _compareFindings(
    AdminIntelligenceSignal first,
    AdminIntelligenceSignal second,
  ) {
    final severityCompare = AdminIntelligenceSeverity.rank(
      second.severity,
    ).compareTo(AdminIntelligenceSeverity.rank(first.severity));

    if (severityCompare != 0) {
      return severityCompare;
    }

    final confidenceCompare = second.safeConfidence.compareTo(
      first.safeConfidence,
    );

    if (confidenceCompare != 0) {
      return confidenceCompare;
    }

    final areaCompare = first.adminArea.compareTo(second.adminArea);

    if (areaCompare != 0) {
      return areaCompare;
    }

    return first.title.compareTo(second.title);
  }
}

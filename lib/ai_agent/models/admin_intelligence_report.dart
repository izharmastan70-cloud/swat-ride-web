import 'admin_intelligence_signal.dart';

class AdminIntelligenceReport {
  const AdminIntelligenceReport({
    required this.reportId,
    required this.generatedAt,
    required this.windowStart,
    required this.windowEnd,
    required this.adminAreasScanned,
    required this.sourcesScanned,
    required this.findings,
    required this.candidateCount,
    required this.dismissedCount,
    required this.duplicateCount,
    required this.readOnly,
    required this.automaticActionAllowed,
  });

  final String reportId;
  final DateTime generatedAt;
  final DateTime windowStart;
  final DateTime windowEnd;
  final List<String> adminAreasScanned;
  final List<String> sourcesScanned;
  final List<AdminIntelligenceSignal> findings;
  final int candidateCount;
  final int dismissedCount;
  final int duplicateCount;
  final bool readOnly;
  final bool automaticActionAllowed;

  int get verifiedFindingCount => findings.length;

  int countByType(String findingType) {
    return findings
        .where((finding) => finding.findingType == findingType)
        .length;
  }

  int countBySeverity(String severity) {
    return findings.where((finding) => finding.severity == severity).length;
  }

  int countByArea(String adminArea) {
    final normalized = adminArea.trim().toLowerCase();

    return findings
        .where(
          (finding) => finding.adminArea.trim().toLowerCase() == normalized,
        )
        .length;
  }

  bool get hasCriticalFindings {
    return findings.any(
      (finding) => finding.severity == AdminIntelligenceSeverity.critical,
    );
  }

  bool get isSafeReadOnlyContract => readOnly && !automaticActionAllowed;
}

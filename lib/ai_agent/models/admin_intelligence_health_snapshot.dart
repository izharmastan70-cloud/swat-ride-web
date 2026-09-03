import 'admin_intelligence_signal.dart';

class AdminIntelligenceEvidenceKind {
  const AdminIntelligenceEvidenceKind._();

  static const String exactPlaceholderMarker = 'exact_placeholder_marker';
  static const String missingScreenReference = 'missing_screen_reference';
  static const String missingServiceReference = 'missing_service_reference';
  static const String missingControlReference = 'missing_control_reference';
  static const String dataInvariantViolation = 'data_invariant_violation';
  static const String operationalThresholdBreach =
      'operational_threshold_breach';
  static const String explicitHumanVerification = 'explicit_human_verification';

  static const Set<String> values = <String>{
    exactPlaceholderMarker,
    missingScreenReference,
    missingServiceReference,
    missingControlReference,
    dataInvariantViolation,
    operationalThresholdBreach,
    explicitHumanVerification,
  };
}

class AdminIntelligenceHealthObservation {
  const AdminIntelligenceHealthObservation({
    required this.observationId,
    required this.adminArea,
    required this.findingType,
    required this.severity,
    required this.title,
    required this.summary,
    required this.evidenceSummary,
    required this.recommendation,
    required this.source,
    required this.evidenceKind,
    required this.observedAt,
    required this.evidenceCount,
    this.deterministicCheckPassed = false,
    this.humanVerified = false,
    this.confidence = 0,
  });

  final String observationId;
  final String adminArea;
  final String findingType;
  final String severity;
  final String title;
  final String summary;
  final String evidenceSummary;
  final String recommendation;
  final String source;
  final String evidenceKind;
  final DateTime observedAt;
  final int evidenceCount;

  /// True only when a deterministic invariant/threshold check actually passed.
  final bool deterministicCheckPassed;

  /// Explicit human verification can promote structural candidates.
  final bool humanVerified;

  final double confidence;

  bool get isStructuralFinding {
    return findingType == AdminIntelligenceFindingType.missingControl ||
        findingType == AdminIntelligenceFindingType.staleScreen ||
        findingType == AdminIntelligenceFindingType.disconnectedService;
  }

  bool get isRuntimeFinding {
    return findingType == AdminIntelligenceFindingType.unusualData ||
        findingType == AdminIntelligenceFindingType.operationalIssue;
  }

  double get safeConfidence => confidence.clamp(0.0, 1.0).toDouble();

  AdminIntelligenceHealthObservation copyWith({
    String? observationId,
    String? adminArea,
    String? findingType,
    String? severity,
    String? title,
    String? summary,
    String? evidenceSummary,
    String? recommendation,
    String? source,
    String? evidenceKind,
    DateTime? observedAt,
    int? evidenceCount,
    bool? deterministicCheckPassed,
    bool? humanVerified,
    double? confidence,
  }) {
    return AdminIntelligenceHealthObservation(
      observationId: observationId ?? this.observationId,
      adminArea: adminArea ?? this.adminArea,
      findingType: findingType ?? this.findingType,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      evidenceSummary: evidenceSummary ?? this.evidenceSummary,
      recommendation: recommendation ?? this.recommendation,
      source: source ?? this.source,
      evidenceKind: evidenceKind ?? this.evidenceKind,
      observedAt: observedAt ?? this.observedAt,
      evidenceCount: evidenceCount ?? this.evidenceCount,
      deterministicCheckPassed:
          deterministicCheckPassed ?? this.deterministicCheckPassed,
      humanVerified: humanVerified ?? this.humanVerified,
      confidence: confidence ?? this.confidence,
    );
  }
}

class AdminIntelligenceHealthSnapshot {
  const AdminIntelligenceHealthSnapshot({
    required this.snapshotId,
    required this.generatedAt,
    required this.windowStart,
    required this.windowEnd,
    required this.adminAreasScanned,
    required this.sourcesScanned,
    required this.observations,
    this.readOnly = true,
    this.automaticActionAllowed = false,
  });

  final String snapshotId;
  final DateTime generatedAt;
  final DateTime windowStart;
  final DateTime windowEnd;
  final List<String> adminAreasScanned;
  final List<String> sourcesScanned;
  final List<AdminIntelligenceHealthObservation> observations;

  final bool readOnly;
  final bool automaticActionAllowed;

  bool get isSafeReadOnlyContract => readOnly && !automaticActionAllowed;
}

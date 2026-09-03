class AdminIntelligenceFindingType {
  const AdminIntelligenceFindingType._();

  static const String missingControl = 'missing_control';
  static const String staleScreen = 'stale_screen';
  static const String disconnectedService = 'disconnected_service';
  static const String unusualData = 'unusual_data';
  static const String operationalIssue = 'operational_issue';

  static const Set<String> values = <String>{
    missingControl,
    staleScreen,
    disconnectedService,
    unusualData,
    operationalIssue,
  };
}

class AdminIntelligenceSeverity {
  const AdminIntelligenceSeverity._();

  static const String info = 'info';
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String critical = 'critical';

  static const Set<String> values = <String>{info, low, medium, high, critical};

  static int rank(String value) {
    switch (value) {
      case critical:
        return 5;
      case high:
        return 4;
      case medium:
        return 3;
      case low:
        return 2;
      case info:
      default:
        return 1;
    }
  }
}

class AdminIntelligenceVerificationStatus {
  const AdminIntelligenceVerificationStatus._();

  static const String candidate = 'candidate';
  static const String verified = 'verified';
  static const String dismissed = 'dismissed';

  static const Set<String> values = <String>{candidate, verified, dismissed};
}

class AdminIntelligenceSignal {
  const AdminIntelligenceSignal({
    required this.signalId,
    required this.adminArea,
    required this.findingType,
    required this.severity,
    required this.title,
    required this.summary,
    required this.evidenceSummary,
    required this.recommendation,
    required this.source,
    required this.observedAt,
    this.verificationStatus = AdminIntelligenceVerificationStatus.candidate,
    this.confidence = 0,
    this.requiresHumanReview = true,
  });

  final String signalId;
  final String adminArea;
  final String findingType;
  final String severity;
  final String title;
  final String summary;
  final String evidenceSummary;
  final String recommendation;
  final String source;
  final DateTime observedAt;
  final String verificationStatus;
  final double confidence;
  final bool requiresHumanReview;

  bool get isVerified =>
      verificationStatus == AdminIntelligenceVerificationStatus.verified;

  bool get isCandidate =>
      verificationStatus == AdminIntelligenceVerificationStatus.candidate;

  bool get isDismissed =>
      verificationStatus == AdminIntelligenceVerificationStatus.dismissed;

  bool get isValidType =>
      AdminIntelligenceFindingType.values.contains(findingType);

  bool get isValidSeverity =>
      AdminIntelligenceSeverity.values.contains(severity);

  double get safeConfidence => confidence.clamp(0.0, 1.0).toDouble();

  String get fingerprint {
    return <String>[
      adminArea.trim().toLowerCase(),
      findingType.trim().toLowerCase(),
      title.trim().toLowerCase(),
      source.trim().toLowerCase(),
    ].join('|');
  }

  AdminIntelligenceSignal copyWith({
    String? signalId,
    String? adminArea,
    String? findingType,
    String? severity,
    String? title,
    String? summary,
    String? evidenceSummary,
    String? recommendation,
    String? source,
    DateTime? observedAt,
    String? verificationStatus,
    double? confidence,
    bool? requiresHumanReview,
  }) {
    return AdminIntelligenceSignal(
      signalId: signalId ?? this.signalId,
      adminArea: adminArea ?? this.adminArea,
      findingType: findingType ?? this.findingType,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      evidenceSummary: evidenceSummary ?? this.evidenceSummary,
      recommendation: recommendation ?? this.recommendation,
      source: source ?? this.source,
      observedAt: observedAt ?? this.observedAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      confidence: confidence ?? this.confidence,
      requiresHumanReview: requiresHumanReview ?? this.requiresHumanReview,
    );
  }
}

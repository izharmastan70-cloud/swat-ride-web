class AgentOwnerWhatsAppReportSectionId {
  AgentOwnerWhatsAppReportSectionId._();

  static const String ride = 'ride';
  static const String driver = 'driver';
  static const String food = 'food';
  static const String hotel = 'hotel';
  static const String tour = 'tour';
  static const String cargo = 'cargo';
  static const String student = 'student';
  static const String revenue = 'revenue';
  static const String complaints = 'complaints';
  static const String refundsDisputes = 'refunds_disputes';
  static const String crashes = 'crashes';
  static const String security = 'security';
  static const String agentStatus = 'agent_status';
  static const String agentActivity = 'agent_activity';
  static const String tasks = 'tasks';
  static const String approvals = 'approvals';
  static const String developmentStatus = 'development_status';
  static const String recommendations = 'recommendations';

  static const Set<String> values = <String>{
    ride,
    driver,
    food,
    hotel,
    tour,
    cargo,
    student,
    revenue,
    complaints,
    refundsDisputes,
    crashes,
    security,
    agentStatus,
    agentActivity,
    tasks,
    approvals,
    developmentStatus,
    recommendations,
  };
}

class AgentOwnerWhatsAppVerifiedReportRequest {
  AgentOwnerWhatsAppVerifiedReportRequest({
    required String reportId,
    required String actorId,
    required this.fromInclusive,
    required this.toExclusive,
    required Iterable<String> requestedSectionIds,
    this.maxItemsPerSection = 50,
  }) : reportId = reportId.trim(),
       actorId = actorId.trim(),
       requestedSectionIds = Set<String>.unmodifiable(
         requestedSectionIds.map((String value) => value.trim()),
       );

  final String reportId;
  final String actorId;
  final DateTime fromInclusive;
  final DateTime toExclusive;
  final Set<String> requestedSectionIds;
  final int maxItemsPerSection;

  void validate() {
    if (reportId.isEmpty || actorId.isEmpty) {
      throw const AgentOwnerWhatsAppVerifiedReportException(
        'Owner report ID and actor ID cannot be empty.',
      );
    }

    if (!toExclusive.isAfter(fromInclusive)) {
      throw const AgentOwnerWhatsAppVerifiedReportException(
        'Owner report end time must be after start time.',
      );
    }

    if (toExclusive.difference(fromInclusive) > const Duration(days: 31)) {
      throw const AgentOwnerWhatsAppVerifiedReportException(
        'Owner report range cannot exceed 31 days.',
      );
    }

    if (requestedSectionIds.isEmpty) {
      throw const AgentOwnerWhatsAppVerifiedReportException(
        'Owner report must request at least one section.',
      );
    }

    final Set<String> unknown = requestedSectionIds.difference(
      AgentOwnerWhatsAppReportSectionId.values,
    );

    if (unknown.isNotEmpty) {
      throw AgentOwnerWhatsAppVerifiedReportException(
        'Unknown Owner report section(s): ${unknown.join(', ')}',
      );
    }

    if (maxItemsPerSection < 1 || maxItemsPerSection > 100) {
      throw const AgentOwnerWhatsAppVerifiedReportException(
        'Owner report maxItemsPerSection must be between 1 and 100.',
      );
    }
  }
}

class AgentOwnerWhatsAppVerifiedReportSectionResult {
  AgentOwnerWhatsAppVerifiedReportSectionResult._({
    required this.sectionId,
    required this.sourceId,
    required this.available,
    required this.backendVerified,
    required this.data,
    required this.warning,
    required this.generatedAt,
  });

  factory AgentOwnerWhatsAppVerifiedReportSectionResult.verified({
    required String sectionId,
    required String sourceId,
    required Map<String, dynamic> data,
    required DateTime generatedAt,
  }) {
    return AgentOwnerWhatsAppVerifiedReportSectionResult._(
      sectionId: sectionId.trim(),
      sourceId: sourceId.trim(),
      available: true,
      backendVerified: true,
      data: Map<String, dynamic>.unmodifiable(Map<String, dynamic>.from(data)),
      warning: '',
      generatedAt: generatedAt,
    );
  }

  factory AgentOwnerWhatsAppVerifiedReportSectionResult.unavailable({
    required String sectionId,
    required String sourceId,
    required String warning,
    required DateTime generatedAt,
  }) {
    return AgentOwnerWhatsAppVerifiedReportSectionResult._(
      sectionId: sectionId.trim(),
      sourceId: sourceId.trim(),
      available: false,
      backendVerified: false,
      data: const <String, dynamic>{},
      warning: warning.trim(),
      generatedAt: generatedAt,
    );
  }

  final String sectionId;
  final String sourceId;
  final bool available;
  final bool backendVerified;
  final Map<String, dynamic> data;
  final String warning;
  final DateTime generatedAt;

  void validate() {
    if (sectionId.isEmpty ||
        !AgentOwnerWhatsAppReportSectionId.values.contains(sectionId)) {
      throw const AgentOwnerWhatsAppVerifiedReportException(
        'Verified Owner report section ID is invalid.',
      );
    }

    if (sourceId.isEmpty) {
      throw const AgentOwnerWhatsAppVerifiedReportException(
        'Verified Owner report source ID cannot be empty.',
      );
    }

    if (available && !backendVerified) {
      throw const AgentOwnerWhatsAppVerifiedReportException(
        'Available Owner report data must be backend verified.',
      );
    }

    if (!available && data.isNotEmpty) {
      throw const AgentOwnerWhatsAppVerifiedReportException(
        'Unavailable Owner report section cannot contain data.',
      );
    }

    if (!available && warning.isEmpty) {
      throw const AgentOwnerWhatsAppVerifiedReportException(
        'Unavailable Owner report section requires a warning.',
      );
    }
  }
}

class AgentOwnerWhatsAppVerifiedReportStatus {
  AgentOwnerWhatsAppVerifiedReportStatus._();

  static const String ready = 'READY';
  static const String partial = 'PARTIAL';
  static const String unavailable = 'UNAVAILABLE';
  static const String denied = 'DENIED';
}

class AgentOwnerWhatsAppVerifiedReport {
  AgentOwnerWhatsAppVerifiedReport({
    required this.reportId,
    required this.status,
    required Iterable<AgentOwnerWhatsAppVerifiedReportSectionResult> sections,
    required Iterable<String> warnings,
    required this.generatedAt,
  }) : sections =
           List<AgentOwnerWhatsAppVerifiedReportSectionResult>.unmodifiable(
             sections,
           ),
       warnings = List<String>.unmodifiable(warnings);

  final String reportId;
  final String status;
  final List<AgentOwnerWhatsAppVerifiedReportSectionResult> sections;
  final List<String> warnings;
  final DateTime generatedAt;

  int get verifiedSectionCount => sections
      .where(
        (AgentOwnerWhatsAppVerifiedReportSectionResult section) =>
            section.available && section.backendVerified,
      )
      .length;

  int get unavailableSectionCount =>
      sections.where((section) => !section.available).length;

  bool get containsGuessedBusinessMetrics => false;
  bool get mayExecuteBusinessOrAdminWrite => false;
  bool get maySendWhatsApp => false;
  bool get mayCallProvider => false;
  bool get mayDeploy => false;
}

class AgentOwnerWhatsAppVerifiedReportException implements Exception {
  final String message;

  const AgentOwnerWhatsAppVerifiedReportException(this.message);

  @override
  String toString() => 'AgentOwnerWhatsAppVerifiedReportException: $message';
}

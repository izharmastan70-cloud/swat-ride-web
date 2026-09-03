class AgentVoiceSuperAdminSectionStatus {
  AgentVoiceSuperAdminSectionStatus._();

  static const String verified = 'VERIFIED';
  static const String unavailable = 'UNAVAILABLE';

  static const Set<String> values = <String>{verified, unavailable};

  static bool isValid(String value) => values.contains(value);
}

/// A Voice Super Admin section may contain only already-sanitized,
/// structured report data.
///
/// This object is NOT an authorization object and can never grant permission,
/// execute a connector, consume an approval, write business data, or mutate
/// Safety.
class AgentVoiceSuperAdminVerifiedSection {
  const AgentVoiceSuperAdminVerifiedSection({
    required this.moduleId,
    required this.status,
    required this.sourceId,
    required this.summaryText,
    required this.facts,
    required this.verifiedAt,
    this.unavailableReason,
  });

  factory AgentVoiceSuperAdminVerifiedSection.verified({
    required String moduleId,
    required String sourceId,
    required String summaryText,
    required Map<String, Object?> facts,
    required DateTime verifiedAt,
  }) {
    return AgentVoiceSuperAdminVerifiedSection(
      moduleId: moduleId,
      status: AgentVoiceSuperAdminSectionStatus.verified,
      sourceId: sourceId,
      summaryText: summaryText,
      facts: Map<String, Object?>.unmodifiable(facts),
      verifiedAt: verifiedAt,
    );
  }

  factory AgentVoiceSuperAdminVerifiedSection.unavailable({
    required String moduleId,
    required String sourceId,
    required String reason,
    required DateTime verifiedAt,
  }) {
    return AgentVoiceSuperAdminVerifiedSection(
      moduleId: moduleId,
      status: AgentVoiceSuperAdminSectionStatus.unavailable,
      sourceId: sourceId,
      summaryText: 'UNAVAILABLE',
      facts: const <String, Object?>{},
      verifiedAt: verifiedAt,
      unavailableReason: reason,
    );
  }

  final String moduleId;
  final String status;
  final String sourceId;
  final String summaryText;
  final Map<String, Object?> facts;
  final DateTime verifiedAt;
  final String? unavailableReason;

  bool get isVerified => status == AgentVoiceSuperAdminSectionStatus.verified;
  bool get isUnavailable =>
      status == AgentVoiceSuperAdminSectionStatus.unavailable;

  bool get grantsAuthority => false;
  bool get mayExecuteConnector => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayMutateSafety => false;
  bool get mayCallProvider => false;
  bool get mayDeploy => false;

  void validate() {
    if (moduleId.trim().isEmpty ||
        !AgentVoiceSuperAdminSectionStatus.isValid(status) ||
        sourceId.trim().isEmpty ||
        summaryText.trim().isEmpty) {
      throw const AgentVoiceSuperAdminVerifiedSectionException(
        'Voice Super Admin verified section is invalid.',
      );
    }

    if (isVerified && unavailableReason != null) {
      throw const AgentVoiceSuperAdminVerifiedSectionException(
        'Verified section cannot carry an unavailable reason.',
      );
    }

    if (isUnavailable &&
        (unavailableReason == null || unavailableReason!.trim().isEmpty)) {
      throw const AgentVoiceSuperAdminVerifiedSectionException(
        'Unavailable section must explain why it is unavailable.',
      );
    }
  }
}

class AgentVoiceSuperAdminVerifiedSectionException implements Exception {
  const AgentVoiceSuperAdminVerifiedSectionException(this.message);

  final String message;

  @override
  String toString() => 'AgentVoiceSuperAdminVerifiedSectionException: $message';
}

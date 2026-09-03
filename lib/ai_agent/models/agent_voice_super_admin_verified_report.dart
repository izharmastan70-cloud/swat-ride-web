import 'agent_voice_super_admin_verified_section.dart';

class AgentVoiceSuperAdminReportStatus {
  AgentVoiceSuperAdminReportStatus._();

  static const String ready = 'READY';
  static const String partial = 'PARTIAL';
  static const String unavailable = 'UNAVAILABLE';
}

class AgentVoiceSuperAdminVerifiedReport {
  const AgentVoiceSuperAdminVerifiedReport({
    required this.reportId,
    required this.status,
    required this.sections,
    required this.readableText,
    required this.createdAt,
  });

  final String reportId;
  final String status;
  final List<AgentVoiceSuperAdminVerifiedSection> sections;

  /// Mandatory source-of-truth text for screen display and optional future
  /// voice playback.
  final String readableText;

  final DateTime createdAt;

  bool get readableTextMandatory => true;
  bool get voicePlaybackMustDeriveFromReadableText => true;

  bool get mayExecuteConnector => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayMutateSafety => false;
  bool get mayCallProvider => false;
  bool get mayDeploy => false;

  void validate() {
    if (reportId.trim().isEmpty ||
        sections.isEmpty ||
        readableText.trim().isEmpty) {
      throw const AgentVoiceSuperAdminVerifiedReportException(
        'Voice Super Admin verified report is invalid.',
      );
    }

    for (final AgentVoiceSuperAdminVerifiedSection section in sections) {
      section.validate();
    }
  }
}

class AgentVoiceSuperAdminVerifiedReportException implements Exception {
  const AgentVoiceSuperAdminVerifiedReportException(this.message);

  final String message;

  @override
  String toString() => 'AgentVoiceSuperAdminVerifiedReportException: $message';
}

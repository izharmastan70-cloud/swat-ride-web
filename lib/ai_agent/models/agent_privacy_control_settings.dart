import '../constants/agent_privacy_control_export_constants.dart';

class AgentPrivacyControlSettings {
  AgentPrivacyControlSettings({
    required this.settingsId,
    required this.updatedByRole,
    required this.chatRetentionDays,
    required this.callTranscriptRetentionDays,
    required this.callRecordingRetentionDays,
    required this.emailRetentionDays,
    required this.whatsappAiRetentionDays,
    required this.dataExportEnabled,
    required this.strictDomainExportEnabled,
    required this.updatedAtUtc,
  }) {
    validate();
  }

  final String settingsId;
  final String updatedByRole;

  final int chatRetentionDays;
  final int callTranscriptRetentionDays;
  final int callRecordingRetentionDays;
  final int emailRetentionDays;
  final int whatsappAiRetentionDays;

  final bool dataExportEnabled;

  /// This is only a master eligibility switch. Strict-domain authorization
  /// is still required per export request.
  final bool strictDomainExportEnabled;

  final DateTime updatedAtUtc;

  bool get foundationPreviewOnly => true;
  bool get productionApplied => false;
  bool get firestoreWritePerformed => false;
  bool get permissionGranted => false;
  bool get approvalConsumed => false;
  bool get runtimeGateOverridden => false;
  bool get deletionPerformed => false;

  void validate() {
    final idPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');

    final bool validId =
        settingsId.isNotEmpty &&
        settingsId == settingsId.trim() &&
        settingsId.length <=
            AgentPrivacyControlSettingsLimits.opaqueIdMaxLength &&
        idPattern.hasMatch(settingsId);

    if (!validId ||
        !AgentPrivacyControlRole.values.contains(updatedByRole) ||
        updatedByRole == AgentPrivacyControlRole.user ||
        chatRetentionDays < 0 ||
        callTranscriptRetentionDays < 0 ||
        callRecordingRetentionDays < 0 ||
        emailRetentionDays < 0 ||
        whatsappAiRetentionDays < 0 ||
        !updatedAtUtc.isUtc) {
      throw const FormatException('Invalid Agent privacy control settings.');
    }
  }
}

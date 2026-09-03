import '../constants/agent_privacy_retention_classification_constants.dart';

class AgentChannelRetentionPolicy {
  AgentChannelRetentionPolicy({
    required this.channel,
    required this.retentionMode,
    required this.foundationDefaultDays,
    required this.maximumOwnerConfigurableDays,
    required this.rawContentRetentionEnabledByDefault,
    required this.redactionRequiredForTraining,
    required this.explicitConsentRequiredForTraining,
    required this.trainingMode,
  }) {
    validate();
  }

  final String channel;
  final String retentionMode;

  final int foundationDefaultDays;
  final int maximumOwnerConfigurableDays;

  final bool rawContentRetentionEnabledByDefault;
  final bool redactionRequiredForTraining;
  final bool explicitConsentRequiredForTraining;
  final String trainingMode;

  bool get foundationOnly => true;
  bool get productionApplied => false;
  bool get deletionPerformed => false;
  bool get purgePerformed => false;
  bool get firestoreWritePerformed => false;
  bool get protectedEvidenceOverrideAllowed => false;
  bool get permissionAuthorityGranted => false;
  bool get approvalAuthorityGranted => false;
  bool get deploymentAuthorityGranted => false;

  bool isOwnerRequestedDaysWithinFoundationBounds(int days) {
    return days >= 0 && days <= maximumOwnerConfigurableDays;
  }

  void validate() {
    if (!AgentPrivacyChannel.values.contains(channel) ||
        !AgentPrivacyRetentionMode.values.contains(retentionMode) ||
        !AgentPrivacyTrainingMode.values.contains(trainingMode) ||
        foundationDefaultDays < 0 ||
        maximumOwnerConfigurableDays < 0 ||
        foundationDefaultDays > maximumOwnerConfigurableDays) {
      throw const FormatException('Invalid Agent channel retention policy.');
    }

    if (channel == AgentPrivacyChannel.callRecording &&
        (rawContentRetentionEnabledByDefault ||
            trainingMode != AgentPrivacyTrainingMode.ineligibleSensitive)) {
      throw const FormatException(
        'Raw call recording must default OFF and remain training-ineligible.',
      );
    }

    if (trainingMode == AgentPrivacyTrainingMode.redactedConsentRequired &&
        (!redactionRequiredForTraining ||
            !explicitConsentRequiredForTraining)) {
      throw const FormatException(
        'Real channel training eligibility requires redaction and consent.',
      );
    }
  }
}

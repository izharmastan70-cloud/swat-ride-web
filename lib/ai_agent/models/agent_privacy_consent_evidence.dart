import '../constants/agent_privacy_consent_training_constants.dart';
import '../constants/agent_privacy_retention_classification_constants.dart';

class AgentPrivacyConsentEvidence {
  AgentPrivacyConsentEvidence({
    required this.consentId,
    required this.subjectRef,
    required this.channel,
    required this.dataKind,
    required this.purpose,
    required this.evidenceFingerprintSha256,
    required this.status,
    required this.grantedAtUtc,
    required this.expiresAtUtc,
  }) {
    validate();
  }

  final String consentId;
  final String subjectRef;
  final String channel;
  final String dataKind;
  final String purpose;
  final String evidenceFingerprintSha256;
  final String status;
  final DateTime grantedAtUtc;
  final DateTime expiresAtUtc;

  bool get explicitlyGranted => status == AgentPrivacyConsentStatus.granted;

  bool get metadataOnly => true;
  bool get rawConversationStored => false;
  bool get rawRecordingStored => false;
  bool get secretsStored => false;
  bool get tokensStored => false;

  bool get permissionAuthorityGranted => false;
  bool get approvalAuthorityGranted => false;
  bool get trainingExecutionPerformed => false;
  bool get deploymentAuthorityGranted => false;

  void validate() {
    final idPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');
    final shaPattern = RegExp(r'^[A-Fa-f0-9]{64}$');

    bool safeId(String value) =>
        value.isNotEmpty &&
        value == value.trim() &&
        value.length <= AgentPrivacyConsentLimits.opaqueIdMaxLength &&
        idPattern.hasMatch(value);

    final validity = expiresAtUtc.difference(grantedAtUtc);

    if (!safeId(consentId) ||
        !safeId(subjectRef) ||
        !AgentPrivacyChannel.values.contains(channel) ||
        !AgentPrivacyDataKind.values.contains(dataKind) ||
        purpose != AgentPrivacyConsentPurpose.trainingEligibilityReview ||
        !AgentPrivacyConsentStatus.values.contains(status) ||
        !shaPattern.hasMatch(evidenceFingerprintSha256) ||
        !grantedAtUtc.isUtc ||
        !expiresAtUtc.isUtc ||
        !expiresAtUtc.isAfter(grantedAtUtc) ||
        validity > AgentPrivacyConsentLimits.maximumConsentValidity) {
      throw const FormatException('Invalid privacy consent evidence.');
    }
  }
}

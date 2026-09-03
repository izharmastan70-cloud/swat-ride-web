import '../constants/agent_privacy_consent_training_constants.dart';
import '../constants/agent_privacy_retention_classification_constants.dart';

class AgentPrivacyRedactionEvidence {
  AgentPrivacyRedactionEvidence({
    required this.redactionId,
    required this.subjectRef,
    required this.channel,
    required this.dataKind,
    required this.sourceFingerprintSha256,
    required this.redactedFingerprintSha256,
    required this.status,
    required this.directIdentifiersRemoved,
    required this.contactIdentifiersRemoved,
    required this.preciseLocationRemoved,
    required this.secretsRemoved,
    required this.authTokensRemoved,
    required this.approvalTokensRemoved,
    required this.permissionTokensRemoved,
    required this.paymentCredentialsRemoved,
    required this.verifiedAtUtc,
  }) {
    validate();
  }

  final String redactionId;
  final String subjectRef;
  final String channel;
  final String dataKind;
  final String sourceFingerprintSha256;
  final String redactedFingerprintSha256;
  final String status;

  final bool directIdentifiersRemoved;
  final bool contactIdentifiersRemoved;
  final bool preciseLocationRemoved;
  final bool secretsRemoved;
  final bool authTokensRemoved;
  final bool approvalTokensRemoved;
  final bool permissionTokensRemoved;
  final bool paymentCredentialsRemoved;

  final DateTime verifiedAtUtc;

  bool get verified => status == AgentPrivacyRedactionStatus.verified;

  bool get allCriticalFieldsRemoved =>
      directIdentifiersRemoved &&
      contactIdentifiersRemoved &&
      preciseLocationRemoved &&
      secretsRemoved &&
      authTokensRemoved &&
      approvalTokensRemoved &&
      permissionTokensRemoved &&
      paymentCredentialsRemoved;

  bool get safeForTrainingReview => verified && allCriticalFieldsRemoved;

  bool get storesRawPayload => false;
  bool get storesSecrets => false;
  bool get storesTokens => false;
  bool get storesPaymentCredentials => false;

  bool get trainingExecutionPerformed => false;
  bool get providerCallPerformed => false;
  bool get deletionPerformed => false;

  void validate() {
    final idPattern = RegExp(r'^[A-Za-z0-9_.:-]+$');
    final shaPattern = RegExp(r'^[A-Fa-f0-9]{64}$');

    bool safeId(String value) =>
        value.isNotEmpty &&
        value == value.trim() &&
        value.length <= AgentPrivacyConsentLimits.opaqueIdMaxLength &&
        idPattern.hasMatch(value);

    if (!safeId(redactionId) ||
        !safeId(subjectRef) ||
        !AgentPrivacyChannel.values.contains(channel) ||
        !AgentPrivacyDataKind.values.contains(dataKind) ||
        !AgentPrivacyRedactionStatus.values.contains(status) ||
        !shaPattern.hasMatch(sourceFingerprintSha256) ||
        !shaPattern.hasMatch(redactedFingerprintSha256) ||
        sourceFingerprintSha256 == redactedFingerprintSha256 ||
        !verifiedAtUtc.isUtc) {
      throw const FormatException('Invalid privacy redaction evidence.');
    }
  }
}

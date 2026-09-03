import '../constants/agent_privacy_retention_classification_constants.dart';

class AgentPrivacyDataClassification {
  AgentPrivacyDataClassification({
    required this.dataKind,
    required this.sensitivityTier,
    required this.trainingMode,
    required this.accessMode,
    required this.redactionRequired,
    required this.explicitConsentRequiredForRealTraining,
    required this.protectedEvidence,
    required this.rawProviderProjectionAllowed,
  }) {
    validate();
  }

  final String dataKind;
  final String sensitivityTier;
  final String trainingMode;
  final String accessMode;

  final bool redactionRequired;
  final bool explicitConsentRequiredForRealTraining;
  final bool protectedEvidence;
  final bool rawProviderProjectionAllowed;

  bool get minimumNecessaryRequired => true;

  bool get realDataTrainingAllowedWithoutConsent => false;

  bool get trainingDeploymentAuthorityGranted => false;
  bool get businessPermissionGranted => false;
  bool get approvalAuthorityGranted => false;
  bool get providerExecutionGranted => false;
  bool get dataDeletionPerformed => false;
  bool get dataPurgePerformed => false;
  bool get retentionWritePerformed => false;

  bool get restrictedCritical =>
      sensitivityTier == AgentPrivacySensitivityTier.restrictedCritical;

  bool get strictlySensitive =>
      AgentPrivacySensitivityTier.rank(sensitivityTier) >=
      AgentPrivacySensitivityTier.rank(
        AgentPrivacySensitivityTier.highlySensitive,
      );

  bool get rawDataBlocked =>
      accessMode == AgentPrivacyAccessMode.blockedRaw ||
      !rawProviderProjectionAllowed;

  bool canUseRealDataForTraining({
    required bool consentGranted,
    required bool redactionVerified,
  }) {
    if (trainingMode != AgentPrivacyTrainingMode.redactedConsentRequired) {
      return false;
    }

    return consentGranted && redactionVerified && !restrictedCritical;
  }

  void validate() {
    if (!AgentPrivacyDataKind.values.contains(dataKind) ||
        !AgentPrivacySensitivityTier.values.contains(sensitivityTier) ||
        !AgentPrivacyTrainingMode.values.contains(trainingMode) ||
        !AgentPrivacyAccessMode.values.contains(accessMode)) {
      throw const FormatException('Invalid Agent privacy data classification.');
    }

    if (restrictedCritical &&
        trainingMode != AgentPrivacyTrainingMode.ineligibleSecret &&
        trainingMode != AgentPrivacyTrainingMode.ineligibleSensitive) {
      throw const FormatException(
        'Restricted critical data cannot be training eligible.',
      );
    }

    if (trainingMode == AgentPrivacyTrainingMode.redactedConsentRequired &&
        (!redactionRequired || !explicitConsentRequiredForRealTraining)) {
      throw const FormatException(
        'Real-data training eligibility requires redaction and consent.',
      );
    }

    if (protectedEvidence && !strictlySensitive) {
      throw const FormatException(
        'Protected evidence must use a strict sensitivity tier.',
      );
    }
  }
}

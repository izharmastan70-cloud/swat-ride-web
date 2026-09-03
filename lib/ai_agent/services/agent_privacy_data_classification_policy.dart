import '../constants/agent_privacy_retention_classification_constants.dart';
import '../models/agent_privacy_data_classification.dart';

class AgentPrivacyDataClassificationPolicy {
  const AgentPrivacyDataClassificationPolicy();

  AgentPrivacyDataClassification classify(String dataKind) {
    switch (dataKind) {
      case AgentPrivacyDataKind.operationalMetadata:
        return _classification(
          dataKind: dataKind,
          tier: AgentPrivacySensitivityTier.internal,
          trainingMode: AgentPrivacyTrainingMode.syntheticOnly,
          accessMode: AgentPrivacyAccessMode.minimumNecessary,
          redactionRequired: false,
          consentRequired: false,
          protectedEvidence: false,
          rawProviderProjectionAllowed: false,
        );

      case AgentPrivacyDataKind.chatContent:
      case AgentPrivacyDataKind.emailContent:
      case AgentPrivacyDataKind.whatsappContent:
      case AgentPrivacyDataKind.callTranscript:
        return _classification(
          dataKind: dataKind,
          tier: AgentPrivacySensitivityTier.private,
          trainingMode: AgentPrivacyTrainingMode.redactedConsentRequired,
          accessMode: AgentPrivacyAccessMode.verifiedProjectionOnly,
          redactionRequired: true,
          consentRequired: true,
          protectedEvidence: false,
          rawProviderProjectionAllowed: false,
        );

      case AgentPrivacyDataKind.personalContact:
      case AgentPrivacyDataKind.preciseLocation:
        return _classification(
          dataKind: dataKind,
          tier: AgentPrivacySensitivityTier.highlySensitive,
          trainingMode: AgentPrivacyTrainingMode.ineligibleSensitive,
          accessMode: AgentPrivacyAccessMode.verifiedProjectionOnly,
          redactionRequired: true,
          consentRequired: false,
          protectedEvidence: false,
          rawProviderProjectionAllowed: false,
        );

      case AgentPrivacyDataKind.studentData:
      case AgentPrivacyDataKind.safetyEmergencyData:
      case AgentPrivacyDataKind.financialData:
        return _classification(
          dataKind: dataKind,
          tier: AgentPrivacySensitivityTier.highlySensitive,
          trainingMode: AgentPrivacyTrainingMode.ineligibleSensitive,
          accessMode: AgentPrivacyAccessMode.verifiedProjectionOnly,
          redactionRequired: true,
          consentRequired: false,
          protectedEvidence: false,
          rawProviderProjectionAllowed: false,
        );

      case AgentPrivacyDataKind.callRecording:
        return _classification(
          dataKind: dataKind,
          tier: AgentPrivacySensitivityTier.restrictedCritical,
          trainingMode: AgentPrivacyTrainingMode.ineligibleSensitive,
          accessMode: AgentPrivacyAccessMode.blockedRaw,
          redactionRequired: true,
          consentRequired: false,
          protectedEvidence: false,
          rawProviderProjectionAllowed: false,
        );

      case AgentPrivacyDataKind.authSecret:
      case AgentPrivacyDataKind.apiCredential:
      case AgentPrivacyDataKind.paymentCredential:
        return _classification(
          dataKind: dataKind,
          tier: AgentPrivacySensitivityTier.restrictedCritical,
          trainingMode: AgentPrivacyTrainingMode.ineligibleSecret,
          accessMode: AgentPrivacyAccessMode.blockedRaw,
          redactionRequired: true,
          consentRequired: false,
          protectedEvidence: false,
          rawProviderProjectionAllowed: false,
        );

      case AgentPrivacyDataKind.auditEvidence:
      case AgentPrivacyDataKind.securityEvidence:
      case AgentPrivacyDataKind.financeEvidence:
        return _classification(
          dataKind: dataKind,
          tier: AgentPrivacySensitivityTier.highlySensitive,
          trainingMode: AgentPrivacyTrainingMode.ineligibleSensitive,
          accessMode: AgentPrivacyAccessMode.verifiedProjectionOnly,
          redactionRequired: true,
          consentRequired: false,
          protectedEvidence: true,
          rawProviderProjectionAllowed: false,
        );

      default:
        throw const FormatException('Unknown Agent privacy data kind.');
    }
  }

  AgentPrivacyDataClassification _classification({
    required String dataKind,
    required String tier,
    required String trainingMode,
    required String accessMode,
    required bool redactionRequired,
    required bool consentRequired,
    required bool protectedEvidence,
    required bool rawProviderProjectionAllowed,
  }) {
    return AgentPrivacyDataClassification(
      dataKind: dataKind,
      sensitivityTier: tier,
      trainingMode: trainingMode,
      accessMode: accessMode,
      redactionRequired: redactionRequired,
      explicitConsentRequiredForRealTraining: consentRequired,
      protectedEvidence: protectedEvidence,
      rawProviderProjectionAllowed: rawProviderProjectionAllowed,
    );
  }

  bool get expandsRuntimePermissions => false;
  bool get consumesApproval => false;
  bool get callsProvider => false;
  bool get writesRetentionSettings => false;
  bool get deletesData => false;
  bool get purgesData => false;
  bool get trainsModel => false;
  bool get deploysTrainingChange => false;
}

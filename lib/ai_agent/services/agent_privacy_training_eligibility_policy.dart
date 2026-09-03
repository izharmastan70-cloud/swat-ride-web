import '../constants/agent_privacy_consent_training_constants.dart';
import '../constants/agent_privacy_retention_classification_constants.dart';
import '../models/agent_privacy_consent_evidence.dart';
import '../models/agent_privacy_data_classification.dart';
import '../models/agent_privacy_redaction_evidence.dart';
import '../models/agent_privacy_training_eligibility.dart';
import 'agent_privacy_consent_policy.dart';
import 'agent_privacy_redaction_gate_policy.dart';

class AgentPrivacyTrainingEligibilityPolicy {
  const AgentPrivacyTrainingEligibilityPolicy({
    this.consentPolicy = const AgentPrivacyConsentPolicy(),
    this.redactionPolicy = const AgentPrivacyRedactionGatePolicy(),
  });

  final AgentPrivacyConsentPolicy consentPolicy;
  final AgentPrivacyRedactionGatePolicy redactionPolicy;

  AgentPrivacyTrainingEligibility evaluate({
    required AgentPrivacyDataClassification classification,
    required String subjectRef,
    required String channel,
    required String sourceFingerprintSha256,
    required bool syntheticData,
    AgentPrivacyConsentEvidence? consent,
    AgentPrivacyRedactionEvidence? redaction,
    required DateTime evaluatedAtUtc,
  }) {
    try {
      classification.validate();
    } catch (_) {
      return _result(
        classification,
        channel,
        AgentPrivacyTrainingEligibilityStatus.blockedInvalidInput,
        'invalid_classification',
        !syntheticData,
      );
    }

    if (!evaluatedAtUtc.isUtc ||
        subjectRef.trim().isEmpty ||
        channel.trim().isEmpty ||
        sourceFingerprintSha256.trim().isEmpty) {
      return _result(
        classification,
        channel,
        AgentPrivacyTrainingEligibilityStatus.blockedInvalidInput,
        'invalid_eligibility_input',
        !syntheticData,
      );
    }

    if (syntheticData) {
      return _result(
        classification,
        channel,
        AgentPrivacyTrainingEligibilityStatus.eligibleSyntheticOnly,
        'synthetic_data_preferred',
        false,
      );
    }

    if (classification.trainingMode ==
        AgentPrivacyTrainingMode.ineligibleSecret) {
      return _result(
        classification,
        channel,
        AgentPrivacyTrainingEligibilityStatus.blockedSecret,
        'secret_or_credential_training_forbidden',
        true,
      );
    }

    if (classification.trainingMode ==
        AgentPrivacyTrainingMode.ineligibleSensitive) {
      return _result(
        classification,
        channel,
        AgentPrivacyTrainingEligibilityStatus.blockedSensitive,
        'sensitive_real_data_training_forbidden',
        true,
      );
    }

    if (classification.trainingMode == AgentPrivacyTrainingMode.syntheticOnly) {
      return _result(
        classification,
        channel,
        AgentPrivacyTrainingEligibilityStatus.eligibleSyntheticOnly,
        'classification_synthetic_only',
        false,
      );
    }

    if (classification.trainingMode !=
        AgentPrivacyTrainingMode.redactedConsentRequired) {
      return _result(
        classification,
        channel,
        AgentPrivacyTrainingEligibilityStatus.blockedInvalidInput,
        'unknown_training_mode',
        true,
      );
    }

    if (consent == null) {
      return _result(
        classification,
        channel,
        AgentPrivacyTrainingEligibilityStatus.blockedConsent,
        'explicit_consent_missing',
        true,
      );
    }

    if (redaction == null) {
      return _result(
        classification,
        channel,
        AgentPrivacyTrainingEligibilityStatus.blockedRedaction,
        'redaction_evidence_missing',
        true,
      );
    }

    final consentOk = consentPolicy.isUsable(
      consent: consent,
      subjectRef: subjectRef,
      channel: channel,
      dataKind: classification.dataKind,
      sourceFingerprintSha256: sourceFingerprintSha256,
      evaluatedAtUtc: evaluatedAtUtc,
    );

    if (!consentOk) {
      final expired = !evaluatedAtUtc.isBefore(consent.expiresAtUtc);

      return _result(
        classification,
        channel,
        expired
            ? AgentPrivacyTrainingEligibilityStatus.blockedExpired
            : AgentPrivacyTrainingEligibilityStatus.blockedConsent,
        expired ? 'consent_expired' : 'consent_invalid_or_mismatched',
        true,
      );
    }

    final redactionOk = redactionPolicy.isUsable(
      redaction: redaction,
      subjectRef: subjectRef,
      channel: channel,
      dataKind: classification.dataKind,
      sourceFingerprintSha256: sourceFingerprintSha256,
      evaluatedAtUtc: evaluatedAtUtc,
    );

    if (!redactionOk) {
      final mismatch =
          redaction.subjectRef != subjectRef ||
          redaction.channel != channel ||
          redaction.dataKind != classification.dataKind ||
          redaction.sourceFingerprintSha256 != sourceFingerprintSha256;

      return _result(
        classification,
        channel,
        mismatch
            ? AgentPrivacyTrainingEligibilityStatus.blockedMismatch
            : AgentPrivacyTrainingEligibilityStatus.blockedRedaction,
        mismatch
            ? 'redaction_identity_or_fingerprint_mismatch'
            : 'redaction_failed_stale_or_incomplete',
        true,
      );
    }

    return _result(
      classification,
      channel,
      AgentPrivacyTrainingEligibilityStatus.eligibleRealData,
      'consent_and_redaction_verified_for_review_only',
      true,
    );
  }

  AgentPrivacyTrainingEligibility _result(
    AgentPrivacyDataClassification classification,
    String channel,
    String status,
    String reason,
    bool usesRealData,
  ) {
    return AgentPrivacyTrainingEligibility(
      status: status,
      dataKind: classification.dataKind,
      channel: channel,
      reasonCode: reason,
      usesRealData: usesRealData,
    );
  }

  bool get decisionOnly => true;
  bool get trainsModel => false;
  bool get mutatesPrompt => false;
  bool get callsProvider => false;
  bool get deploysChange => false;
  bool get activatesProduction => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get writesConsent => false;
  bool get writesRedactionData => false;
  bool get changesRetention => false;
  bool get deletesData => false;
  bool get writesBusinessData => false;
}

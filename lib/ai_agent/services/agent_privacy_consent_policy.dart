import '../constants/agent_privacy_consent_training_constants.dart';
import '../models/agent_privacy_consent_evidence.dart';

class AgentPrivacyConsentPolicy {
  const AgentPrivacyConsentPolicy();

  bool isUsable({
    required AgentPrivacyConsentEvidence consent,
    required String subjectRef,
    required String channel,
    required String dataKind,
    required String sourceFingerprintSha256,
    required DateTime evaluatedAtUtc,
  }) {
    try {
      consent.validate();
    } catch (_) {
      return false;
    }

    if (!evaluatedAtUtc.isUtc || !consent.explicitlyGranted) {
      return false;
    }

    if (consent.subjectRef != subjectRef ||
        consent.channel != channel ||
        consent.dataKind != dataKind ||
        consent.purpose !=
            AgentPrivacyConsentPurpose.trainingEligibilityReview ||
        consent.evidenceFingerprintSha256 != sourceFingerprintSha256) {
      return false;
    }

    if (consent.grantedAtUtc.isAfter(
      evaluatedAtUtc.add(AgentPrivacyConsentLimits.maximumFutureClockSkew),
    )) {
      return false;
    }

    return evaluatedAtUtc.isBefore(consent.expiresAtUtc);
  }

  bool get writesConsent => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get trainsModel => false;
  bool get deploysChange => false;
  bool get deletesData => false;
}

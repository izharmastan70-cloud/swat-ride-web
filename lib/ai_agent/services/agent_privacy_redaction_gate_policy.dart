import '../constants/agent_privacy_consent_training_constants.dart';
import '../models/agent_privacy_redaction_evidence.dart';

class AgentPrivacyRedactionGatePolicy {
  const AgentPrivacyRedactionGatePolicy();

  bool isUsable({
    required AgentPrivacyRedactionEvidence redaction,
    required String subjectRef,
    required String channel,
    required String dataKind,
    required String sourceFingerprintSha256,
    required DateTime evaluatedAtUtc,
  }) {
    try {
      redaction.validate();
    } catch (_) {
      return false;
    }

    if (!evaluatedAtUtc.isUtc || !redaction.safeForTrainingReview) {
      return false;
    }

    if (redaction.subjectRef != subjectRef ||
        redaction.channel != channel ||
        redaction.dataKind != dataKind ||
        redaction.sourceFingerprintSha256 != sourceFingerprintSha256) {
      return false;
    }

    if (redaction.verifiedAtUtc.isAfter(
      evaluatedAtUtc.add(AgentPrivacyConsentLimits.maximumFutureClockSkew),
    )) {
      return false;
    }

    return evaluatedAtUtc.difference(redaction.verifiedAtUtc) <=
        AgentPrivacyConsentLimits.maximumRedactionEvidenceAge;
  }

  bool get storesRawPayload => false;
  bool get writesRedactedPayload => false;
  bool get callsProvider => false;
  bool get trainsModel => false;
  bool get deploysChange => false;
  bool get deletesData => false;
}

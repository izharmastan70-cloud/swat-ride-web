import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_privacy_consent_training_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_privacy_retention_classification_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_privacy_consent_evidence.dart';
import 'package:swat_ride/ai_agent/models/agent_privacy_redaction_evidence.dart';
import 'package:swat_ride/ai_agent/services/agent_privacy_data_classification_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_privacy_training_eligibility_policy.dart';

void main() {
  const classificationPolicy = AgentPrivacyDataClassificationPolicy();
  const eligibilityPolicy = AgentPrivacyTrainingEligibilityPolicy();

  const sourceSha =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
  const redactedSha =
      'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';

  final evaluatedAtUtc = DateTime.utc(2026, 8, 24, 4);

  AgentPrivacyConsentEvidence consent({
    String status = AgentPrivacyConsentStatus.granted,
    String subjectRef = 'customer:123',
    String channel = AgentPrivacyChannel.chat,
    String dataKind = AgentPrivacyDataKind.chatContent,
    String fingerprint = sourceSha,
    DateTime? expiresAtUtc,
  }) {
    final granted = DateTime.utc(2026, 8, 24, 3);

    return AgentPrivacyConsentEvidence(
      consentId: 'consent:customer:123:training',
      subjectRef: subjectRef,
      channel: channel,
      dataKind: dataKind,
      purpose: AgentPrivacyConsentPurpose.trainingEligibilityReview,
      evidenceFingerprintSha256: fingerprint,
      status: status,
      grantedAtUtc: granted,
      expiresAtUtc: expiresAtUtc ?? granted.add(const Duration(days: 30)),
    );
  }

  AgentPrivacyRedactionEvidence redaction({
    String subjectRef = 'customer:123',
    String channel = AgentPrivacyChannel.chat,
    String dataKind = AgentPrivacyDataKind.chatContent,
    String sourceFingerprint = sourceSha,
    bool paymentCredentialsRemoved = true,
    DateTime? verifiedAtUtc,
  }) {
    return AgentPrivacyRedactionEvidence(
      redactionId: 'redaction:customer:123:training',
      subjectRef: subjectRef,
      channel: channel,
      dataKind: dataKind,
      sourceFingerprintSha256: sourceFingerprint,
      redactedFingerprintSha256: redactedSha,
      status: AgentPrivacyRedactionStatus.verified,
      directIdentifiersRemoved: true,
      contactIdentifiersRemoved: true,
      preciseLocationRemoved: true,
      secretsRemoved: true,
      authTokensRemoved: true,
      approvalTokensRemoved: true,
      permissionTokensRemoved: true,
      paymentCredentialsRemoved: paymentCredentialsRemoved,
      verifiedAtUtc: verifiedAtUtc ?? DateTime.utc(2026, 8, 24, 3, 30),
    );
  }

  test('clean real chat evidence is eligible for review only', () {
    final result = eligibilityPolicy.evaluate(
      classification: classificationPolicy.classify(
        AgentPrivacyDataKind.chatContent,
      ),
      subjectRef: 'customer:123',
      channel: AgentPrivacyChannel.chat,
      sourceFingerprintSha256: sourceSha,
      syntheticData: false,
      consent: consent(),
      redaction: redaction(),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(result.eligibleForRealDataReview, true);
    expect(result.trainingPerformed, false);
    expect(result.deploymentPerformed, false);
  });

  test('missing consent blocks', () {
    final result = eligibilityPolicy.evaluate(
      classification: classificationPolicy.classify(
        AgentPrivacyDataKind.chatContent,
      ),
      subjectRef: 'customer:123',
      channel: AgentPrivacyChannel.chat,
      sourceFingerprintSha256: sourceSha,
      syntheticData: false,
      redaction: redaction(),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(result.status, AgentPrivacyTrainingEligibilityStatus.blockedConsent);
  });

  test('denied/revoked consent blocks', () {
    for (final status in <String>[
      AgentPrivacyConsentStatus.denied,
      AgentPrivacyConsentStatus.revoked,
    ]) {
      final result = eligibilityPolicy.evaluate(
        classification: classificationPolicy.classify(
          AgentPrivacyDataKind.chatContent,
        ),
        subjectRef: 'customer:123',
        channel: AgentPrivacyChannel.chat,
        sourceFingerprintSha256: sourceSha,
        syntheticData: false,
        consent: consent(status: status),
        redaction: redaction(),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.eligibleForRealDataReview, false);
    }
  });

  test('expired consent blocks', () {
    final result = eligibilityPolicy.evaluate(
      classification: classificationPolicy.classify(
        AgentPrivacyDataKind.chatContent,
      ),
      subjectRef: 'customer:123',
      channel: AgentPrivacyChannel.chat,
      sourceFingerprintSha256: sourceSha,
      syntheticData: false,
      consent: consent(expiresAtUtc: DateTime.utc(2026, 8, 24, 3, 59)),
      redaction: redaction(),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(result.status, AgentPrivacyTrainingEligibilityStatus.blockedExpired);
  });

  test('redaction with payment credential remaining blocks', () {
    final result = eligibilityPolicy.evaluate(
      classification: classificationPolicy.classify(
        AgentPrivacyDataKind.chatContent,
      ),
      subjectRef: 'customer:123',
      channel: AgentPrivacyChannel.chat,
      sourceFingerprintSha256: sourceSha,
      syntheticData: false,
      consent: consent(),
      redaction: redaction(paymentCredentialsRemoved: false),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(
      result.status,
      AgentPrivacyTrainingEligibilityStatus.blockedRedaction,
    );
  });

  test('stale redaction blocks', () {
    final result = eligibilityPolicy.evaluate(
      classification: classificationPolicy.classify(
        AgentPrivacyDataKind.chatContent,
      ),
      subjectRef: 'customer:123',
      channel: AgentPrivacyChannel.chat,
      sourceFingerprintSha256: sourceSha,
      syntheticData: false,
      consent: consent(),
      redaction: redaction(
        verifiedAtUtc: evaluatedAtUtc.subtract(const Duration(hours: 25)),
      ),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(
      result.status,
      AgentPrivacyTrainingEligibilityStatus.blockedRedaction,
    );
  });

  test('redaction identity mismatch blocks', () {
    final result = eligibilityPolicy.evaluate(
      classification: classificationPolicy.classify(
        AgentPrivacyDataKind.chatContent,
      ),
      subjectRef: 'customer:123',
      channel: AgentPrivacyChannel.chat,
      sourceFingerprintSha256: sourceSha,
      syntheticData: false,
      consent: consent(),
      redaction: redaction(subjectRef: 'customer:999'),
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(
      result.status,
      AgentPrivacyTrainingEligibilityStatus.blockedMismatch,
    );
  });

  test('raw call recording remains blocked despite evidence', () {
    final result = eligibilityPolicy.evaluate(
      classification: classificationPolicy.classify(
        AgentPrivacyDataKind.callRecording,
      ),
      subjectRef: 'customer:123',
      channel: AgentPrivacyChannel.callRecording,
      sourceFingerprintSha256: sourceSha,
      syntheticData: false,
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(
      result.status,
      AgentPrivacyTrainingEligibilityStatus.blockedSensitive,
    );
  });

  test('Student/Safety/financial real data remain blocked', () {
    for (final kind in <String>[
      AgentPrivacyDataKind.studentData,
      AgentPrivacyDataKind.safetyEmergencyData,
      AgentPrivacyDataKind.financialData,
    ]) {
      final result = eligibilityPolicy.evaluate(
        classification: classificationPolicy.classify(kind),
        subjectRef: 'customer:123',
        channel: AgentPrivacyChannel.chat,
        sourceFingerprintSha256: sourceSha,
        syntheticData: false,
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentPrivacyTrainingEligibilityStatus.blockedSensitive,
      );
    }
  });

  test('auth/API/payment credentials remain blocked', () {
    for (final kind in <String>[
      AgentPrivacyDataKind.authSecret,
      AgentPrivacyDataKind.apiCredential,
      AgentPrivacyDataKind.paymentCredential,
    ]) {
      final result = eligibilityPolicy.evaluate(
        classification: classificationPolicy.classify(kind),
        subjectRef: 'customer:123',
        channel: AgentPrivacyChannel.chat,
        sourceFingerprintSha256: sourceSha,
        syntheticData: false,
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentPrivacyTrainingEligibilityStatus.blockedSecret,
      );
    }
  });

  test('synthetic data is preferred and needs no consent', () {
    final result = eligibilityPolicy.evaluate(
      classification: classificationPolicy.classify(
        AgentPrivacyDataKind.chatContent,
      ),
      subjectRef: 'synthetic:test:1',
      channel: AgentPrivacyChannel.chat,
      sourceFingerprintSha256: sourceSha,
      syntheticData: true,
      evaluatedAtUtc: evaluatedAtUtc,
    );

    expect(result.eligibleSyntheticOnly, true);
    expect(result.usesRealData, false);
  });

  test('eligibility policy has zero protected execution authority', () {
    expect(eligibilityPolicy.decisionOnly, true);
    expect(eligibilityPolicy.trainsModel, false);
    expect(eligibilityPolicy.mutatesPrompt, false);
    expect(eligibilityPolicy.callsProvider, false);
    expect(eligibilityPolicy.deploysChange, false);
    expect(eligibilityPolicy.activatesProduction, false);
    expect(eligibilityPolicy.consumesApproval, false);
    expect(eligibilityPolicy.grantsPermission, false);
    expect(eligibilityPolicy.writesConsent, false);
    expect(eligibilityPolicy.writesRedactionData, false);
    expect(eligibilityPolicy.changesRetention, false);
    expect(eligibilityPolicy.deletesData, false);
    expect(eligibilityPolicy.writesBusinessData, false);
  });
}

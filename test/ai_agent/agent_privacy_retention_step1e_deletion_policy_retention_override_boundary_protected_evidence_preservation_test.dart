import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_privacy_deletion_retention_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_privacy_retention_classification_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_privacy_deletion_request.dart';
import 'package:swat_ride/ai_agent/models/agent_privacy_retention_override_request.dart';
import 'package:swat_ride/ai_agent/services/agent_privacy_deletion_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_privacy_retention_override_policy.dart';

void main() {
  const AgentPrivacyDeletionPolicy deletionPolicy =
      AgentPrivacyDeletionPolicy();

  const AgentPrivacyRetentionOverridePolicy overridePolicy =
      AgentPrivacyRetentionOverridePolicy();

  const String recordSha =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  final DateTime evaluatedAtUtc = DateTime.utc(2026, 8, 24, 6);

  AgentPrivacyDeletionRequest deletionRequest({
    String dataKind = AgentPrivacyDataKind.chatContent,
    String recordClass = AgentPrivacyDeletionRecordClass.transientContent,
    bool retentionExpired = true,
    bool protectedEvidence = false,
    bool legalOrSecurityHold = false,
  }) {
    return AgentPrivacyDeletionRequest(
      requestId: 'deletion:phase63:1',
      recordReferenceSha256: recordSha,
      dataKind: dataKind,
      recordClass: recordClass,
      retentionExpiredByCanonicalEngine: retentionExpired,
      protectedEvidence: protectedEvidence,
      legalOrSecurityHold: legalOrSecurityHold,
      requestedAtUtc: DateTime.utc(2026, 8, 24, 5, 59),
    );
  }

  AgentPrivacyRetentionOverrideRequest overrideRequest({
    String channel = AgentPrivacyChannel.chat,
    int requestedDays = 30,
    String role = AgentPrivacyRetentionOverrideRole.owner,
    bool protectedEvidence = false,
  }) {
    return AgentPrivacyRetentionOverrideRequest(
      overrideId: 'override:phase63:1',
      channel: channel,
      requestedDays: requestedDays,
      requestedByRole: role,
      protectedEvidence: protectedEvidence,
      requestedAtUtc: DateTime.utc(2026, 8, 24, 5, 59),
    );
  }

  group('Phase 63 Step 1E deletion policy', () {
    test('expired transient content becomes review-eligible only', () {
      final result = deletionPolicy.evaluate(
        request: deletionRequest(),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.eligibleForLaterDeletionReview, true);
      expect(result.deletionPerformed, false);
      expect(result.purgePerformed, false);
    });

    test('not-expired canonical retention blocks deletion review', () {
      final result = deletionPolicy.evaluate(
        request: deletionRequest(retentionExpired: false),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentPrivacyDeletionStatus.blockedRetentionNotExpired,
      );
    });

    test('legal/security hold blocks deletion review', () {
      final result = deletionPolicy.evaluate(
        request: deletionRequest(legalOrSecurityHold: true),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentPrivacyDeletionStatus.blockedLegalOrSecurityHold,
      );
    });

    test('audit evidence is never generic-deletion eligible', () {
      final result = deletionPolicy.evaluate(
        request: deletionRequest(
          dataKind: AgentPrivacyDataKind.auditEvidence,
          recordClass: AgentPrivacyDeletionRecordClass.auditEvidence,
          protectedEvidence: true,
        ),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentPrivacyDeletionStatus.blockedProtectedEvidence,
      );
    });

    test('security evidence is never generic-deletion eligible', () {
      final result = deletionPolicy.evaluate(
        request: deletionRequest(
          dataKind: AgentPrivacyDataKind.securityEvidence,
          recordClass: AgentPrivacyDeletionRecordClass.securityEvidence,
          protectedEvidence: true,
        ),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentPrivacyDeletionStatus.blockedProtectedEvidence,
      );
    });

    test('finance evidence is never generic-deletion eligible', () {
      final result = deletionPolicy.evaluate(
        request: deletionRequest(
          dataKind: AgentPrivacyDataKind.financeEvidence,
          recordClass: AgentPrivacyDeletionRecordClass.financeEvidence,
          protectedEvidence: true,
        ),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentPrivacyDeletionStatus.blockedProtectedEvidence,
      );
    });

    test('protected flag mismatch fails closed', () {
      final result = deletionPolicy.evaluate(
        request: deletionRequest(
          dataKind: AgentPrivacyDataKind.chatContent,
          recordClass: AgentPrivacyDeletionRecordClass.auditEvidence,
          protectedEvidence: false,
        ),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.status, AgentPrivacyDeletionStatus.blockedMismatch);
    });

    test('restricted-critical call recording needs dedicated flow', () {
      final result = deletionPolicy.evaluate(
        request: deletionRequest(dataKind: AgentPrivacyDataKind.callRecording),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentPrivacyDeletionStatus.blockedRestrictedCritical,
      );
    });

    test('auth/API/payment credential records need dedicated flow', () {
      for (final String kind in <String>[
        AgentPrivacyDataKind.authSecret,
        AgentPrivacyDataKind.apiCredential,
        AgentPrivacyDataKind.paymentCredential,
      ]) {
        final result = deletionPolicy.evaluate(
          request: deletionRequest(dataKind: kind),
          evaluatedAtUtc: evaluatedAtUtc,
        );

        expect(
          result.status,
          AgentPrivacyDeletionStatus.blockedRestrictedCritical,
        );
      }
    });

    test('deletion policy has zero destructive authority', () {
      expect(deletionPolicy.reliesOnCanonicalRetentionExpiry, true);
      expect(deletionPolicy.decisionOnly, true);
      expect(deletionPolicy.deletesData, false);
      expect(deletionPolicy.purgesData, false);
      expect(deletionPolicy.writesFirestore, false);
      expect(deletionPolicy.callsProvider, false);
      expect(deletionPolicy.grantsPermission, false);
      expect(deletionPolicy.consumesApproval, false);
      expect(deletionPolicy.overridesRuntimeGate, false);
      expect(deletionPolicy.writesBusinessData, false);
      expect(deletionPolicy.changesRetention, false);
    });
  });

  group('Phase 63 Step 1E retention override boundary', () {
    test('Owner chat override within 90-day cap is review-eligible only', () {
      final result = overridePolicy.evaluate(
        request: overrideRequest(
          channel: AgentPrivacyChannel.chat,
          requestedDays: 90,
        ),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.eligibleForLaterSettingsReview, true);
      expect(result.productionApplied, false);
      expect(result.retentionMutationPerformed, false);
    });

    test('chat override above 90 days is blocked', () {
      final result = overridePolicy.evaluate(
        request: overrideRequest(requestedDays: 91),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentPrivacyRetentionOverrideStatus.blockedChannelCap,
      );
    });

    test('call transcript override above 30 days is blocked', () {
      final result = overridePolicy.evaluate(
        request: overrideRequest(
          channel: AgentPrivacyChannel.callTranscript,
          requestedDays: 31,
        ),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentPrivacyRetentionOverrideStatus.blockedChannelCap,
      );
    });

    test('call recording cannot exceed 7 foundation days', () {
      final allowed = overridePolicy.evaluate(
        request: overrideRequest(
          channel: AgentPrivacyChannel.callRecording,
          requestedDays: 7,
        ),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      final blocked = overridePolicy.evaluate(
        request: overrideRequest(
          channel: AgentPrivacyChannel.callRecording,
          requestedDays: 8,
        ),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(allowed.eligibleForLaterSettingsReview, true);
      expect(
        blocked.status,
        AgentPrivacyRetentionOverrideStatus.blockedChannelCap,
      );
    });

    test('non Owner/Super Admin role is blocked', () {
      final result = overridePolicy.evaluate(
        request: overrideRequest(role: 'AGENT'),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.status, AgentPrivacyRetentionOverrideStatus.blockedRole);
    });

    test('channel override cannot modify protected evidence', () {
      final result = overridePolicy.evaluate(
        request: overrideRequest(protectedEvidence: true),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(
        result.status,
        AgentPrivacyRetentionOverrideStatus.blockedProtectedEvidence,
      );
    });

    test('Super Admin within cap is review-eligible', () {
      final result = overridePolicy.evaluate(
        request: overrideRequest(
          role: AgentPrivacyRetentionOverrideRole.superAdmin,
          channel: AgentPrivacyChannel.email,
          requestedDays: 60,
        ),
        evaluatedAtUtc: evaluatedAtUtc,
      );

      expect(result.eligibleForLaterSettingsReview, true);
    });

    test('override policy has zero mutation authority', () {
      expect(overridePolicy.foundationEligibilityOnly, true);
      expect(overridePolicy.appliesProductionSetting, false);
      expect(overridePolicy.writesFirestore, false);
      expect(overridePolicy.changesProtectedEvidenceRetention, false);
      expect(overridePolicy.deletesData, false);
      expect(overridePolicy.purgesData, false);
      expect(overridePolicy.grantsPermission, false);
      expect(overridePolicy.consumesApproval, false);
      expect(overridePolicy.overridesRuntimeGate, false);
      expect(overridePolicy.writesBusinessData, false);
    });
  });
}

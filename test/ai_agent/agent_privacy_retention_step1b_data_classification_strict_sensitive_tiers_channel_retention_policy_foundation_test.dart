import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_privacy_retention_classification_constants.dart';
import 'package:swat_ride/ai_agent/services/agent_channel_retention_policy_service.dart';
import 'package:swat_ride/ai_agent/services/agent_privacy_data_classification_policy.dart';

void main() {
  const AgentPrivacyDataClassificationPolicy classificationPolicy =
      AgentPrivacyDataClassificationPolicy();

  const AgentChannelRetentionPolicyService channelPolicy =
      AgentChannelRetentionPolicyService();

  group('Phase 63 Step 1B strict data classification', () {
    test('Student data is highly sensitive and training-ineligible', () {
      final result = classificationPolicy.classify(
        AgentPrivacyDataKind.studentData,
      );

      expect(
        result.sensitivityTier,
        AgentPrivacySensitivityTier.highlySensitive,
      );
      expect(result.trainingMode, AgentPrivacyTrainingMode.ineligibleSensitive);
      expect(result.strictlySensitive, true);
      expect(result.rawProviderProjectionAllowed, false);
    });

    test('Safety/emergency data is highly sensitive', () {
      final result = classificationPolicy.classify(
        AgentPrivacyDataKind.safetyEmergencyData,
      );

      expect(
        result.sensitivityTier,
        AgentPrivacySensitivityTier.highlySensitive,
      );
      expect(result.redactionRequired, true);
      expect(result.rawProviderProjectionAllowed, false);
    });

    test('Financial data is highly sensitive', () {
      final result = classificationPolicy.classify(
        AgentPrivacyDataKind.financialData,
      );

      expect(
        result.sensitivityTier,
        AgentPrivacySensitivityTier.highlySensitive,
      );
      expect(result.trainingMode, AgentPrivacyTrainingMode.ineligibleSensitive);
    });

    test('raw call recording is restricted critical', () {
      final result = classificationPolicy.classify(
        AgentPrivacyDataKind.callRecording,
      );

      expect(
        result.sensitivityTier,
        AgentPrivacySensitivityTier.restrictedCritical,
      );
      expect(result.restrictedCritical, true);
      expect(result.rawDataBlocked, true);
      expect(result.trainingMode, AgentPrivacyTrainingMode.ineligibleSensitive);
    });

    test('auth/API/payment credentials are restricted critical', () {
      for (final kind in <String>[
        AgentPrivacyDataKind.authSecret,
        AgentPrivacyDataKind.apiCredential,
        AgentPrivacyDataKind.paymentCredential,
      ]) {
        final result = classificationPolicy.classify(kind);

        expect(
          result.sensitivityTier,
          AgentPrivacySensitivityTier.restrictedCritical,
        );
        expect(result.trainingMode, AgentPrivacyTrainingMode.ineligibleSecret);
        expect(result.rawDataBlocked, true);
      }
    });

    test('protected audit/security/finance evidence cannot be low tier', () {
      for (final kind in <String>[
        AgentPrivacyDataKind.auditEvidence,
        AgentPrivacyDataKind.securityEvidence,
        AgentPrivacyDataKind.financeEvidence,
      ]) {
        final result = classificationPolicy.classify(kind);

        expect(result.protectedEvidence, true);
        expect(result.strictlySensitive, true);
        expect(
          result.trainingMode,
          AgentPrivacyTrainingMode.ineligibleSensitive,
        );
      }
    });

    test('chat/email/WhatsApp/call transcript require redaction + consent', () {
      for (final kind in <String>[
        AgentPrivacyDataKind.chatContent,
        AgentPrivacyDataKind.emailContent,
        AgentPrivacyDataKind.whatsappContent,
        AgentPrivacyDataKind.callTranscript,
      ]) {
        final result = classificationPolicy.classify(kind);

        expect(
          result.trainingMode,
          AgentPrivacyTrainingMode.redactedConsentRequired,
        );
        expect(result.redactionRequired, true);
        expect(result.explicitConsentRequiredForRealTraining, true);

        expect(
          result.canUseRealDataForTraining(
            consentGranted: false,
            redactionVerified: true,
          ),
          false,
        );

        expect(
          result.canUseRealDataForTraining(
            consentGranted: true,
            redactionVerified: false,
          ),
          false,
        );

        expect(
          result.canUseRealDataForTraining(
            consentGranted: true,
            redactionVerified: true,
          ),
          true,
        );
      }
    });

    test('real-data training is never allowed without consent', () {
      final result = classificationPolicy.classify(
        AgentPrivacyDataKind.callTranscript,
      );

      expect(result.realDataTrainingAllowedWithoutConsent, false);
    });

    test('classification grants no runtime/deployment authority', () {
      final result = classificationPolicy.classify(
        AgentPrivacyDataKind.chatContent,
      );

      expect(result.trainingDeploymentAuthorityGranted, false);
      expect(result.businessPermissionGranted, false);
      expect(result.approvalAuthorityGranted, false);
      expect(result.providerExecutionGranted, false);
      expect(result.dataDeletionPerformed, false);
      expect(result.dataPurgePerformed, false);
      expect(result.retentionWritePerformed, false);
    });

    test('unknown data kind fails closed', () {
      expect(
        () => classificationPolicy.classify('UNKNOWN_KIND'),
        throwsFormatException,
      );
    });
  });

  group('Phase 63 Step 1B channel retention foundation', () {
    test('chat foundation is 30 days with max 90', () {
      final policy = channelPolicy.policyFor(AgentPrivacyChannel.chat);

      expect(policy.foundationDefaultDays, 30);
      expect(policy.maximumOwnerConfigurableDays, 90);
      expect(policy.redactionRequiredForTraining, true);
      expect(policy.explicitConsentRequiredForTraining, true);
      expect(policy.productionApplied, false);
    });

    test('call transcript is stricter: 14 days with max 30', () {
      final policy = channelPolicy.policyFor(
        AgentPrivacyChannel.callTranscript,
      );

      expect(policy.foundationDefaultDays, 14);
      expect(policy.maximumOwnerConfigurableDays, 30);
      expect(
        policy.trainingMode,
        AgentPrivacyTrainingMode.redactedConsentRequired,
      );
    });

    test('raw call recording is OFF by default and max 7 days', () {
      final policy = channelPolicy.policyFor(AgentPrivacyChannel.callRecording);

      expect(policy.retentionMode, AgentPrivacyRetentionMode.disabledByDefault);
      expect(policy.foundationDefaultDays, 0);
      expect(policy.maximumOwnerConfigurableDays, 7);
      expect(policy.rawContentRetentionEnabledByDefault, false);
      expect(policy.trainingMode, AgentPrivacyTrainingMode.ineligibleSensitive);
    });

    test('email is 30 days with max 90', () {
      final policy = channelPolicy.policyFor(AgentPrivacyChannel.email);

      expect(policy.foundationDefaultDays, 30);
      expect(policy.maximumOwnerConfigurableDays, 90);
    });

    test('WhatsApp AI is 30 days with max 90', () {
      final policy = channelPolicy.policyFor(AgentPrivacyChannel.whatsappAi);

      expect(policy.foundationDefaultDays, 30);
      expect(policy.maximumOwnerConfigurableDays, 90);
    });

    test('Owner requested channel days must remain within foundation cap', () {
      final transcript = channelPolicy.policyFor(
        AgentPrivacyChannel.callTranscript,
      );

      expect(transcript.isOwnerRequestedDaysWithinFoundationBounds(30), true);
      expect(transcript.isOwnerRequestedDaysWithinFoundationBounds(31), false);
      expect(transcript.isOwnerRequestedDaysWithinFoundationBounds(-1), false);
    });

    test('channel policy never overrides protected evidence retention', () {
      final policy = channelPolicy.policyFor(AgentPrivacyChannel.chat);

      expect(policy.protectedEvidenceOverrideAllowed, false);
    });

    test('channel foundation performs no delete/purge/write', () {
      final policy = channelPolicy.policyFor(AgentPrivacyChannel.whatsappAi);

      expect(policy.foundationOnly, true);
      expect(policy.productionApplied, false);
      expect(policy.deletionPerformed, false);
      expect(policy.purgePerformed, false);
      expect(policy.firestoreWritePerformed, false);
      expect(policy.permissionAuthorityGranted, false);
      expect(policy.approvalAuthorityGranted, false);
      expect(policy.deploymentAuthorityGranted, false);
    });

    test('unknown channel fails closed', () {
      expect(
        () => channelPolicy.policyFor('UNKNOWN_CHANNEL'),
        throwsFormatException,
      );
    });
  });

  group('Phase 63 Step 1B service authority locks', () {
    test('classification policy has zero protected execution authority', () {
      expect(classificationPolicy.expandsRuntimePermissions, false);
      expect(classificationPolicy.consumesApproval, false);
      expect(classificationPolicy.callsProvider, false);
      expect(classificationPolicy.writesRetentionSettings, false);
      expect(classificationPolicy.deletesData, false);
      expect(classificationPolicy.purgesData, false);
      expect(classificationPolicy.trainsModel, false);
      expect(classificationPolicy.deploysTrainingChange, false);
    });

    test('channel service is policy-only', () {
      expect(channelPolicy.foundationOnly, true);
      expect(channelPolicy.appliesProductionSetting, false);
      expect(channelPolicy.overridesProtectedEvidenceRetention, false);
      expect(channelPolicy.deletesData, false);
      expect(channelPolicy.purgesData, false);
      expect(channelPolicy.writesFirestore, false);
      expect(channelPolicy.expandsRuntimePermissions, false);
      expect(channelPolicy.consumesApproval, false);
      expect(channelPolicy.trainsModel, false);
      expect(channelPolicy.deploysTrainingChange, false);
    });
  });
}

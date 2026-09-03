import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_provider_privacy_projection_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_privacy_profile.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_privacy_projection_request.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_privacy_projection_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_sensitive_task_restriction_policy.dart';

void main() {
  const AgentProviderPrivacyProjectionPolicy policy =
      AgentProviderPrivacyProjectionPolicy();

  const AgentProviderSensitiveTaskRestrictionPolicy sensitivePolicy =
      AgentProviderSensitiveTaskRestrictionPolicy();

  AgentProviderPrivacyProfile provider({
    String providerId = 'provider:free:a',
    String privacyBoundary = AgentProviderPrivacyBoundary.externalOnline,
    bool backendOnly = true,
    bool enabled = true,
  }) {
    return AgentProviderPrivacyProfile(
      providerId: providerId,
      privacyBoundary: privacyBoundary,
      backendOnly: backendOnly,
      enabled: enabled,
    );
  }

  AgentProviderPrivacyProjectionRequest request({
    String sensitiveTaskClass = AgentProviderSensitiveTaskClass.normal,
    String dataSensitivity = AgentProviderDataSensitivity.operational,
    bool minimumNecessaryDataConfirmed = true,
    bool redactionCompleted = true,
    Set<String> restrictedDataFlags = const <String>{},
  }) {
    return AgentProviderPrivacyProjectionRequest(
      requestId: 'privacy:route:001',
      taskType: 'GENERAL_REASONING',
      sensitiveTaskClass: sensitiveTaskClass,
      dataSensitivity: dataSensitivity,
      minimumNecessaryDataConfirmed: minimumNecessaryDataConfirmed,
      redactionCompleted: redactionCompleted,
      contextReferenceIds: const <String>['context_ref:privacy:001'],
      restrictedDataFlags: restrictedDataFlags,
    );
  }

  group('Phase 58 Step 1E privacy/data-minimization boundary', () {
    test('2 provider privacy boundaries are locked', () {
      expect(AgentProviderPrivacyBoundary.values.length, 2);
    });

    test('5 data sensitivity classes are locked', () {
      expect(AgentProviderDataSensitivity.values.length, 5);
    });

    test('14 restricted data classes are locked', () {
      expect(AgentProviderRestrictedDataClass.values.length, 14);
    });

    test('6 sensitive task classes are locked', () {
      expect(AgentProviderSensitiveTaskClass.values.length, 6);
    });

    test('6 privacy projection statuses are locked', () {
      expect(AgentProviderPrivacyProjectionStatus.values.length, 6);
    });

    test('normal operational task may use eligible external provider', () {
      final result = policy.evaluate(request: request(), provider: provider());

      expect(result.eligible, true);
      expect(
        result.status,
        AgentProviderPrivacyProjectionStatus.eligibleForProviderRouting,
      );
      expect(result.projection, isNotNull);
      expect(result.projection!.referenceMetadataOnly, true);
    });

    test('minimum-necessary data confirmation is required', () {
      final result = policy.evaluate(
        request: request(minimumNecessaryDataConfirmed: false),
        provider: provider(),
      );

      expect(
        result.status,
        AgentProviderPrivacyProjectionStatus.blockedMinimumDataPolicy,
      );
      expect(result.failClosed, true);
    });

    test('redaction completion is required', () {
      final result = policy.evaluate(
        request: request(redactionCompleted: false),
        provider: provider(),
      );

      expect(
        result.status,
        AgentProviderPrivacyProjectionStatus.blockedMinimumDataPolicy,
      );
    });

    test('every restricted data flag blocks provider projection', () {
      for (final String flag in AgentProviderRestrictedDataClass.values) {
        final result = policy.evaluate(
          request: request(restrictedDataFlags: <String>{flag}),
          provider: provider(),
        );

        expect(
          result.status,
          AgentProviderPrivacyProjectionStatus.blockedRestrictedData,
          reason: 'Restricted data must block: $flag',
        );
      }
    });

    test('restricted sensitivity blocks even without explicit flag', () {
      final result = policy.evaluate(
        request: request(
          dataSensitivity: AgentProviderDataSensitivity.restricted,
        ),
        provider: provider(),
      );

      expect(
        result.status,
        AgentProviderPrivacyProjectionStatus.blockedRestrictedData,
      );
    });

    test('personal data is blocked from external online provider', () {
      final result = policy.evaluate(
        request: request(
          dataSensitivity: AgentProviderDataSensitivity.personal,
        ),
        provider: provider(),
      );

      expect(
        result.status,
        AgentProviderPrivacyProjectionStatus.blockedSensitiveExternalProvider,
      );
    });

    test('sensitive data is blocked from external online provider', () {
      final result = policy.evaluate(
        request: request(
          dataSensitivity: AgentProviderDataSensitivity.sensitive,
        ),
        provider: provider(),
      );

      expect(
        result.status,
        AgentProviderPrivacyProjectionStatus.blockedSensitiveExternalProvider,
      );
    });

    test('identity-sensitive task is blocked externally', () {
      final result = policy.evaluate(
        request: request(
          sensitiveTaskClass: AgentProviderSensitiveTaskClass.identitySensitive,
        ),
        provider: provider(),
      );

      expect(
        result.status,
        AgentProviderPrivacyProjectionStatus.blockedSensitiveExternalProvider,
      );
    });

    test('payment-sensitive task is blocked externally', () {
      final result = policy.evaluate(
        request: request(
          sensitiveTaskClass: AgentProviderSensitiveTaskClass.paymentSensitive,
        ),
        provider: provider(),
      );

      expect(
        result.status,
        AgentProviderPrivacyProjectionStatus.blockedSensitiveExternalProvider,
      );
    });

    test('health-sensitive task is blocked externally', () {
      final result = policy.evaluate(
        request: request(
          sensitiveTaskClass: AgentProviderSensitiveTaskClass.healthSensitive,
        ),
        provider: provider(),
      );

      expect(
        result.status,
        AgentProviderPrivacyProjectionStatus.blockedSensitiveExternalProvider,
      );
    });

    test('emergency-sensitive task is blocked externally', () {
      final result = policy.evaluate(
        request: request(
          sensitiveTaskClass:
              AgentProviderSensitiveTaskClass.emergencySensitive,
        ),
        provider: provider(),
      );

      expect(
        result.status,
        AgentProviderPrivacyProjectionStatus.blockedSensitiveExternalProvider,
      );
    });

    test('admin-security-sensitive task is blocked externally', () {
      final result = policy.evaluate(
        request: request(
          sensitiveTaskClass:
              AgentProviderSensitiveTaskClass.adminSecuritySensitive,
        ),
        provider: provider(),
      );

      expect(
        result.status,
        AgentProviderPrivacyProjectionStatus.blockedSensitiveExternalProvider,
      );
    });

    test(
      'sensitive task may be eligible for local-private after minimization',
      () {
        final result = policy.evaluate(
          request: request(
            sensitiveTaskClass:
                AgentProviderSensitiveTaskClass.identitySensitive,
            dataSensitivity: AgentProviderDataSensitivity.sensitive,
          ),
          provider: provider(
            providerId: 'provider:local:a',
            privacyBoundary: AgentProviderPrivacyBoundary.localPrivate,
          ),
        );

        expect(result.eligible, true);
        expect(
          result.projection!.privacyBoundary,
          AgentProviderPrivacyBoundary.localPrivate,
        );
      },
    );

    test('restricted data is blocked even for local-private provider', () {
      final result = policy.evaluate(
        request: request(
          dataSensitivity: AgentProviderDataSensitivity.restricted,
        ),
        provider: provider(
          providerId: 'provider:local:a',
          privacyBoundary: AgentProviderPrivacyBoundary.localPrivate,
        ),
      );

      expect(
        result.status,
        AgentProviderPrivacyProjectionStatus.blockedRestrictedData,
      );
    });

    test('disabled provider is blocked', () {
      final result = policy.evaluate(
        request: request(),
        provider: provider(enabled: false),
      );

      expect(
        result.status,
        AgentProviderPrivacyProjectionStatus.blockedBoundaryMismatch,
      );
    });

    test('client-side provider boundary is blocked', () {
      final result = policy.evaluate(
        request: request(),
        provider: provider(backendOnly: false),
      );

      expect(
        result.status,
        AgentProviderPrivacyProjectionStatus.blockedBoundaryMismatch,
      );
    });

    test('privacy projection contains only opaque references', () {
      final result = policy.evaluate(request: request(), provider: provider());

      final projection = result.projection!;

      expect(projection.referenceMetadataOnly, true);
      expect(projection.minimumNecessaryDataOnly, true);
      expect(projection.redactionRequiredBeforeProjection, true);
      expect(projection.contextReferenceIds, const <String>[
        'context_ref:privacy:001',
      ]);
      expect(projection.containsRawPrompt, false);
      expect(projection.containsRawConversation, false);
      expect(projection.containsRawUserMessage, false);
      expect(projection.containsPhoneNumber, false);
      expect(projection.containsEmailAddress, false);
      expect(projection.containsAuthToken, false);
      expect(projection.containsPassword, false);
      expect(projection.containsApiSecret, false);
      expect(projection.containsPaymentCard, false);
      expect(projection.containsCvv, false);
      expect(projection.containsPin, false);
      expect(projection.containsIdentityDocumentImage, false);
      expect(projection.containsPrecisePrivateLocation, false);
      expect(projection.containsPrivateHealthRecord, false);
      expect(projection.containsPrivateEmergencyEvidence, false);
      expect(projection.containsPrivateComplaintEvidence, false);
    });

    test('projection adds no provider/business/cost authority', () {
      final projection = policy
          .evaluate(request: request(), provider: provider())
          .projection!;

      expect(projection.invokesProvider, false);
      expect(projection.activatesProvider, false);
      expect(projection.grantsPermission, false);
      expect(projection.consumesApproval, false);
      expect(projection.expandsScope, false);
      expect(projection.executesBusinessAction, false);
      expect(projection.writesBusinessData, false);
      expect(projection.chargesCost, false);
      expect(projection.mutatesBudget, false);
      expect(projection.persistsProjection, false);
    });

    test('request model itself stores no raw sensitive payload', () {
      final value = request();

      expect(value.containsRawPrompt, false);
      expect(value.containsRawConversation, false);
      expect(value.containsRawUserMessage, false);
      expect(value.containsPhoneNumber, false);
      expect(value.containsEmailAddress, false);
      expect(value.containsAuthToken, false);
      expect(value.containsPassword, false);
      expect(value.containsApiSecret, false);
      expect(value.containsPaymentCard, false);
      expect(value.containsCvv, false);
      expect(value.containsPin, false);
      expect(value.containsIdentityDocumentImage, false);
      expect(value.containsPrivateHealthRecord, false);
      expect(value.containsPrivateEmergencyEvidence, false);
      expect(value.invokesProvider, false);
      expect(value.grantsPermission, false);
      expect(value.consumesApproval, false);
      expect(value.expandsScope, false);
      expect(value.executesBusinessAction, false);
      expect(value.persistsRequest, false);
    });

    test('provider privacy profile is secret-free metadata only', () {
      final value = provider();

      expect(value.metadataOnly, true);
      expect(value.containsRawApiKey, false);
      expect(value.containsRawToken, false);
      expect(value.containsRawSecret, false);
      expect(value.clientMayExecuteProvider, false);
      expect(value.grantsPermission, false);
      expect(value.consumesApproval, false);
      expect(value.expandsScope, false);
      expect(value.executesBusinessAction, false);
      expect(value.persistsProfile, false);
    });

    test('sensitive restriction policy locks external restrictions', () {
      expect(sensitivePolicy.identitySensitiveExternalBlocked, true);
      expect(sensitivePolicy.paymentSensitiveExternalBlocked, true);
      expect(sensitivePolicy.healthSensitiveExternalBlocked, true);
      expect(sensitivePolicy.emergencySensitiveExternalBlocked, true);
      expect(sensitivePolicy.adminSecuritySensitiveExternalBlocked, true);
      expect(
        sensitivePolicy.restrictedDataAlwaysBlockedFromProviderProjection,
        true,
      );
      expect(sensitivePolicy.localPrivateStillRequiresMinimization, true);
      expect(sensitivePolicy.providerBoundaryDoesNotGrantAuthority, true);
    });

    test('sensitive restriction policy has no provider/action authority', () {
      expect(sensitivePolicy.invokesProvider, false);
      expect(sensitivePolicy.grantsPermission, false);
      expect(sensitivePolicy.consumesApproval, false);
      expect(sensitivePolicy.executesBusinessAction, false);
      expect(sensitivePolicy.persistsPolicy, false);
    });

    test('privacy decision itself remains policy-only', () {
      final result = policy.evaluate(request: request(), provider: provider());

      expect(result.policyDecisionOnly, true);
      expect(result.providerInvocationAllowedHere, false);
      expect(result.grantsPermission, false);
      expect(result.consumesApproval, false);
      expect(result.expandsScope, false);
      expect(result.executesBusinessAction, false);
      expect(result.writesBusinessData, false);
      expect(result.chargesCost, false);
      expect(result.mutatesBudget, false);
      expect(result.persistsDecision, false);
    });

    test('policy locks data-minimization/privacy boundaries', () {
      expect(policy.minimumNecessaryDataRequired, true);
      expect(policy.redactionRequired, true);
      expect(policy.rawPromptForbidden, true);
      expect(policy.rawConversationForbidden, true);
      expect(policy.authSecretsForbidden, true);
      expect(policy.paymentCredentialsForbidden, true);
      expect(policy.rawIdentityDocumentsForbidden, true);
      expect(policy.privateHealthEmergencyEvidenceForbidden, true);
      expect(policy.restrictedDataFailsClosed, true);
      expect(policy.sensitiveExternalProviderBlocked, true);
      expect(policy.localPrivateBoundaryRequiredForSensitiveTasks, true);
      expect(policy.restrictedDataBlockedEvenLocalPrivate, true);
      expect(policy.projectionReferenceMetadataOnly, true);
    });

    test('Step 1C/1D and Phase 59 ownership remain preserved', () {
      expect(policy.preservesStep1CFreeLocalPaidOrderAfterPrivacyFilter, true);
      expect(policy.preservesStep1DModelTokenBoundary, true);
      expect(policy.providerInvocationImplementedHere, false);
      expect(policy.providerQualityEvaluationOwnedHere, false);
      expect(policy.phase59OwnsProviderQualityEvaluator, true);
      expect(policy.phase63PrivacyRetentionUiSeparate, true);
    });

    test(
      'policy adds no permission/approval/business/persistence authority',
      () {
        expect(policy.grantsPermission, false);
        expect(policy.consumesApproval, false);
        expect(policy.expandsScope, false);
        expect(policy.executesBusinessAction, false);
        expect(policy.writesBusinessData, false);
        expect(policy.chargesCost, false);
        expect(policy.mutatesBudget, false);
        expect(policy.persistsProjection, false);
      },
    );
  });
}

import '../constants/agent_provider_privacy_projection_constants.dart';
import '../models/agent_provider_privacy_profile.dart';
import '../models/agent_provider_privacy_projection_decision.dart';
import '../models/agent_provider_privacy_projection_request.dart';
import '../models/agent_provider_privacy_safe_projection.dart';
import 'agent_provider_sensitive_task_restriction_policy.dart';

class AgentProviderPrivacyProjectionPolicy {
  const AgentProviderPrivacyProjectionPolicy({
    this.sensitiveTaskPolicy =
        const AgentProviderSensitiveTaskRestrictionPolicy(),
  });

  final AgentProviderSensitiveTaskRestrictionPolicy sensitiveTaskPolicy;

  AgentProviderPrivacyProjectionDecision evaluate({
    required AgentProviderPrivacyProjectionRequest request,
    required AgentProviderPrivacyProfile provider,
  }) {
    try {
      request.validateStructure();
      provider.validateStructure();
    } catch (_) {
      return _blocked(
        status: AgentProviderPrivacyProjectionStatus.blockedInvalidRequest,
        requestId: request.requestId,
        reasons: const <String>[
          'invalid_privacy_projection_metadata',
          'fail_closed',
        ],
      );
    }

    if (!provider.enabled || !provider.backendOnly) {
      return _blocked(
        status: AgentProviderPrivacyProjectionStatus.blockedBoundaryMismatch,
        requestId: request.requestId,
        reasons: const <String>[
          'enabled_backend_only_provider_required',
          'client_provider_execution_blocked',
        ],
      );
    }

    if (!request.minimumNecessaryDataConfirmed || !request.redactionCompleted) {
      return _blocked(
        status: AgentProviderPrivacyProjectionStatus.blockedMinimumDataPolicy,
        requestId: request.requestId,
        reasons: const <String>[
          'minimum_necessary_data_and_redaction_required',
          'fail_closed',
        ],
      );
    }

    if (request.restrictedDataFlags.isNotEmpty ||
        request.dataSensitivity == AgentProviderDataSensitivity.restricted) {
      return _blocked(
        status: AgentProviderPrivacyProjectionStatus.blockedRestrictedData,
        requestId: request.requestId,
        reasons: const <String>[
          'restricted_data_detected',
          'raw_private_payment_auth_secret_payload_blocked',
          'fail_closed',
        ],
      );
    }

    if (provider.externalOnline &&
        !sensitiveTaskPolicy.externalProviderAllowed(
          sensitiveTaskClass: request.sensitiveTaskClass,
          dataSensitivity: request.dataSensitivity,
        )) {
      return _blocked(
        status: AgentProviderPrivacyProjectionStatus
            .blockedSensitiveExternalProvider,
        requestId: request.requestId,
        reasons: const <String>[
          'sensitive_or_personal_task_not_allowed_external',
          'use_local_private_boundary_or_no_provider',
          'fail_closed',
        ],
      );
    }

    if (provider.localPrivate &&
        !sensitiveTaskPolicy.localPrivateProviderAllowed(
          sensitiveTaskClass: request.sensitiveTaskClass,
          dataSensitivity: request.dataSensitivity,
        )) {
      return _blocked(
        status: AgentProviderPrivacyProjectionStatus.blockedRestrictedData,
        requestId: request.requestId,
        reasons: const <String>[
          'restricted_data_not_allowed_even_local_private',
          'fail_closed',
        ],
      );
    }

    final AgentProviderPrivacySafeProjection projection =
        AgentProviderPrivacySafeProjection(
          requestId: request.requestId,
          taskType: request.taskType,
          providerId: provider.providerId,
          privacyBoundary: provider.privacyBoundary,
          dataSensitivity: request.dataSensitivity,
          contextReferenceIds: request.contextReferenceIds,
        );

    final AgentProviderPrivacyProjectionDecision decision =
        AgentProviderPrivacyProjectionDecision(
          status:
              AgentProviderPrivacyProjectionStatus.eligibleForProviderRouting,
          requestId: request.requestId,
          projection: projection,
          reasonCodes: const <String>[
            'minimum_necessary_data_confirmed',
            'redaction_completed',
            'restricted_data_absent',
            'provider_privacy_boundary_eligible',
            'opaque_context_references_only',
            'step1c_routing_order_applies_next',
            'step1d_model_token_boundary_applies_next',
            'provider_not_invoked_here',
          ],
        );

    decision.validateStructure();
    return decision;
  }

  AgentProviderPrivacyProjectionDecision _blocked({
    required String status,
    required String requestId,
    required List<String> reasons,
  }) {
    final AgentProviderPrivacyProjectionDecision decision =
        AgentProviderPrivacyProjectionDecision(
          status: status,
          requestId: requestId.trim().isEmpty
              ? 'invalid_provider_privacy_request'
              : requestId,
          projection: null,
          reasonCodes: reasons,
        );

    decision.validateStructure();
    return decision;
  }

  bool get minimumNecessaryDataRequired => true;
  bool get redactionRequired => true;
  bool get rawPromptForbidden => true;
  bool get rawConversationForbidden => true;
  bool get authSecretsForbidden => true;
  bool get paymentCredentialsForbidden => true;
  bool get rawIdentityDocumentsForbidden => true;
  bool get privateHealthEmergencyEvidenceForbidden => true;
  bool get restrictedDataFailsClosed => true;
  bool get sensitiveExternalProviderBlocked => true;
  bool get localPrivateBoundaryRequiredForSensitiveTasks => true;
  bool get restrictedDataBlockedEvenLocalPrivate => true;
  bool get projectionReferenceMetadataOnly => true;
  bool get preservesStep1CFreeLocalPaidOrderAfterPrivacyFilter => true;
  bool get preservesStep1DModelTokenBoundary => true;
  bool get providerInvocationImplementedHere => false;
  bool get providerQualityEvaluationOwnedHere => false;
  bool get phase59OwnsProviderQualityEvaluator => true;
  bool get phase63PrivacyRetentionUiSeparate => true;

  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get chargesCost => false;
  bool get mutatesBudget => false;
  bool get persistsProjection => false;
}

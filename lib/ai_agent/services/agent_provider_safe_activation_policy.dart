import '../constants/agent_provider_expansion_contract_constants.dart';
import '../models/agent_provider_activation_decision.dart';
import '../models/agent_provider_activation_request.dart';
import '../models/agent_provider_expansion_contract.dart';

class AgentProviderSafeActivationPolicy {
  const AgentProviderSafeActivationPolicy();

  AgentProviderActivationDecision evaluate({
    required AgentProviderExpansionContract contract,
    required AgentProviderActivationRequest request,
  }) {
    try {
      contract.validateStructure();
    } catch (_) {
      return _decision(
        AgentProviderExpansionActivationStatus.blockedInvalidContract,
        request,
        'invalid_provider_contract',
      );
    }

    if (contract.providerId != request.providerId) {
      return _decision(
        AgentProviderExpansionActivationStatus.blockedInvalidContract,
        request,
        'provider_id_mismatch',
      );
    }

    if (!contract.enabled || !request.providerEnabled) {
      return _decision(
        AgentProviderExpansionActivationStatus.blockedDisabled,
        request,
        'provider_disabled',
      );
    }

    if (!contract.backendOnly ||
        !request.backendExecution ||
        !request.secretReferenceResolvedByBackend) {
      return _decision(
        AgentProviderExpansionActivationStatus.blockedSecretBoundary,
        request,
        'trusted_backend_secret_boundary_required',
      );
    }

    if (!contract.capabilities.contains(request.requiredCapability)) {
      return _decision(
        AgentProviderExpansionActivationStatus.blockedCapabilityMismatch,
        request,
        'required_capability_not_supported',
      );
    }

    if (request.requestsPermissionGrant ||
        request.requestsApprovalConsumption ||
        request.requestsScopeExpansion ||
        request.requestsBusinessAction) {
      return _decision(
        AgentProviderExpansionActivationStatus.blockedUnsafeAuthorityRequest,
        request,
        'provider_activation_cannot_grant_authority',
      );
    }

    if (contract.tier == AgentProviderExpansionTier.paidLastEscalation) {
      if (!request.paidAiEnabled ||
          !request.budgetAllowed ||
          (request.askBeforePaid && !request.paidApprovalGranted)) {
        return _decision(
          AgentProviderExpansionActivationStatus.blockedPaidControl,
          request,
          'paid_ai_control_or_budget_not_satisfied',
        );
      }
    }

    return _decision(
      AgentProviderExpansionActivationStatus
          .eligibleForTrustedBackendActivation,
      request,
      'eligible_policy_only_backend_activation_still_external',
    );
  }

  AgentProviderActivationDecision _decision(
    String status,
    AgentProviderActivationRequest request,
    String reason,
  ) {
    return AgentProviderActivationDecision(
      status: status,
      providerId: request.providerId,
      requiredCapability: request.requiredCapability,
      reason: reason,
    );
  }

  bool get freeOnlineFirstPriority => true;
  bool get localAiOptionalFuture => true;
  bool get paidAiLastEscalation => true;
  bool get paidAiOnOffRequired => true;
  bool get askBeforePaidPreserved => true;
  bool get paidBudgetRequired => true;
  bool get budgetExhaustionStopsPaidOnly => true;
  bool get backendExecutionRequired => true;
  bool get backendSecretResolutionRequired => true;
  bool get rawSecretsForbiddenInClient => true;
  bool get providerCannotGrantPermission => true;
  bool get providerCannotConsumeApproval => true;
  bool get providerCannotExpandScope => true;
  bool get providerCannotExecuteBusinessAction => true;
  bool get realActivationImplementedHere => false;
  bool get providerInvocationImplementedHere => false;
  bool get qualityEvaluatorImplementedHere => false;
  bool get phase59OwnsProviderQualityEvaluator => true;
  bool get phase62TrainingDeploymentSeparate => true;
  bool get phase63PrivacyRetentionUiSeparate => true;
}

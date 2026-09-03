import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_provider_expansion_contract_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_activation_request.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_expansion_contract.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_capability_registry.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_safe_activation_policy.dart';

void main() {
  const AgentProviderCapabilityRegistry registry =
      AgentProviderCapabilityRegistry();

  const AgentProviderSafeActivationPolicy policy =
      AgentProviderSafeActivationPolicy();

  AgentProviderExpansionContract contract({
    String providerId = 'provider:free:primary',
    String tier = AgentProviderExpansionTier.freeOnline,
    bool enabled = true,
    bool backendOnly = true,
    Set<String> capabilities = const <String>{
      AgentProviderExpansionCapability.textReasoning,
      AgentProviderExpansionCapability.structuredJson,
    },
  }) {
    return AgentProviderExpansionContract(
      providerId: providerId,
      displayName: 'Primary Free Provider',
      tier: tier,
      enabled: enabled,
      backendOnly: backendOnly,
      secretReferenceId: 'secret_ref:provider:free:primary',
      defaultModelReference: 'model_ref:provider:free:primary',
      capabilities: capabilities,
    );
  }

  AgentProviderActivationRequest request({
    String providerId = 'provider:free:primary',
    String capability = AgentProviderExpansionCapability.textReasoning,
    bool backendExecution = true,
    bool providerEnabled = true,
    bool secretResolved = true,
    bool paidAiEnabled = false,
    bool askBeforePaid = true,
    bool paidApprovalGranted = false,
    bool budgetAllowed = false,
    bool requestsPermissionGrant = false,
    bool requestsApprovalConsumption = false,
    bool requestsScopeExpansion = false,
    bool requestsBusinessAction = false,
  }) {
    return AgentProviderActivationRequest(
      providerId: providerId,
      requiredCapability: capability,
      backendExecution: backendExecution,
      providerEnabled: providerEnabled,
      secretReferenceResolvedByBackend: secretResolved,
      paidAiEnabled: paidAiEnabled,
      askBeforePaid: askBeforePaid,
      paidApprovalGranted: paidApprovalGranted,
      budgetAllowed: budgetAllowed,
      requestsPermissionGrant: requestsPermissionGrant,
      requestsApprovalConsumption: requestsApprovalConsumption,
      requestsScopeExpansion: requestsScopeExpansion,
      requestsBusinessAction: requestsBusinessAction,
    );
  }

  group('Phase 58 Step 1B provider expansion contracts', () {
    test('3 provider tiers are locked', () {
      expect(AgentProviderExpansionTier.values.length, 3);
    });

    test('8 provider capabilities are locked', () {
      expect(AgentProviderExpansionCapability.values.length, 8);
    });

    test('7 activation statuses are locked', () {
      expect(AgentProviderExpansionActivationStatus.values.length, 7);
    });

    test('valid free provider contract is metadata-only', () {
      final value = contract();
      value.validateStructure();

      expect(value.secretReferenceOnly, true);
      expect(value.containsRawApiKey, false);
      expect(value.containsRawToken, false);
      expect(value.containsRawSecret, false);
      expect(value.clientMayReadSecret, false);
      expect(value.clientMayActivateProvider, false);
      expect(value.grantsPermission, false);
      expect(value.consumesApproval, false);
      expect(value.expandsScope, false);
      expect(value.executesBusinessAction, false);
      expect(value.invokesProvider, false);
      expect(value.persistsContract, false);
    });

    test('raw OpenAI-style secret is rejected as secret reference', () {
      final invalid = AgentProviderExpansionContract(
        providerId: 'provider:bad',
        displayName: 'Bad Provider',
        tier: AgentProviderExpansionTier.freeOnline,
        enabled: true,
        backendOnly: true,
        secretReferenceId: 'sk-abcdefghijklmnopqrstuvwxyz1234567890',
        defaultModelReference: 'model_ref:bad',
        capabilities: const <String>{
          AgentProviderExpansionCapability.textReasoning,
        },
      );

      expect(invalid.validateStructure, throwsFormatException);
    });

    test('capability registry returns deterministic metadata', () {
      final descriptors = registry.describe(contract());

      expect(descriptors.length, 2);
      expect(descriptors.map((value) => value.capability).toList(), <String>[
        AgentProviderExpansionCapability.structuredJson,
        AgentProviderExpansionCapability.textReasoning,
      ]);
      expect(descriptors.every((value) => value.metadataOnly), true);
      expect(descriptors.every((value) => !value.qualityScoreOwnedHere), true);
    });

    test('registry supports declared capability only', () {
      final value = contract();

      expect(
        registry.supports(
          value,
          AgentProviderExpansionCapability.textReasoning,
        ),
        true,
      );

      expect(
        registry.supports(value, AgentProviderExpansionCapability.visionInput),
        false,
      );
    });

    test('free provider can be policy-eligible on trusted backend', () {
      final result = policy.evaluate(contract: contract(), request: request());

      expect(result.eligible, true);
      expect(
        result.status,
        AgentProviderExpansionActivationStatus
            .eligibleForTrustedBackendActivation,
      );
      expect(result.policyDecisionOnly, true);
      expect(result.activatesProviderHere, false);
      expect(result.invokesProvider, false);
    });

    test('disabled provider is blocked', () {
      final result = policy.evaluate(
        contract: contract(enabled: false),
        request: request(providerEnabled: false),
      );

      expect(
        result.status,
        AgentProviderExpansionActivationStatus.blockedDisabled,
      );
    });

    test('client-side activation is blocked', () {
      final result = policy.evaluate(
        contract: contract(),
        request: request(backendExecution: false),
      );

      expect(
        result.status,
        AgentProviderExpansionActivationStatus.blockedSecretBoundary,
      );
    });

    test('unresolved backend secret reference blocks activation', () {
      final result = policy.evaluate(
        contract: contract(),
        request: request(secretResolved: false),
      );

      expect(
        result.status,
        AgentProviderExpansionActivationStatus.blockedSecretBoundary,
      );
    });

    test('unsupported capability is blocked', () {
      final result = policy.evaluate(
        contract: contract(),
        request: request(
          capability: AgentProviderExpansionCapability.visionInput,
        ),
      );

      expect(
        result.status,
        AgentProviderExpansionActivationStatus.blockedCapabilityMismatch,
      );
    });

    test('provider cannot request permission grant', () {
      final result = policy.evaluate(
        contract: contract(),
        request: request(requestsPermissionGrant: true),
      );

      expect(
        result.status,
        AgentProviderExpansionActivationStatus.blockedUnsafeAuthorityRequest,
      );
    });

    test('provider cannot consume approval', () {
      final result = policy.evaluate(
        contract: contract(),
        request: request(requestsApprovalConsumption: true),
      );

      expect(
        result.status,
        AgentProviderExpansionActivationStatus.blockedUnsafeAuthorityRequest,
      );
    });

    test('provider cannot expand scope', () {
      final result = policy.evaluate(
        contract: contract(),
        request: request(requestsScopeExpansion: true),
      );

      expect(
        result.status,
        AgentProviderExpansionActivationStatus.blockedUnsafeAuthorityRequest,
      );
    });

    test('provider cannot execute business action', () {
      final result = policy.evaluate(
        contract: contract(),
        request: request(requestsBusinessAction: true),
      );

      expect(
        result.status,
        AgentProviderExpansionActivationStatus.blockedUnsafeAuthorityRequest,
      );
    });

    test('paid provider blocked when paid AI disabled', () {
      final paidContract = contract(
        providerId: 'provider:paid:primary',
        tier: AgentProviderExpansionTier.paidLastEscalation,
      );

      final result = policy.evaluate(
        contract: paidContract,
        request: request(
          providerId: 'provider:paid:primary',
          paidAiEnabled: false,
          budgetAllowed: true,
          paidApprovalGranted: true,
        ),
      );

      expect(
        result.status,
        AgentProviderExpansionActivationStatus.blockedPaidControl,
      );
    });

    test('paid provider blocked when budget disallows use', () {
      final paidContract = contract(
        providerId: 'provider:paid:primary',
        tier: AgentProviderExpansionTier.paidLastEscalation,
      );

      final result = policy.evaluate(
        contract: paidContract,
        request: request(
          providerId: 'provider:paid:primary',
          paidAiEnabled: true,
          budgetAllowed: false,
          paidApprovalGranted: true,
        ),
      );

      expect(
        result.status,
        AgentProviderExpansionActivationStatus.blockedPaidControl,
      );
    });

    test('ask-before-paid blocks without approval', () {
      final paidContract = contract(
        providerId: 'provider:paid:primary',
        tier: AgentProviderExpansionTier.paidLastEscalation,
      );

      final result = policy.evaluate(
        contract: paidContract,
        request: request(
          providerId: 'provider:paid:primary',
          paidAiEnabled: true,
          askBeforePaid: true,
          paidApprovalGranted: false,
          budgetAllowed: true,
        ),
      );

      expect(
        result.status,
        AgentProviderExpansionActivationStatus.blockedPaidControl,
      );
    });

    test('paid provider may become policy-eligible only after controls', () {
      final paidContract = contract(
        providerId: 'provider:paid:primary',
        tier: AgentProviderExpansionTier.paidLastEscalation,
      );

      final result = policy.evaluate(
        contract: paidContract,
        request: request(
          providerId: 'provider:paid:primary',
          paidAiEnabled: true,
          askBeforePaid: true,
          paidApprovalGranted: true,
          budgetAllowed: true,
        ),
      );

      expect(result.eligible, true);
      expect(result.activatesProviderHere, false);
    });

    test('activation decision grants no authority', () {
      final result = policy.evaluate(contract: contract(), request: request());

      expect(result.containsSecret, false);
      expect(result.grantsPermission, false);
      expect(result.consumesApproval, false);
      expect(result.expandsScope, false);
      expect(result.executesBusinessAction, false);
      expect(result.writesBusinessData, false);
      expect(result.persistsDecision, false);
    });

    test('policy locks free/local/paid and secret boundaries', () {
      expect(policy.freeOnlineFirstPriority, true);
      expect(policy.localAiOptionalFuture, true);
      expect(policy.paidAiLastEscalation, true);
      expect(policy.paidAiOnOffRequired, true);
      expect(policy.askBeforePaidPreserved, true);
      expect(policy.paidBudgetRequired, true);
      expect(policy.budgetExhaustionStopsPaidOnly, true);
      expect(policy.backendExecutionRequired, true);
      expect(policy.backendSecretResolutionRequired, true);
      expect(policy.rawSecretsForbiddenInClient, true);
    });

    test('policy preserves authority separation and phase ownership', () {
      expect(policy.providerCannotGrantPermission, true);
      expect(policy.providerCannotConsumeApproval, true);
      expect(policy.providerCannotExpandScope, true);
      expect(policy.providerCannotExecuteBusinessAction, true);
      expect(policy.realActivationImplementedHere, false);
      expect(policy.providerInvocationImplementedHere, false);
      expect(policy.qualityEvaluatorImplementedHere, false);
      expect(policy.phase59OwnsProviderQualityEvaluator, true);
      expect(policy.phase62TrainingDeploymentSeparate, true);
      expect(policy.phase63PrivacyRetentionUiSeparate, true);
    });

    test('registry itself adds no activation or authority', () {
      expect(registry.registryIsMetadataOnly, true);
      expect(registry.qualityEvaluationOwnedHere, false);
      expect(registry.rankingOwnedHere, false);
      expect(registry.activatesProvider, false);
      expect(registry.invokesProvider, false);
      expect(registry.grantsPermission, false);
      expect(registry.executesBusinessAction, false);
      expect(registry.persistsRegistry, false);
    });
  });
}

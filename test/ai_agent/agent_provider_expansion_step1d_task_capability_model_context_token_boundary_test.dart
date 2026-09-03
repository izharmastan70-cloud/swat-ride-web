import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_provider_expansion_contract_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_provider_task_routing_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_context_token_budget.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_model_compatibility_profile.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_task_requirements.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_task_capability_matrix.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_task_routing_policy.dart';

void main() {
  const AgentProviderTaskCapabilityMatrix matrix =
      AgentProviderTaskCapabilityMatrix();

  const AgentProviderTaskRoutingPolicy policy =
      AgentProviderTaskRoutingPolicy();

  AgentProviderTaskRequirements task({
    String taskType = AgentProviderTaskType.generalReasoning,
    Set<String>? requiredCapabilities,
    bool requiresStructuredOutput = false,
    bool requiresVisionInput = false,
    bool minimumNecessaryContextConfirmed = true,
  }) {
    return AgentProviderTaskRequirements(
      requestId: 'task:route:001',
      taskType: taskType,
      requiredCapabilities:
          requiredCapabilities ?? matrix.requiredCapabilitiesFor(taskType),
      requiresStructuredOutput: requiresStructuredOutput,
      requiresVisionInput: requiresVisionInput,
      minimumNecessaryContextConfirmed: minimumNecessaryContextConfirmed,
    );
  }

  AgentProviderModelCompatibilityProfile model({
    bool enabled = true,
    bool backendOnly = true,
    Set<String> supportedCapabilities = const <String>{
      AgentProviderExpansionCapability.textReasoning,
      AgentProviderExpansionCapability.structuredJson,
      AgentProviderExpansionCapability.summarization,
      AgentProviderExpansionCapability.classification,
      AgentProviderExpansionCapability.translation,
      AgentProviderExpansionCapability.visionInput,
      AgentProviderExpansionCapability.codeReasoning,
      AgentProviderExpansionCapability.embeddings,
    },
    int maxContextTokens = 8192,
    int maxOutputTokens = 2048,
    bool supportsStructuredOutput = true,
    bool supportsVisionInput = true,
  }) {
    return AgentProviderModelCompatibilityProfile(
      providerId: 'provider:free:a',
      modelReference: 'model_ref:provider:free:a',
      enabled: enabled,
      backendOnly: backendOnly,
      supportedCapabilities: supportedCapabilities,
      maxContextTokens: maxContextTokens,
      maxOutputTokens: maxOutputTokens,
      supportsStructuredOutput: supportsStructuredOutput,
      supportsVisionInput: supportsVisionInput,
    );
  }

  const AgentProviderContextTokenBudget normalBudget =
      AgentProviderContextTokenBudget(
        estimatedInputTokens: 1200,
        requestedMaxOutputTokens: 600,
        safetyReserveTokens: 256,
      );

  group('Phase 58 Step 1D task/capability/model/token boundary', () {
    test('10 task types are locked', () {
      expect(AgentProviderTaskType.values.length, 10);
    });

    test('9 task route statuses are locked', () {
      expect(AgentProviderTaskRouteStatus.values.length, 9);
    });

    test('general reasoning maps to text reasoning', () {
      expect(
        matrix.requiredCapabilitiesFor(AgentProviderTaskType.generalReasoning),
        const <String>{AgentProviderExpansionCapability.textReasoning},
      );
    });

    test('structured response requires text + JSON', () {
      expect(
        matrix.requiredCapabilitiesFor(
          AgentProviderTaskType.structuredResponse,
        ),
        const <String>{
          AgentProviderExpansionCapability.textReasoning,
          AgentProviderExpansionCapability.structuredJson,
        },
      );
    });

    test('vision task requires vision + text reasoning', () {
      expect(
        matrix.requiredCapabilitiesFor(
          AgentProviderTaskType.visionUnderstanding,
        ),
        const <String>{
          AgentProviderExpansionCapability.visionInput,
          AgentProviderExpansionCapability.textReasoning,
        },
      );
    });

    test('content and knowledge tasks require structured output', () {
      expect(
        matrix.requiresStructuredOutput(AgentProviderTaskType.contentDraft),
        true,
      );
      expect(
        matrix.requiresStructuredOutput(AgentProviderTaskType.knowledgeAnswer),
        true,
      );
    });

    test('valid compatible task is eligible for resilient routing', () {
      final result = policy.evaluate(
        task: task(),
        model: model(),
        contextBudget: normalBudget,
      );

      expect(result.eligible, true);
      expect(
        result.status,
        AgentProviderTaskRouteStatus.eligibleForResilientRouting,
      );
      expect(result.providerId, 'provider:free:a');
      expect(result.totalReservedTokens, 2056);
      expect(result.preservesStep1CRoutingOrder, true);
    });

    test('declared capabilities must match deterministic task matrix', () {
      final result = policy.evaluate(
        task: task(
          requiredCapabilities: const <String>{
            AgentProviderExpansionCapability.translation,
          },
        ),
        model: model(),
        contextBudget: normalBudget,
      );

      expect(result.status, AgentProviderTaskRouteStatus.blockedInvalidRequest);
    });

    test('disabled model is blocked', () {
      final result = policy.evaluate(
        task: task(),
        model: model(enabled: false),
        contextBudget: normalBudget,
      );

      expect(result.status, AgentProviderTaskRouteStatus.blockedModelDisabled);
    });

    test('client-side model execution is blocked', () {
      final result = policy.evaluate(
        task: task(),
        model: model(backendOnly: false),
        contextBudget: normalBudget,
      );

      expect(
        result.status,
        AgentProviderTaskRouteStatus.blockedBackendBoundary,
      );
    });

    test('minimum necessary context confirmation is mandatory', () {
      final result = policy.evaluate(
        task: task(minimumNecessaryContextConfirmed: false),
        model: model(),
        contextBudget: normalBudget,
      );

      expect(
        result.status,
        AgentProviderTaskRouteStatus.blockedMinimumContextPolicy,
      );
    });

    test('missing capability blocks model compatibility', () {
      final result = policy.evaluate(
        task: task(taskType: AgentProviderTaskType.translation),
        model: model(
          supportedCapabilities: const <String>{
            AgentProviderExpansionCapability.textReasoning,
          },
        ),
        contextBudget: normalBudget,
      );

      expect(
        result.status,
        AgentProviderTaskRouteStatus.blockedCapabilityMismatch,
      );
    });

    test('structured output requirement must be supported', () {
      final result = policy.evaluate(
        task: task(
          taskType: AgentProviderTaskType.structuredResponse,
          requiresStructuredOutput: true,
        ),
        model: model(supportsStructuredOutput: false),
        contextBudget: normalBudget,
      );

      expect(
        result.status,
        AgentProviderTaskRouteStatus.blockedModelFeatureMismatch,
      );
    });

    test('vision task requires model vision support', () {
      final result = policy.evaluate(
        task: task(
          taskType: AgentProviderTaskType.visionUnderstanding,
          requiresVisionInput: true,
        ),
        model: model(supportsVisionInput: false),
        contextBudget: normalBudget,
      );

      expect(
        result.status,
        AgentProviderTaskRouteStatus.blockedModelFeatureMismatch,
      );
    });

    test('context window overflow fails closed', () {
      const budget = AgentProviderContextTokenBudget(
        estimatedInputTokens: 7600,
        requestedMaxOutputTokens: 600,
        safetyReserveTokens: 256,
      );

      final result = policy.evaluate(
        task: task(),
        model: model(maxContextTokens: 8192),
        contextBudget: budget,
      );

      expect(result.status, AgentProviderTaskRouteStatus.blockedContextBudget);
    });

    test('requested output above model max fails closed', () {
      const budget = AgentProviderContextTokenBudget(
        estimatedInputTokens: 1000,
        requestedMaxOutputTokens: 3000,
        safetyReserveTokens: 256,
      );

      final result = policy.evaluate(
        task: task(),
        model: model(maxOutputTokens: 2048),
        contextBudget: budget,
      );

      expect(result.status, AgentProviderTaskRouteStatus.blockedContextBudget);
    });

    test('token budget reserves explicit safety margin', () {
      expect(normalBudget.totalReservedTokens, 2056);
      expect(
        normalBudget.fits(
          modelMaxContextTokens: 8192,
          modelMaxOutputTokens: 2048,
        ),
        true,
      );
    });

    test('context budget stores no raw prompt/conversation', () {
      expect(normalBudget.rawPromptStored, false);
      expect(normalBudget.rawConversationStored, false);
      expect(normalBudget.tokenizerImplementedHere, false);
      expect(normalBudget.automaticTruncationImplementedHere, false);
      expect(normalBudget.tokenChargeImplementedHere, false);
      expect(normalBudget.costChargeImplementedHere, false);
      expect(normalBudget.mutatesBudget, false);
      expect(normalBudget.invokesProvider, false);
      expect(normalBudget.persistsBudget, false);
    });

    test('task requirements contain no raw prompt and no authority', () {
      final value = task();

      expect(value.containsRawPrompt, false);
      expect(value.containsRawConversation, false);
      expect(value.containsRawUserMessage, false);
      expect(value.tokenizerRunsHere, false);
      expect(value.truncatesContentHere, false);
      expect(value.invokesProvider, false);
      expect(value.chargesTokens, false);
      expect(value.mutatesBudget, false);
      expect(value.grantsPermission, false);
      expect(value.executesBusinessAction, false);
      expect(value.persistsRequest, false);
    });

    test('model profile is secret-free metadata only', () {
      final value = model();

      expect(value.metadataOnly, true);
      expect(value.containsRawApiKey, false);
      expect(value.containsRawToken, false);
      expect(value.containsRawSecret, false);
      expect(value.clientMayExecuteModel, false);
      expect(value.qualityScoreOwnedHere, false);
      expect(value.providerRankingOwnedHere, false);
      expect(value.invokesProvider, false);
      expect(value.grantsPermission, false);
      expect(value.consumesApproval, false);
      expect(value.expandsScope, false);
      expect(value.executesBusinessAction, false);
      expect(value.persistsProfile, false);
    });

    test('eligible decision does not invoke/charge/mutate authority', () {
      final result = policy.evaluate(
        task: task(),
        model: model(),
        contextBudget: normalBudget,
      );

      expect(result.decisionOnly, true);
      expect(result.invokesProvider, false);
      expect(result.activatesProvider, false);
      expect(result.grantsPermission, false);
      expect(result.consumesApproval, false);
      expect(result.expandsScope, false);
      expect(result.executesBusinessAction, false);
      expect(result.writesBusinessData, false);
      expect(result.chargesTokens, false);
      expect(result.chargesCost, false);
      expect(result.mutatesBudget, false);
      expect(result.persistsDecision, false);
    });

    test('policy locks model/context/token boundaries', () {
      expect(policy.taskCapabilityMatrixRequired, true);
      expect(policy.modelCompatibilityRequired, true);
      expect(policy.backendOnlyExecutionRequired, true);
      expect(policy.minimumNecessaryContextRequired, true);
      expect(policy.contextMustFitModelWindow, true);
      expect(policy.outputMustFitModelLimit, true);
      expect(policy.safetyReserveRequired, true);
      expect(policy.automaticTruncationDisabled, true);
      expect(policy.rawPromptNotStored, true);
      expect(policy.rawConversationNotStored, true);
    });

    test('policy does not charge tokens/cost or mutate budget', () {
      expect(policy.tokenChargingImplementedHere, false);
      expect(policy.costChargingImplementedHere, false);
      expect(policy.budgetMutationImplementedHere, false);
      expect(policy.providerInvocationImplementedHere, false);
    });

    test('Step 1C routing order remains authoritative next', () {
      expect(policy.preservesStep1CFreeLocalPaidOrder, true);
    });

    test('Phase 59 quality evaluator remains separate', () {
      expect(policy.providerQualityEvaluationOwnedHere, false);
      expect(policy.phase59OwnsProviderQualityEvaluator, true);
      expect(matrix.providerRankingOwnedHere, false);
      expect(matrix.qualityScoringOwnedHere, false);
    });

    test('matrix itself is deterministic metadata only', () {
      expect(matrix.mappingIsDeterministicMetadata, true);
      expect(matrix.invokesProvider, false);
      expect(matrix.grantsAuthority, false);
      expect(matrix.persistsMatrix, false);
    });

    test('policy adds no permission/approval/scope/business authority', () {
      expect(policy.grantsPermission, false);
      expect(policy.consumesApproval, false);
      expect(policy.expandsScope, false);
      expect(policy.executesBusinessAction, false);
      expect(policy.writesBusinessData, false);
      expect(policy.persistsRoutingDecision, false);
    });
  });
}

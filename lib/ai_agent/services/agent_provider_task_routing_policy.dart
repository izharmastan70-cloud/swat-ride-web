import '../constants/agent_provider_task_routing_constants.dart';
import '../models/agent_provider_context_token_budget.dart';
import '../models/agent_provider_model_compatibility_profile.dart';
import '../models/agent_provider_task_requirements.dart';
import '../models/agent_provider_task_route_decision.dart';
import 'agent_provider_task_capability_matrix.dart';

class AgentProviderTaskRoutingPolicy {
  const AgentProviderTaskRoutingPolicy({
    this.matrix = const AgentProviderTaskCapabilityMatrix(),
  });

  final AgentProviderTaskCapabilityMatrix matrix;

  AgentProviderTaskRouteDecision evaluate({
    required AgentProviderTaskRequirements task,
    required AgentProviderModelCompatibilityProfile model,
    required AgentProviderContextTokenBudget contextBudget,
  }) {
    try {
      task.validateStructure();
      model.validateStructure();
      contextBudget.validateStructure();
    } catch (_) {
      return _blocked(
        status: AgentProviderTaskRouteStatus.blockedInvalidRequest,
        requestId: task.requestId,
        reasons: const <String>[
          'invalid_task_model_or_context_metadata',
          'fail_closed',
        ],
      );
    }

    final Set<String> matrixCapabilities = matrix.requiredCapabilitiesFor(
      task.taskType,
    );

    if (matrixCapabilities.isEmpty) {
      return _blocked(
        status: AgentProviderTaskRouteStatus.blockedUnsupportedTask,
        requestId: task.requestId,
        reasons: const <String>['task_type_not_mapped', 'fail_closed'],
      );
    }

    if (task.requiredCapabilities.length != matrixCapabilities.length ||
        !task.requiredCapabilities.containsAll(matrixCapabilities)) {
      return _blocked(
        status: AgentProviderTaskRouteStatus.blockedInvalidRequest,
        requestId: task.requestId,
        reasons: const <String>[
          'declared_capabilities_do_not_match_task_matrix',
          'fail_closed',
        ],
      );
    }

    if (!model.enabled) {
      return _blocked(
        status: AgentProviderTaskRouteStatus.blockedModelDisabled,
        requestId: task.requestId,
        reasons: const <String>['model_disabled'],
      );
    }

    if (!model.backendOnly) {
      return _blocked(
        status: AgentProviderTaskRouteStatus.blockedBackendBoundary,
        requestId: task.requestId,
        reasons: const <String>[
          'backend_only_model_execution_required',
          'client_model_execution_blocked',
        ],
      );
    }

    if (!task.minimumNecessaryContextConfirmed) {
      return _blocked(
        status: AgentProviderTaskRouteStatus.blockedMinimumContextPolicy,
        requestId: task.requestId,
        reasons: const <String>[
          'minimum_necessary_context_not_confirmed',
          'reduce_context_before_routing',
        ],
      );
    }

    if (!model.supportedCapabilities.containsAll(matrixCapabilities)) {
      return _blocked(
        status: AgentProviderTaskRouteStatus.blockedCapabilityMismatch,
        requestId: task.requestId,
        reasons: const <String>['model_missing_required_capability'],
      );
    }

    final bool structuredRequired =
        task.requiresStructuredOutput ||
        matrix.requiresStructuredOutput(task.taskType);

    final bool visionRequired =
        task.requiresVisionInput || matrix.requiresVisionInput(task.taskType);

    if ((structuredRequired && !model.supportsStructuredOutput) ||
        (visionRequired && !model.supportsVisionInput)) {
      return _blocked(
        status: AgentProviderTaskRouteStatus.blockedModelFeatureMismatch,
        requestId: task.requestId,
        reasons: const <String>['model_feature_compatibility_mismatch'],
      );
    }

    if (!contextBudget.fits(
      modelMaxContextTokens: model.maxContextTokens,
      modelMaxOutputTokens: model.maxOutputTokens,
    )) {
      return _blocked(
        status: AgentProviderTaskRouteStatus.blockedContextBudget,
        requestId: task.requestId,
        reasons: const <String>[
          'context_or_output_budget_exceeds_model_limits',
          'do_not_auto_truncate_or_charge',
          'fail_closed',
        ],
      );
    }

    final List<String> sortedCapabilities = matrixCapabilities.toList()..sort();

    final AgentProviderTaskRouteDecision decision =
        AgentProviderTaskRouteDecision(
          status: AgentProviderTaskRouteStatus.eligibleForResilientRouting,
          requestId: task.requestId,
          providerId: model.providerId,
          modelReference: model.modelReference,
          requiredCapabilities: sortedCapabilities,
          totalReservedTokens: contextBudget.totalReservedTokens,
          reasonCodes: const <String>[
            'task_capability_matrix_match',
            'model_capability_match',
            'backend_only_boundary_satisfied',
            'minimum_necessary_context_confirmed',
            'context_token_budget_fit',
            'step1c_routing_order_still_applies_next',
            'no_provider_invocation_here',
          ],
        );

    decision.validateStructure();
    return decision;
  }

  AgentProviderTaskRouteDecision _blocked({
    required String status,
    required String requestId,
    required List<String> reasons,
  }) {
    final AgentProviderTaskRouteDecision decision =
        AgentProviderTaskRouteDecision(
          status: status,
          requestId: requestId.trim().isEmpty
              ? 'invalid_task_route_request'
              : requestId,
          providerId: '',
          modelReference: '',
          requiredCapabilities: const <String>[],
          totalReservedTokens: 0,
          reasonCodes: reasons,
        );

    decision.validateStructure();
    return decision;
  }

  bool get taskCapabilityMatrixRequired => true;
  bool get modelCompatibilityRequired => true;
  bool get backendOnlyExecutionRequired => true;
  bool get minimumNecessaryContextRequired => true;
  bool get contextMustFitModelWindow => true;
  bool get outputMustFitModelLimit => true;
  bool get safetyReserveRequired => true;
  bool get automaticTruncationDisabled => true;
  bool get rawPromptNotStored => true;
  bool get rawConversationNotStored => true;
  bool get tokenChargingImplementedHere => false;
  bool get costChargingImplementedHere => false;
  bool get budgetMutationImplementedHere => false;
  bool get providerInvocationImplementedHere => false;
  bool get preservesStep1CFreeLocalPaidOrder => true;
  bool get providerQualityEvaluationOwnedHere => false;
  bool get phase59OwnsProviderQualityEvaluator => true;

  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get expandsScope => false;
  bool get executesBusinessAction => false;
  bool get writesBusinessData => false;
  bool get persistsRoutingDecision => false;
}

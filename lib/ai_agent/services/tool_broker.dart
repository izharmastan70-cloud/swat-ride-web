import '../models/admin_intelligence_execution_boundary_result.dart';
import '../models/admin_intelligence_execution_handoff.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_role.dart';
import '../models/agent_cross_agent_supervisor_request.dart';
import '../models/agent_project_context.dart';
import '../models/capability_contract.dart';
import 'admin_intelligence_execution_boundary_service.dart';
import 'agent_action_registry.dart';
import 'agent_cross_agent_supervisor_contract_service.dart';

class ToolBrokerResult<T> {
  const ToolBrokerResult._({
    required this.prepared,
    required this.reason,
    required this.boundaryResult,
    this.data,
  });

  final bool prepared;
  final String reason;
  final AdminIntelligenceExecutionBoundaryResult? boundaryResult;
  final T? data;

  factory ToolBrokerResult.ready({
    required T data,
    required AdminIntelligenceExecutionBoundaryResult boundaryResult,
  }) {
    return ToolBrokerResult<T>._(
      prepared: true,
      reason: 'tool_preparation_ready',
      boundaryResult: boundaryResult,
      data: data,
    );
  }

  factory ToolBrokerResult.blocked({
    required String reason,
    AdminIntelligenceExecutionBoundaryResult? boundaryResult,
  }) {
    return ToolBrokerResult<T>._(
      prepared: false,
      reason: reason,
      boundaryResult: boundaryResult,
    );
  }
}

/// Registers preparation-only capability adapters behind the established AI
/// authorization boundary. This broker never grants roles, trusts a caller's
/// approval claim, or executes provider/business/financial operations.
class ToolBroker {
  ToolBroker({
    AdminIntelligenceExecutionBoundary? executionBoundary,
    AgentCrossAgentSupervisorContractService? supervisor,
  }) : _supervisor =
           supervisor ?? const AgentCrossAgentSupervisorContractService(),
       _executionBoundary =
           executionBoundary ?? AdminIntelligenceExecutionBoundaryService();

  final AdminIntelligenceExecutionBoundary _executionBoundary;
  final AgentCrossAgentSupervisorContractService _supervisor;
  final Map<String, CapabilityContract<dynamic>> _capabilities =
      <String, CapabilityContract<dynamic>>{};

  void register<T>(CapabilityContract<T> capability) {
    final String actionId = capability.actionId.trim();
    final action = AgentActionRegistry.get(actionId);

    if (actionId.isEmpty || action == null) {
      throw ArgumentError.value(
        capability.actionId,
        'capability.actionId',
        'A capability must use a registered action ID.',
      );
    }

    if (capability.module.trim() != action.module) {
      throw ArgumentError.value(
        capability.module,
        'capability.module',
        'Capability module must match the registered action module.',
      );
    }

    if (_capabilities.containsKey(actionId)) {
      throw StateError('Capability "$actionId" is already registered.');
    }

    _capabilities[actionId] = capability;
  }

  Future<ToolBrokerResult<T>> prepare<T>({
    required String actionId,
    required AgentMasterSettings settings,
    required AgentRole role,
    required String actorId,
    required AdminIntelligenceExecutionHandoff handoff,
    required AgentProjectContext projectContext,
    required AgentCrossAgentSupervisorRequest supervisorRequest,
    required Map<String, dynamic> input,
    String? approvalId,
  }) async {
    final String normalizedActionId = actionId.trim();
    final CapabilityContract<dynamic>? capability =
        _capabilities[normalizedActionId];

    if (capability == null) {
      return ToolBrokerResult<T>.blocked(
        reason: 'tool_capability_not_registered_fail_closed',
      );
    }

    try {
      projectContext.validate(now: DateTime.now().toUtc());
    } on Object {
      return ToolBrokerResult<T>.blocked(
        reason: 'tool_project_context_invalid_fail_closed',
      );
    }

    if (!projectContext.allowsModule(capability.module) ||
        !_projectContextMatches(handoff.projectContext, projectContext)) {
      return ToolBrokerResult<T>.blocked(
        reason: 'tool_project_context_mismatch_fail_closed',
      );
    }

    if (handoff.requiredCapability.trim() != normalizedActionId) {
      return ToolBrokerResult<T>.blocked(
        reason: 'tool_handoff_capability_mismatch_fail_closed',
      );
    }

    if (supervisorRequest.taskId != handoff.taskId ||
        supervisorRequest.targetAgentId != role.roleId ||
        supervisorRequest.actionId != normalizedActionId) {
      return ToolBrokerResult<T>.blocked(
        reason: 'tool_supervisor_role_or_action_mismatch_fail_closed',
      );
    }

    final supervisorDecision = _supervisor.evaluate(supervisorRequest);
    if (supervisorDecision.recommendHold || supervisorDecision.recommendStop) {
      return ToolBrokerResult<T>.blocked(
        reason: 'tool_supervisor_${supervisorDecision.status.toLowerCase()}',
      );
    }

    try {
      capability.validateInput(Map<String, dynamic>.from(input));
    } on Object {
      return ToolBrokerResult<T>.blocked(
        reason: 'tool_input_invalid_fail_closed',
      );
    }

    final AdminIntelligenceExecutionBoundaryResult boundaryResult;
    try {
      boundaryResult = await _executionBoundary.prepare(
        now: DateTime.now().toUtc(),
        settings: settings,
        role: role,
        actionId: normalizedActionId,
        actorId: actorId,
        handoff: handoff,
        approvalId: approvalId,
      );
    } on Object {
      return ToolBrokerResult<T>.blocked(
        reason: 'tool_authorization_boundary_error_fail_closed',
      );
    }

    if (!boundaryResult.boundaryReady) {
      return ToolBrokerResult<T>.blocked(
        reason: boundaryResult.reason,
        boundaryResult: boundaryResult,
      );
    }

    try {
      final dynamic prepared = await capability.prepare(
        Map<String, dynamic>.from(input),
      );
      return ToolBrokerResult<T>.ready(
        data: prepared as T,
        boundaryResult: boundaryResult,
      );
    } on Object {
      return ToolBrokerResult<T>.blocked(
        reason: 'tool_preparation_failed_fail_closed',
        boundaryResult: boundaryResult,
      );
    }
  }

  bool _projectContextMatches(
    AgentProjectContext? handoffContext,
    AgentProjectContext requestContext,
  ) {
    if (handoffContext == null) return false;
    return handoffContext.tenantId == requestContext.tenantId &&
        handoffContext.projectId == requestContext.projectId &&
        handoffContext.workspaceId == requestContext.workspaceId &&
        handoffContext.contextFingerprint == requestContext.contextFingerprint;
  }
}
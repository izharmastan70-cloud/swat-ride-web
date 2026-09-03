import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_enums.dart';
import 'package:swat_ride/ai_agent/models/admin_intelligence_execution_boundary_result.dart';
import 'package:swat_ride/ai_agent/models/admin_intelligence_execution_handoff.dart';
import 'package:swat_ride/ai_agent/models/admin_intelligence_security_authorization.dart';
import 'package:swat_ride/ai_agent/models/agent_cross_agent_supervisor_request.dart';
import 'package:swat_ride/ai_agent/models/agent_cross_agent_supervisor_security_snapshot.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_permission_decision.dart';
import 'package:swat_ride/ai_agent/models/agent_project_context.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/models/capability_contract.dart';
import 'package:swat_ride/ai_agent/services/admin_intelligence_execution_boundary_service.dart';
import 'package:swat_ride/ai_agent/services/tool_broker.dart';

void main() {
  final AgentRole role = AgentRole(
    roleId: 'core_agent',
    name: 'Core Agent',
    description: 'Test role.',
    module: 'core',
    enabled: true,
    mode: AgentMode.auto,
    allowedActions: const <String>['core.read_system_health'],
    aiClass: AiClass.freeAi,
    privacyLevel: PrivacyLevel.internal,
    createdAt: DateTime.utc(2026, 8, 31),
  );

  test('prepares only after the trusted boundary is ready', () async {
    final FakeBoundary boundary = FakeBoundary(readyBoundaryResult());
    final ToolBroker broker = ToolBroker(executionBoundary: boundary);
    final TestCapability capability = TestCapability();
    final AgentProjectContext projectContext = validProjectContext();
    broker.register<String>(capability);

    final ToolBrokerResult<String> result = await broker.prepare<String>(
      actionId: capability.actionId,
      settings: enabledSettings(),
      role: role,
      actorId: 'owner_1',
      handoff: validHandoff(projectContext: projectContext),
      projectContext: projectContext,
      supervisorRequest: validSupervisorRequest(),
      input: const <String, dynamic>{'requestId': 'request_1'},
    );

    expect(result.prepared, isTrue);
    expect(result.data, 'prepared:request_1');
    expect(boundary.prepareCalls, 1);
    expect(capability.prepareCalls, 1);
  });

  test('does not prepare when boundary blocks authorization', () async {
    final FakeBoundary boundary = FakeBoundary(blockedBoundaryResult());
    final ToolBroker broker = ToolBroker(executionBoundary: boundary);
    final TestCapability capability = TestCapability();
    final AgentProjectContext projectContext = validProjectContext();
    broker.register<String>(capability);

    final ToolBrokerResult<String> result = await broker.prepare<String>(
      actionId: capability.actionId,
      settings: enabledSettings(),
      role: role,
      actorId: 'owner_1',
      handoff: validHandoff(projectContext: projectContext),
      projectContext: projectContext,
      supervisorRequest: validSupervisorRequest(),
      input: const <String, dynamic>{'requestId': 'request_1'},
    );

    expect(result.prepared, isFalse);
    expect(result.reason, 'blocked_by_boundary');
    expect(capability.prepareCalls, 0);
  });

  test('rejects a handoff for a different capability before authorization',
      () async {
    final FakeBoundary boundary = FakeBoundary(readyBoundaryResult());
    final ToolBroker broker = ToolBroker(executionBoundary: boundary);
    final TestCapability capability = TestCapability();
    final AgentProjectContext projectContext = validProjectContext();
    broker.register<String>(capability);

    final ToolBrokerResult<String> result = await broker.prepare<String>(
      actionId: capability.actionId,
      settings: enabledSettings(),
      role: role,
      actorId: 'owner_1',
      handoff: validHandoff(
        requiredCapability: 'core.read_daily_summary',
        projectContext: projectContext,
      ),
      projectContext: projectContext,
      supervisorRequest: validSupervisorRequest(),
      input: const <String, dynamic>{'requestId': 'request_1'},
    );

    expect(result.prepared, isFalse);
    expect(result.reason, 'tool_handoff_capability_mismatch_fail_closed');
    expect(boundary.prepareCalls, 0);
    expect(capability.prepareCalls, 0);
  });

  test('rejects a project context from another tenant before authorization',
      () async {
    final FakeBoundary boundary = FakeBoundary(readyBoundaryResult());
    final ToolBroker broker = ToolBroker(executionBoundary: boundary);
    final TestCapability capability = TestCapability();
    final AgentProjectContext handoffContext = validProjectContext();
    final AgentProjectContext otherProjectContext = AgentProjectContext.create(
      tenantId: 'client_tenant',
      projectId: 'client_project',
      workspaceId: 'client_workspace',
      allowedModules: const <String>['core'],
      issuedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 5)),
    );
    broker.register<String>(capability);

    final ToolBrokerResult<String> result = await broker.prepare<String>(
      actionId: capability.actionId,
      settings: enabledSettings(),
      role: role,
      actorId: 'owner_1',
      handoff: validHandoff(projectContext: handoffContext),
      projectContext: otherProjectContext,
      supervisorRequest: validSupervisorRequest(),
      input: const <String, dynamic>{'requestId': 'request_1'},
    );

    expect(result.prepared, isFalse);
    expect(result.reason, 'tool_project_context_mismatch_fail_closed');
    expect(boundary.prepareCalls, 0);
    expect(capability.prepareCalls, 0);
  });

  test('blocks when supervisor recommends an emergency stop', () async {
    final FakeBoundary boundary = FakeBoundary(readyBoundaryResult());
    final ToolBroker broker = ToolBroker(executionBoundary: boundary);
    final TestCapability capability = TestCapability();
    final AgentProjectContext projectContext = validProjectContext();
    broker.register<String>(capability);

    final ToolBrokerResult<String> result = await broker.prepare<String>(
      actionId: capability.actionId,
      settings: enabledSettings(),
      role: role,
      actorId: 'owner_1',
      handoff: validHandoff(projectContext: projectContext),
      projectContext: projectContext,
      supervisorRequest: validSupervisorRequest(emergencyStopClear: false),
      input: const <String, dynamic>{'requestId': 'request_1'},
    );

    expect(result.prepared, isFalse);
    expect(result.reason, 'tool_supervisor_recommend_stop_and_escalate');
    expect(boundary.prepareCalls, 0);
    expect(capability.prepareCalls, 0);
  });
}

AgentMasterSettings enabledSettings() => AgentMasterSettings.safeDefaults().copyWith(
  masterEnabled: true,
  emergencyReadOnly: false,
  freeAiEnabled: true,
);

AdminIntelligenceExecutionHandoff validHandoff({
  String requiredCapability = 'core.read_system_health',
  required AgentProjectContext projectContext,
}) => AdminIntelligenceExecutionHandoff(
  handoffId: 'handoff_1',
  taskId: 'task_1',
  providerId: 'provider_1',
  routingLane: 'local',
  requiredCapability: requiredCapability,
  createdAt: DateTime.utc(2026, 8, 31),
  expiresAt: DateTime.utc(2026, 9, 1),
  estimatedCostRs: 0,
  paidReasoning: false,
  ownerApprovalSatisfied: false,
  budgetAllowed: false,
  providerCapacityAllowed: false,
  routingPlanReady: true,
  readOnlyPreparation: true,
  blockedReason: null,
  projectContext: projectContext,
);

AgentProjectContext validProjectContext() {
  final DateTime now = DateTime.now().toUtc();
  return AgentProjectContext.create(
    tenantId: 'swat_ride',
    projectId: 'swat_ride_app',
    workspaceId: 'swat_ride_workspace',
    allowedModules: const <String>['core'],
    issuedAt: now.subtract(const Duration(minutes: 1)),
    expiresAt: now.add(const Duration(minutes: 5)),
  );
}

AgentCrossAgentSupervisorRequest validSupervisorRequest({
  bool emergencyStopClear = true,
}) =>
    AgentCrossAgentSupervisorRequest(
      requestId: 'supervisor_request_1',
      taskId: 'task_1',
      sourceAgentId: 'orchestrator_agent',
      targetAgentId: 'core_agent',
      actionId: 'core.read_system_health',
      securitySnapshot: AgentCrossAgentSupervisorSecuritySnapshot(
        permissionDecisionRef: 'permission_1',
        approvalDecisionRef: 'approval_1',
        runtimeGateDecisionRef: 'runtime_1',
        guardianSecurityDecisionRef: 'guardian_1',
        ownerSuperAdminControlRef: 'owner_1',
        masterAiControlRef: 'master_1',
        emergencyStopDecisionRef: 'emergency_1',
        costBudgetDecisionRef: 'cost_1',
        mandatoryAuditDecisionRef: 'audit_1',
        permissionSatisfied: true,
        approvalSatisfied: true,
        runtimeGateSatisfied: true,
        guardianSecuritySatisfied: true,
        ownerSuperAdminControlSatisfied: true,
        masterAiControlSatisfied: true,
        emergencyStopClear: emergencyStopClear,
        costBudgetSatisfied: true,
        mandatoryAuditSatisfied: true,
        restrictedAction: false,
        ownerAdminAuthorityPresent: true,
      ),
    );

AdminIntelligenceExecutionBoundaryResult readyBoundaryResult() =>
    boundaryResult(status: AdminIntelligenceExecutionBoundaryStatus.readyNoApproval);

AdminIntelligenceExecutionBoundaryResult blockedBoundaryResult() =>
    boundaryResult(
      status: AdminIntelligenceExecutionBoundaryStatus.blocked,
      reason: 'blocked_by_boundary',
    );

AdminIntelligenceExecutionBoundaryResult boundaryResult({
  required String status,
  String reason = 'ready',
}) {
  final AgentPermissionDecision decision = AgentPermissionDecision.allow(
    roleId: 'core_agent',
    actionId: 'core.read_system_health',
    reason: reason,
    effectiveMode: AgentMode.auto,
  );

  return AdminIntelligenceExecutionBoundaryResult(
    status: status,
    authorization: AdminIntelligenceSecurityAuthorization(
      permissionDecision: decision,
      runtimeDecision: decision,
      actionKnown: true,
      handoffValid: true,
      approvalRequired: false,
      approvalSnapshotValid: false,
      approvalConsumptionRequired: false,
      authorizationReady: status == AdminIntelligenceExecutionBoundaryStatus.readyNoApproval,
      reason: reason,
      approvalScope: const <String, dynamic>{},
    ),
    auditRecorded: true,
    providerExecutionPerformed: false,
    businessDataWritePerformed: false,
    costCharged: false,
    budgetMutated: false,
    reason: reason,
  );
}

class FakeBoundary implements AdminIntelligenceExecutionBoundary {
  FakeBoundary(this.result);

  final AdminIntelligenceExecutionBoundaryResult result;
  int prepareCalls = 0;

  @override
  Future<AdminIntelligenceExecutionBoundaryResult> prepare({
    required DateTime now,
    required AgentMasterSettings settings,
    required AgentRole role,
    required String actionId,
    required String actorId,
    required AdminIntelligenceExecutionHandoff handoff,
    String? approvalId,
  }) async {
    prepareCalls++;
    return result;
  }
}

class TestCapability implements CapabilityContract<String> {
  int prepareCalls = 0;

  @override
  String get actionId => 'core.read_system_health';

  @override
  String get module => 'core';

  @override
  void validateInput(Map<String, dynamic> input) {
    if (input['requestId']?.toString().trim().isEmpty ?? true) {
      throw ArgumentError('requestId is required.');
    }
  }

  @override
  Future<String> prepare(Map<String, dynamic> input) async {
    prepareCalls++;
    return 'prepared:${input['requestId']}';
  }
}
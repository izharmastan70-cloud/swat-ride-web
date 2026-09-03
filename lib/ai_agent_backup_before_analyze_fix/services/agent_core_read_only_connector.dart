import '../constants/agent_action_ids.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_read_only_payload.dart';
import '../models/agent_role.dart';
import '../models/agent_tool_request.dart';
import 'agent_master_settings_service.dart';
import 'agent_read_only_connector.dart';
import 'agent_role_service.dart';

// =========================================================
// AI AGENT — CORE READ-ONLY CONNECTOR
// =========================================================
//
// This is the ONLY connector attached in Phase 7.
// It reads AI-owned configuration only:
//   agent_settings/master
//   agent_roles
//
// It does NOT read Ride, Driver, Food, Hotel, Tour, Cargo, Student,
// Finance, Rewards, Safety, or other SWAT RIDE business collections.

class AgentCoreReadOnlyConnector implements AgentReadOnlyConnector {
  final AgentMasterSettingsService settingsService;
  final AgentRoleService roleService;

  AgentCoreReadOnlyConnector({
    AgentMasterSettingsService? settingsService,
    AgentRoleService? roleService,
  })  : settingsService =
            settingsService ?? AgentMasterSettingsService(),
        roleService = roleService ?? AgentRoleService();

  @override
  String get connectorId => 'connector.ai_core.read_only';

  @override
  String get module => 'core';

  @override
  Set<String> get supportedActionIds => const <String>{
        AgentActionId.readSystemHealth,
        AgentActionId.readDailySummary,
      };

  @override
  Future<AgentReadOnlyPayload> executeReadOnly(
    AgentToolRequest request,
  ) async {
    if (!supports(request.actionId)) {
      throw StateError(
        'Core connector does not support "${request.actionId}".',
      );
    }

    final AgentMasterSettings settings =
        await settingsService.getSettings();

    final List<AgentRole> roles = await roleService.getAllRoles();

    final int operationalRoles =
        roles.where((AgentRole role) => role.isOperational).length;

    final int failClosedRoles =
        roles.where((AgentRole role) => role.isFailClosed).length;

    return AgentReadOnlyPayload(
      actionId: request.actionId,
      module: module,
      generatedAt: DateTime.now(),
      data: <String, dynamic>{
        'aiMasterEnabled': settings.masterEnabled,
        'emergencyReadOnly': settings.emergencyReadOnly,
        'freeAiEnabled': settings.freeAiEnabled,
        'localAiEnabled': settings.localAiEnabled,
        'paidCodeAiEnabled': settings.paidCodeAiEnabled,
        'callAgentEnabled': settings.callAgentEnabled,
        'approvalEngineEnabled': settings.approvalEngineEnabled,
        'auditLoggingEnabled': settings.auditLoggingEnabled,
        'paidCodeBudgetAvailable': settings.paidBudgetAvailable,
        'rolesTotal': roles.length,
        'rolesOperational': operationalRoles,
        'rolesFailClosed': failClosedRoles,
      },
    );
  }
}

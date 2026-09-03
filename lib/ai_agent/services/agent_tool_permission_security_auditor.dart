import '../models/agent_action_definition.dart';
import '../models/agent_role.dart';
import '../models/agent_security_finding.dart';
import '../models/agent_tool_definition.dart';
import 'agent_action_registry.dart';
import 'agent_controlled_tool_registry.dart';

// =========================================================
// AI AGENT - TOOL PERMISSION SECURITY AUDITOR
// =========================================================
//
// Phase 27 Step 6.
//
// AUDIT ONLY:
// - no Firestore writes
// - no tool execution
// - no connector activation
// - no permission mutation
// - no role mutation
//
// Existing Permission Engine and Runtime Gate remain authoritative.

class AgentToolPermissionSecurityAuditor {
  const AgentToolPermissionSecurityAuditor();

  List<AgentSecurityFinding> auditAllTools({
    required Iterable<AgentRole> roles,
  }) {
    final List<AgentSecurityFinding> findings =
        <AgentSecurityFinding>[];

    final List<AgentToolDefinition> tools =
        AgentControlledToolRegistry.all;

    for (final AgentToolDefinition tool in tools) {
      findings.addAll(
        auditTool(
          tool: tool,
          roles: roles,
        ),
      );
    }

    return List<AgentSecurityFinding>.unmodifiable(
      findings,
    );
  }

  List<AgentSecurityFinding> auditTool({
    required AgentToolDefinition tool,
    required Iterable<AgentRole> roles,
  }) {
    final List<AgentSecurityFinding> findings =
        <AgentSecurityFinding>[];

    final AgentActionDefinition? action =
        AgentActionRegistry.get(tool.actionId);

    if (action == null) {
      findings.add(
        AgentSecurityFinding(
          findingType:
              AgentSecurityFindingType.securityPolicyViolation,
          severity:
              AgentSecuritySeverity.critical,
          module: tool.module,
          actionId: tool.actionId,
          reason:
              'Controlled tool references an unknown Agent Action.',
          metadata: <String, dynamic>{
            'toolId': tool.toolId,
          },
        ),
      );

      return List<AgentSecurityFinding>.unmodifiable(
        findings,
      );
    }

    try {
      tool.validateAgainstAction(action);
    } catch (error) {
      findings.add(
        AgentSecurityFinding(
          findingType:
              AgentSecurityFindingType.securityPolicyViolation,
          severity:
              AgentSecuritySeverity.critical,
          module: tool.module,
          actionId: tool.actionId,
          reason:
              'Controlled tool metadata does not match the authoritative Action Registry definition.',
          metadata: <String, dynamic>{
            'toolId': tool.toolId,
            'validationError': error.runtimeType.toString(),
          },
        ),
      );
    }

    if (tool.connectorReady &&
        action.permanentlyForbiddenForAi) {
      findings.add(
        AgentSecurityFinding(
          findingType:
              AgentSecurityFindingType.securityPolicyViolation,
          severity:
              AgentSecuritySeverity.critical,
          module: tool.module,
          actionId: tool.actionId,
          reason:
              'A permanently forbidden AI action has a connector-ready tool.',
          metadata: <String, dynamic>{
            'toolId': tool.toolId,
          },
        ),
      );
    }

    if (tool.connectorReady &&
        !tool.enabled) {
      findings.add(
        AgentSecurityFinding(
          findingType:
              AgentSecurityFindingType.suspiciousRuntimeState,
          severity:
              AgentSecuritySeverity.warning,
          module: tool.module,
          actionId: tool.actionId,
          reason:
              'Tool connector is ready while the tool itself is disabled. Configuration should be reviewed.',
          metadata: <String, dynamic>{
            'toolId': tool.toolId,
          },
        ),
      );
    }

    if (tool.executable &&
        action.permanentlyForbiddenForAi) {
      findings.add(
        AgentSecurityFinding(
          findingType:
              AgentSecurityFindingType.securityPolicyViolation,
          severity:
              AgentSecuritySeverity.critical,
          module: tool.module,
          actionId: tool.actionId,
          reason:
              'A permanently forbidden AI action is marked executable.',
          metadata: <String, dynamic>{
            'toolId': tool.toolId,
          },
        ),
      );
    }

    final List<AgentRole> referencingRoles =
        roles.where(
      (AgentRole role) =>
          role.allowedActions.contains(tool.actionId) ||
          role.approvalRequiredActions.contains(
            tool.actionId,
          ) ||
          role.forbiddenActions.contains(tool.actionId),
    ).toList(growable: false);

    for (final AgentRole role in referencingRoles) {
      if (action.module != 'core' &&
          role.module != action.module) {
        findings.add(
          AgentSecurityFinding(
            findingType:
                AgentSecurityFindingType.crossModulePermission,
            severity:
                AgentSecuritySeverity.high,
            roleId: role.roleId,
            module: role.module,
            actionId: tool.actionId,
            reason:
                'Role references a controlled tool action from another module.',
            metadata: <String, dynamic>{
              'toolId': tool.toolId,
              'toolModule': tool.module,
              'actionModule': action.module,
            },
          ),
        );
      }

      if (role.allowedActions.contains(
            tool.actionId,
          ) &&
          action.permanentlyForbiddenForAi) {
        findings.add(
          AgentSecurityFinding(
            findingType:
                AgentSecurityFindingType.securityPolicyViolation,
            severity:
                AgentSecuritySeverity.critical,
            roleId: role.roleId,
            module: role.module,
            actionId: tool.actionId,
            reason:
                'Role allows an action that is permanently forbidden for AI.',
            metadata: <String, dynamic>{
              'toolId': tool.toolId,
            },
          ),
        );
      }

      if (role.approvalRequiredActions.contains(
            tool.actionId,
          ) &&
          !role.allowedActions.contains(
            tool.actionId,
          )) {
        findings.add(
          AgentSecurityFinding(
            findingType:
                AgentSecurityFindingType.approvalActionNotAllowed,
            severity:
                AgentSecuritySeverity.high,
            roleId: role.roleId,
            module: role.module,
            actionId: tool.actionId,
            reason:
                'Tool action requires approval in role policy but is absent from allowedActions.',
            metadata: <String, dynamic>{
              'toolId': tool.toolId,
            },
          ),
        );
      }
    }

    return List<AgentSecurityFinding>.unmodifiable(
      findings,
    );
  }
}
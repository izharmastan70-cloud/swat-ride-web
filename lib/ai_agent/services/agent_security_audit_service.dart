import '../constants/agent_enums.dart';
import '../models/agent_action_definition.dart';
import '../models/agent_role.dart';
import '../models/agent_security_finding.dart';
import 'agent_action_registry.dart';

// =========================================================
// AI AGENT - SECURITY AUDIT SERVICE
// =========================================================
//
// Phase 27 Step 3.
//
// READ/AUDIT ONLY:
// - does not modify AgentRole
// - does not modify Firestore
// - does not execute tools
// - does not bypass Permission Engine
// - does not suspend/disable any account
//
// Existing Permission Engine + Runtime Gate remain authoritative.

class AgentSecurityAuditService {
  const AgentSecurityAuditService();

  List<AgentSecurityFinding> auditRoles(
    Iterable<AgentRole> roles,
  ) {
    final List<AgentSecurityFinding> findings =
        <AgentSecurityFinding>[];

    for (final AgentRole role in roles) {
      findings.addAll(auditRole(role));
    }

    return List<AgentSecurityFinding>.unmodifiable(findings);
  }

  List<AgentSecurityFinding> auditRole(AgentRole role) {
    final List<AgentSecurityFinding> findings =
        <AgentSecurityFinding>[];

    if (!role.isValid) {
      findings.add(
        AgentSecurityFinding(
          findingType:
              AgentSecurityFindingType.invalidRoleConfiguration,
          severity: AgentSecuritySeverity.critical,
          roleId: role.roleId,
          module: role.module,
          reason:
              'Agent role configuration is invalid and must fail closed.',
        ),
      );
    }

    if (role.isFailClosed) {
      findings.add(
        AgentSecurityFinding(
          findingType: AgentSecurityFindingType.failClosedRole,
          severity: AgentSecuritySeverity.high,
          roleId: role.roleId,
          module: role.module,
          reason:
              'Role is already in fail-closed state because its configuration is unsafe or corrupted.',
        ),
      );
    }

    _auditActionList(
      role: role,
      actionIds: role.allowedActions,
      source: 'allowedActions',
      findings: findings,
    );

    _auditActionList(
      role: role,
      actionIds: role.approvalRequiredActions,
      source: 'approvalRequiredActions',
      findings: findings,
    );

    _auditActionList(
      role: role,
      actionIds: role.forbiddenActions,
      source: 'forbiddenActions',
      findings: findings,
    );

    final Set<String> allowed =
        role.allowedActions.toSet();

    final Set<String> approval =
        role.approvalRequiredActions.toSet();

    final Set<String> forbidden =
        role.forbiddenActions.toSet();

    for (final String actionId
        in allowed.intersection(forbidden)) {
      findings.add(
        AgentSecurityFinding(
          findingType:
              AgentSecurityFindingType.forbiddenActionAlsoAllowed,
          severity: AgentSecuritySeverity.critical,
          roleId: role.roleId,
          module: role.module,
          actionId: actionId,
          reason:
              'The same action is present in allowedActions and forbiddenActions.',
        ),
      );
    }

    for (final String actionId in approval) {
      if (!allowed.contains(actionId)) {
        findings.add(
          AgentSecurityFinding(
            findingType:
                AgentSecurityFindingType.approvalActionNotAllowed,
            severity: AgentSecuritySeverity.high,
            roleId: role.roleId,
            module: role.module,
            actionId: actionId,
            reason:
                'Approval-required action is not also present in allowedActions. Current default-deny Permission Engine will deny it before approval.',
          ),
        );
      }
    }

    if (role.aiClass == AiClass.paidCodeAi &&
        role.roleId != AgentRole.codeAgentRoleId) {
      findings.add(
        AgentSecurityFinding(
          findingType:
              AgentSecurityFindingType.paidAiRoleViolation,
          severity: AgentSecuritySeverity.critical,
          roleId: role.roleId,
          module: role.module,
          reason:
              'PAID_CODE_AI is assigned outside the dedicated Code Agent role.',
        ),
      );
    }

    if (role.roleId == AgentRole.codeAgentRoleId &&
        role.aiClass != AiClass.paidCodeAi) {
      findings.add(
        AgentSecurityFinding(
          findingType:
              AgentSecurityFindingType.paidAiRoleViolation,
          severity: AgentSecuritySeverity.critical,
          roleId: role.roleId,
          module: role.module,
          reason:
              'Code Agent is not configured with PAID_CODE_AI as required by role policy.',
        ),
      );
    }

    return List<AgentSecurityFinding>.unmodifiable(findings);
  }

  void _auditActionList({
    required AgentRole role,
    required Iterable<String> actionIds,
    required String source,
    required List<AgentSecurityFinding> findings,
  }) {
    for (final String actionId in actionIds) {
      final AgentActionDefinition? action =
          AgentActionRegistry.get(actionId);

      if (action == null) {
        findings.add(
          AgentSecurityFinding(
            findingType:
                AgentSecurityFindingType.unknownAllowedAction,
            severity: AgentSecuritySeverity.high,
            roleId: role.roleId,
            module: role.module,
            actionId: actionId,
            reason:
                'Unknown action "$actionId" exists in $source.',
            metadata: <String, dynamic>{
              'source': source,
            },
          ),
        );
        continue;
      }

      if (action.module != 'core' &&
          action.module != role.module) {
        findings.add(
          AgentSecurityFinding(
            findingType:
                AgentSecurityFindingType.crossModulePermission,
            severity: AgentSecuritySeverity.high,
            roleId: role.roleId,
            module: role.module,
            actionId: actionId,
            reason:
                'Role module "${role.module}" references action module "${action.module}".',
            metadata: <String, dynamic>{
              'source': source,
              'actionModule': action.module,
            },
          ),
        );
      }

      if (source == 'allowedActions' &&
          action.permanentlyForbiddenForAi) {
        findings.add(
          AgentSecurityFinding(
            findingType:
                AgentSecurityFindingType.securityPolicyViolation,
            severity: AgentSecuritySeverity.critical,
            roleId: role.roleId,
            module: role.module,
            actionId: actionId,
            reason:
                'A permanently forbidden AI action appears in allowedActions.',
          ),
        );
      }

      if (source == 'allowedActions' &&
          role.mode == AgentMode.monitorOnly &&
          !action.readOnly) {
        findings.add(
          AgentSecurityFinding(
            findingType:
                AgentSecurityFindingType.excessivePermission,
            severity: AgentSecuritySeverity.warning,
            roleId: role.roleId,
            module: role.module,
            actionId: actionId,
            reason:
                'MONITOR_ONLY role contains a non-read-only allowed action. Runtime Permission Engine should deny execution, but the role configuration is broader than necessary.',
          ),
        );
      }

      if (source == 'allowedActions' &&
          role.mode == AgentMode.suggestOnly &&
          !action.readOnly &&
          actionId != 'core.create_suggestion') {
        findings.add(
          AgentSecurityFinding(
            findingType:
                AgentSecurityFindingType.excessivePermission,
            severity: AgentSecuritySeverity.warning,
            roleId: role.roleId,
            module: role.module,
            actionId: actionId,
            reason:
                'SUGGEST_ONLY role contains a business write action in allowedActions.',
          ),
        );
      }
    }
  }
}
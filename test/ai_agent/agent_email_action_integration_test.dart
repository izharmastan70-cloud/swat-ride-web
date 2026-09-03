import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_action_definition.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_action_registry.dart';
import 'package:swat_ride/ai_agent/services/agent_permission_engine.dart';

void main() {
  test('email send is a known approval-required registry action', () {
    expect(AgentActionId.isKnown(AgentActionId.sendEmail), isTrue);
    expect(AgentActionRegistry.contains(AgentActionId.sendEmail), isTrue);

    final AgentActionDefinition? definition = AgentActionRegistry.get(
      AgentActionId.sendEmail,
    );

    expect(definition, isNotNull);
    expect(definition!.module, 'email');
    expect(definition.risk, AgentActionRisk.medium);
    expect(definition.readOnly, isFalse);
    expect(definition.alwaysRequiresApproval, isTrue);
    expect(definition.permanentlyForbiddenForAi, isFalse);
  });

  test(
    'email agent has no direct send allow and permission engine requires approval',
    () {
      final AgentRole role = buildInitialAgentRoles().firstWhere(
        (AgentRole value) => value.roleId == 'email_agent',
      );

      // Current Permission Engine is DEFAULT-DENY: the action must be
      // explicitly present in allowedActions before approval policy is evaluated.
      // Direct execution is still impossible because the registry and role both
      // require approval for sendEmail.
      expect(role.allowedActions, contains(AgentActionId.sendEmail));
      expect(role.approvalRequiredActions, contains(AgentActionId.sendEmail));
      expect(role.forbiddenActions, isNot(contains(AgentActionId.sendEmail)));

      final decision = const AgentPermissionEngine().evaluate(
        role: role,
        actionId: AgentActionId.sendEmail,
      );

      expect(decision.needsApproval, isTrue);
      expect(decision.isAllowed, isFalse);
      expect(decision.isDenied, isFalse);
    },
  );

  test('support and feedback role send permissions remain unchanged', () {
    final List<AgentRole> roles = buildInitialAgentRoles();

    final AgentRole support = roles.firstWhere(
      (AgentRole value) => value.roleId == 'support_agent',
    );

    final AgentRole feedback = roles.firstWhere(
      (AgentRole value) => value.roleId == 'feedback_agent',
    );

    expect(
      support.approvalRequiredActions,
      contains(AgentActionId.sendSupportReply),
    );
    expect(
      feedback.approvalRequiredActions,
      contains(AgentActionId.sendFeedbackReply),
    );

    expect(
      support.approvalRequiredActions,
      isNot(contains(AgentActionId.sendEmail)),
    );
    expect(
      feedback.approvalRequiredActions,
      isNot(contains(AgentActionId.sendEmail)),
    );
  });
}

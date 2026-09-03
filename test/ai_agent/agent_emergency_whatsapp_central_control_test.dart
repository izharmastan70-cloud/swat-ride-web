import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/constants/agent_enums.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/services/agent_action_registry.dart';
import 'package:swat_ride/ai_agent/services/agent_emergency_whatsapp_control_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_permission_engine.dart';
import 'package:swat_ride/ai_agent/services/agent_runtime_gate.dart';

void main() {
  group('Phase 47 Step 3B Emergency WhatsApp central control', () {
    test('dedicated actions are known and module-isolated', () {
      expect(
        AgentActionId.isKnown(
          AgentActionId.readEmergencyWhatsAppVerifiedSafety,
        ),
        isTrue,
      );
      expect(
        AgentActionId.isKnown(AgentActionId.requestEmergencyWhatsAppEscalation),
        isTrue,
      );

      final read = AgentActionRegistry.get(
        AgentActionId.readEmergencyWhatsAppVerifiedSafety,
      );
      final escalation = AgentActionRegistry.get(
        AgentActionId.requestEmergencyWhatsAppEscalation,
      );

      expect(read, isNotNull);
      expect(read!.module, 'emergency_whatsapp');
      expect(read.readOnly, isTrue);
      expect(read.alwaysRequiresApproval, isFalse);

      expect(escalation, isNotNull);
      expect(escalation!.module, 'emergency_whatsapp');
      expect(escalation.readOnly, isFalse);
      expect(escalation.alwaysRequiresApproval, isTrue);
    });

    test(
      'Emergency role is separate and does not inherit safety.send_alert',
      () {
        final role = buildInitialAgentRoles().singleWhere(
          (item) => item.roleId == 'emergency_whatsapp_agent',
        );

        expect(role.module, 'emergency_whatsapp');
        expect(role.mode, AgentMode.suggestOnly);
        expect(role.privacyLevel, PrivacyLevel.highlySensitive);
        expect(
          role.allowedActions,
          contains(AgentActionId.readEmergencyWhatsAppVerifiedSafety),
        );
        expect(
          role.allowedActions,
          contains(AgentActionId.requestEmergencyWhatsAppEscalation),
        );
        expect(
          role.approvalRequiredActions,
          contains(AgentActionId.requestEmergencyWhatsAppEscalation),
        );
        expect(
          role.allowedActions,
          isNot(contains(AgentActionId.sendSafetyAlert)),
        );
        expect(
          role.allowedActions,
          isNot(contains(AgentActionId.readCustomerWhatsAppVerifiedData)),
        );
        expect(
          role.allowedActions,
          isNot(contains(AgentActionId.readOwnerWhatsAppVerifiedReport)),
        );
      },
    );

    test('Customer and Owner roles do not inherit Emergency actions', () {
      final roles = buildInitialAgentRoles();

      final customer = roles.singleWhere(
        (item) => item.roleId == 'customer_whatsapp_agent',
      );
      final owner = roles.singleWhere(
        (item) => item.roleId == 'owner_whatsapp_agent',
      );

      for (final role in <dynamic>[customer, owner]) {
        expect(
          role.allowedActions,
          isNot(contains(AgentActionId.readEmergencyWhatsAppVerifiedSafety)),
        );
        expect(
          role.allowedActions,
          isNot(contains(AgentActionId.requestEmergencyWhatsAppEscalation)),
        );
      }
    });

    test('Emergency master switch defaults OFF and round-trips', () {
      final defaults = AgentMasterSettings.safeDefaults();

      expect(defaults.emergencyWhatsAppAgentEnabled, isFalse);
      expect(defaults.toMap()['emergencyWhatsAppAgentEnabled'], isFalse);

      final enabled = defaults.copyWith(emergencyWhatsAppAgentEnabled: true);

      expect(enabled.emergencyWhatsAppAgentEnabled, isTrue);

      final restored = AgentMasterSettings.fromMap(enabled.toMap());
      expect(restored.emergencyWhatsAppAgentEnabled, isTrue);
    });

    test('only Admin or Super Admin can authorize the master toggle', () {
      const policy = AgentEmergencyWhatsAppControlPolicy();

      expect(policy.authorizeMasterToggle(actorRole: 'admin').allowed, isTrue);
      expect(
        policy.authorizeMasterToggle(actorRole: 'super_admin').allowed,
        isTrue,
      );
      expect(
        policy.authorizeMasterToggle(actorRole: 'Super Admin').allowed,
        isTrue,
      );

      for (final role in <String>[
        'customer',
        'driver',
        'customer_whatsapp_agent',
        'owner_whatsapp_agent',
        'emergency_whatsapp_agent',
      ]) {
        expect(
          policy.authorizeMasterToggle(actorRole: role).allowed,
          isFalse,
          reason: role,
        );
      }
    });

    test('Permission Engine keeps escalation approval-bound', () {
      final seeded = buildInitialAgentRoles().singleWhere(
        (item) => item.roleId == 'emergency_whatsapp_agent',
      );
      final role = seeded.copyWith(enabled: true);

      const engine = AgentPermissionEngine();

      final read = engine.evaluate(
        role: role,
        actionId: AgentActionId.readEmergencyWhatsAppVerifiedSafety,
      );
      final escalation = engine.evaluate(
        role: role,
        actionId: AgentActionId.requestEmergencyWhatsAppEscalation,
      );

      expect(read.isDenied, isFalse);
      expect(read.needsApproval, isFalse);

      expect(escalation.isDenied, isFalse);
      expect(escalation.needsApproval, isTrue);
    });

    test('Runtime Gate denies Emergency role while its switch is OFF', () {
      final seeded = buildInitialAgentRoles().singleWhere(
        (item) => item.roleId == 'emergency_whatsapp_agent',
      );
      final role = seeded.copyWith(enabled: true);

      const engine = AgentPermissionEngine();
      const runtime = AgentRuntimeGate();

      final permission = engine.evaluate(
        role: role,
        actionId: AgentActionId.readEmergencyWhatsAppVerifiedSafety,
      );

      final settings = AgentMasterSettings.safeDefaults().copyWith(
        masterEnabled: true,
        emergencyReadOnly: false,
        freeAiEnabled: true,
        emergencyWhatsAppAgentEnabled: false,
      );

      final decision = runtime.apply(
        settings: settings,
        role: role,
        permissionDecision: permission,
      );

      expect(decision.isDenied, isTrue);
      expect(
        decision.reason,
        contains('Emergency WhatsApp Agent master switch is OFF'),
      );
    });

    test('Runtime Gate allows authorized read when Emergency switch is ON', () {
      final seeded = buildInitialAgentRoles().singleWhere(
        (item) => item.roleId == 'emergency_whatsapp_agent',
      );
      final role = seeded.copyWith(enabled: true);

      const engine = AgentPermissionEngine();
      const runtime = AgentRuntimeGate();

      final permission = engine.evaluate(
        role: role,
        actionId: AgentActionId.readEmergencyWhatsAppVerifiedSafety,
      );

      final settings = AgentMasterSettings.safeDefaults().copyWith(
        masterEnabled: true,
        emergencyReadOnly: false,
        freeAiEnabled: true,
        emergencyWhatsAppAgentEnabled: true,
      );

      final decision = runtime.apply(
        settings: settings,
        role: role,
        permissionDecision: permission,
      );

      expect(decision.isDenied, isFalse);
      expect(decision.needsApproval, isFalse);
    });

    test(
      'global Emergency Read-Only still blocks escalation approval path',
      () {
        final seeded = buildInitialAgentRoles().singleWhere(
          (item) => item.roleId == 'emergency_whatsapp_agent',
        );
        final role = seeded.copyWith(enabled: true);

        const engine = AgentPermissionEngine();
        const runtime = AgentRuntimeGate();

        final permission = engine.evaluate(
          role: role,
          actionId: AgentActionId.requestEmergencyWhatsAppEscalation,
        );

        final settings = AgentMasterSettings.safeDefaults().copyWith(
          masterEnabled: true,
          emergencyReadOnly: true,
          freeAiEnabled: true,
          emergencyWhatsAppAgentEnabled: true,
        );

        final decision = runtime.apply(
          settings: settings,
          role: role,
          permissionDecision: permission,
        );

        expect(decision.isDenied, isTrue);
        expect(
          decision.reason,
          contains('Emergency Read-Only mode blocks approval/write actions'),
        );
      },
    );
  });
}

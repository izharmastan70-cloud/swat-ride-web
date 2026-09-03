import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/constants/agent_enums.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_whatsapp_foundation.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_action_registry.dart';
import 'package:swat_ride/ai_agent/services/agent_permission_engine.dart';
import 'package:swat_ride/ai_agent/services/agent_runtime_gate.dart';

void main() {
  group('Phase 46 Owner WhatsApp central registry', () {
    const AgentPermissionEngine permissionEngine = AgentPermissionEngine();
    const AgentRuntimeGate runtimeGate = AgentRuntimeGate();

    AgentRole ownerRole() {
      return AgentRole(
        roleId: AgentOwnerWhatsAppFoundation.roleId,
        name: 'Owner WhatsApp Agent',
        description: 'Phase 46 test role',
        module: 'owner_whatsapp',
        enabled: true,
        mode: AgentMode.suggestOnly,
        allowedActions: const <String>[
          AgentActionId.readOwnerWhatsAppVerifiedReport,
          AgentActionId.requestOwnerWhatsAppConsequentialAction,
        ],
        approvalRequiredActions: const <String>[
          AgentActionId.requestOwnerWhatsAppConsequentialAction,
        ],
        forbiddenActions: const <String>[],
        aiClass: AiClass.freeAi,
        privacyLevel: PrivacyLevel.highlySensitive,
        createdAt: DateTime.utc(2026, 8, 18),
      );
    }

    AgentMasterSettings enabledSettings({
      bool ownerWhatsAppEnabled = true,
      bool approvalEngineEnabled = true,
    }) {
      return AgentMasterSettings.safeDefaults().copyWith(
        masterEnabled: true,
        emergencyReadOnly: false,
        freeAiEnabled: true,
        ownerWhatsAppAgentEnabled: ownerWhatsAppEnabled,
        approvalEngineEnabled: approvalEngineEnabled,
      );
    }

    test('Owner WhatsApp action IDs are known and module-isolated', () {
      expect(
        AgentActionId.isKnown(AgentActionId.readOwnerWhatsAppVerifiedReport),
        isTrue,
      );
      expect(
        AgentActionId.isKnown(
          AgentActionId.requestOwnerWhatsAppConsequentialAction,
        ),
        isTrue,
      );

      final read = AgentActionRegistry.get(
        AgentActionId.readOwnerWhatsAppVerifiedReport,
      );
      final request = AgentActionRegistry.get(
        AgentActionId.requestOwnerWhatsAppConsequentialAction,
      );

      expect(read, isNotNull);
      expect(read!.module, 'owner_whatsapp');
      expect(read.readOnly, isTrue);

      expect(request, isNotNull);
      expect(request!.module, 'owner_whatsapp');
      expect(request.readOnly, isFalse);
      expect(request.alwaysRequiresApproval, isTrue);
    });

    test('Owner WhatsApp master switch defaults OFF and round-trips', () {
      final defaults = AgentMasterSettings.safeDefaults();

      expect(defaults.ownerWhatsAppAgentEnabled, isFalse);
      expect(defaults.toMap()['ownerWhatsAppAgentEnabled'], isFalse);

      final restored = AgentMasterSettings.fromMap(defaults.toMap());

      expect(restored.ownerWhatsAppAgentEnabled, isFalse);
    });

    test('missing persisted Owner WhatsApp switch fails closed to false', () {
      final source = AgentMasterSettings.safeDefaults().toMap()
        ..remove('ownerWhatsAppAgentEnabled');

      final restored = AgentMasterSettings.fromMap(source);

      expect(restored.ownerWhatsAppAgentEnabled, isFalse);
    });

    test(
      'Permission Engine allows only verified Owner WhatsApp report action',
      () {
        final role = ownerRole();

        final decision = permissionEngine.evaluate(
          role: role,
          actionId: AgentActionId.readOwnerWhatsAppVerifiedReport,
        );

        expect(decision.isDenied, isFalse);
        expect(decision.needsApproval, isFalse);
      },
    );

    test(
      'consequential Owner WhatsApp request is always approval-required',
      () {
        final role = ownerRole();

        final decision = permissionEngine.evaluate(
          role: role,
          actionId: AgentActionId.requestOwnerWhatsAppConsequentialAction,
        );

        expect(decision.isDenied, isFalse);
        expect(decision.needsApproval, isTrue);
      },
    );

    test('Runtime Gate denies Owner WhatsApp while master switch is OFF', () {
      final role = ownerRole();
      final permission = permissionEngine.evaluate(
        role: role,
        actionId: AgentActionId.readOwnerWhatsAppVerifiedReport,
      );

      final runtime = runtimeGate.apply(
        settings: enabledSettings(ownerWhatsAppEnabled: false),
        role: role,
        permissionDecision: permission,
      );

      expect(runtime.isDenied, isTrue);
      expect(
        runtime.reason,
        contains('Owner WhatsApp Agent master switch is OFF'),
      );
    });

    test('Runtime Gate permits authorized read when Owner WhatsApp is ON', () {
      final role = ownerRole();
      final permission = permissionEngine.evaluate(
        role: role,
        actionId: AgentActionId.readOwnerWhatsAppVerifiedReport,
      );

      final runtime = runtimeGate.apply(
        settings: enabledSettings(),
        role: role,
        permissionDecision: permission,
      );

      expect(runtime.isDenied, isFalse);
      expect(runtime.needsApproval, isFalse);
    });

    test('Approval Engine OFF blocks consequential Owner WhatsApp request', () {
      final role = ownerRole();
      final permission = permissionEngine.evaluate(
        role: role,
        actionId: AgentActionId.requestOwnerWhatsAppConsequentialAction,
      );

      expect(permission.needsApproval, isTrue);

      final runtime = runtimeGate.apply(
        settings: enabledSettings(approvalEngineEnabled: false),
        role: role,
        permissionDecision: permission,
      );

      expect(runtime.isDenied, isTrue);
      expect(runtime.reason, contains('Approval Engine is OFF'));
    });

    test('Customer WhatsApp role cannot inherit Owner WhatsApp action', () {
      final customerRole = AgentRole(
        roleId: AgentOwnerWhatsAppFoundation.customerWhatsAppRoleId,
        name: 'Customer WhatsApp Agent',
        description: 'Isolation test',
        module: 'customer_whatsapp',
        enabled: true,
        mode: AgentMode.suggestOnly,
        allowedActions: const <String>[
          AgentActionId.readOwnerWhatsAppVerifiedReport,
        ],
        approvalRequiredActions: const <String>[],
        forbiddenActions: const <String>[],
        aiClass: AiClass.freeAi,
        privacyLevel: PrivacyLevel.private,
        createdAt: DateTime.utc(2026, 8, 18),
      );

      final decision = permissionEngine.evaluate(
        role: customerRole,
        actionId: AgentActionId.readOwnerWhatsAppVerifiedReport,
      );

      expect(decision.isDenied, isTrue);
      expect(decision.reason, contains('module'));
    });
  });
}

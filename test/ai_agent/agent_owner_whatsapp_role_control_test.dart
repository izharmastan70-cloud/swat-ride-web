import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/constants/agent_enums.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_owner_whatsapp_foundation.dart';
import 'package:swat_ride/ai_agent/services/agent_owner_whatsapp_control_policy.dart';

void main() {
  group('Phase 46 Owner WhatsApp role/control integration', () {
    test('initial Owner WhatsApp role is narrow and highly sensitive', () {
      final roles = buildInitialAgentRoles();

      final role = roles.singleWhere(
        (value) => value.roleId == AgentOwnerWhatsAppFoundation.roleId,
      );

      expect(role.module, 'owner_whatsapp');
      expect(role.mode, AgentMode.suggestOnly);
      expect(role.privacyLevel, PrivacyLevel.highlySensitive);

      expect(
        role.allowedActions,
        contains(AgentActionId.readOwnerWhatsAppVerifiedReport),
      );
      expect(
        role.allowedActions,
        contains(AgentActionId.requestOwnerWhatsAppConsequentialAction),
      );
      expect(role.allowedActions.length, 2);

      expect(role.approvalRequiredActions, <String>[
        AgentActionId.requestOwnerWhatsAppConsequentialAction,
      ]);
    });

    test('Admin and Super Admin may control Owner WhatsApp switch', () {
      const policy = AgentOwnerWhatsAppControlPolicy();

      expect(policy.authorizeMasterToggle(actorRole: 'admin').allowed, isTrue);
      expect(
        policy.authorizeMasterToggle(actorRole: 'super_admin').allowed,
        isTrue,
      );
    });

    test(
      'Customer and Owner WhatsApp identities cannot control master switch',
      () {
        const policy = AgentOwnerWhatsAppControlPolicy();

        expect(
          policy.authorizeMasterToggle(actorRole: 'customer').allowed,
          isFalse,
        );
        expect(
          policy
              .authorizeMasterToggle(actorRole: 'customer_whatsapp_agent')
              .allowed,
          isFalse,
        );
        expect(
          policy
              .authorizeMasterToggle(actorRole: 'owner_whatsapp_agent')
              .allowed,
          isFalse,
        );
      },
    );

    test('Owner control policy exposes no direct authority', () {
      expect(
        AgentOwnerWhatsAppControlPolicy.whatsappMessageIsAuthority,
        isFalse,
      );
      expect(
        AgentOwnerWhatsAppControlPolicy.phoneNumberMatchAloneIsAuthority,
        isFalse,
      );
      expect(
        AgentOwnerWhatsAppControlPolicy.customerPrivilegeInheritanceAllowed,
        isFalse,
      );
      expect(
        AgentOwnerWhatsAppControlPolicy.directBusinessExecutionAllowed,
        isFalse,
      );
      expect(AgentOwnerWhatsAppControlPolicy.deployAllowed, isFalse);
      expect(
        AgentOwnerWhatsAppControlPolicy.liveTransportEnabledByDefault,
        isFalse,
      );
    });
  });
}

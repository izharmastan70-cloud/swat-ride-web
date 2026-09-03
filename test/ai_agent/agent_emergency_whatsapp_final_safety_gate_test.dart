import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_action_ids.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_emergency_whatsapp_foundation.dart';
import 'package:swat_ride/ai_agent/models/agent_emergency_whatsapp_prepared_escalation.dart';
import 'package:swat_ride/ai_agent/models/agent_emergency_whatsapp_verified_safety_snapshot.dart';
import 'package:swat_ride/ai_agent/models/agent_master_settings.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_emergency_whatsapp_command_classifier.dart';
import 'package:swat_ride/ai_agent/services/agent_emergency_whatsapp_response_guard.dart';
import 'package:swat_ride/ai_agent/services/agent_permission_engine.dart';

void main() {
  const foundation = AgentEmergencyWhatsAppFoundation();
  const classifier = AgentEmergencyWhatsAppCommandClassifier();
  const responseGuard = AgentEmergencyWhatsAppResponseGuard();

  AgentRole emergencyRole() {
    return buildInitialAgentRoles()
        .singleWhere(
          (AgentRole role) =>
              role.roleId == AgentEmergencyWhatsAppFoundation.roleId,
        )
        .copyWith(enabled: true);
  }

  group('Phase 47 Emergency WhatsApp final safety gate', () {
    test('role remains isolated and escalation remains approval-bound', () {
      final AgentRole role = emergencyRole();

      expect(role.roleId, AgentEmergencyWhatsAppFoundation.roleId);
      expect(role.module, AgentEmergencyWhatsAppFoundation.module);
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

      final decision = const AgentPermissionEngine().evaluate(
        role: role,
        actionId: AgentActionId.requestEmergencyWhatsAppEscalation,
      );

      expect(decision.needsApproval, isTrue);
    });

    test('Emergency WhatsApp master switch remains default OFF', () {
      final settings = AgentMasterSettings.safeDefaults();

      expect(settings.emergencyWhatsAppAgentEnabled, isFalse);
    });

    test(
      'foundation grants no message, Safety-write or transport authority',
      () {
        expect(foundation.messageGrantsAuthority, isFalse);
        expect(foundation.phoneNumberMatchAloneIsAuthority, isFalse);
        expect(foundation.customerWhatsAppAuthorityInherited, isFalse);
        expect(foundation.ownerWhatsAppAuthorityInherited, isFalse);
        expect(
          foundation.emergencyAuthorityGrantedToOtherWhatsAppRoles,
          isFalse,
        );
        expect(foundation.arbitrarySafetyFirestoreAccessAllowed, isFalse);
        expect(foundation.mayCreateSafetyIncidentFromMessage, isFalse);
        expect(foundation.mayAcknowledgeIncident, isFalse);
        expect(foundation.mayAssignSafetyAgent, isFalse);
        expect(foundation.mayResolveIncident, isFalse);
        expect(foundation.mayMarkUserSafe, isFalse);
        expect(foundation.mayUpdateEmergencyLocation, isFalse);
        expect(foundation.mayModifyTrustedContacts, isFalse);
        expect(foundation.mayExposeExactGpsByDefault, isFalse);
        expect(foundation.mayExposeTrustedContactPhoneByDefault, isFalse);
        expect(foundation.mayExposeMedicalProfileByDefault, isFalse);
        expect(foundation.maySendWhatsApp, isFalse);
        expect(foundation.maySendSms, isFalse);
        expect(foundation.mayPlaceEmergencyCall, isFalse);
        expect(foundation.mayCallProvider, isFalse);
        expect(foundation.mayHandleLiveWebhook, isFalse);
        expect(foundation.mayDeploy, isFalse);
      },
    );

    test(
      'classifier keeps status, SOS, sensitive and forbidden paths distinct',
      () {
        expect(
          classifier.classify('SOS status').commandClass,
          AgentEmergencyWhatsAppCommandClass.readVerifiedSafetyStatus,
        );
        expect(
          classifier.classify('SOS').commandClass,
          AgentEmergencyWhatsAppCommandClass.prepareEmergencyEscalation,
        );
        expect(
          classifier.classify('show my exact GPS location').commandClass,
          AgentEmergencyWhatsAppCommandClass.sensitiveSafetyData,
        );
        expect(
          classifier.classify('give me my OTP').commandClass,
          AgentEmergencyWhatsAppCommandClass.forbidden,
        );
        expect(
          classifier.classify('maybe do something').commandClass,
          AgentEmergencyWhatsAppCommandClass.forbidden,
        );
      },
    );

    test(
      'unverified safety source cannot produce invented emergency facts',
      () {
        final classification = classifier.classify('incident status');

        const snapshot =
            AgentEmergencyWhatsAppVerifiedSafetySnapshot.unavailable(
              reason: 'verified source unavailable',
            );

        final response = responseGuard.build(
          classification: classification,
          snapshot: snapshot,
        );

        expect(response.mustNotInvent, isTrue);
        expect(response.usedVerifiedFactsOnly, isTrue);
        expect(response.visibleText.toLowerCase(), contains('unavailable'));
        expect(response.visibleText.toLowerCase(), contains('will not guess'));
        expect(response.mayWriteSafetyData, isFalse);
        expect(response.mayCallProvider, isFalse);
      },
    );

    test('prepared escalation never becomes execution authority', () {
      final classification = classifier.classify('SOS');

      final prepared = AgentEmergencyWhatsAppPreparedEscalation(
        roleId: AgentEmergencyWhatsAppFoundation.roleId,
        module: AgentEmergencyWhatsAppFoundation.module,
        actionId: AgentActionId.requestEmergencyWhatsAppEscalation,
        principalUid: 'user_final_gate',
        subjectType: 'customer',
        reasonCode: AgentEmergencyWhatsAppEscalationReasonCode
            .userRequestsEmergencyHelp,
        preparedAt: DateTime.utc(2026, 8, 18, 3),
        validUntil: DateTime.utc(2026, 8, 18, 3, 5),
      );

      final response = responseGuard.build(
        classification: classification,
        preparedEscalation: prepared,
      );

      expect(prepared.persistentApprovalCreated, isFalse);
      expect(prepared.approvalConsumed, isFalse);
      expect(prepared.safetyIncidentCreated, isFalse);
      expect(prepared.safetyIncidentMutated, isFalse);
      expect(prepared.safetyAlertSent, isFalse);
      expect(prepared.whatsappSent, isFalse);
      expect(prepared.smsSent, isFalse);
      expect(prepared.emergencyCallPlaced, isFalse);
      expect(prepared.providerCalled, isFalse);
      expect(prepared.liveWebhookHandled, isFalse);
      expect(prepared.deploymentTriggered, isFalse);

      expect(response.escalationOnlyPrepared, isTrue);
      expect(response.visibleText.toLowerCase(), contains('requires approval'));
      expect(response.mayCreateApproval, isFalse);
      expect(response.mayConsumeApproval, isFalse);
      expect(response.mayWriteSafetyData, isFalse);
      expect(response.maySendWhatsApp, isFalse);
      expect(response.maySendSms, isFalse);
      expect(response.mayPlaceEmergencyCall, isFalse);
      expect(response.mayCallProvider, isFalse);
      expect(response.mayDeploy, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_omnichannel_constants.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_omnichannel_raw_ingress.dart';
import 'package:swat_ride/ai_agent/models/agent_omnichannel_routing_handoff.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_omnichannel_orchestrator_handoff_service.dart';

void main() {
  const AgentOmnichannelOrchestratorHandoffService service =
      AgentOmnichannelOrchestratorHandoffService();

  AgentOmnichannelRawIngress raw({
    required String channel,
    required String roleId,
    bool trusted = true,
    bool strongReauth = false,
    bool unsafePrivacy = false,
  }) {
    return AgentOmnichannelRawIngress(
      rawIngressId: 'step1d_${channel}_001',
      channel: channel,
      externalMessageRef: 'ext_step1d_001',
      intendedAgentRoleId: roleId,
      receivedAt: DateTime.utc(2026, 8, 19, 6, 10),
      sanitizedText: 'Need safe support.',
      subjectRef: 'subject_step1d_001',
      identityAssurance: strongReauth
          ? AgentOmnichannelIdentityAssurance.strongReauth
          : trusted
          ? AgentOmnichannelIdentityAssurance.verifiedSession
          : AgentOmnichannelIdentityAssurance.asserted,
      verifiedByTrustedBoundary: trusted,
      strongReauthSatisfied: strongReauth,
      fromChannelClaimOnly: !trusted,
      containsRawSecrets: unsafePrivacy,
      containsPaymentCredentials: false,
      containsAuthToken: false,
      containsGovernmentId: false,
      containsUnredactedContactDetails: false,
      redactionApplied: !unsafePrivacy,
    );
  }

  group('Phase 51 Step 1D safe routing handoff', () {
    test('trusted customer WhatsApp gets STANDARD safe route', () {
      final handoff = service.prepare(
        raw(
          channel: AgentOmnichannelChannel.customerWhatsApp,
          roleId: 'customer_whatsapp_agent',
        ),
      );

      expect(handoff.ready, isTrue);
      expect(
        handoff.routingDecision.mode,
        AgentOmnichannelRoutingMode.standard,
      );
      expect(handoff.orchestratorInvoked, isFalse);
      expect(handoff.targetAgentInvoked, isFalse);
    });

    test('unverified customer WhatsApp gets IDENTITY_RESTRICTED route', () {
      final handoff = service.prepare(
        raw(
          channel: AgentOmnichannelChannel.customerWhatsApp,
          roleId: 'customer_whatsapp_agent',
          trusted: false,
        ),
      );

      expect(handoff.ready, isTrue);
      expect(
        handoff.routingDecision.mode,
        AgentOmnichannelRoutingMode.identityRestricted,
      );
      expect(handoff.routingDecision.identityVerificationRequired, isTrue);
      expect(handoff.permissionGranted, isFalse);
    });

    test('unverified emergency stays EMERGENCY_SAFE_TRIAGE only', () {
      final handoff = service.prepare(
        raw(
          channel: AgentOmnichannelChannel.emergencyWhatsApp,
          roleId: 'emergency_whatsapp_agent',
          trusted: false,
        ),
      );

      expect(handoff.ready, isTrue);
      expect(
        handoff.routingDecision.mode,
        AgentOmnichannelRoutingMode.emergencySafeTriage,
      );
      expect(handoff.routingDecision.safeTriageOnly, isTrue);
      expect(handoff.runtimeActionExecuted, isFalse);
      expect(handoff.businessDataWritten, isFalse);
    });

    test('Owner WhatsApp without strong reauth is restricted', () {
      final handoff = service.prepare(
        raw(
          channel: AgentOmnichannelChannel.ownerWhatsApp,
          roleId: 'owner_whatsapp_agent',
          trusted: true,
          strongReauth: false,
        ),
      );

      expect(handoff.ready, isTrue);
      expect(
        handoff.routingDecision.mode,
        AgentOmnichannelRoutingMode.ownerReauthRestricted,
      );
      expect(
        handoff.routingDecision.strongReauthRequiredBeforeConsequentialAction,
        isTrue,
      );
      expect(handoff.approvalConsumed, isFalse);
    });

    test('Owner Voice with strong reauth can use STANDARD route', () {
      final handoff = service.prepare(
        raw(
          channel: AgentOmnichannelChannel.ownerVoice,
          roleId: 'voice_super_admin_agent',
          trusted: true,
          strongReauth: true,
        ),
      );

      expect(handoff.ready, isTrue);
      expect(
        handoff.routingDecision.mode,
        AgentOmnichannelRoutingMode.standard,
      );
      expect(
        handoff.routingDecision.strongReauthRequiredBeforeConsequentialAction,
        isFalse,
      );
      expect(handoff.permissionGranted, isFalse);
    });

    test('privacy-unsafe Email fails closed into BLOCKED route', () {
      final handoff = service.prepare(
        raw(
          channel: AgentOmnichannelChannel.email,
          roleId: 'email_agent',
          unsafePrivacy: true,
        ),
      );

      expect(handoff.ready, isFalse);
      expect(handoff.routingDecision.mode, AgentOmnichannelRoutingMode.blocked);
      expect(handoff.routingDecision.readyForOrchestratorHandoff, isFalse);
      expect(handoff.orchestratorInvoked, isFalse);
    });

    test('channel-role mismatch fails closed into BLOCKED route', () {
      final handoff = service.prepare(
        raw(
          channel: AgentOmnichannelChannel.phoneCall,
          roleId: 'owner_whatsapp_agent',
        ),
      );

      expect(handoff.ready, isFalse);
      expect(handoff.routingDecision.mode, AgentOmnichannelRoutingMode.blocked);
      expect(handoff.targetAgentInvoked, isFalse);
    });

    test('all seven correct trusted channel-role pairs are routable', () {
      const Map<String, String> roles = <String, String>{
        AgentOmnichannelChannel.appChat: 'support_agent',
        AgentOmnichannelChannel.customerWhatsApp: 'customer_whatsapp_agent',
        AgentOmnichannelChannel.ownerWhatsApp: 'owner_whatsapp_agent',
        AgentOmnichannelChannel.emergencyWhatsApp: 'emergency_whatsapp_agent',
        AgentOmnichannelChannel.email: 'email_agent',
        AgentOmnichannelChannel.phoneCall: 'call_agent',
        AgentOmnichannelChannel.ownerVoice: 'voice_super_admin_agent',
      };

      for (final MapEntry<String, String> entry in roles.entries) {
        final bool privileged =
            entry.key == AgentOmnichannelChannel.ownerWhatsApp ||
            entry.key == AgentOmnichannelChannel.ownerVoice;

        final handoff = service.prepare(
          raw(
            channel: entry.key,
            roleId: entry.value,
            trusted: true,
            strongReauth: privileged,
          ),
        );

        expect(handoff.ready, isTrue);
        expect(handoff.routingDecision.targetAgentRoleId, entry.value);
        expect(handoff.orchestratorInvoked, isFalse);
      }
    });

    test('routing safe map exposes no execution or shared-context claim', () {
      final handoff = service.prepare(
        raw(channel: AgentOmnichannelChannel.appChat, roleId: 'support_agent'),
      );

      final Map<String, dynamic> map = handoff.routingDecision.toSafeMap();

      expect(map['readyForOrchestratorHandoff'], isTrue);
      expect(map['orchestratorInvoked'], isFalse);
      expect(map['targetAgentInvoked'], isFalse);
      expect(map['providerInvoked'], isFalse);
      expect(map['runtimeActionExecuted'], isFalse);
      expect(map['permissionGranted'], isFalse);
      expect(map['approvalConsumed'], isFalse);
      expect(map['businessDataWritten'], isFalse);
      expect(map['sharedCrossChannelContextLoaded'], isFalse);
    });

    test('handoff service exposes no runtime/provider/deploy authority', () {
      expect(service.invokesOrchestrator, isFalse);
      expect(service.invokesTargetAgent, isFalse);
      expect(service.providerExecutionAllowed, isFalse);
      expect(service.runtimeActionAllowed, isFalse);
      expect(service.productionDataAccessAllowed, isFalse);
      expect(service.businessWriteAllowed, isFalse);
      expect(service.approvalConsumptionAllowed, isFalse);
      expect(service.permissionGrantAllowed, isFalse);
      expect(service.sharedCrossChannelContextAccessAllowed, isFalse);
      expect(service.promptMutationAllowed, isFalse);
      expect(service.modelTrainingAllowed, isFalse);
      expect(service.deploymentAllowed, isFalse);
    });

    test(
      'existing channel roles remain present and call_agent stays four actions',
      () {
        final List<AgentRole> roles = buildInitialAgentRoles();

        const Set<String> expectedRoles = <String>{
          'support_agent',
          'customer_whatsapp_agent',
          'owner_whatsapp_agent',
          'emergency_whatsapp_agent',
          'email_agent',
          'call_agent',
          'voice_super_admin_agent',
        };

        expect(
          roles.map((AgentRole role) => role.roleId).toSet(),
          containsAll(expectedRoles),
        );

        final AgentRole callRole = roles.firstWhere(
          (AgentRole role) => role.roleId == 'call_agent',
        );

        expect(callRole.allowedActions.length, 4);
      },
    );
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_omnichannel_constants.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_omnichannel_raw_ingress.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_omnichannel_channel_adapter.dart';
import 'package:swat_ride/ai_agent/services/agent_omnichannel_gateway.dart';

void main() {
  const AgentOmnichannelChannelAdapterRegistry registry =
      AgentOmnichannelChannelAdapterRegistry();

  const AgentOmnichannelGateway gateway = AgentOmnichannelGateway();

  AgentOmnichannelRawIngress raw({
    required String channel,
    required String roleId,
    bool trusted = true,
    bool strongReauth = false,
    bool unsafePrivacy = false,
  }) {
    return AgentOmnichannelRawIngress(
      rawIngressId: 'raw_${channel}_001',
      channel: channel,
      externalMessageRef: 'external_ref_001',
      intendedAgentRoleId: roleId,
      receivedAt: DateTime.utc(2026, 8, 19, 1, 20),
      sanitizedText: 'Need help with my booking.',
      subjectRef: 'subject_001',
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

  const Map<String, String> roleByChannel = <String, String>{
    AgentOmnichannelChannel.appChat: 'support_agent',
    AgentOmnichannelChannel.customerWhatsApp: 'customer_whatsapp_agent',
    AgentOmnichannelChannel.ownerWhatsApp: 'owner_whatsapp_agent',
    AgentOmnichannelChannel.emergencyWhatsApp: 'emergency_whatsapp_agent',
    AgentOmnichannelChannel.email: 'email_agent',
    AgentOmnichannelChannel.phoneCall: 'call_agent',
    AgentOmnichannelChannel.ownerVoice: 'voice_super_admin_agent',
  };

  group('Phase 51 Step 1C gateway + adapters', () {
    test('adapter registry covers exactly all seven locked channels', () {
      expect(
        AgentOmnichannelChannelAdapterRegistry.adaptersByChannel.keys.toSet(),
        AgentOmnichannelChannel.values,
      );
      expect(
        AgentOmnichannelChannelAdapterRegistry.adaptersByChannel.length,
        7,
      );
    });

    test('each adapter normalizes its own channel deterministically', () {
      for (final String channel in AgentOmnichannelChannel.values) {
        final adapter = registry.adapterFor(channel);
        final normalized = adapter.normalize(
          raw(
            channel: channel,
            roleId: roleByChannel[channel]!,
            strongReauth:
                channel == AgentOmnichannelChannel.ownerVoice ||
                channel == AgentOmnichannelChannel.ownerWhatsApp,
          ),
        );

        expect(normalized.providerNeutral, isTrue);
        expect(normalized.isRuntimeExecutable, isFalse);
        expect(normalized.grantsAuthority, isFalse);
        expect(normalized.envelope.channel, channel);
        expect(normalized.envelope.intendedAgentRoleId, roleByChannel[channel]);
        expect(normalized.envelope.envelopeId, startsWith('omni_raw_'));
      }
    });

    test('adapter refuses a different channel', () {
      final adapter = registry.adapterFor(AgentOmnichannelChannel.email);

      expect(
        () => adapter.normalize(
          raw(channel: AgentOmnichannelChannel.phoneCall, roleId: 'call_agent'),
        ),
        throwsA(isA<AgentOmnichannelAdapterException>()),
      );
    });

    test(
      'gateway prepares routing for all seven correct channel-role pairs',
      () {
        for (final MapEntry<String, String> entry in roleByChannel.entries) {
          final handoff = gateway.prepare(
            raw(
              channel: entry.key,
              roleId: entry.value,
              strongReauth:
                  entry.key == AgentOmnichannelChannel.ownerVoice ||
                  entry.key == AgentOmnichannelChannel.ownerWhatsApp,
            ),
          );

          expect(handoff.preparedForRouting, isTrue);
          expect(handoff.preparedTargetAgentRoleId, entry.value);
          expect(handoff.orchestratorInvoked, isFalse);
          expect(handoff.agentInvoked, isFalse);
          expect(handoff.providerInvoked, isFalse);
          expect(handoff.runtimeActionExecuted, isFalse);
        }
      },
    );

    test('gateway preserves unverified emergency safe-triage semantics', () {
      final handoff = gateway.prepare(
        raw(
          channel: AgentOmnichannelChannel.emergencyWhatsApp,
          roleId: 'emergency_whatsapp_agent',
          trusted: false,
        ),
      );

      expect(handoff.preparedForRouting, isTrue);
      expect(handoff.ingressDecision.emergencySafeTriageOnly, isTrue);
      expect(handoff.ingressDecision.requiresIdentityVerification, isTrue);
      expect(handoff.runtimeActionExecuted, isFalse);
    });

    test('gateway preserves Owner strong re-auth requirement', () {
      final handoff = gateway.prepare(
        raw(
          channel: AgentOmnichannelChannel.ownerWhatsApp,
          roleId: 'owner_whatsapp_agent',
          trusted: true,
          strongReauth: false,
        ),
      );

      expect(handoff.preparedForRouting, isTrue);
      expect(
        handoff.ingressDecision.requiresStrongReauthBeforeConsequentialAction,
        isTrue,
      );
      expect(handoff.permissionGranted, isFalse);
      expect(handoff.approvalConsumed, isFalse);
    });

    test('privacy-unsafe input is normalized but blocked from routing', () {
      final handoff = gateway.prepare(
        raw(
          channel: AgentOmnichannelChannel.email,
          roleId: 'email_agent',
          unsafePrivacy: true,
        ),
      );

      expect(handoff.preparedForRouting, isFalse);
      expect(
        handoff.ingressDecision.reasonCodes,
        contains(AgentOmnichannelIngressReason.privacyFilterRequired),
      );
      expect(handoff.businessDataWritten, isFalse);
    });

    test('channel-role mismatch is blocked by the gateway', () {
      final handoff = gateway.prepare(
        raw(
          channel: AgentOmnichannelChannel.phoneCall,
          roleId: 'owner_whatsapp_agent',
        ),
      );

      expect(handoff.preparedForRouting, isFalse);
      expect(
        handoff.ingressDecision.reasonCodes,
        contains(AgentOmnichannelIngressReason.channelRoleMismatch),
      );
    });

    test('unknown adapter lookup fails closed', () {
      expect(
        () => registry.adapterFor('UNKNOWN_CHANNEL'),
        throwsA(isA<AgentOmnichannelAdapterException>()),
      );
    });

    test('gateway handoff safe map confirms no execution authority', () {
      final handoff = gateway.prepare(
        raw(
          channel: AgentOmnichannelChannel.customerWhatsApp,
          roleId: 'customer_whatsapp_agent',
        ),
      );

      final Map<String, dynamic> map = handoff.toSafeMap();

      expect(map['preparedForRouting'], isTrue);
      expect(map['orchestratorInvoked'], isFalse);
      expect(map['agentInvoked'], isFalse);
      expect(map['providerInvoked'], isFalse);
      expect(map['runtimeActionExecuted'], isFalse);
      expect(map['permissionGranted'], isFalse);
      expect(map['approvalConsumed'], isFalse);
      expect(map['businessDataWritten'], isFalse);
      expect(map['sharedCrossChannelContextLoaded'], isFalse);
    });

    test('registry and gateway expose no provider/runtime authority', () {
      expect(registry.providerExecutionAllowed, isFalse);
      expect(registry.runtimeActionAllowed, isFalse);
      expect(registry.permissionGrantAllowed, isFalse);
      expect(registry.approvalConsumptionAllowed, isFalse);
      expect(registry.businessWriteAllowed, isFalse);

      expect(gateway.orchestratorExecutionAllowed, isFalse);
      expect(gateway.agentExecutionAllowed, isFalse);
      expect(gateway.providerExecutionAllowed, isFalse);
      expect(gateway.runtimeActionAllowed, isFalse);
      expect(gateway.productionDataAccessAllowed, isFalse);
      expect(gateway.businessWriteAllowed, isFalse);
      expect(gateway.approvalConsumptionAllowed, isFalse);
      expect(gateway.permissionGrantAllowed, isFalse);
      expect(gateway.sharedCrossChannelContextAccessAllowed, isFalse);
      expect(gateway.promptMutationAllowed, isFalse);
      expect(gateway.modelTrainingAllowed, isFalse);
      expect(gateway.deploymentAllowed, isFalse);
    });

    test(
      'existing channel roles remain present and call_agent stays four actions',
      () {
        final List<AgentRole> roles = buildInitialAgentRoles();

        expect(
          roles.map((AgentRole role) => role.roleId).toSet(),
          containsAll(roleByChannel.values.toSet()),
        );

        final AgentRole callRole = roles.firstWhere(
          (AgentRole role) => role.roleId == 'call_agent',
        );

        expect(callRole.allowedActions.length, 4);
      },
    );
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_omnichannel_constants.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_omnichannel_envelope.dart';
import 'package:swat_ride/ai_agent/models/agent_omnichannel_identity_privacy.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_omnichannel_ingress_policy.dart';

void main() {
  const AgentOmnichannelIngressPolicy policy = AgentOmnichannelIngressPolicy();

  AgentOmnichannelIdentityContext trustedIdentity({bool strongReauth = false}) {
    return AgentOmnichannelIdentityContext(
      subjectRef: 'subject_test_001',
      assurance: strongReauth
          ? AgentOmnichannelIdentityAssurance.strongReauth
          : AgentOmnichannelIdentityAssurance.verifiedSession,
      verifiedByTrustedBoundary: true,
      strongReauthSatisfied: strongReauth,
      fromChannelClaimOnly: false,
    );
  }

  AgentOmnichannelIdentityContext unverifiedIdentity() {
    return const AgentOmnichannelIdentityContext(
      subjectRef: 'subject_unverified_001',
      assurance: AgentOmnichannelIdentityAssurance.asserted,
      verifiedByTrustedBoundary: false,
      strongReauthSatisfied: false,
      fromChannelClaimOnly: true,
    );
  }

  const AgentOmnichannelPrivacyContext safePrivacy =
      AgentOmnichannelPrivacyContext(
        sanitizedText: 'Need help with my existing booking.',
        containsRawSecrets: false,
        containsPaymentCredentials: false,
        containsAuthToken: false,
        containsGovernmentId: false,
        containsUnredactedContactDetails: false,
        redactionApplied: true,
      );

  AgentOmnichannelEnvelope envelope({
    required String channel,
    required String roleId,
    required AgentOmnichannelIdentityContext identity,
    AgentOmnichannelPrivacyContext privacy = safePrivacy,
  }) {
    return AgentOmnichannelEnvelope(
      envelopeId: 'env_${channel}_001',
      externalMessageRef: 'msg_ref_001',
      channel: channel,
      intendedAgentRoleId: roleId,
      receivedAt: DateTime.utc(2026, 8, 19, 0, 30),
      identity: identity,
      privacy: privacy,
    );
  }

  group('Phase 51 Step 1B omnichannel contract', () {
    test('exact seven locked ingress channels exist', () {
      expect(AgentOmnichannelChannel.values, <String>{
        AgentOmnichannelChannel.appChat,
        AgentOmnichannelChannel.customerWhatsApp,
        AgentOmnichannelChannel.ownerWhatsApp,
        AgentOmnichannelChannel.emergencyWhatsApp,
        AgentOmnichannelChannel.email,
        AgentOmnichannelChannel.phoneCall,
        AgentOmnichannelChannel.ownerVoice,
      });
      expect(AgentOmnichannelChannel.values.length, 7);
    });

    test('allowed role map covers every locked channel exactly once', () {
      expect(
        AgentOmnichannelIngressPolicy.allowedRolesByChannel.keys.toSet(),
        AgentOmnichannelChannel.values,
      );

      for (final Set<String> roles
          in AgentOmnichannelIngressPolicy.allowedRolesByChannel.values) {
        expect(roles.length, 1);
      }
    });

    test('trusted Customer WhatsApp envelope is accepted for routing', () {
      final decision = policy.evaluate(
        envelope(
          channel: AgentOmnichannelChannel.customerWhatsApp,
          roleId: 'customer_whatsapp_agent',
          identity: trustedIdentity(),
        ),
      );

      expect(decision.acceptedForRouting, isTrue);
      expect(decision.requiresIdentityVerification, isFalse);
      expect(decision.requiresStrongReauthBeforeConsequentialAction, isFalse);
      expect(decision.emergencySafeTriageOnly, isFalse);
    });

    test('unverified channel identity never becomes authority', () {
      final item = envelope(
        channel: AgentOmnichannelChannel.customerWhatsApp,
        roleId: 'customer_whatsapp_agent',
        identity: unverifiedIdentity(),
      );

      final decision = policy.evaluate(item);

      expect(decision.acceptedForRouting, isTrue);
      expect(decision.requiresIdentityVerification, isTrue);
      expect(
        decision.reasonCodes,
        contains(AgentOmnichannelIngressReason.identityVerificationRequired),
      );
      expect(item.identity.identityIsAuthority, isFalse);
      expect(decision.grantsAuthority, isFalse);
    });

    test(
      'Owner WhatsApp requires strong re-auth flag for consequential work',
      () {
        final decision = policy.evaluate(
          envelope(
            channel: AgentOmnichannelChannel.ownerWhatsApp,
            roleId: 'owner_whatsapp_agent',
            identity: trustedIdentity(),
          ),
        );

        expect(decision.acceptedForRouting, isTrue);
        expect(decision.requiresStrongReauthBeforeConsequentialAction, isTrue);
        expect(
          decision.reasonCodes,
          contains(AgentOmnichannelIngressReason.strongReauthRequired),
        );
        expect(decision.grantsAuthority, isFalse);
      },
    );

    test(
      'Owner Voice strong re-auth can be proven but still grants no authority',
      () {
        final decision = policy.evaluate(
          envelope(
            channel: AgentOmnichannelChannel.ownerVoice,
            roleId: 'voice_super_admin_agent',
            identity: trustedIdentity(strongReauth: true),
          ),
        );

        expect(decision.acceptedForRouting, isTrue);
        expect(decision.requiresStrongReauthBeforeConsequentialAction, isFalse);
        expect(decision.grantsAuthority, isFalse);
        expect(decision.executesBusinessAction, isFalse);
      },
    );

    test(
      'unverified emergency input is accepted only for safe triage routing',
      () {
        final decision = policy.evaluate(
          envelope(
            channel: AgentOmnichannelChannel.emergencyWhatsApp,
            roleId: 'emergency_whatsapp_agent',
            identity: unverifiedIdentity(),
          ),
        );

        expect(decision.acceptedForRouting, isTrue);
        expect(decision.requiresIdentityVerification, isTrue);
        expect(decision.emergencySafeTriageOnly, isTrue);
        expect(
          decision.reasonCodes,
          contains(AgentOmnichannelIngressReason.emergencyUnverifiedSafeTriage),
        );
        expect(decision.executesBusinessAction, isFalse);
      },
    );

    test('privacy-unsafe envelope is rejected from routing', () {
      const unsafePrivacy = AgentOmnichannelPrivacyContext(
        sanitizedText: 'contains secret material',
        containsRawSecrets: true,
        containsPaymentCredentials: false,
        containsAuthToken: false,
        containsGovernmentId: false,
        containsUnredactedContactDetails: false,
        redactionApplied: false,
      );

      final decision = policy.evaluate(
        envelope(
          channel: AgentOmnichannelChannel.email,
          roleId: 'email_agent',
          identity: trustedIdentity(),
          privacy: unsafePrivacy,
        ),
      );

      expect(decision.acceptedForRouting, isFalse);
      expect(
        decision.reasonCodes,
        contains(AgentOmnichannelIngressReason.privacyFilterRequired),
      );
    });

    test('channel-role mismatch is rejected', () {
      final decision = policy.evaluate(
        envelope(
          channel: AgentOmnichannelChannel.phoneCall,
          roleId: 'owner_whatsapp_agent',
          identity: trustedIdentity(),
        ),
      );

      expect(decision.acceptedForRouting, isFalse);
      expect(
        decision.reasonCodes,
        contains(AgentOmnichannelIngressReason.channelRoleMismatch),
      );
    });

    test('channel-only identity claim cannot masquerade as trusted proof', () {
      const invalid = AgentOmnichannelIdentityContext(
        subjectRef: 'subject_invalid',
        assurance: AgentOmnichannelIdentityAssurance.asserted,
        verifiedByTrustedBoundary: true,
        strongReauthSatisfied: false,
        fromChannelClaimOnly: true,
      );

      expect(
        invalid.validate,
        throwsA(isA<AgentOmnichannelContractException>()),
      );
    });

    test('strong re-auth cannot exist without trusted boundary', () {
      const invalid = AgentOmnichannelIdentityContext(
        subjectRef: 'subject_invalid',
        assurance: AgentOmnichannelIdentityAssurance.strongReauth,
        verifiedByTrustedBoundary: false,
        strongReauthSatisfied: true,
        fromChannelClaimOnly: false,
      );

      expect(
        invalid.validate,
        throwsA(isA<AgentOmnichannelContractException>()),
      );
    });

    test('safe maps omit raw sanitized content and subject reference', () {
      final item = envelope(
        channel: AgentOmnichannelChannel.appChat,
        roleId: 'support_agent',
        identity: trustedIdentity(),
      );

      final Map<String, dynamic> envelopeMap = item.toSafeMap();
      final Map<String, dynamic> identityMap = item.identity.toSafeMap();
      final Map<String, dynamic> privacyMap = item.privacy.toSafeMap();

      expect(envelopeMap.containsKey('sanitizedText'), isFalse);
      expect(identityMap.containsKey('subjectRef'), isFalse);
      expect(privacyMap.containsKey('sanitizedText'), isFalse);
    });

    test('policy exposes no provider/runtime/permission authority', () {
      expect(policy.providerExecutionAllowed, isFalse);
      expect(policy.runtimeActionAllowed, isFalse);
      expect(policy.productionDataAccessAllowed, isFalse);
      expect(policy.businessWriteAllowed, isFalse);
      expect(policy.approvalConsumptionAllowed, isFalse);
      expect(policy.permissionGrantAllowed, isFalse);
      expect(policy.channelContentAuthorityAllowed, isFalse);
      expect(policy.identityAuthorityAllowed, isFalse);
      expect(policy.promptMutationAllowed, isFalse);
      expect(policy.modelTrainingAllowed, isFalse);
      expect(policy.deploymentAllowed, isFalse);
    });

    test(
      'existing channel roles remain present and call_agent stays four actions',
      () {
        final List<AgentRole> roles = buildInitialAgentRoles();

        const Set<String> expectedRoleIds = <String>{
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
          containsAll(expectedRoleIds),
        );

        final AgentRole callRole = roles.firstWhere(
          (AgentRole role) => role.roleId == 'call_agent',
        );

        expect(callRole.allowedActions.length, 4);
      },
    );
  });
}

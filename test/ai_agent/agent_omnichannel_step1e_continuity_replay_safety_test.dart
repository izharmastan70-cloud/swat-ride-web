import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_omnichannel_constants.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_omnichannel_continuity_metadata.dart';
import 'package:swat_ride/ai_agent/models/agent_omnichannel_raw_ingress.dart';
import 'package:swat_ride/ai_agent/models/agent_omnichannel_replay_assessment.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_omnichannel_orchestrator_handoff_service.dart';
import 'package:swat_ride/ai_agent/services/agent_omnichannel_replay_guard.dart';

void main() {
  const AgentOmnichannelOrchestratorHandoffService handoffService =
      AgentOmnichannelOrchestratorHandoffService();

  const AgentOmnichannelReplayGuard replayGuard = AgentOmnichannelReplayGuard();

  AgentOmnichannelRawIngress raw({
    required String id,
    required String channel,
    required String roleId,
    required DateTime receivedAt,
    bool trusted = true,
    bool strongReauth = false,
    bool unsafePrivacy = false,
  }) {
    return AgentOmnichannelRawIngress(
      rawIngressId: id,
      channel: channel,
      externalMessageRef: 'ext_$id',
      intendedAgentRoleId: roleId,
      receivedAt: receivedAt,
      sanitizedText: 'Continue safe support.',
      subjectRef: 'subject_continuity_001',
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

  AgentOmnichannelReplayWindow replayWindow({
    Iterable<String> externalRefs = const <String>[],
    Iterable<String> envelopeIds = const <String>[],
    DateTime? notBefore,
  }) {
    return AgentOmnichannelReplayWindow(
      seenExternalMessageRefs: externalRefs,
      seenEnvelopeIds: envelopeIds,
      notBefore: notBefore ?? DateTime.utc(2026, 8, 19, 5, 0),
    );
  }

  AgentOmnichannelContinuityMetadata continuityFor({
    required String previousChannel,
    required String currentChannel,
    required String currentEnvelopeId,
    required String currentExternalRef,
    required DateTime previousAt,
    required DateTime currentAt,
    bool trustedBoundary = true,
    String subjectRef = 'subject_continuity_001',
    int hopCount = 1,
  }) {
    return AgentOmnichannelContinuityMetadata(
      continuityId: 'continuity_001',
      previousEnvelopeId: 'previous_env_001',
      previousExternalMessageRef: 'previous_ext_001',
      previousChannel: previousChannel,
      currentEnvelopeId: currentEnvelopeId,
      currentExternalMessageRef: currentExternalRef,
      currentChannel: currentChannel,
      continuitySubjectRef: subjectRef,
      previousReceivedAt: previousAt,
      currentReceivedAt: currentAt,
      hopCount: hopCount,
      generatedByTrustedBoundary: trustedBoundary,
    );
  }

  group('Phase 51 Step 1E continuity + replay safety', () {
    test('fresh trusted cross-channel metadata continuity is accepted', () {
      final DateTime now = DateTime.utc(2026, 8, 19, 6, 30);

      final handoff = handoffService.prepare(
        raw(
          id: 'trusted_email_to_call',
          channel: AgentOmnichannelChannel.phoneCall,
          roleId: 'call_agent',
          receivedAt: now,
        ),
      );

      final envelope = handoff.gatewayHandoff.normalizedIngress.envelope;

      final assessment = replayGuard.assess(
        handoff: handoff,
        replayWindow: replayWindow(),
        continuity: continuityFor(
          previousChannel: AgentOmnichannelChannel.email,
          currentChannel: AgentOmnichannelChannel.phoneCall,
          currentEnvelopeId: envelope.envelopeId,
          currentExternalRef: envelope.externalMessageRef,
          previousAt: now.subtract(const Duration(minutes: 20)),
          currentAt: now,
        ),
      );

      expect(assessment.routeMayProceed, isTrue);
      expect(assessment.continuityAccepted, isTrue);
      expect(
        assessment.disposition,
        AgentOmnichannelReplayDisposition.freshWithContinuity,
      );
      expect(assessment.replayDetected, isFalse);
    });

    test('fresh route without continuity metadata still proceeds', () {
      final DateTime now = DateTime.utc(2026, 8, 19, 6, 35);

      final handoff = handoffService.prepare(
        raw(
          id: 'no_continuity',
          channel: AgentOmnichannelChannel.appChat,
          roleId: 'support_agent',
          receivedAt: now,
        ),
      );

      final assessment = replayGuard.assess(
        handoff: handoff,
        replayWindow: replayWindow(),
      );

      expect(assessment.routeMayProceed, isTrue);
      expect(assessment.continuityAccepted, isFalse);
      expect(
        assessment.disposition,
        AgentOmnichannelReplayDisposition.freshWithoutContinuity,
      );
    });

    test('duplicate external message reference fails closed', () {
      final DateTime now = DateTime.utc(2026, 8, 19, 6, 40);

      final handoff = handoffService.prepare(
        raw(
          id: 'duplicate_ext',
          channel: AgentOmnichannelChannel.customerWhatsApp,
          roleId: 'customer_whatsapp_agent',
          receivedAt: now,
        ),
      );

      final envelope = handoff.gatewayHandoff.normalizedIngress.envelope;

      final assessment = replayGuard.assess(
        handoff: handoff,
        replayWindow: replayWindow(
          externalRefs: <String>[envelope.externalMessageRef],
        ),
      );

      expect(assessment.routeMayProceed, isFalse);
      expect(assessment.replayDetected, isTrue);
      expect(
        assessment.disposition,
        AgentOmnichannelReplayDisposition.blockedDuplicateExternalRef,
      );
      expect(assessment.invokesOrchestrator, isFalse);
    });

    test('duplicate normalized envelope ID fails closed', () {
      final DateTime now = DateTime.utc(2026, 8, 19, 6, 45);

      final handoff = handoffService.prepare(
        raw(
          id: 'duplicate_envelope',
          channel: AgentOmnichannelChannel.email,
          roleId: 'email_agent',
          receivedAt: now,
        ),
      );

      final envelope = handoff.gatewayHandoff.normalizedIngress.envelope;

      final assessment = replayGuard.assess(
        handoff: handoff,
        replayWindow: replayWindow(envelopeIds: <String>[envelope.envelopeId]),
      );

      expect(assessment.routeMayProceed, isFalse);
      expect(assessment.replayDetected, isTrue);
      expect(
        assessment.disposition,
        AgentOmnichannelReplayDisposition.blockedDuplicateEnvelope,
      );
    });

    test('message older than replay window fails closed', () {
      final handoff = handoffService.prepare(
        raw(
          id: 'stale',
          channel: AgentOmnichannelChannel.appChat,
          roleId: 'support_agent',
          receivedAt: DateTime.utc(2026, 8, 19, 4, 59),
        ),
      );

      final assessment = replayGuard.assess(
        handoff: handoff,
        replayWindow: replayWindow(notBefore: DateTime.utc(2026, 8, 19, 5, 0)),
      );

      expect(assessment.routeMayProceed, isFalse);
      expect(assessment.replayDetected, isTrue);
      expect(
        assessment.disposition,
        AgentOmnichannelReplayDisposition.blockedStaleReplay,
      );
    });

    test('untrusted identity cannot inherit previous-channel continuity', () {
      final DateTime now = DateTime.utc(2026, 8, 19, 6, 50);

      final handoff = handoffService.prepare(
        raw(
          id: 'untrusted_customer',
          channel: AgentOmnichannelChannel.customerWhatsApp,
          roleId: 'customer_whatsapp_agent',
          receivedAt: now,
          trusted: false,
        ),
      );

      final envelope = handoff.gatewayHandoff.normalizedIngress.envelope;

      final assessment = replayGuard.assess(
        handoff: handoff,
        replayWindow: replayWindow(),
        continuity: continuityFor(
          previousChannel: AgentOmnichannelChannel.appChat,
          currentChannel: AgentOmnichannelChannel.customerWhatsApp,
          currentEnvelopeId: envelope.envelopeId,
          currentExternalRef: envelope.externalMessageRef,
          previousAt: now.subtract(const Duration(minutes: 5)),
          currentAt: now,
        ),
      );

      expect(assessment.routeMayProceed, isTrue);
      expect(assessment.continuityAccepted, isFalse);
      expect(assessment.continuityRejected, isTrue);
      expect(
        assessment.disposition,
        AgentOmnichannelReplayDisposition.freshWithoutContinuity,
      );
    });

    test(
      'unverified emergency route remains safe triage without continuity merge',
      () {
        final DateTime now = DateTime.utc(2026, 8, 19, 6, 55);

        final handoff = handoffService.prepare(
          raw(
            id: 'emergency_untrusted',
            channel: AgentOmnichannelChannel.emergencyWhatsApp,
            roleId: 'emergency_whatsapp_agent',
            receivedAt: now,
            trusted: false,
          ),
        );

        final envelope = handoff.gatewayHandoff.normalizedIngress.envelope;

        final assessment = replayGuard.assess(
          handoff: handoff,
          replayWindow: replayWindow(),
          continuity: continuityFor(
            previousChannel: AgentOmnichannelChannel.customerWhatsApp,
            currentChannel: AgentOmnichannelChannel.emergencyWhatsApp,
            currentEnvelopeId: envelope.envelopeId,
            currentExternalRef: envelope.externalMessageRef,
            previousAt: now.subtract(const Duration(minutes: 2)),
            currentAt: now,
          ),
        );

        expect(handoff.routingDecision.safeTriageOnly, isTrue);
        expect(assessment.routeMayProceed, isTrue);
        expect(assessment.continuityAccepted, isFalse);
        expect(assessment.continuityRejected, isTrue);
        expect(assessment.writesBusinessData, isFalse);
      },
    );

    test('continuity subject mismatch does not merge channels', () {
      final DateTime now = DateTime.utc(2026, 8, 19, 7, 0);

      final handoff = handoffService.prepare(
        raw(
          id: 'subject_mismatch',
          channel: AgentOmnichannelChannel.phoneCall,
          roleId: 'call_agent',
          receivedAt: now,
        ),
      );

      final envelope = handoff.gatewayHandoff.normalizedIngress.envelope;

      final assessment = replayGuard.assess(
        handoff: handoff,
        replayWindow: replayWindow(),
        continuity: continuityFor(
          previousChannel: AgentOmnichannelChannel.email,
          currentChannel: AgentOmnichannelChannel.phoneCall,
          currentEnvelopeId: envelope.envelopeId,
          currentExternalRef: envelope.externalMessageRef,
          previousAt: now.subtract(const Duration(minutes: 10)),
          currentAt: now,
          subjectRef: 'different_subject',
        ),
      );

      expect(assessment.routeMayProceed, isTrue);
      expect(assessment.continuityAccepted, isFalse);
      expect(assessment.continuityRejected, isTrue);
    });

    test(
      'continuity older than 24 hours is rejected without blocking fresh route',
      () {
        final DateTime now = DateTime.utc(2026, 8, 19, 7, 5);

        final handoff = handoffService.prepare(
          raw(
            id: 'old_continuity',
            channel: AgentOmnichannelChannel.phoneCall,
            roleId: 'call_agent',
            receivedAt: now,
          ),
        );

        final envelope = handoff.gatewayHandoff.normalizedIngress.envelope;

        final assessment = replayGuard.assess(
          handoff: handoff,
          replayWindow: replayWindow(),
          continuity: continuityFor(
            previousChannel: AgentOmnichannelChannel.email,
            currentChannel: AgentOmnichannelChannel.phoneCall,
            currentEnvelopeId: envelope.envelopeId,
            currentExternalRef: envelope.externalMessageRef,
            previousAt: now.subtract(const Duration(hours: 25)),
            currentAt: now,
          ),
        );

        expect(assessment.routeMayProceed, isTrue);
        expect(assessment.continuityAccepted, isFalse);
        expect(assessment.continuityRejected, isTrue);
      },
    );

    test('blocked routing remains blocked before continuity logic', () {
      final DateTime now = DateTime.utc(2026, 8, 19, 7, 10);

      final handoff = handoffService.prepare(
        raw(
          id: 'blocked_route',
          channel: AgentOmnichannelChannel.email,
          roleId: 'call_agent',
          receivedAt: now,
        ),
      );

      final assessment = replayGuard.assess(
        handoff: handoff,
        replayWindow: replayWindow(),
      );

      expect(handoff.ready, isFalse);
      expect(assessment.routeMayProceed, isFalse);
      expect(
        assessment.disposition,
        AgentOmnichannelReplayDisposition.blockedRouting,
      );
    });

    test(
      'continuity metadata safe map contains no message history or shared context',
      () {
        final DateTime now = DateTime.utc(2026, 8, 19, 7, 15);

        final metadata = continuityFor(
          previousChannel: AgentOmnichannelChannel.appChat,
          currentChannel: AgentOmnichannelChannel.email,
          currentEnvelopeId: 'omni_current',
          currentExternalRef: 'external_current',
          previousAt: now.subtract(const Duration(minutes: 3)),
          currentAt: now,
        );

        final Map<String, dynamic> map = metadata.toSafeMap();

        expect(map['containsMessageHistory'], isFalse);
        expect(map['containsConversationSummary'], isFalse);
        expect(map['containsSharedCustomerContext'], isFalse);
        expect(map['loadsPriorChannelContent'], isFalse);
        expect(map.containsKey('continuitySubjectRef'), isFalse);
        expect(map.containsKey('previousEnvelopeId'), isFalse);
        expect(map.containsKey('previousExternalMessageRef'), isFalse);
      },
    );

    test('replay window is immutable and not persisted by contract', () {
      final window = replayWindow(
        externalRefs: const <String>['one'],
        envelopeIds: const <String>['env_one'],
      );

      expect(window.persistedByThisContract, isFalse);
      expect(window.writesReplayState, isFalse);

      expect(
        () => window.seenExternalMessageRefs.add('two'),
        throwsUnsupportedError,
      );
      expect(
        () => window.seenEnvelopeIds.add('env_two'),
        throwsUnsupportedError,
      );
    });

    test('replay guard exposes no execution/persistence/Phase52 authority', () {
      expect(replayGuard.persistsReplayWindow, isFalse);
      expect(replayGuard.writesReplayState, isFalse);
      expect(replayGuard.providerExecutionAllowed, isFalse);
      expect(replayGuard.orchestratorExecutionAllowed, isFalse);
      expect(replayGuard.targetAgentExecutionAllowed, isFalse);
      expect(replayGuard.runtimeActionAllowed, isFalse);
      expect(replayGuard.productionDataAccessAllowed, isFalse);
      expect(replayGuard.businessWriteAllowed, isFalse);
      expect(replayGuard.approvalConsumptionAllowed, isFalse);
      expect(replayGuard.permissionGrantAllowed, isFalse);
      expect(replayGuard.sharedCrossChannelContextAccessAllowed, isFalse);
      expect(replayGuard.promptMutationAllowed, isFalse);
      expect(replayGuard.modelTrainingAllowed, isFalse);
      expect(replayGuard.deploymentAllowed, isFalse);
    });

    test(
      'existing channel roles remain and call_agent stays exact four actions',
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

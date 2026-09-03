import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_omnichannel_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_unified_context_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_unified_context_channel_handoff.dart';
import 'package:swat_ride/ai_agent/models/agent_unified_context_continuity_evidence.dart';
import 'package:swat_ride/ai_agent/models/agent_unified_context_prompt_projection.dart';
import 'package:swat_ride/ai_agent/services/agent_unified_context_channel_handoff_service.dart';

void main() {
  const AgentUnifiedContextChannelHandoffService service =
      AgentUnifiedContextChannelHandoffService();

  AgentUnifiedContextPromptProjection projection({
    String subjectRef = 'subject_hash_001',
    String purpose = AgentUnifiedContextPurpose.statusRead,
    bool withOmission = false,
    bool unresolved = false,
  }) {
    return AgentUnifiedContextPromptProjection(
      status: withOmission || unresolved
          ? AgentUnifiedContextPromptProjectionStatus.readyWithOmissions
          : AgentUnifiedContextPromptProjectionStatus.ready,
      reasonCode: AgentUnifiedContextPromptProjectionReason.ready,
      requestId: 'projection_001',
      requestingSubjectRef: subjectRef,
      requestedPurpose: purpose,
      projectedFacts: <AgentUnifiedContextProjectedFact>[
        AgentUnifiedContextProjectedFact(
          semanticKey: 'ride.current_status',
          sanitizedValue: 'assigned',
          sourceTrust: AgentUnifiedContextSourceTrust.verifiedSystem,
          sensitivity: AgentUnifiedContextSensitivity.personalData,
          dataKind: AgentUnifiedContextDataKind.statusFact,
          disclosureLabel: AgentUnifiedContextDisclosureLabel.verifiedSystem,
        ),
      ],
      omissionReasonBySemanticKey: withOmission
          ? const <String, String>{
              'ride.driver_eta': AgentUnifiedContextPromptProjectionReason
                  .requiredKeyUnavailable,
            }
          : const <String, String>{},
      unresolvedRequiredKeys: unresolved
          ? const <String>{'ride.driver_eta'}
          : const <String>{},
    );
  }

  AgentUnifiedContextContinuityEvidence evidence({
    String previousChannel = AgentOmnichannelChannel.appChat,
    String currentChannel = AgentOmnichannelChannel.customerWhatsApp,
    bool sameSubject = true,
    bool trustedIdentity = true,
    bool withinWindow = true,
    bool replayPassed = true,
    bool metadataOnly = true,
    bool carriesHistory = false,
    bool carriesSharedContext = false,
    bool emergencySafeTriageOnly = false,
    int hopCount = 1,
  }) {
    return AgentUnifiedContextContinuityEvidence(
      evidenceId: 'continuity_001',
      previousChannel: previousChannel,
      currentChannel: currentChannel,
      samePseudonymousSubject: sameSubject,
      trustedIdentityContinuity: trustedIdentity,
      withinContinuityWindow: withinWindow,
      replayAssessmentPassed: replayPassed,
      phase51ContinuityMetadataOnly: metadataOnly,
      phase51CarriesMessageHistory: carriesHistory,
      phase51CarriesSharedCustomerContext: carriesSharedContext,
      emergencySafeTriageOnly: emergencySafeTriageOnly,
      hopCount: hopCount,
    );
  }

  AgentUnifiedContextChannelHandoff prepare({
    String subjectRef = 'subject_hash_001',
    String purpose = AgentUnifiedContextPurpose.statusRead,
    String sourceChannel = AgentOmnichannelChannel.appChat,
    String targetChannel = AgentOmnichannelChannel.customerWhatsApp,
    String targetRoleId = 'customer_whatsapp_agent',
    AgentUnifiedContextPromptProjection? sourceProjection,
    AgentUnifiedContextContinuityEvidence? continuity,
    bool controlAllowed = true,
    bool targetAvailable = true,
    bool failureIsolationIntact = true,
  }) {
    return service.prepare(
      handoffId: 'handoff_001',
      subjectRef: subjectRef,
      requestedPurpose: purpose,
      sourceChannel: sourceChannel,
      targetChannel: targetChannel,
      targetRoleId: targetRoleId,
      projection: sourceProjection ?? projection(),
      continuityEvidence:
          continuity ??
          evidence(
            previousChannel: sourceChannel,
            currentChannel: targetChannel,
          ),
      phase51ChannelControlAllowed: controlAllowed,
      targetChannelAvailable: targetAvailable,
      phase51FailureIsolationIntact: failureIsolationIntact,
    );
  }

  group('Phase 52 Step 1F continuity handoff and isolation', () {
    test('customer-domain App Chat to Customer WhatsApp prepares safely', () {
      final AgentUnifiedContextChannelHandoff handoff = prepare();

      expect(handoff.prepared, isTrue);
      expect(handoff.hasProjection, isTrue);
      expect(handoff.failureContainedToHandoff, isTrue);
      expect(handoff.otherChannelsRemainAvailable, isTrue);
      expect(handoff.coreSwatRideRemainsAvailable, isTrue);
    });

    test('customer-domain App Chat to Email continuity is allowed', () {
      final handoff = prepare(
        targetChannel: AgentOmnichannelChannel.email,
        targetRoleId: 'email_agent',
        continuity: evidence(
          previousChannel: AgentOmnichannelChannel.appChat,
          currentChannel: AgentOmnichannelChannel.email,
        ),
      );

      expect(handoff.prepared, isTrue);
    });

    test('customer-domain Email to Phone Call continuity is allowed', () {
      final handoff = prepare(
        sourceChannel: AgentOmnichannelChannel.email,
        targetChannel: AgentOmnichannelChannel.phoneCall,
        targetRoleId: 'call_agent',
        continuity: evidence(
          previousChannel: AgentOmnichannelChannel.email,
          currentChannel: AgentOmnichannelChannel.phoneCall,
        ),
      );

      expect(handoff.prepared, isTrue);
    });

    test(
      'owner-domain Owner WhatsApp to Owner Voice continuity is allowed',
      () {
        final handoff = prepare(
          purpose: AgentUnifiedContextPurpose.ownerOperations,
          sourceChannel: AgentOmnichannelChannel.ownerWhatsApp,
          targetChannel: AgentOmnichannelChannel.ownerVoice,
          targetRoleId: 'voice_super_admin_agent',
          sourceProjection: projection(
            purpose: AgentUnifiedContextPurpose.ownerOperations,
          ),
          continuity: evidence(
            previousChannel: AgentOmnichannelChannel.ownerWhatsApp,
            currentChannel: AgentOmnichannelChannel.ownerVoice,
          ),
        );

        expect(handoff.prepared, isTrue);
      },
    );

    test('customer-to-owner domain handoff is blocked', () {
      final handoff = prepare(
        targetChannel: AgentOmnichannelChannel.ownerWhatsApp,
        targetRoleId: 'owner_whatsapp_agent',
        continuity: evidence(
          previousChannel: AgentOmnichannelChannel.appChat,
          currentChannel: AgentOmnichannelChannel.ownerWhatsApp,
        ),
      );

      expect(handoff.blocked, isTrue);
      expect(
        handoff.reasonCode,
        AgentUnifiedContextChannelHandoffReason.channelDomainMismatch,
      );
    });

    test('owner-to-customer domain handoff is blocked', () {
      final handoff = prepare(
        sourceChannel: AgentOmnichannelChannel.ownerWhatsApp,
        targetChannel: AgentOmnichannelChannel.appChat,
        targetRoleId: 'support_agent',
        continuity: evidence(
          previousChannel: AgentOmnichannelChannel.ownerWhatsApp,
          currentChannel: AgentOmnichannelChannel.appChat,
        ),
      );

      expect(handoff.blocked, isTrue);
      expect(
        handoff.reasonCode,
        AgentUnifiedContextChannelHandoffReason.channelDomainMismatch,
      );
    });

    test('Emergency WhatsApp cannot cross-merge with normal channels', () {
      final handoff = prepare(
        sourceChannel: AgentOmnichannelChannel.emergencyWhatsApp,
        targetChannel: AgentOmnichannelChannel.appChat,
        targetRoleId: 'support_agent',
        continuity: evidence(
          previousChannel: AgentOmnichannelChannel.emergencyWhatsApp,
          currentChannel: AgentOmnichannelChannel.appChat,
          emergencySafeTriageOnly: true,
        ),
      );

      expect(handoff.blocked, isTrue);
      expect(
        handoff.reasonCode,
        AgentUnifiedContextChannelHandoffReason.emergencyContinuityIsolated,
      );
    });

    test(
      'Emergency WhatsApp same-channel safe-triage handoff remains isolated',
      () {
        final handoff = prepare(
          purpose: AgentUnifiedContextPurpose.safetyTriage,
          sourceChannel: AgentOmnichannelChannel.emergencyWhatsApp,
          targetChannel: AgentOmnichannelChannel.emergencyWhatsApp,
          targetRoleId: 'emergency_whatsapp_agent',
          sourceProjection: projection(
            purpose: AgentUnifiedContextPurpose.safetyTriage,
          ),
          continuity: evidence(
            previousChannel: AgentOmnichannelChannel.emergencyWhatsApp,
            currentChannel: AgentOmnichannelChannel.emergencyWhatsApp,
            emergencySafeTriageOnly: true,
          ),
        );

        expect(handoff.prepared, isTrue);
      },
    );

    test('wrong target role-channel mapping blocks handoff', () {
      final handoff = prepare(
        targetChannel: AgentOmnichannelChannel.email,
        targetRoleId: 'support_agent',
        continuity: evidence(
          previousChannel: AgentOmnichannelChannel.appChat,
          currentChannel: AgentOmnichannelChannel.email,
        ),
      );

      expect(handoff.blocked, isTrue);
      expect(
        handoff.reasonCode,
        AgentUnifiedContextChannelHandoffReason.roleChannelMismatch,
      );
    });

    test('projection subject mismatch blocks handoff', () {
      final handoff = prepare(
        sourceProjection: projection(subjectRef: 'wrong_subject'),
      );

      expect(handoff.blocked, isTrue);
      expect(
        handoff.reasonCode,
        AgentUnifiedContextChannelHandoffReason.subjectMismatch,
      );
    });

    test('projection purpose mismatch blocks handoff', () {
      final handoff = prepare(
        sourceProjection: projection(
          purpose: AgentUnifiedContextPurpose.generalSupport,
        ),
      );

      expect(handoff.blocked, isTrue);
      expect(
        handoff.reasonCode,
        AgentUnifiedContextChannelHandoffReason.purposeMismatch,
      );
    });

    test('untrusted pseudonymous subject continuity blocks handoff', () {
      final handoff = prepare(continuity: evidence(sameSubject: false));

      expect(handoff.blocked, isTrue);
      expect(
        handoff.reasonCode,
        AgentUnifiedContextChannelHandoffReason.subjectContinuityUntrusted,
      );
    });

    test('untrusted identity continuity blocks handoff', () {
      final handoff = prepare(continuity: evidence(trustedIdentity: false));

      expect(handoff.blocked, isTrue);
      expect(
        handoff.reasonCode,
        AgentUnifiedContextChannelHandoffReason.identityContinuityUntrusted,
      );
    });

    test('expired cross-channel continuity window blocks handoff', () {
      final handoff = prepare(continuity: evidence(withinWindow: false));

      expect(handoff.blocked, isTrue);
      expect(
        handoff.reasonCode,
        AgentUnifiedContextChannelHandoffReason.continuityWindowExpired,
      );
    });

    test('failed replay assessment blocks handoff', () {
      final handoff = prepare(continuity: evidence(replayPassed: false));

      expect(handoff.blocked, isTrue);
      expect(
        handoff.reasonCode,
        AgentUnifiedContextChannelHandoffReason.replaySafetyFailed,
      );
    });

    test('Phase 51 metadata boundary violation blocks handoff', () {
      final carriesHistory = prepare(
        continuity: evidence(carriesHistory: true),
      );

      final carriesSharedContext = prepare(
        continuity: evidence(carriesSharedContext: true),
      );

      final notMetadataOnly = prepare(
        continuity: evidence(metadataOnly: false),
      );

      expect(carriesHistory.blocked, isTrue);
      expect(carriesSharedContext.blocked, isTrue);
      expect(notMetadataOnly.blocked, isTrue);
    });

    test('target channel OFF is isolated failure, not core failure', () {
      final handoff = prepare(controlAllowed: false);

      expect(handoff.isolatedFailure, isTrue);
      expect(handoff.failureContainedToHandoff, isTrue);
      expect(handoff.otherChannelsRemainAvailable, isTrue);
      expect(handoff.coreSwatRideRemainsAvailable, isTrue);
      expect(handoff.hasProjection, isFalse);
    });

    test('target channel unavailable is isolated failure', () {
      final handoff = prepare(targetAvailable: false);

      expect(handoff.isolatedFailure, isTrue);
      expect(
        handoff.reasonCode,
        AgentUnifiedContextChannelHandoffReason.targetChannelUnavailable,
      );
      expect(handoff.otherChannelsRemainAvailable, isTrue);
      expect(handoff.coreSwatRideRemainsAvailable, isTrue);
    });

    test('Phase 51 failure-isolation contract must remain intact', () {
      final handoff = prepare(failureIsolationIntact: false);

      expect(handoff.blocked, isTrue);
      expect(
        handoff.reasonCode,
        AgentUnifiedContextChannelHandoffReason.phase51FailureIsolationMissing,
      );
    });

    test(
      'projection omissions remain limitations, never silently disappear',
      () {
        final handoff = prepare(
          sourceProjection: projection(withOmission: true),
        );

        expect(handoff.prepared, isTrue);
        expect(
          handoff.status,
          AgentUnifiedContextChannelHandoffStatus.preparedWithLimitations,
        );
      },
    );

    test('unresolved projection remains explicit limitation', () {
      final handoff = prepare(sourceProjection: projection(unresolved: true));

      expect(handoff.prepared, isTrue);
      expect(
        handoff.status,
        AgentUnifiedContextChannelHandoffStatus.preparedWithLimitations,
      );
      expect(
        handoff.renderPreparedContextForTarget(),
        contains('UNRESOLVED_CONTEXT_KEYS'),
      );
    });

    test('handoff does not invoke target agent or provider', () {
      final handoff = prepare();

      expect(handoff.invokesProvider, isFalse);
      expect(handoff.invokesTargetAgent, isFalse);
      expect(handoff.invokesRuntimeGate, isFalse);
      expect(handoff.grantsPermission, isFalse);
      expect(handoff.consumesApproval, isFalse);
      expect(handoff.writesBusinessData, isFalse);
      expect(handoff.activatesChannel, isFalse);
      expect(handoff.changesChannelControl, isFalse);
    });

    test(
      'safe metadata omits projection values and preserves isolation flags',
      () {
        final handoff = prepare();

        final Map<String, dynamic> map = handoff.toSafeMetadataMap();

        expect(map['projectionValuesIncluded'], isFalse);
        expect(map['failureContainedToHandoff'], isTrue);
        expect(map['otherChannelsRemainAvailable'], isTrue);
        expect(map['coreSwatRideRemainsAvailable'], isTrue);
        expect(map['invokesProvider'], isFalse);
        expect(map['invokesTargetAgent'], isFalse);
        expect(map['writesBusinessData'], isFalse);
        expect(map['persistsHandoff'], isFalse);
      },
    );

    test('continuity evidence itself grants no authority', () {
      final AgentUnifiedContextContinuityEvidence continuity = evidence();

      expect(continuity.grantsAuthority, isFalse);
      expect(continuity.grantsPermission, isFalse);
      expect(continuity.consumesApproval, isFalse);
      expect(continuity.invokesProvider, isFalse);
      expect(continuity.invokesTargetAgent, isFalse);
      expect(continuity.writesBusinessData, isFalse);
      expect(continuity.persistsEvidence, isFalse);
    });

    test('service cannot bypass Phase 51 continuity/replay/control', () {
      expect(service.grantsAuthority, isFalse);
      expect(service.grantsPermission, isFalse);
      expect(service.consumesApproval, isFalse);
      expect(service.invokesProvider, isFalse);
      expect(service.invokesTargetAgent, isFalse);
      expect(service.invokesRuntimeGate, isFalse);
      expect(service.writesBusinessData, isFalse);
      expect(service.persistsContext, isFalse);
      expect(service.persistsHandoff, isFalse);
      expect(service.activatesChannel, isFalse);
      expect(service.changesPhase51ChannelControl, isFalse);
      expect(service.bypassesPhase51ContinuityPolicy, isFalse);
      expect(service.bypassesPhase51ReplayGuard, isFalse);
      expect(service.loadsFullConversationHistory, isFalse);
    });
  });
}

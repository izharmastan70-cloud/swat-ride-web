import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_omnichannel_constants.dart';
import 'package:swat_ride/ai_agent/data/initial_agent_roles_seed.dart';
import 'package:swat_ride/ai_agent/models/agent_omnichannel_channel_control.dart';
import 'package:swat_ride/ai_agent/models/agent_omnichannel_failure_isolation.dart';
import 'package:swat_ride/ai_agent/models/agent_omnichannel_readiness_report.dart';
import 'package:swat_ride/ai_agent/models/agent_role.dart';
import 'package:swat_ride/ai_agent/services/agent_omnichannel_failure_isolation_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_omnichannel_readiness_evaluator.dart';
import 'package:swat_ride/ai_agent/services/agent_omnichannel_replay_guard.dart';

void main() {
  const AgentOmnichannelReadinessEvaluator evaluator =
      AgentOmnichannelReadinessEvaluator();

  const AgentOmnichannelFailureIsolationPolicy failurePolicy =
      AgentOmnichannelFailureIsolationPolicy();

  const AgentOmnichannelReplayGuard replayGuard = AgentOmnichannelReplayGuard();

  AgentOmnichannelReadinessEvidence completeEvidence() {
    return const AgentOmnichannelReadinessEvidence(
      sevenChannelContractPresent: true,
      identityPrivacyBoundaryPresent: true,
      normalizationGatewayPresent: true,
      failClosedRoutingPresent: true,
      replayProtectionPresent: true,
      channelControlsPresent: true,
      failureIsolationPresent: true,
      privacyMinimizedAuditPresent: true,
      phase52SharedContextAbsent: true,
      providerExecutionAbsent: true,
      runtimeBusinessWriteAbsent: true,
    );
  }

  group('Phase 51 Step 1G final Omnichannel readiness closeout', () {
    test('all seven channels remain locked in the contract', () {
      expect(
        AgentOmnichannelChannel.values,
        containsAll(<String>[
          AgentOmnichannelChannel.appChat,
          AgentOmnichannelChannel.customerWhatsApp,
          AgentOmnichannelChannel.ownerWhatsApp,
          AgentOmnichannelChannel.emergencyWhatsApp,
          AgentOmnichannelChannel.email,
          AgentOmnichannelChannel.phoneCall,
          AgentOmnichannelChannel.ownerVoice,
        ]),
      );

      expect(AgentOmnichannelChannel.values.length, 7);
    });

    test(
      'complete Phase 51 evidence yields foundation-ready not production-active',
      () {
        final report = evaluator.evaluate(completeEvidence());

        expect(
          report.status,
          AgentOmnichannelReadinessStatus.foundationReadyNotProductionActive,
        );
        expect(report.phase51FoundationComplete, isTrue);
        expect(report.productionActive, isFalse);
        expect(report.productionReady, isFalse);
        expect(report.phase52Implemented, isFalse);
      },
    );

    test('missing any safety evidence blocks readiness', () {
      final report = evaluator.evaluate(
        const AgentOmnichannelReadinessEvidence(
          sevenChannelContractPresent: true,
          identityPrivacyBoundaryPresent: true,
          normalizationGatewayPresent: true,
          failClosedRoutingPresent: false,
          replayProtectionPresent: true,
          channelControlsPresent: true,
          failureIsolationPresent: true,
          privacyMinimizedAuditPresent: true,
          phase52SharedContextAbsent: true,
          providerExecutionAbsent: true,
          runtimeBusinessWriteAbsent: true,
        ),
      );

      expect(report.status, AgentOmnichannelReadinessStatus.blocked);
      expect(report.phase51FoundationComplete, isFalse);
    });

    test('final readiness report explicitly preserves production gaps', () {
      final report = evaluator.evaluate(completeEvidence());

      expect(report.productionPersistentSettingsBackendWired, isFalse);
      expect(report.adminToggleUiWired, isFalse);
      expect(report.liveProviderActivationWired, isFalse);
      expect(report.auditPersistenceBackendWired, isFalse);
    });

    test('final readiness report grants no authority or execution', () {
      final report = evaluator.evaluate(completeEvidence());

      expect(report.grantsAuthority, isFalse);
      expect(report.invokesProvider, isFalse);
      expect(report.writesBusinessData, isFalse);

      expect(evaluator.activatesProvider, isFalse);
      expect(evaluator.invokesOrchestrator, isFalse);
      expect(evaluator.invokesTargetAgent, isFalse);
      expect(evaluator.grantsPermission, isFalse);
      expect(evaluator.consumesApproval, isFalse);
      expect(evaluator.writesBusinessData, isFalse);
      expect(evaluator.persistsSettings, isFalse);
      expect(evaluator.persistsAuditEvents, isFalse);
      expect(evaluator.implementsPhase52SharedContext, isFalse);
      expect(evaluator.productionActivationAllowed, isFalse);
    });

    test('channel controls preserve independent WhatsApp safety switches', () {
      final snapshot = AgentOmnichannelChannelControlSnapshot(
        globalOmnichannelEnabled: true,
        appChatEnabled: true,
        customerWhatsAppEnabled: false,
        ownerWhatsAppEnabled: true,
        emergencyWhatsAppEnabled: true,
        emailEnabled: true,
        phoneCallEnabled: true,
        ownerVoiceEnabled: true,
        whatsAppProviderLiveEnabled: true,
        updatedByRoleId: AgentOmnichannelControlActorRole.superAdmin,
        updatedAt: DateTime.utc(2026, 8, 19, 8, 0),
      );

      expect(
        snapshot.isRouteEnabled(AgentOmnichannelChannel.customerWhatsApp),
        isFalse,
      );

      expect(
        snapshot.isRouteEnabled(AgentOmnichannelChannel.emergencyWhatsApp),
        isTrue,
      );

      expect(snapshot.coreSwatRideEnabledByThisSnapshot, isTrue);
    });

    test(
      'WhatsApp provider switch stays isolated from non-WhatsApp channels',
      () {
        final snapshot = AgentOmnichannelChannelControlSnapshot(
          globalOmnichannelEnabled: true,
          appChatEnabled: true,
          customerWhatsAppEnabled: true,
          ownerWhatsAppEnabled: true,
          emergencyWhatsAppEnabled: true,
          emailEnabled: true,
          phoneCallEnabled: true,
          ownerVoiceEnabled: true,
          whatsAppProviderLiveEnabled: false,
          updatedByRoleId: AgentOmnichannelControlActorRole.admin,
          updatedAt: DateTime.utc(2026, 8, 19, 8, 1),
        );

        expect(
          snapshot.isRouteEnabled(AgentOmnichannelChannel.customerWhatsApp),
          isFalse,
        );
        expect(
          snapshot.isRouteEnabled(AgentOmnichannelChannel.emergencyWhatsApp),
          isFalse,
        );
        expect(
          snapshot.isRouteEnabled(AgentOmnichannelChannel.appChat),
          isTrue,
        );
        expect(snapshot.isRouteEnabled(AgentOmnichannelChannel.email), isTrue);
        expect(
          snapshot.isRouteEnabled(AgentOmnichannelChannel.phoneCall),
          isTrue,
        );
        expect(
          snapshot.isRouteEnabled(AgentOmnichannelChannel.ownerVoice),
          isTrue,
        );
      },
    );

    test(
      'single-channel failure preserves other channels and core SWAT RIDE',
      () {
        final signal = AgentOmnichannelFailureSignal(
          failureId: 'phase51_step1g_failure',
          channel: AgentOmnichannelChannel.customerWhatsApp,
          failureType: AgentOmnichannelFailureType.providerUnavailable,
          detectedAt: DateTime.utc(2026, 8, 19, 8, 2),
        );

        final decision = failurePolicy.isolate(signal);

        expect(decision.failedChannelBlocked, isTrue);
        expect(decision.otherChannelsRemainAvailable, isTrue);
        expect(decision.coreSwatRideRemainsAvailable, isTrue);
        expect(decision.globalShutdownTriggered, isFalse);
      },
    );

    test('replay guard remains non-persistent and non-authoritative', () {
      expect(replayGuard.persistsReplayWindow, isFalse);
      expect(replayGuard.writesReplayState, isFalse);
      expect(replayGuard.providerExecutionAllowed, isFalse);
      expect(replayGuard.orchestratorExecutionAllowed, isFalse);
      expect(replayGuard.targetAgentExecutionAllowed, isFalse);
      expect(replayGuard.businessWriteAllowed, isFalse);
      expect(replayGuard.permissionGrantAllowed, isFalse);
      expect(replayGuard.approvalConsumptionAllowed, isFalse);
      expect(replayGuard.sharedCrossChannelContextAccessAllowed, isFalse);
    });

    test(
      'safe readiness map states foundation ready without production claim',
      () {
        final Map<String, dynamic> map = evaluator
            .evaluate(completeEvidence())
            .toSafeMap();

        expect(
          map['status'],
          AgentOmnichannelReadinessStatus.foundationReadyNotProductionActive,
        );
        expect(map['phase51FoundationComplete'], isTrue);
        expect(map['productionActive'], isFalse);
        expect(map['productionReady'], isFalse);
        expect(map['phase52Implemented'], isFalse);
        expect(map['invokesProvider'], isFalse);
        expect(map['writesBusinessData'], isFalse);
      },
    );

    test('existing seven target roles remain present', () {
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
    });

    test('call_agent remains exactly four locked actions', () {
      final List<AgentRole> roles = buildInitialAgentRoles();

      final AgentRole callRole = roles.firstWhere(
        (AgentRole role) => role.roleId == 'call_agent',
      );

      expect(callRole.allowedActions.length, 4);
    });
  });
}

import '../models/agent_omnichannel_continuity_metadata.dart';
import '../models/agent_omnichannel_replay_assessment.dart';
import '../models/agent_omnichannel_routing_handoff.dart';
import 'agent_omnichannel_continuity_policy.dart';

class AgentOmnichannelReplayGuard {
  const AgentOmnichannelReplayGuard({
    this.continuityPolicy = const AgentOmnichannelContinuityPolicy(),
  });

  final AgentOmnichannelContinuityPolicy continuityPolicy;

  AgentOmnichannelContinuityReplayAssessment assess({
    required AgentOmnichannelOrchestratorHandoff handoff,
    required AgentOmnichannelReplayWindow replayWindow,
    AgentOmnichannelContinuityMetadata? continuity,
  }) {
    handoff.validate();
    replayWindow.validate();

    final envelope = handoff.gatewayHandoff.normalizedIngress.envelope;

    if (!handoff.ready) {
      return _assessment(
        disposition: AgentOmnichannelReplayDisposition.blockedRouting,
        routeMayProceed: false,
        continuityAccepted: false,
        replayDetected: false,
        continuityRejected: continuity != null,
        reasons: <String>['routing_handoff_not_ready'],
      );
    }

    if (replayWindow.seenExternalMessageRefs.contains(
      envelope.externalMessageRef,
    )) {
      return _assessment(
        disposition:
            AgentOmnichannelReplayDisposition.blockedDuplicateExternalRef,
        routeMayProceed: false,
        continuityAccepted: false,
        replayDetected: true,
        continuityRejected: continuity != null,
        reasons: <String>['duplicate_external_message_ref'],
      );
    }

    if (replayWindow.seenEnvelopeIds.contains(envelope.envelopeId)) {
      return _assessment(
        disposition: AgentOmnichannelReplayDisposition.blockedDuplicateEnvelope,
        routeMayProceed: false,
        continuityAccepted: false,
        replayDetected: true,
        continuityRejected: continuity != null,
        reasons: <String>['duplicate_envelope_id'],
      );
    }

    if (envelope.receivedAt.toUtc().isBefore(replayWindow.notBefore.toUtc())) {
      return _assessment(
        disposition: AgentOmnichannelReplayDisposition.blockedStaleReplay,
        routeMayProceed: false,
        continuityAccepted: false,
        replayDetected: true,
        continuityRejected: continuity != null,
        reasons: <String>['stale_message_before_replay_window'],
      );
    }

    if (continuity == null) {
      return _assessment(
        disposition: AgentOmnichannelReplayDisposition.freshWithoutContinuity,
        routeMayProceed: true,
        continuityAccepted: false,
        replayDetected: false,
        continuityRejected: false,
        reasons: <String>['fresh_route_without_continuity'],
      );
    }

    try {
      continuity.validate();
    } on Object {
      return _assessment(
        disposition:
            AgentOmnichannelReplayDisposition.blockedContinuityMismatch,
        routeMayProceed: false,
        continuityAccepted: false,
        replayDetected: false,
        continuityRejected: true,
        reasons: <String>['continuity_metadata_invalid'],
      );
    }

    final bool continuityAccepted = continuityPolicy.canAttachContinuity(
      handoff: handoff,
      continuity: continuity,
    );

    if (!continuityAccepted) {
      return _assessment(
        disposition: AgentOmnichannelReplayDisposition.freshWithoutContinuity,
        routeMayProceed: true,
        continuityAccepted: false,
        replayDetected: false,
        continuityRejected: true,
        reasons: <String>[
          'continuity_not_trusted_or_not_matching',
          'fresh_route_preserved_without_cross_channel_merge',
        ],
      );
    }

    return _assessment(
      disposition: AgentOmnichannelReplayDisposition.freshWithContinuity,
      routeMayProceed: true,
      continuityAccepted: true,
      replayDetected: false,
      continuityRejected: false,
      reasons: <String>['fresh_route_with_trusted_metadata_continuity'],
    );
  }

  AgentOmnichannelContinuityReplayAssessment _assessment({
    required String disposition,
    required bool routeMayProceed,
    required bool continuityAccepted,
    required bool replayDetected,
    required bool continuityRejected,
    required List<String> reasons,
  }) {
    final AgentOmnichannelContinuityReplayAssessment assessment =
        AgentOmnichannelContinuityReplayAssessment(
          disposition: disposition,
          routeMayProceed: routeMayProceed,
          continuityAccepted: continuityAccepted,
          replayDetected: replayDetected,
          continuityRejected: continuityRejected,
          reasonCodes: reasons,
        );

    assessment.validate();
    return assessment;
  }

  bool get persistsReplayWindow => false;
  bool get writesReplayState => false;
  bool get providerExecutionAllowed => false;
  bool get orchestratorExecutionAllowed => false;
  bool get targetAgentExecutionAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get productionDataAccessAllowed => false;
  bool get businessWriteAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get sharedCrossChannelContextAccessAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;
}

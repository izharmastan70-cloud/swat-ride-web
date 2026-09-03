import '../models/agent_omnichannel_failure_isolation.dart';

class AgentOmnichannelFailureIsolationPolicy {
  const AgentOmnichannelFailureIsolationPolicy();

  AgentOmnichannelFailureIsolationDecision isolate(
    AgentOmnichannelFailureSignal signal,
  ) {
    signal.validate();

    final AgentOmnichannelFailureIsolationDecision decision =
        AgentOmnichannelFailureIsolationDecision(
          failedChannel: signal.channel,
          failedChannelBlocked: true,
          otherChannelsRemainAvailable: true,
          coreSwatRideRemainsAvailable: true,
          reasonCodes: <String>[
            'affected_channel_failed_closed',
            'other_channels_isolated_from_failure',
            'core_swat_ride_not_coupled_to_omnichannel_failure',
            'failure_type:${signal.failureType}',
          ],
        );

    decision.validate();
    return decision;
  }

  bool get disablesAllChannels => false;
  bool get disablesCoreSwatRide => false;
  bool get restartsProvider => false;
  bool get invokesOrchestrator => false;
  bool get businessWriteAllowed => false;
}

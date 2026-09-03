import '../models/agent_omnichannel_channel_control.dart';
import '../models/agent_omnichannel_routing_handoff.dart';

class AgentOmnichannelChannelControlDecision {
  AgentOmnichannelChannelControlDecision({
    required this.routeAllowed,
    required this.globalEnabled,
    required this.channelEnabled,
    required this.transportEnabled,
    required this.channel,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final bool routeAllowed;
  final bool globalEnabled;
  final bool channelEnabled;
  final bool transportEnabled;
  final String channel;
  final List<String> reasonCodes;

  bool get grantsAuthority => false;
  bool get invokesOrchestrator => false;
  bool get invokesProvider => false;
  bool get writesBusinessData => false;
}

class AgentOmnichannelChannelControlPolicy {
  const AgentOmnichannelChannelControlPolicy();

  AgentOmnichannelChannelControlDecision evaluate({
    required AgentOmnichannelOrchestratorHandoff handoff,
    required AgentOmnichannelChannelControlSnapshot controls,
  }) {
    handoff.validate();
    controls.validate();

    final String channel = handoff.routingDecision.channel;

    final bool globalEnabled = controls.globalOmnichannelEnabled;

    final bool channelEnabled = controls.isChannelEnabled(channel);

    final bool transportEnabled = controls.isTransportEnabled(channel);

    final bool routeAllowed =
        handoff.ready && globalEnabled && channelEnabled && transportEnabled;

    final List<String> reasons = <String>[];

    if (!handoff.ready) {
      reasons.add('routing_handoff_not_ready');
    }

    if (!globalEnabled) {
      reasons.add('global_omnichannel_disabled');
    }

    if (!channelEnabled) {
      reasons.add('channel_disabled');
    }

    if (!transportEnabled) {
      reasons.add('channel_transport_disabled');
    }

    if (routeAllowed) {
      reasons.add('channel_control_allows_route');
    }

    return AgentOmnichannelChannelControlDecision(
      routeAllowed: routeAllowed,
      globalEnabled: globalEnabled,
      channelEnabled: channelEnabled,
      transportEnabled: transportEnabled,
      channel: channel,
      reasonCodes: reasons,
    );
  }

  bool get coreSwatRideControlAllowed => false;
  bool get providerActivationAllowed => false;
  bool get businessWriteAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get approvalConsumptionAllowed => false;
}

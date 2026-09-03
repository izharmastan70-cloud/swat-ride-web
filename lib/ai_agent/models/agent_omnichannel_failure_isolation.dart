class AgentOmnichannelFailureType {
  AgentOmnichannelFailureType._();

  static const String adapterFailure = 'ADAPTER_FAILURE';
  static const String providerUnavailable = 'PROVIDER_UNAVAILABLE';
  static const String privacyFailure = 'PRIVACY_FAILURE';
  static const String identityFailure = 'IDENTITY_FAILURE';
  static const String routingFailure = 'ROUTING_FAILURE';

  static const Set<String> values = <String>{
    adapterFailure,
    providerUnavailable,
    privacyFailure,
    identityFailure,
    routingFailure,
  };
}

class AgentOmnichannelFailureSignal {
  const AgentOmnichannelFailureSignal({
    required this.failureId,
    required this.channel,
    required this.failureType,
    required this.detectedAt,
  });

  final String failureId;
  final String channel;
  final String failureType;
  final DateTime detectedAt;

  void validate() {
    if (failureId.trim().isEmpty ||
        channel.trim().isEmpty ||
        !AgentOmnichannelFailureType.values.contains(failureType)) {
      throw const AgentOmnichannelFailureIsolationException(
        'Invalid omnichannel channel failure signal.',
      );
    }
  }
}

class AgentOmnichannelFailureIsolationDecision {
  AgentOmnichannelFailureIsolationDecision({
    required this.failedChannel,
    required this.failedChannelBlocked,
    required this.otherChannelsRemainAvailable,
    required this.coreSwatRideRemainsAvailable,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String failedChannel;
  final bool failedChannelBlocked;
  final bool otherChannelsRemainAvailable;
  final bool coreSwatRideRemainsAvailable;
  final List<String> reasonCodes;

  bool get providerRestartedByThisDecision => false;
  bool get orchestratorInvoked => false;
  bool get businessDataWritten => false;
  bool get globalShutdownTriggered => false;

  void validate() {
    if (failedChannel.trim().isEmpty ||
        reasonCodes.isEmpty ||
        !failedChannelBlocked ||
        !otherChannelsRemainAvailable ||
        !coreSwatRideRemainsAvailable) {
      throw const AgentOmnichannelFailureIsolationException(
        'Channel failure isolation must fail only the affected channel.',
      );
    }
  }
}

class AgentOmnichannelFailureIsolationException implements Exception {
  const AgentOmnichannelFailureIsolationException(this.message);

  final String message;

  @override
  String toString() => 'AgentOmnichannelFailureIsolationException: $message';
}

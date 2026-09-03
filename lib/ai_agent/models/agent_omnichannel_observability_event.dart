class AgentOmnichannelAuditEventType {
  AgentOmnichannelAuditEventType._();

  static const String routeAllowed = 'ROUTE_ALLOWED';
  static const String routeBlocked = 'ROUTE_BLOCKED';
  static const String channelDisabled = 'CHANNEL_DISABLED';
  static const String globalDisabled = 'GLOBAL_DISABLED';
  static const String providerDisabled = 'PROVIDER_DISABLED';
  static const String channelFailureIsolated = 'CHANNEL_FAILURE_ISOLATED';
  static const String replayBlocked = 'REPLAY_BLOCKED';

  static const Set<String> values = <String>{
    routeAllowed,
    routeBlocked,
    channelDisabled,
    globalDisabled,
    providerDisabled,
    channelFailureIsolated,
    replayBlocked,
  };
}

class AgentOmnichannelAuditEvent {
  AgentOmnichannelAuditEvent({
    required this.eventId,
    required this.eventType,
    required this.channel,
    required this.targetAgentRoleId,
    required this.occurredAt,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String eventId;
  final String eventType;
  final String channel;
  final String targetAgentRoleId;
  final DateTime occurredAt;
  final List<String> reasonCodes;

  bool get containsRawMessageContent => false;
  bool get containsRawIdentity => false;
  bool get containsPaymentCredentials => false;
  bool get containsAuthToken => false;
  bool get grantsAuthority => false;
  bool get invokesProvider => false;
  bool get writesBusinessData => false;

  void validate() {
    if (eventId.trim().isEmpty ||
        channel.trim().isEmpty ||
        targetAgentRoleId.trim().isEmpty ||
        reasonCodes.isEmpty ||
        !AgentOmnichannelAuditEventType.values.contains(eventType)) {
      throw const AgentOmnichannelAuditEventException(
        'Invalid omnichannel audit event.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'eventId': eventId.trim(),
      'eventType': eventType,
      'channel': channel,
      'targetAgentRoleId': targetAgentRoleId.trim(),
      'occurredAt': occurredAt.toUtc().toIso8601String(),
      'reasonCodes': List<String>.unmodifiable(reasonCodes),
      'containsRawMessageContent': false,
      'containsRawIdentity': false,
      'containsPaymentCredentials': false,
      'containsAuthToken': false,
      'grantsAuthority': false,
      'invokesProvider': false,
      'writesBusinessData': false,
    });
  }
}

class AgentOmnichannelAuditEventException implements Exception {
  const AgentOmnichannelAuditEventException(this.message);

  final String message;

  @override
  String toString() => 'AgentOmnichannelAuditEventException: $message';
}

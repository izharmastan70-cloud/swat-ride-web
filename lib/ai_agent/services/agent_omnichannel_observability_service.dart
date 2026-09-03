import '../models/agent_omnichannel_observability_event.dart';
import 'agent_omnichannel_channel_control_policy.dart';

class AgentOmnichannelObservabilityService {
  const AgentOmnichannelObservabilityService();

  AgentOmnichannelAuditEvent buildControlEvent({
    required String eventId,
    required String targetAgentRoleId,
    required DateTime occurredAt,
    required AgentOmnichannelChannelControlDecision decision,
  }) {
    final String eventType;

    if (decision.routeAllowed) {
      eventType = AgentOmnichannelAuditEventType.routeAllowed;
    } else if (!decision.globalEnabled) {
      eventType = AgentOmnichannelAuditEventType.globalDisabled;
    } else if (!decision.channelEnabled) {
      eventType = AgentOmnichannelAuditEventType.channelDisabled;
    } else if (!decision.transportEnabled) {
      eventType = AgentOmnichannelAuditEventType.providerDisabled;
    } else {
      eventType = AgentOmnichannelAuditEventType.routeBlocked;
    }

    final AgentOmnichannelAuditEvent event = AgentOmnichannelAuditEvent(
      eventId: eventId,
      eventType: eventType,
      channel: decision.channel,
      targetAgentRoleId: targetAgentRoleId,
      occurredAt: occurredAt,
      reasonCodes: decision.reasonCodes,
    );

    event.validate();
    return event;
  }

  bool get persistsEventByItself => false;
  bool get containsRawMessageContent => false;
  bool get containsRawIdentity => false;
  bool get providerExecutionAllowed => false;
  bool get businessWriteAllowed => false;
}

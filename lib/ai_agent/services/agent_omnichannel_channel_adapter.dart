import '../constants/agent_omnichannel_constants.dart';
import '../models/agent_omnichannel_envelope.dart';
import '../models/agent_omnichannel_identity_privacy.dart';
import '../models/agent_omnichannel_normalized_ingress.dart';
import '../models/agent_omnichannel_raw_ingress.dart';

abstract class AgentOmnichannelChannelAdapter {
  const AgentOmnichannelChannelAdapter();

  String get adapterId;
  String get supportedChannel;

  AgentOmnichannelNormalizedIngress normalize(AgentOmnichannelRawIngress raw);

  bool get providerExecutionAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get businessWriteAllowed => false;
}

class AgentOmnichannelDeterministicChannelAdapter
    extends AgentOmnichannelChannelAdapter {
  const AgentOmnichannelDeterministicChannelAdapter({
    required this.adapterId,
    required this.supportedChannel,
  });

  @override
  final String adapterId;

  @override
  final String supportedChannel;

  @override
  AgentOmnichannelNormalizedIngress normalize(AgentOmnichannelRawIngress raw) {
    raw.validate();

    if (raw.channel != supportedChannel) {
      throw AgentOmnichannelAdapterException(
        'Adapter $adapterId does not support channel ${raw.channel}.',
      );
    }

    final AgentOmnichannelIdentityContext identity =
        AgentOmnichannelIdentityContext(
          subjectRef: raw.subjectRef,
          assurance: raw.identityAssurance,
          verifiedByTrustedBoundary: raw.verifiedByTrustedBoundary,
          strongReauthSatisfied: raw.strongReauthSatisfied,
          fromChannelClaimOnly: raw.fromChannelClaimOnly,
        );

    final AgentOmnichannelPrivacyContext privacy =
        AgentOmnichannelPrivacyContext(
          sanitizedText: raw.sanitizedText,
          containsRawSecrets: raw.containsRawSecrets,
          containsPaymentCredentials: raw.containsPaymentCredentials,
          containsAuthToken: raw.containsAuthToken,
          containsGovernmentId: raw.containsGovernmentId,
          containsUnredactedContactDetails:
              raw.containsUnredactedContactDetails,
          redactionApplied: raw.redactionApplied,
        );

    final AgentOmnichannelEnvelope envelope = AgentOmnichannelEnvelope(
      envelopeId: 'omni_${raw.rawIngressId.trim()}',
      externalMessageRef: raw.externalMessageRef,
      channel: raw.channel,
      intendedAgentRoleId: raw.intendedAgentRoleId,
      receivedAt: raw.receivedAt.toUtc(),
      identity: identity,
      privacy: privacy,
    );

    final AgentOmnichannelNormalizedIngress normalized =
        AgentOmnichannelNormalizedIngress(
          adapterId: adapterId,
          envelope: envelope,
        );

    normalized.validate();
    return normalized;
  }
}

class AgentOmnichannelChannelAdapterRegistry {
  const AgentOmnichannelChannelAdapterRegistry();

  static const Map<String, AgentOmnichannelChannelAdapter> adaptersByChannel =
      <String, AgentOmnichannelChannelAdapter>{
        AgentOmnichannelChannel.appChat:
            AgentOmnichannelDeterministicChannelAdapter(
              adapterId: 'app_chat_adapter_v1',
              supportedChannel: AgentOmnichannelChannel.appChat,
            ),
        AgentOmnichannelChannel.customerWhatsApp:
            AgentOmnichannelDeterministicChannelAdapter(
              adapterId: 'customer_whatsapp_adapter_v1',
              supportedChannel: AgentOmnichannelChannel.customerWhatsApp,
            ),
        AgentOmnichannelChannel.ownerWhatsApp:
            AgentOmnichannelDeterministicChannelAdapter(
              adapterId: 'owner_whatsapp_adapter_v1',
              supportedChannel: AgentOmnichannelChannel.ownerWhatsApp,
            ),
        AgentOmnichannelChannel.emergencyWhatsApp:
            AgentOmnichannelDeterministicChannelAdapter(
              adapterId: 'emergency_whatsapp_adapter_v1',
              supportedChannel: AgentOmnichannelChannel.emergencyWhatsApp,
            ),
        AgentOmnichannelChannel.email:
            AgentOmnichannelDeterministicChannelAdapter(
              adapterId: 'email_adapter_v1',
              supportedChannel: AgentOmnichannelChannel.email,
            ),
        AgentOmnichannelChannel.phoneCall:
            AgentOmnichannelDeterministicChannelAdapter(
              adapterId: 'phone_call_adapter_v1',
              supportedChannel: AgentOmnichannelChannel.phoneCall,
            ),
        AgentOmnichannelChannel.ownerVoice:
            AgentOmnichannelDeterministicChannelAdapter(
              adapterId: 'owner_voice_adapter_v1',
              supportedChannel: AgentOmnichannelChannel.ownerVoice,
            ),
      };

  AgentOmnichannelChannelAdapter adapterFor(String channel) {
    final AgentOmnichannelChannelAdapter? adapter = adaptersByChannel[channel];

    if (adapter == null) {
      throw AgentOmnichannelAdapterException(
        'No omnichannel adapter registered for channel: $channel',
      );
    }

    return adapter;
  }

  bool get providerExecutionAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get businessWriteAllowed => false;
}

class AgentOmnichannelAdapterException implements Exception {
  const AgentOmnichannelAdapterException(this.message);

  final String message;

  @override
  String toString() => 'AgentOmnichannelAdapterException: $message';
}

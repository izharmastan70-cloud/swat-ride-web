import '../models/agent_omnichannel_continuity_metadata.dart';
import '../models/agent_omnichannel_routing_handoff.dart';

class AgentOmnichannelContinuityPolicy {
  const AgentOmnichannelContinuityPolicy();

  static const Duration maxAcceptedContinuityAge = Duration(hours: 24);

  bool canAttachContinuity({
    required AgentOmnichannelOrchestratorHandoff handoff,
    required AgentOmnichannelContinuityMetadata continuity,
  }) {
    handoff.validate();
    continuity.validate();

    final envelope = handoff.gatewayHandoff.normalizedIngress.envelope;

    if (!handoff.ready ||
        !continuity.generatedByTrustedBoundary ||
        !envelope.identity.isTrustedIdentity ||
        continuity.currentEnvelopeId != envelope.envelopeId ||
        continuity.currentExternalMessageRef != envelope.externalMessageRef ||
        continuity.currentChannel != envelope.channel ||
        continuity.continuitySubjectRef != envelope.identity.subjectRef ||
        continuity.continuityAge > maxAcceptedContinuityAge) {
      return false;
    }

    return true;
  }

  bool get readsPriorMessageContent => false;
  bool get readsConversationHistory => false;
  bool get readsSharedCustomerProfile => false;
  bool get providerExecutionAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get businessWriteAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get sharedCrossChannelContextAccessAllowed => false;
}

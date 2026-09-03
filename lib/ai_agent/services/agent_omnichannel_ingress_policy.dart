import '../constants/agent_omnichannel_constants.dart';
import '../models/agent_omnichannel_envelope.dart';

class AgentOmnichannelIngressPolicy {
  const AgentOmnichannelIngressPolicy();

  static const Map<String, Set<String>> allowedRolesByChannel =
      <String, Set<String>>{
        AgentOmnichannelChannel.appChat: <String>{'support_agent'},
        AgentOmnichannelChannel.customerWhatsApp: <String>{
          'customer_whatsapp_agent',
        },
        AgentOmnichannelChannel.ownerWhatsApp: <String>{'owner_whatsapp_agent'},
        AgentOmnichannelChannel.emergencyWhatsApp: <String>{
          'emergency_whatsapp_agent',
        },
        AgentOmnichannelChannel.email: <String>{'email_agent'},
        AgentOmnichannelChannel.phoneCall: <String>{'call_agent'},
        AgentOmnichannelChannel.ownerVoice: <String>{'voice_super_admin_agent'},
      };

  AgentOmnichannelIngressDecision evaluate(AgentOmnichannelEnvelope envelope) {
    envelope.validate();

    final Set<String> allowedRoles =
        allowedRolesByChannel[envelope.channel] ?? const <String>{};

    final bool channelRoleAllowed = allowedRoles.contains(
      envelope.intendedAgentRoleId,
    );

    final bool privacySafe = envelope.privacy.safeForRouting;

    final bool requiresIdentityVerification =
        !envelope.identity.isTrustedIdentity;

    final bool ownerPrivilegedChannel =
        envelope.channel == AgentOmnichannelChannel.ownerWhatsApp ||
        envelope.channel == AgentOmnichannelChannel.ownerVoice;

    final bool requiresStrongReauth =
        ownerPrivilegedChannel && !envelope.identity.hasStrongReauth;

    final bool emergencySafeTriageOnly =
        envelope.channel == AgentOmnichannelChannel.emergencyWhatsApp &&
        !envelope.identity.isTrustedIdentity;

    final List<String> reasons = <String>[];

    if (!channelRoleAllowed) {
      reasons.add(AgentOmnichannelIngressReason.channelRoleMismatch);
    }

    if (!privacySafe) {
      reasons.add(AgentOmnichannelIngressReason.privacyFilterRequired);
    }

    if (requiresIdentityVerification) {
      reasons.add(AgentOmnichannelIngressReason.identityVerificationRequired);
    }

    if (requiresStrongReauth) {
      reasons.add(AgentOmnichannelIngressReason.strongReauthRequired);
    }

    if (emergencySafeTriageOnly) {
      reasons.add(AgentOmnichannelIngressReason.emergencyUnverifiedSafeTriage);
    }

    final bool acceptedForRouting = channelRoleAllowed && privacySafe;

    if (acceptedForRouting && reasons.isEmpty) {
      reasons.add(AgentOmnichannelIngressReason.accepted);
    }

    final AgentOmnichannelIngressDecision decision =
        AgentOmnichannelIngressDecision(
          acceptedForRouting: acceptedForRouting,
          requiresIdentityVerification: requiresIdentityVerification,
          requiresStrongReauthBeforeConsequentialAction: requiresStrongReauth,
          emergencySafeTriageOnly: emergencySafeTriageOnly,
          reasonCodes: reasons,
        );

    decision.validate();
    return decision;
  }

  bool get providerExecutionAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get productionDataAccessAllowed => false;
  bool get businessWriteAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get channelContentAuthorityAllowed => false;
  bool get identityAuthorityAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;
}

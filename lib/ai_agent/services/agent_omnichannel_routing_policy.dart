import '../constants/agent_omnichannel_constants.dart';
import '../models/agent_omnichannel_normalized_ingress.dart';
import '../models/agent_omnichannel_routing_handoff.dart';

class AgentOmnichannelRoutingPolicy {
  const AgentOmnichannelRoutingPolicy();

  AgentOmnichannelRoutingDecision evaluate(
    AgentOmnichannelGatewayHandoff gatewayHandoff,
  ) {
    gatewayHandoff.validate();

    final envelope = gatewayHandoff.normalizedIngress.envelope;

    final ingressDecision = gatewayHandoff.ingressDecision;

    if (!gatewayHandoff.preparedForRouting) {
      return _decision(
        gatewayHandoff: gatewayHandoff,
        mode: AgentOmnichannelRoutingMode.blocked,
        ready: false,
        identityVerificationRequired:
            ingressDecision.requiresIdentityVerification,
        strongReauthRequired:
            ingressDecision.requiresStrongReauthBeforeConsequentialAction,
        safeTriageOnly: false,
        reasons: <String>[
          'gateway_not_prepared_for_routing',
          ...gatewayHandoff.gatewayReasonCodes,
        ],
      );
    }

    if (ingressDecision.emergencySafeTriageOnly) {
      return _decision(
        gatewayHandoff: gatewayHandoff,
        mode: AgentOmnichannelRoutingMode.emergencySafeTriage,
        ready: true,
        identityVerificationRequired: true,
        strongReauthRequired: false,
        safeTriageOnly: true,
        reasons: <String>[
          'emergency_safe_triage_only',
          ...gatewayHandoff.gatewayReasonCodes,
        ],
      );
    }

    if (ingressDecision.requiresStrongReauthBeforeConsequentialAction) {
      return _decision(
        gatewayHandoff: gatewayHandoff,
        mode: AgentOmnichannelRoutingMode.ownerReauthRestricted,
        ready: true,
        identityVerificationRequired:
            ingressDecision.requiresIdentityVerification,
        strongReauthRequired: true,
        safeTriageOnly: false,
        reasons: <String>[
          'owner_consequential_action_requires_strong_reauth',
          ...gatewayHandoff.gatewayReasonCodes,
        ],
      );
    }

    if (ingressDecision.requiresIdentityVerification) {
      return _decision(
        gatewayHandoff: gatewayHandoff,
        mode: AgentOmnichannelRoutingMode.identityRestricted,
        ready: true,
        identityVerificationRequired: true,
        strongReauthRequired: false,
        safeTriageOnly: false,
        reasons: <String>[
          'identity_restricted_route',
          ...gatewayHandoff.gatewayReasonCodes,
        ],
      );
    }

    if (!_channelRolePairStillAllowed(
      envelope.channel,
      envelope.intendedAgentRoleId,
    )) {
      return _decision(
        gatewayHandoff: gatewayHandoff,
        mode: AgentOmnichannelRoutingMode.blocked,
        ready: false,
        identityVerificationRequired: false,
        strongReauthRequired: false,
        safeTriageOnly: false,
        reasons: <String>['channel_role_pair_failed_closed_recheck'],
      );
    }

    return _decision(
      gatewayHandoff: gatewayHandoff,
      mode: AgentOmnichannelRoutingMode.standard,
      ready: true,
      identityVerificationRequired: false,
      strongReauthRequired: false,
      safeTriageOnly: false,
      reasons: <String>[
        'standard_safe_route',
        ...gatewayHandoff.gatewayReasonCodes,
      ],
    );
  }

  bool _channelRolePairStillAllowed(String channel, String roleId) {
    const Map<String, String> exactRoleByChannel = <String, String>{
      AgentOmnichannelChannel.appChat: 'support_agent',
      AgentOmnichannelChannel.customerWhatsApp: 'customer_whatsapp_agent',
      AgentOmnichannelChannel.ownerWhatsApp: 'owner_whatsapp_agent',
      AgentOmnichannelChannel.emergencyWhatsApp: 'emergency_whatsapp_agent',
      AgentOmnichannelChannel.email: 'email_agent',
      AgentOmnichannelChannel.phoneCall: 'call_agent',
      AgentOmnichannelChannel.ownerVoice: 'voice_super_admin_agent',
    };

    return exactRoleByChannel[channel] == roleId;
  }

  AgentOmnichannelRoutingDecision _decision({
    required AgentOmnichannelGatewayHandoff gatewayHandoff,
    required String mode,
    required bool ready,
    required bool identityVerificationRequired,
    required bool strongReauthRequired,
    required bool safeTriageOnly,
    required List<String> reasons,
  }) {
    final envelope = gatewayHandoff.normalizedIngress.envelope;

    final AgentOmnichannelRoutingDecision decision =
        AgentOmnichannelRoutingDecision(
          routingDecisionId: 'route_${gatewayHandoff.gatewayDecisionId}',
          mode: mode,
          targetAgentRoleId: gatewayHandoff.preparedTargetAgentRoleId,
          channel: envelope.channel,
          readyForOrchestratorHandoff: ready,
          identityVerificationRequired: identityVerificationRequired,
          strongReauthRequiredBeforeConsequentialAction: strongReauthRequired,
          safeTriageOnly: safeTriageOnly,
          reasonCodes: reasons,
        );

    decision.validate();
    return decision;
  }

  bool get orchestratorExecutionAllowed => false;
  bool get targetAgentExecutionAllowed => false;
  bool get providerExecutionAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get businessWriteAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get sharedCrossChannelContextAccessAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;
}

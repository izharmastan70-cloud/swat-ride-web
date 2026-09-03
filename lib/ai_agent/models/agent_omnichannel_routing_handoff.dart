import 'agent_omnichannel_identity_privacy.dart';
import 'agent_omnichannel_normalized_ingress.dart';

class AgentOmnichannelRoutingMode {
  AgentOmnichannelRoutingMode._();

  static const String standard = 'STANDARD';
  static const String identityRestricted = 'IDENTITY_RESTRICTED';
  static const String emergencySafeTriage = 'EMERGENCY_SAFE_TRIAGE';
  static const String ownerReauthRestricted = 'OWNER_REAUTH_RESTRICTED';
  static const String blocked = 'BLOCKED';

  static const Set<String> values = <String>{
    standard,
    identityRestricted,
    emergencySafeTriage,
    ownerReauthRestricted,
    blocked,
  };
}

class AgentOmnichannelRoutingDecision {
  AgentOmnichannelRoutingDecision({
    required this.routingDecisionId,
    required this.mode,
    required this.targetAgentRoleId,
    required this.channel,
    required this.readyForOrchestratorHandoff,
    required this.identityVerificationRequired,
    required this.strongReauthRequiredBeforeConsequentialAction,
    required this.safeTriageOnly,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String routingDecisionId;
  final String mode;
  final String targetAgentRoleId;
  final String channel;
  final bool readyForOrchestratorHandoff;
  final bool identityVerificationRequired;
  final bool strongReauthRequiredBeforeConsequentialAction;
  final bool safeTriageOnly;
  final List<String> reasonCodes;

  bool get orchestratorInvoked => false;
  bool get targetAgentInvoked => false;
  bool get providerInvoked => false;
  bool get runtimeActionExecuted => false;
  bool get permissionGranted => false;
  bool get approvalConsumed => false;
  bool get businessDataWritten => false;
  bool get sharedCrossChannelContextLoaded => false;

  void validate() {
    if (routingDecisionId.trim().isEmpty ||
        targetAgentRoleId.trim().isEmpty ||
        channel.trim().isEmpty ||
        reasonCodes.isEmpty ||
        !AgentOmnichannelRoutingMode.values.contains(mode)) {
      throw const AgentOmnichannelContractException(
        'Omnichannel routing decision is structurally invalid.',
      );
    }

    if (mode == AgentOmnichannelRoutingMode.blocked &&
        readyForOrchestratorHandoff) {
      throw const AgentOmnichannelContractException(
        'Blocked omnichannel route cannot be ready for orchestrator handoff.',
      );
    }

    if (mode == AgentOmnichannelRoutingMode.emergencySafeTriage &&
        !safeTriageOnly) {
      throw const AgentOmnichannelContractException(
        'Emergency safe-triage mode must remain safe-triage-only.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'routingDecisionId': routingDecisionId.trim(),
      'mode': mode,
      'targetAgentRoleId': targetAgentRoleId.trim(),
      'channel': channel,
      'readyForOrchestratorHandoff': readyForOrchestratorHandoff,
      'identityVerificationRequired': identityVerificationRequired,
      'strongReauthRequiredBeforeConsequentialAction':
          strongReauthRequiredBeforeConsequentialAction,
      'safeTriageOnly': safeTriageOnly,
      'reasonCodes': List<String>.unmodifiable(reasonCodes),
      'orchestratorInvoked': false,
      'targetAgentInvoked': false,
      'providerInvoked': false,
      'runtimeActionExecuted': false,
      'permissionGranted': false,
      'approvalConsumed': false,
      'businessDataWritten': false,
      'sharedCrossChannelContextLoaded': false,
    });
  }
}

class AgentOmnichannelOrchestratorHandoff {
  const AgentOmnichannelOrchestratorHandoff({
    required this.gatewayHandoff,
    required this.routingDecision,
  });

  final AgentOmnichannelGatewayHandoff gatewayHandoff;
  final AgentOmnichannelRoutingDecision routingDecision;

  bool get ready =>
      gatewayHandoff.preparedForRouting &&
      routingDecision.readyForOrchestratorHandoff;

  bool get orchestratorInvoked => false;
  bool get targetAgentInvoked => false;
  bool get providerInvoked => false;
  bool get runtimeActionExecuted => false;
  bool get permissionGranted => false;
  bool get approvalConsumed => false;
  bool get businessDataWritten => false;
  bool get sharedCrossChannelContextLoaded => false;

  void validate() {
    gatewayHandoff.validate();
    routingDecision.validate();

    if (routingDecision.targetAgentRoleId !=
            gatewayHandoff.preparedTargetAgentRoleId ||
        routingDecision.channel !=
            gatewayHandoff.normalizedIngress.envelope.channel) {
      throw const AgentOmnichannelContractException(
        'Routing handoff target/channel must match the gateway handoff.',
      );
    }
  }
}

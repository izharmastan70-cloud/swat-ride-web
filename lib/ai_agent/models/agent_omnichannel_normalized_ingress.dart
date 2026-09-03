import 'agent_omnichannel_envelope.dart';
import 'agent_omnichannel_identity_privacy.dart';

class AgentOmnichannelNormalizedIngress {
  const AgentOmnichannelNormalizedIngress({
    required this.adapterId,
    required this.envelope,
  });

  final String adapterId;
  final AgentOmnichannelEnvelope envelope;

  bool get providerNeutral => true;
  bool get isRuntimeExecutable => false;
  bool get grantsAuthority => false;
  bool get consumesApproval => false;
  bool get writesBusinessData => false;

  void validate() {
    if (adapterId.trim().isEmpty) {
      throw const AgentOmnichannelContractException(
        'Normalized omnichannel ingress requires an adapter ID.',
      );
    }

    envelope.validate();
  }
}

class AgentOmnichannelGatewayHandoff {
  AgentOmnichannelGatewayHandoff({
    required this.gatewayDecisionId,
    required this.normalizedIngress,
    required this.ingressDecision,
    required this.preparedTargetAgentRoleId,
    required List<String> gatewayReasonCodes,
  }) : gatewayReasonCodes = List<String>.unmodifiable(gatewayReasonCodes);

  final String gatewayDecisionId;
  final AgentOmnichannelNormalizedIngress normalizedIngress;
  final AgentOmnichannelIngressDecision ingressDecision;

  /// This is a prepared routing target only. No agent/orchestrator is invoked
  /// by this contract.
  final String preparedTargetAgentRoleId;

  final List<String> gatewayReasonCodes;

  bool get preparedForRouting => ingressDecision.acceptedForRouting;

  bool get orchestratorInvoked => false;
  bool get agentInvoked => false;
  bool get providerInvoked => false;
  bool get runtimeActionExecuted => false;
  bool get permissionGranted => false;
  bool get approvalConsumed => false;
  bool get businessDataWritten => false;
  bool get sharedCrossChannelContextLoaded => false;

  void validate() {
    normalizedIngress.validate();
    ingressDecision.validate();

    if (gatewayDecisionId.trim().isEmpty ||
        preparedTargetAgentRoleId.trim().isEmpty ||
        gatewayReasonCodes.isEmpty) {
      throw const AgentOmnichannelContractException(
        'Omnichannel gateway handoff is structurally invalid.',
      );
    }

    if (preparedTargetAgentRoleId !=
        normalizedIngress.envelope.intendedAgentRoleId) {
      throw const AgentOmnichannelContractException(
        'Gateway handoff cannot silently change target agent role.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'gatewayDecisionId': gatewayDecisionId.trim(),
      'channel': normalizedIngress.envelope.channel,
      'preparedTargetAgentRoleId': preparedTargetAgentRoleId.trim(),
      'preparedForRouting': preparedForRouting,
      'gatewayReasonCodes': List<String>.unmodifiable(gatewayReasonCodes),
      'orchestratorInvoked': false,
      'agentInvoked': false,
      'providerInvoked': false,
      'runtimeActionExecuted': false,
      'permissionGranted': false,
      'approvalConsumed': false,
      'businessDataWritten': false,
      'sharedCrossChannelContextLoaded': false,
    });
  }
}

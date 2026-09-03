import '../models/agent_omnichannel_normalized_ingress.dart';
import '../models/agent_omnichannel_raw_ingress.dart';
import 'agent_omnichannel_channel_adapter.dart';
import 'agent_omnichannel_ingress_policy.dart';

class AgentOmnichannelGateway {
  const AgentOmnichannelGateway({
    this.registry = const AgentOmnichannelChannelAdapterRegistry(),
    this.ingressPolicy = const AgentOmnichannelIngressPolicy(),
  });

  final AgentOmnichannelChannelAdapterRegistry registry;
  final AgentOmnichannelIngressPolicy ingressPolicy;

  AgentOmnichannelGatewayHandoff prepare(AgentOmnichannelRawIngress raw) {
    raw.validate();

    final AgentOmnichannelChannelAdapter adapter = registry.adapterFor(
      raw.channel,
    );

    final AgentOmnichannelNormalizedIngress normalized = adapter.normalize(raw);

    final ingressDecision = ingressPolicy.evaluate(normalized.envelope);

    final List<String> reasons = <String>[
      'adapter:${adapter.adapterId}',
      ...ingressDecision.reasonCodes,
    ];

    final AgentOmnichannelGatewayHandoff handoff =
        AgentOmnichannelGatewayHandoff(
          gatewayDecisionId: 'gateway_${raw.rawIngressId.trim()}',
          normalizedIngress: normalized,
          ingressDecision: ingressDecision,
          preparedTargetAgentRoleId: normalized.envelope.intendedAgentRoleId,
          gatewayReasonCodes: reasons,
        );

    handoff.validate();
    return handoff;
  }

  bool get orchestratorExecutionAllowed => false;
  bool get agentExecutionAllowed => false;
  bool get providerExecutionAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get productionDataAccessAllowed => false;
  bool get businessWriteAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get sharedCrossChannelContextAccessAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;
}

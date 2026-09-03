import '../models/agent_omnichannel_raw_ingress.dart';
import '../models/agent_omnichannel_routing_handoff.dart';
import 'agent_omnichannel_gateway.dart';
import 'agent_omnichannel_routing_policy.dart';

class AgentOmnichannelOrchestratorHandoffService {
  const AgentOmnichannelOrchestratorHandoffService({
    this.gateway = const AgentOmnichannelGateway(),
    this.routingPolicy = const AgentOmnichannelRoutingPolicy(),
  });

  final AgentOmnichannelGateway gateway;
  final AgentOmnichannelRoutingPolicy routingPolicy;

  AgentOmnichannelOrchestratorHandoff prepare(AgentOmnichannelRawIngress raw) {
    final gatewayHandoff = gateway.prepare(raw);
    final routingDecision = routingPolicy.evaluate(gatewayHandoff);

    final AgentOmnichannelOrchestratorHandoff handoff =
        AgentOmnichannelOrchestratorHandoff(
          gatewayHandoff: gatewayHandoff,
          routingDecision: routingDecision,
        );

    handoff.validate();
    return handoff;
  }

  bool get invokesOrchestrator => false;
  bool get invokesTargetAgent => false;
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

import '../models/agent_omnichannel_channel_control.dart';
import '../models/agent_omnichannel_observability_event.dart';
import '../models/agent_omnichannel_raw_ingress.dart';
import '../models/agent_omnichannel_replay_assessment.dart';
import '../models/agent_omnichannel_routing_handoff.dart';
import 'agent_omnichannel_channel_control_policy.dart';
import 'agent_omnichannel_observability_service.dart';
import 'agent_omnichannel_orchestrator_handoff_service.dart';
import 'agent_omnichannel_replay_guard.dart';

class AgentOmnichannelControlledRoutingResult {
  const AgentOmnichannelControlledRoutingResult({
    required this.handoff,
    required this.replayAssessment,
    required this.controlDecision,
    required this.auditEvent,
  });

  final AgentOmnichannelOrchestratorHandoff handoff;
  final AgentOmnichannelContinuityReplayAssessment replayAssessment;
  final AgentOmnichannelChannelControlDecision controlDecision;
  final AgentOmnichannelAuditEvent auditEvent;

  bool get routeMayProceed =>
      handoff.ready &&
      replayAssessment.routeMayProceed &&
      controlDecision.routeAllowed;

  bool get orchestratorInvoked => false;
  bool get targetAgentInvoked => false;
  bool get providerInvoked => false;
  bool get businessDataWritten => false;
  bool get coreSwatRideAffected => false;
}

class AgentOmnichannelControlledRoutingGate {
  const AgentOmnichannelControlledRoutingGate({
    this.handoffService = const AgentOmnichannelOrchestratorHandoffService(),
    this.replayGuard = const AgentOmnichannelReplayGuard(),
    this.controlPolicy = const AgentOmnichannelChannelControlPolicy(),
    this.observabilityService = const AgentOmnichannelObservabilityService(),
  });

  final AgentOmnichannelOrchestratorHandoffService handoffService;
  final AgentOmnichannelReplayGuard replayGuard;
  final AgentOmnichannelChannelControlPolicy controlPolicy;
  final AgentOmnichannelObservabilityService observabilityService;

  AgentOmnichannelControlledRoutingResult evaluate({
    required AgentOmnichannelRawIngress raw,
    required AgentOmnichannelReplayWindow replayWindow,
    required AgentOmnichannelChannelControlSnapshot controls,
  }) {
    final AgentOmnichannelOrchestratorHandoff handoff = handoffService.prepare(
      raw,
    );

    final AgentOmnichannelContinuityReplayAssessment replay = replayGuard
        .assess(handoff: handoff, replayWindow: replayWindow);

    final AgentOmnichannelChannelControlDecision control = controlPolicy
        .evaluate(handoff: handoff, controls: controls);

    final AgentOmnichannelAuditEvent event = observabilityService
        .buildControlEvent(
          eventId: 'audit_${raw.rawIngressId}',
          targetAgentRoleId: handoff.routingDecision.targetAgentRoleId,
          occurredAt: raw.receivedAt,
          decision: control,
        );

    return AgentOmnichannelControlledRoutingResult(
      handoff: handoff,
      replayAssessment: replay,
      controlDecision: control,
      auditEvent: event,
    );
  }

  bool get invokesOrchestrator => false;
  bool get invokesTargetAgent => false;
  bool get invokesProvider => false;
  bool get writesBusinessData => false;
  bool get persistsControlSettings => false;
  bool get persistsAuditEvents => false;
  bool get coreSwatRideControlAllowed => false;
}

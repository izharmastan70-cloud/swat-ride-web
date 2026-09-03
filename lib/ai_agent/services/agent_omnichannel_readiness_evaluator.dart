import '../models/agent_omnichannel_readiness_report.dart';

class AgentOmnichannelReadinessEvidence {
  const AgentOmnichannelReadinessEvidence({
    required this.sevenChannelContractPresent,
    required this.identityPrivacyBoundaryPresent,
    required this.normalizationGatewayPresent,
    required this.failClosedRoutingPresent,
    required this.replayProtectionPresent,
    required this.channelControlsPresent,
    required this.failureIsolationPresent,
    required this.privacyMinimizedAuditPresent,
    required this.phase52SharedContextAbsent,
    required this.providerExecutionAbsent,
    required this.runtimeBusinessWriteAbsent,
  });

  final bool sevenChannelContractPresent;
  final bool identityPrivacyBoundaryPresent;
  final bool normalizationGatewayPresent;
  final bool failClosedRoutingPresent;
  final bool replayProtectionPresent;
  final bool channelControlsPresent;
  final bool failureIsolationPresent;
  final bool privacyMinimizedAuditPresent;
  final bool phase52SharedContextAbsent;
  final bool providerExecutionAbsent;
  final bool runtimeBusinessWriteAbsent;

  bool get allPhase51SafetyEvidencePresent =>
      sevenChannelContractPresent &&
      identityPrivacyBoundaryPresent &&
      normalizationGatewayPresent &&
      failClosedRoutingPresent &&
      replayProtectionPresent &&
      channelControlsPresent &&
      failureIsolationPresent &&
      privacyMinimizedAuditPresent &&
      phase52SharedContextAbsent &&
      providerExecutionAbsent &&
      runtimeBusinessWriteAbsent;
}

class AgentOmnichannelReadinessEvaluator {
  const AgentOmnichannelReadinessEvaluator();

  AgentOmnichannelReadinessReport evaluate(
    AgentOmnichannelReadinessEvidence evidence,
  ) {
    final bool ready = evidence.allPhase51SafetyEvidencePresent;

    final AgentOmnichannelReadinessReport
    report = AgentOmnichannelReadinessReport(
      status: ready
          ? AgentOmnichannelReadinessStatus.foundationReadyNotProductionActive
          : AgentOmnichannelReadinessStatus.blocked,
      phase51FoundationComplete: ready,
      sevenChannelContractPresent: evidence.sevenChannelContractPresent,
      identityPrivacyBoundaryPresent: evidence.identityPrivacyBoundaryPresent,
      normalizationGatewayPresent: evidence.normalizationGatewayPresent,
      failClosedRoutingPresent: evidence.failClosedRoutingPresent,
      replayProtectionPresent: evidence.replayProtectionPresent,
      channelControlsPresent: evidence.channelControlsPresent,
      failureIsolationPresent: evidence.failureIsolationPresent,
      privacyMinimizedAuditPresent: evidence.privacyMinimizedAuditPresent,
      phase52SharedContextAbsent: evidence.phase52SharedContextAbsent,
      providerExecutionAbsent: evidence.providerExecutionAbsent,
      runtimeBusinessWriteAbsent: evidence.runtimeBusinessWriteAbsent,
      productionPersistentSettingsBackendWired: false,
      adminToggleUiWired: false,
      liveProviderActivationWired: false,
      auditPersistenceBackendWired: false,
      reasonCodes: ready
          ? const <String>[
              'phase51_foundation_complete',
              'seven_channels_normalized_and_routed_safely',
              'identity_privacy_boundary_preserved',
              'duplicate_replay_protection_present',
              'channel_controls_and_failure_isolation_present',
              'phase52_shared_context_not_implemented',
              'production_activation_not_claimed',
            ]
          : const <String>['phase51_readiness_blocked_missing_safety_evidence'],
    );

    report.validate();
    return report;
  }

  bool get activatesProvider => false;
  bool get invokesOrchestrator => false;
  bool get invokesTargetAgent => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get writesBusinessData => false;
  bool get persistsSettings => false;
  bool get persistsAuditEvents => false;
  bool get implementsPhase52SharedContext => false;
  bool get productionActivationAllowed => false;
}

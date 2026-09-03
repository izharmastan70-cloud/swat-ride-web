import '../constants/agent_ecosystem_channel_safety_constants.dart';
import '../models/agent_ecosystem_channel_safety_decision.dart';
import '../models/agent_ecosystem_channel_safety_request.dart';

class AgentEcosystemChannelSafetyPolicy {
  const AgentEcosystemChannelSafetyPolicy();

  AgentEcosystemChannelSafetyDecision evaluate(
    AgentEcosystemChannelSafetyRequest request,
  ) {
    request.validate();

    if (request.emergencyStopActive) {
      return _decision(
        status: AgentEcosystemSafetyDecisionStatus.blockEmergencyStop,
        routeTo: AgentEcosystemRoutingTarget.blocked,
        reasonCode: 'emergency_stop_active',
      );
    }

    if (!request.moduleEnabled) {
      return _decision(
        status: AgentEcosystemSafetyDecisionStatus.blockModuleDisabled,
        routeTo: AgentEcosystemRoutingTarget.blocked,
        reasonCode: 'channel_or_module_disabled',
      );
    }

    final privilegedClaim =
        request.actorClaim == AgentEcosystemActorClaim.owner ||
        request.actorClaim == AgentEcosystemActorClaim.admin;

    final privateOrAccountScoped =
        request.requestKind ==
            AgentEcosystemRequestKind.accountPrivateInformation ||
        request.requestKind ==
            AgentEcosystemRequestKind.factualBookingOrderPayment ||
        request.requestKind == AgentEcosystemRequestKind.consequentialAction;

    if ((privilegedClaim || privateOrAccountScoped) &&
        !request.trustedIdentityVerified) {
      return _decision(
        status: AgentEcosystemSafetyDecisionStatus.requireTrustedIdentity,
        routeTo: AgentEcosystemRoutingTarget.trustedIdentityGate,
        reasonCode: _identityReasonForChannel(request.channel),
        trustedIdentityRequired: true,
      );
    }

    if (privateOrAccountScoped && !request.trustedSubjectMatch) {
      return _decision(
        status: AgentEcosystemSafetyDecisionStatus.blockSubjectMismatch,
        routeTo: AgentEcosystemRoutingTarget.blocked,
        reasonCode: 'trusted_subject_mismatch',
        trustedIdentityRequired: true,
      );
    }

    if (request.requestKind ==
            AgentEcosystemRequestKind.factualBookingOrderPayment &&
        !request.verifiedBackendEvidence) {
      return _decision(
        status: AgentEcosystemSafetyDecisionStatus.requireVerifiedEvidence,
        routeTo: AgentEcosystemRoutingTarget.verifiedEvidenceGate,
        reasonCode: 'verified_backend_or_tool_evidence_required',
        trustedIdentityRequired: true,
        verifiedEvidenceRequired: true,
      );
    }

    if (request.requestKind == AgentEcosystemRequestKind.consequentialAction) {
      final controlChainReady =
          request.permissionVerified &&
          request.approvalVerified &&
          request.runtimeGateVerified;

      if (!controlChainReady) {
        return _decision(
          status: AgentEcosystemSafetyDecisionStatus.requireControlChain,
          routeTo: AgentEcosystemRoutingTarget.permissionApprovalRuntimeGate,
          reasonCode: 'permission_approval_runtime_gate_chain_required',
          trustedIdentityRequired: true,
          controlChainRequired: true,
        );
      }

      return _decision(
        status: AgentEcosystemSafetyDecisionStatus.eligibleControlledHandoff,
        routeTo: AgentEcosystemRoutingTarget.controlledExecutionHandoff,
        reasonCode: 'control_chain_verified_but_execution_remains_external',
        trustedIdentityRequired: true,
        controlChainRequired: true,
      );
    }

    return _decision(
      status: AgentEcosystemSafetyDecisionStatus.allowSafeResponse,
      routeTo: AgentEcosystemRoutingTarget.safeResponse,
      reasonCode: 'safe_response_allowed',
    );
  }

  String _identityReasonForChannel(String channel) {
    switch (channel) {
      case AgentEcosystemChannel.email:
        return 'email_identity_not_trusted_by_default';
      case AgentEcosystemChannel.whatsapp:
        return 'whatsapp_identity_not_admin_authority';
      case AgentEcosystemChannel.phone:
        return 'caller_identity_not_authority';
      case AgentEcosystemChannel.voice:
        return 'voice_input_not_owner_authorization';
      case AgentEcosystemChannel.appChat:
        return 'app_session_requires_trusted_identity_binding';
      default:
        return 'trusted_identity_required';
    }
  }

  AgentEcosystemChannelSafetyDecision _decision({
    required String status,
    required String routeTo,
    required String reasonCode,
    bool trustedIdentityRequired = false,
    bool verifiedEvidenceRequired = false,
    bool controlChainRequired = false,
  }) {
    return AgentEcosystemChannelSafetyDecision(
      status: status,
      routeTo: routeTo,
      reasonCode: reasonCode,
      trustedIdentityRequired: trustedIdentityRequired,
      verifiedEvidenceRequired: verifiedEvidenceRequired,
      controlChainRequired: controlChainRequired,
    );
  }

  bool channelTransportGrantsAuthority(String channel) {
    if (!AgentEcosystemChannel.values.contains(channel)) {
      throw const FormatException('Unknown ecosystem channel.');
    }

    return false;
  }

  bool get policyOnly => true;
  bool get executesBusinessAction => false;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get overridesRuntimeGate => false;
  bool get callsProvider => false;
  bool get sendsMessage => false;
  bool get readsFirestore => false;
  bool get writesFirestore => false;
  bool get activatesProduction => false;
}

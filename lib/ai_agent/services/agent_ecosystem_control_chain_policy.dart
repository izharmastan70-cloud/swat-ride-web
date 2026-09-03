import '../constants/agent_ecosystem_control_chain_constants.dart';
import '../models/agent_ecosystem_control_chain_decision.dart';
import '../models/agent_ecosystem_control_chain_request.dart';

class AgentEcosystemControlChainPolicy {
  const AgentEcosystemControlChainPolicy();

  AgentEcosystemControlChainDecision evaluate(
    AgentEcosystemControlChainRequest request,
  ) {
    request.validate();

    if (request.emergencyStopActive) {
      return _blocked(
        status: AgentEcosystemControlDecisionStatus.blockEmergencyStop,
        reasonCode: 'emergency_stop_active',
      );
    }

    if (!request.moduleEnabled) {
      return _blocked(
        status: AgentEcosystemControlDecisionStatus.blockModuleDisabled,
        reasonCode: 'module_or_agent_kill_switch_off',
      );
    }

    final privilegedClaim =
        request.actorClaim == AgentEcosystemControlActor.owner ||
        request.actorClaim == AgentEcosystemControlActor.admin;

    if (privilegedClaim && !request.trustedIdentityVerified) {
      return AgentEcosystemControlChainDecision(
        status: AgentEcosystemControlDecisionStatus
            .blockUntrustedPrivilegedIdentity,
        routeTo: AgentEcosystemControlRoute.trustedIdentityGate,
        reasonCode: request.actorClaim == AgentEcosystemControlActor.owner
            ? 'fake_or_unverified_owner_claim'
            : 'unauthorized_or_unverified_admin_claim',
      );
    }

    if (!request.trustedSubjectMatch) {
      return _blocked(
        status: AgentEcosystemControlDecisionStatus.blockSubjectMismatch,
        reasonCode: 'trusted_subject_mismatch',
      );
    }

    if (request.selfPermissionEscalationRequested ||
        request.actorClaim == AgentEcosystemControlActor.agent &&
            !request.permissionAllowed) {
      return AgentEcosystemControlChainDecision(
        status:
            AgentEcosystemControlDecisionStatus.blockSelfPermissionEscalation,
        routeTo: AgentEcosystemControlRoute.permissionGate,
        reasonCode: 'agent_cannot_self_grant_permission',
      );
    }

    if (!request.permissionAllowed) {
      return AgentEcosystemControlChainDecision(
        status: AgentEcosystemControlDecisionStatus.blockPermissionDenied,
        routeTo: AgentEcosystemControlRoute.permissionGate,
        reasonCode: 'permission_denied',
      );
    }

    if (request.approvalRequired) {
      if (!request.approvalPresent) {
        return AgentEcosystemControlChainDecision(
          status: AgentEcosystemControlDecisionStatus.blockApprovalMissing,
          routeTo: AgentEcosystemControlRoute.approvalGate,
          reasonCode: 'required_approval_missing',
        );
      }

      if (request.selfApprovalAttempted) {
        return AgentEcosystemControlChainDecision(
          status: AgentEcosystemControlDecisionStatus.blockSelfApproval,
          routeTo: AgentEcosystemControlRoute.approvalGate,
          reasonCode: 'self_approval_forbidden',
        );
      }

      if (!request.approvalFresh) {
        return AgentEcosystemControlChainDecision(
          status: AgentEcosystemControlDecisionStatus.blockApprovalExpired,
          routeTo: AgentEcosystemControlRoute.approvalGate,
          reasonCode: 'approval_expired_or_already_consumed',
        );
      }

      if (!request.approvalBindingMatch) {
        return AgentEcosystemControlChainDecision(
          status:
              AgentEcosystemControlDecisionStatus.blockApprovalBindingMismatch,
          routeTo: AgentEcosystemControlRoute.approvalGate,
          reasonCode: 'approval_fingerprint_or_action_binding_mismatch',
        );
      }
    }

    if (!request.runtimeGateAllowed) {
      return AgentEcosystemControlChainDecision(
        status: AgentEcosystemControlDecisionStatus.blockRuntimeGate,
        routeTo: AgentEcosystemControlRoute.runtimeGate,
        reasonCode: 'runtime_gate_denied',
      );
    }

    return AgentEcosystemControlChainDecision(
      status: AgentEcosystemControlDecisionStatus.eligibleControlledHandoff,
      routeTo: AgentEcosystemControlRoute.controlledExecutionHandoff,
      reasonCode: 'all_external_controls_verified_handoff_only',
    );
  }

  AgentEcosystemControlChainDecision _blocked({
    required String status,
    required String reasonCode,
  }) {
    return AgentEcosystemControlChainDecision(
      status: status,
      routeTo: AgentEcosystemControlRoute.blocked,
      reasonCode: reasonCode,
    );
  }

  bool get policyOnly => true;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get overridesRuntimeGate => false;
  bool get disablesEmergencyStop => false;
  bool get enablesModule => false;
  bool get callsProvider => false;
  bool get sendsMessage => false;
  bool get readsFirestore => false;
  bool get writesFirestore => false;
  bool get executesBusinessAction => false;
  bool get activatesProduction => false;
}

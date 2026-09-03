import '../constants/agent_ecosystem_control_chain_constants.dart';

class AgentEcosystemControlChainRequest {
  AgentEcosystemControlChainRequest({
    required this.actorClaim,
    required this.trustedIdentityVerified,
    required this.trustedSubjectMatch,
    required this.permissionAllowed,
    required this.selfPermissionEscalationRequested,
    required this.approvalRequired,
    required this.approvalPresent,
    required this.approvalFresh,
    required this.approvalBindingMatch,
    required this.selfApprovalAttempted,
    required this.runtimeGateAllowed,
    required this.emergencyStopActive,
    required this.moduleEnabled,
  }) {
    validate();
  }

  final String actorClaim;

  final bool trustedIdentityVerified;
  final bool trustedSubjectMatch;

  final bool permissionAllowed;
  final bool selfPermissionEscalationRequested;

  final bool approvalRequired;
  final bool approvalPresent;
  final bool approvalFresh;
  final bool approvalBindingMatch;
  final bool selfApprovalAttempted;

  final bool runtimeGateAllowed;

  final bool emergencyStopActive;
  final bool moduleEnabled;

  bool get requestIsEvaluationOnly => true;
  bool get actorClaimGrantsAuthority => false;

  void validate() {
    if (!AgentEcosystemControlActor.values.contains(actorClaim)) {
      throw const FormatException(
        'Invalid ecosystem control-chain actor claim.',
      );
    }
  }
}

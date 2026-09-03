import '../constants/agent_production_rollout_arming_token_constants.dart';
import '../models/agent_production_rollout_arming_token_models.dart';
import '../models/agent_production_rollout_repository_models.dart';
import 'agent_production_rollout_arming_token_service.dart';

class AgentProductionRolloutActivationAuthorizationPolicy {
  const AgentProductionRolloutActivationAuthorizationPolicy();

  AgentProductionRolloutActivationAuthorizationDecision evaluate({
    required AgentProductionRolloutMonitorExecutionRequest request,
    required AgentProductionRolloutArmingCredential? credential,
    required DateTime nowUtc,
  }) {
    if (credential == null) {
      return const AgentProductionRolloutActivationAuthorizationDecision(
        status: AgentProductionRolloutArmingAuthorizationStatus.blockedMissing,
        reasonCode: 'one_time_arming_credential_is_required',
        authorized: false,
        tokenIdSha256: '',
      );
    }

    try {
      credential.validate();
    } on FormatException {
      return const AgentProductionRolloutActivationAuthorizationDecision(
        status: AgentProductionRolloutArmingAuthorizationStatus.blockedInvalid,
        reasonCode: 'arming_credential_validation_failed',
        authorized: false,
        tokenIdSha256: '',
      );
    }

    final AgentProductionRolloutArmingTokenService tokenService =
        AgentProductionRolloutArmingTokenService();

    if (!tokenService.matches(
      rawToken: credential.rawToken,
      tokenIdSha256: credential.tokenIdSha256,
    )) {
      return AgentProductionRolloutActivationAuthorizationDecision(
        status: AgentProductionRolloutArmingAuthorizationStatus.blockedInvalid,
        reasonCode: 'raw_arming_token_does_not_match_sha256_token_id',
        authorized: false,
        tokenIdSha256: credential.tokenIdSha256,
      );
    }

    final DateTime now = nowUtc.toUtc();

    if (now.isBefore(credential.issuedAtUtc) ||
        !now.isBefore(credential.expiresAtUtc)) {
      return AgentProductionRolloutActivationAuthorizationDecision(
        status: AgentProductionRolloutArmingAuthorizationStatus.blockedExpired,
        reasonCode: 'arming_token_is_expired_or_not_yet_valid',
        authorized: false,
        tokenIdSha256: credential.tokenIdSha256,
      );
    }

    final bool exactBinding =
        credential.actorReferenceSha256.toLowerCase() ==
            request.plan.actorReferenceSha256.toLowerCase() &&
        credential.ownerApprovalId == request.plan.ownerApprovalId &&
        credential.planFingerprintSha256.toLowerCase() ==
            request.planFingerprintSha256.toLowerCase() &&
        credential.controlStateFingerprintSha256.toLowerCase() ==
            request.plan.sourceControlStateFingerprintSha256.toLowerCase() &&
        credential.guardRevision == request.expectedGuardRevision &&
        credential.guardVersion == request.expectedGuardVersion &&
        credential.roleCount == request.plan.precondition.expectedRoleCount;

    if (!exactBinding) {
      return AgentProductionRolloutActivationAuthorizationDecision(
        status: AgentProductionRolloutArmingAuthorizationStatus.blockedBinding,
        reasonCode:
            'arming_token_binding_does_not_match_exact_activation_request',
        authorized: false,
        tokenIdSha256: credential.tokenIdSha256,
      );
    }

    return AgentProductionRolloutActivationAuthorizationDecision(
      status: AgentProductionRolloutArmingAuthorizationStatus.authorized,
      reasonCode:
          'one_time_arming_token_exactly_authorizes_monitor_only_transaction_attempt',
      authorized: true,
      tokenIdSha256: credential.tokenIdSha256.toLowerCase(),
    );
  }

  bool get policyOnly => true;
  bool get consumesToken => false;
  bool get activatesProduction => false;
  bool get grantsAutoAuthority => false;
  bool get grantsBusinessWriteAuthority => false;
}

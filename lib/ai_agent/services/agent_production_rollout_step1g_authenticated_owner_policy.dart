import '../constants/agent_production_rollout_step1g_evidence_constants.dart';

class AgentProductionRolloutStep1GAuthDecision {
  const AgentProductionRolloutStep1GAuthDecision({
    required this.allowed,
    required this.reasonCode,
  });

  final bool allowed;
  final String reasonCode;
}

class AgentProductionRolloutStep1GAuthenticatedOwnerPolicy {
  const AgentProductionRolloutStep1GAuthenticatedOwnerPolicy();

  AgentProductionRolloutStep1GAuthDecision evaluate({
    required bool signedIn,
    required bool uidMatchesScreenAdmin,
    required bool superAdminAccessAllowed,
    required bool testingBypass,
    required bool accessCameFromCustomClaim,
    required String claimRole,
    required bool idTokenPresent,
    required DateTime? authTimeUtc,
    required DateTime nowUtc,
  }) {
    if (!signedIn) {
      return _deny('firebase_sign_in_required');
    }

    if (!uidMatchesScreenAdmin) {
      return _deny('authenticated_uid_does_not_match_super_admin_screen');
    }

    if (!superAdminAccessAllowed) {
      return _deny('production_super_admin_access_required');
    }

    if (testingBypass) {
      return _deny('testing_bypass_never_authorizes_production_rollout');
    }

    if (!accessCameFromCustomClaim ||
        claimRole.trim().toLowerCase() !=
            AgentProductionRolloutStep1GEvidence.requiredClaimRole) {
      return _deny(
        'firebase_super_admin_custom_claim_required_for_production_rollout',
      );
    }

    if (!idTokenPresent || authTimeUtc == null) {
      return _deny('verified_id_token_and_auth_time_required');
    }

    final DateTime now = nowUtc.toUtc();
    final DateTime authTime = authTimeUtc.toUtc();
    final Duration age = now.difference(authTime);

    if (age < -AgentProductionRolloutStep1GEvidence.maxFutureAuthSkew) {
      return _deny('firebase_auth_time_future_skew_exceeded');
    }

    if (age > AgentProductionRolloutStep1GEvidence.maxFreshLoginAge) {
      return _deny(
        'fresh_login_required_sign_out_and_sign_in_again_with_normal_otp',
      );
    }

    return const AgentProductionRolloutStep1GAuthDecision(
      allowed: true,
      reasonCode: 'fresh_authenticated_super_admin_custom_claim_verified',
    );
  }

  AgentProductionRolloutStep1GAuthDecision _deny(String reasonCode) {
    return AgentProductionRolloutStep1GAuthDecision(
      allowed: false,
      reasonCode: reasonCode,
    );
  }

  bool get tokenRefreshCountsAsReauthentication => false;
  bool get phoneNumberAloneGrantsAuthority => false;
  bool get firestoreAdminRecordAloneGrantsCriticalRolloutAuthority => false;
  bool get testingBypassGrantsAuthority => false;
}

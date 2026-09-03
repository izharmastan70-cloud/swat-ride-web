import 'package:firebase_auth/firebase_auth.dart';

import '../../super_admin/models/super_admin_access_result.dart';
import '../../super_admin/services/super_admin_access_service.dart';
import '../constants/agent_production_rollout_step1g_evidence_constants.dart';
import '../models/agent_security_incident_fresh_owner_claim_verification_result.dart';
import 'agent_production_rollout_step1g_authenticated_owner_policy.dart';

class AgentSecurityIncidentFreshOwnerClaimVerificationService {
  AgentSecurityIncidentFreshOwnerClaimVerificationService({
    FirebaseAuth? auth,
    SuperAdminAccessService? accessService,
    AgentProductionRolloutStep1GAuthenticatedOwnerPolicy? authPolicy,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _accessService = accessService ?? SuperAdminAccessService(),
       _authPolicy =
           authPolicy ??
           const AgentProductionRolloutStep1GAuthenticatedOwnerPolicy();

  final FirebaseAuth _auth;
  final SuperAdminAccessService _accessService;
  final AgentProductionRolloutStep1GAuthenticatedOwnerPolicy _authPolicy;

  Future<AgentSecurityIncidentFreshOwnerClaimVerificationResult> verify({
    required String currentAdminId,
  }) async {
    final DateTime nowUtc = DateTime.now().toUtc();
    final User? user = _auth.currentUser;

    if (user == null) {
      return _blocked(
        reasonCode: 'firebase_sign_in_required',
        authAgeBucket: AgentSecurityIncidentFreshOwnerAuthAgeBucket.unavailable,
      );
    }

    try {
      final SuperAdminAccessResult access = await _accessService
          .checkCurrentAccess(forceRefreshToken: true);

      final IdTokenResult token = await user.getIdTokenResult(true);
      final Map<String, dynamic> claims = token.claims ?? <String, dynamic>{};

      final String claimRole =
          claims['role']?.toString().trim().toLowerCase() ?? '';

      final dynamic rawAuthTime = claims['auth_time'];

      final int? authSeconds = rawAuthTime is num
          ? rawAuthTime.toInt()
          : int.tryParse(rawAuthTime?.toString() ?? '');

      final DateTime? authTimeUtc = authSeconds == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              authSeconds * 1000,
              isUtc: true,
            );

      // Raw token is only checked for presence in local memory.
      // It is never returned, logged, displayed or persisted.
      final bool idTokenPresent = token.token?.trim().isNotEmpty == true;

      final bool uidBindingVerified = user.uid == currentAdminId.trim();

      final bool customClaimSourceVerified =
          access.source == SuperAdminAccessSource.customClaim;

      final bool roleClaimVerified =
          claimRole == AgentProductionRolloutStep1GEvidence.requiredClaimRole;

      final AgentProductionRolloutStep1GAuthDecision decision = _authPolicy
          .evaluate(
            signedIn: true,
            uidMatchesScreenAdmin: uidBindingVerified,
            superAdminAccessAllowed: access.isAllowed && access.isSuperAdmin,
            testingBypass: access.isTestingBypass,
            accessCameFromCustomClaim: customClaimSourceVerified,
            claimRole: claimRole,
            idTokenPresent: idTokenPresent,
            authTimeUtc: authTimeUtc,
            nowUtc: nowUtc,
          );

      final _SafeAuthAge safeAge = _safeAuthAge(
        nowUtc: nowUtc,
        authTimeUtc: authTimeUtc,
      );

      return AgentSecurityIncidentFreshOwnerClaimVerificationResult(
        status: decision.allowed
            ? AgentSecurityIncidentFreshOwnerClaimVerificationStatus.verified
            : AgentSecurityIncidentFreshOwnerClaimVerificationStatus.blocked,
        reasonCode: decision.reasonCode,
        superAdminAccessVerified:
            access.isAllowed && access.isSuperAdmin && !access.isTestingBypass,
        roleClaimVerified: roleClaimVerified,
        uidBindingVerified: uidBindingVerified,
        customClaimSourceVerified: customClaimSourceVerified,
        freshLoginVerified: decision.allowed,
        authAgeBucket: safeAge.bucket,
        boundedAuthAgeSeconds: safeAge.boundedSeconds,
      );
    } on Object catch (error) {
      return _blocked(
        reasonCode: 'VERIFICATION_EXCEPTION_${error.runtimeType}',
        authAgeBucket: AgentSecurityIncidentFreshOwnerAuthAgeBucket.unavailable,
      );
    }
  }

  _SafeAuthAge _safeAuthAge({
    required DateTime nowUtc,
    required DateTime? authTimeUtc,
  }) {
    if (authTimeUtc == null) {
      return const _SafeAuthAge(
        bucket: AgentSecurityIncidentFreshOwnerAuthAgeBucket.unavailable,
        boundedSeconds: null,
      );
    }

    final Duration age = nowUtc.toUtc().difference(authTimeUtc.toUtc());

    if (age < -AgentProductionRolloutStep1GEvidence.maxFutureAuthSkew) {
      return const _SafeAuthAge(
        bucket: AgentSecurityIncidentFreshOwnerAuthAgeBucket.futureSkew,
        boundedSeconds: null,
      );
    }

    if (age > AgentProductionRolloutStep1GEvidence.maxFreshLoginAge) {
      return const _SafeAuthAge(
        bucket: AgentSecurityIncidentFreshOwnerAuthAgeBucket.stale,
        boundedSeconds: 301,
      );
    }

    final int safeSeconds = age.isNegative ? 0 : age.inSeconds.clamp(0, 300);

    return _SafeAuthAge(
      bucket: AgentSecurityIncidentFreshOwnerAuthAgeBucket.fresh,
      boundedSeconds: safeSeconds,
    );
  }

  AgentSecurityIncidentFreshOwnerClaimVerificationResult _blocked({
    required String reasonCode,
    required String authAgeBucket,
  }) {
    return AgentSecurityIncidentFreshOwnerClaimVerificationResult(
      status: AgentSecurityIncidentFreshOwnerClaimVerificationStatus.blocked,
      reasonCode: reasonCode,
      superAdminAccessVerified: false,
      roleClaimVerified: false,
      uidBindingVerified: false,
      customClaimSourceVerified: false,
      freshLoginVerified: false,
      authAgeBucket: authAgeBucket,
      boundedAuthAgeSeconds: null,
    );
  }

  bool get readOnlyVerification => true;
  bool get persistsVerification => false;
  bool get writesFirestore => false;
  bool get mutatesAuthClaims => false;
  bool get attachesRuntime => false;
  bool get armsRepository => false;
  bool get createsIncident => false;
  bool get createsIdempotencyReceipt => false;
  bool get changesRolloutStage => false;
  bool get changesAgentMode => false;
  bool get changesEmergencyStop => false;
  bool get authorizesSuggestOnly => false;
  bool get authorizesAuto => false;
}

class _SafeAuthAge {
  const _SafeAuthAge({required this.bucket, required this.boundedSeconds});

  final String bucket;
  final int? boundedSeconds;
}

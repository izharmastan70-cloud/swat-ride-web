import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/models/agent_security_incident_fresh_owner_claim_verification_result.dart';

void main() {
  AgentSecurityIncidentFreshOwnerClaimVerificationResult verified() {
    return const AgentSecurityIncidentFreshOwnerClaimVerificationResult(
      status: AgentSecurityIncidentFreshOwnerClaimVerificationStatus.verified,
      reasonCode: 'fresh_authenticated_super_admin_custom_claim_verified',
      superAdminAccessVerified: true,
      roleClaimVerified: true,
      uidBindingVerified: true,
      customClaimSourceVerified: true,
      freshLoginVerified: true,
      authAgeBucket: AgentSecurityIncidentFreshOwnerAuthAgeBucket.fresh,
      boundedAuthAgeSeconds: 120,
    );
  }

  test('verified result contains only safe identity projection', () {
    final result = verified();

    expect(result.verified, isTrue);
    expect(result.superAdminAccessVerified, isTrue);
    expect(result.roleClaimVerified, isTrue);
    expect(result.uidBindingVerified, isTrue);
    expect(result.customClaimSourceVerified, isTrue);
    expect(result.freshLoginVerified, isTrue);
    expect(result.boundedAuthAgeSeconds, inInclusiveRange(0, 300));
  });

  test('safe projection never contains raw sensitive identity values', () {
    final result = verified();

    expect(result.containsRawIdToken, isFalse);
    expect(result.containsUid, isFalse);
    expect(result.containsEmail, isFalse);
    expect(result.containsPhone, isFalse);
    expect(result.containsRawClaims, isFalse);
  });

  test('verification result does not persist or mutate Auth', () {
    final result = verified();

    expect(result.persistsVerification, isFalse);
    expect(result.mutatesAuthClaims, isFalse);
  });

  test('verification result grants no Firestore write authority', () {
    final result = verified();

    expect(result.writesFirestore, isFalse);
    expect(result.createsIncident, isFalse);
    expect(result.createsIdempotencyReceipt, isFalse);
  });

  test('verification result cannot attach or arm repository', () {
    final result = verified();

    expect(result.attachesRuntime, isFalse);
    expect(result.armsRepository, isFalse);
  });

  test('verification result cannot change rollout or AgentMode', () {
    final result = verified();

    expect(result.changesRolloutStage, isFalse);
    expect(result.changesAgentMode, isFalse);
    expect(result.changesEmergencyStop, isFalse);
  });

  test('verification result does not authorize SUGGEST_ONLY or AUTO', () {
    final result = verified();

    expect(result.authorizesSuggestOnly, isFalse);
    expect(result.authorizesAuto, isFalse);
  });

  test('stale auth age uses bounded non-sensitive sentinel', () {
    const result = AgentSecurityIncidentFreshOwnerClaimVerificationResult(
      status: AgentSecurityIncidentFreshOwnerClaimVerificationStatus.blocked,
      reasonCode:
          'fresh_login_required_sign_out_and_sign_in_again_with_normal_otp',
      superAdminAccessVerified: true,
      roleClaimVerified: true,
      uidBindingVerified: true,
      customClaimSourceVerified: true,
      freshLoginVerified: false,
      authAgeBucket: AgentSecurityIncidentFreshOwnerAuthAgeBucket.stale,
      boundedAuthAgeSeconds: 301,
    );

    expect(result.verified, isFalse);
    expect(result.boundedAuthAgeSeconds, 301);
  });

  test('missing auth time exposes no epoch value', () {
    const result = AgentSecurityIncidentFreshOwnerClaimVerificationResult(
      status: AgentSecurityIncidentFreshOwnerClaimVerificationStatus.blocked,
      reasonCode: 'verified_id_token_and_auth_time_required',
      superAdminAccessVerified: true,
      roleClaimVerified: true,
      uidBindingVerified: true,
      customClaimSourceVerified: true,
      freshLoginVerified: false,
      authAgeBucket: AgentSecurityIncidentFreshOwnerAuthAgeBucket.unavailable,
      boundedAuthAgeSeconds: null,
    );

    expect(result.boundedAuthAgeSeconds, isNull);
  });

  test('successful identity verification is not runtime authorization', () {
    final result = verified();

    expect(result.verified, isTrue);
    expect(result.attachesRuntime, isFalse);
    expect(result.armsRepository, isFalse);
    expect(result.writesFirestore, isFalse);
    expect(result.authorizesSuggestOnly, isFalse);
    expect(result.authorizesAuto, isFalse);
  });
}

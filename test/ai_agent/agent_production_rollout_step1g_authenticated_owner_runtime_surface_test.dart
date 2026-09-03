import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_production_rollout_step1g_evidence_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_production_rollout_step1g_runtime_models.dart';
import 'package:swat_ride/ai_agent/services/agent_production_rollout_step1g_authenticated_owner_policy.dart';

void main() {
  const AgentProductionRolloutStep1GAuthenticatedOwnerPolicy policy =
      AgentProductionRolloutStep1GAuthenticatedOwnerPolicy();

  final DateTime now = DateTime.utc(2026, 8, 24, 18, 30);

  AgentProductionRolloutStep1GAuthDecision evaluate({
    bool signedIn = true,
    bool uidMatches = true,
    bool superAdminAllowed = true,
    bool testingBypass = false,
    bool customClaim = true,
    String claimRole = 'super_admin',
    bool tokenPresent = true,
    DateTime? authTime,
  }) {
    return policy.evaluate(
      signedIn: signedIn,
      uidMatchesScreenAdmin: uidMatches,
      superAdminAccessAllowed: superAdminAllowed,
      testingBypass: testingBypass,
      accessCameFromCustomClaim: customClaim,
      claimRole: claimRole,
      idTokenPresent: tokenPresent,
      authTimeUtc: authTime ?? now.subtract(const Duration(minutes: 1)),
      nowUtc: now,
    );
  }

  test('Phase65 and Phase62 evidence are real SHA-256 sized', () {
    expect(
      AgentProductionRolloutStep1GEvidence.phase65SafetyEvidenceSha256,
      matches(RegExp(r'^[a-f0-9]{64}$')),
    );
    expect(
      AgentProductionRolloutStep1GEvidence.phase62VersionEvidenceSha256,
      matches(RegExp(r'^[a-f0-9]{64}$')),
    );
  });

  test('fresh custom-claim Super Admin is eligible', () {
    final decision = evaluate();
    expect(decision.allowed, true);
  });

  test('signed-out session fails closed', () {
    expect(evaluate(signedIn: false).allowed, false);
  });

  test('screen admin UID mismatch fails closed', () {
    expect(evaluate(uidMatches: false).allowed, false);
  });

  test('testing bypass never authorizes production rollout', () {
    expect(evaluate(testingBypass: true).allowed, false);
    expect(policy.testingBypassGrantsAuthority, false);
  });

  test('Firestore-only Super Admin is insufficient for critical rollout', () {
    final decision = evaluate(customClaim: false);
    expect(decision.allowed, false);
    expect(
      policy.firestoreAdminRecordAloneGrantsCriticalRolloutAuthority,
      false,
    );
  });

  test('wrong custom claim role fails closed', () {
    expect(evaluate(claimRole: 'admin').allowed, false);
  });

  test('missing ID token fails closed', () {
    expect(evaluate(tokenPresent: false).allowed, false);
  });

  test('login older than five minutes requires real re-login', () {
    final decision = evaluate(
      authTime: now.subtract(const Duration(minutes: 6)),
    );

    expect(decision.allowed, false);
    expect(decision.reasonCode, contains('fresh_login_required'));
    expect(policy.tokenRefreshCountsAsReauthentication, false);
  });

  test('excessive future auth_time skew fails closed', () {
    final decision = evaluate(authTime: now.add(const Duration(minutes: 2)));

    expect(decision.allowed, false);
  });

  test('rollout constants keep AUTO/business/external disabled', () {
    expect(AgentProductionRolloutStep1GEvidence.autoTrafficEnabled, false);
    expect(
      AgentProductionRolloutStep1GEvidence.businessWriteTrafficEnabled,
      false,
    );
    expect(AgentProductionRolloutStep1GEvidence.externalChannelsEnabled, false);
    expect(
      AgentProductionRolloutStep1GEvidence.confirmationPhrase,
      'MONITOR_ONLY',
    );
  });

  test(
    'successful outcome model never implies AUTO/business/paid/external',
    () {
      const outcome = AgentProductionRolloutStep1GActivationOutcome(
        activated: true,
        postActivationVerified: true,
        status: 'APPLIED_MONITOR_ONLY',
        reasonCode: 'verified',
        activationId: 'activation',
        armingTokenIdSha256: 'token',
        guardRevision: 1,
      );

      expect(outcome.monitorOnlyProductionActive, true);
      expect(outcome.autoTrafficEnabled, false);
      expect(outcome.businessWriteTrafficEnabled, false);
      expect(outcome.paidAiEnabled, false);
      expect(outcome.externalChannelsEnabled, false);
      expect(outcome.automaticRollbackPerformed, false);
    },
  );
}

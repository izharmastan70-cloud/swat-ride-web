import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_ecosystem_privacy_adversarial_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_ecosystem_privacy_adversarial_request.dart';
import 'package:swat_ride/ai_agent/services/agent_ecosystem_privacy_adversarial_policy.dart';

void main() {
  const policy = AgentEcosystemPrivacyAdversarialPolicy();

  AgentEcosystemPrivacyAdversarialRequest request({
    String attackType = AgentEcosystemPrivacyAttackType.none,
    String domain = AgentEcosystemPrivacyDomain.general,
    bool promptInjectionDetected = false,
    bool secretExtractionRequested = false,
    bool trustedSessionVerified = true,
    bool sessionFresh = true,
    bool sessionSubjectMatch = true,
    bool crossCustomerRequested = false,
    bool requestedDataScopeAllowed = true,
    bool minimumNecessaryVerified = true,
    bool redactionVerified = true,
    bool strictSensitiveDomainAuthorized = true,
    bool providerHandoffRequested = false,
    bool providerPrivacyProjectionVerified = true,
  }) {
    return AgentEcosystemPrivacyAdversarialRequest(
      attackType: attackType,
      domain: domain,
      promptInjectionDetected: promptInjectionDetected,
      secretExtractionRequested: secretExtractionRequested,
      trustedSessionVerified: trustedSessionVerified,
      sessionFresh: sessionFresh,
      sessionSubjectMatch: sessionSubjectMatch,
      crossCustomerRequested: crossCustomerRequested,
      requestedDataScopeAllowed: requestedDataScopeAllowed,
      minimumNecessaryVerified: minimumNecessaryVerified,
      redactionVerified: redactionVerified,
      strictSensitiveDomainAuthorized: strictSensitiveDomainAuthorized,
      providerHandoffRequested: providerHandoffRequested,
      providerPrivacyProjectionVerified: providerPrivacyProjectionVerified,
    );
  }

  test('prompt injection cannot override security/authority', () {
    final decision = policy.evaluate(
      request(
        attackType: AgentEcosystemPrivacyAttackType.promptInjection,
        promptInjectionDetected: true,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemPrivacyDecisionStatus.blockPromptInjection,
    );
    expect(decision.mayOverrideSystemInstruction, false);
    expect(decision.mayGrantPermission, false);
    expect(decision.mayConsumeApproval, false);
  });

  test('secret extraction request fails closed without raw secret', () {
    final decision = policy.evaluate(
      request(
        attackType: AgentEcosystemPrivacyAttackType.secretExtraction,
        secretExtractionRequested: true,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemPrivacyDecisionStatus.blockSecretExtraction,
    );
    expect(decision.mayRevealSecret, false);
    expect(decision.mayReturnRawCredential, false);
    expect(decision.mayReturnRawToken, false);
  });

  test('unverified stolen customer session fails closed', () {
    final decision = policy.evaluate(
      request(
        attackType: AgentEcosystemPrivacyAttackType.stolenSession,
        trustedSessionVerified: false,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemPrivacyDecisionStatus.blockUntrustedSession,
    );
    expect(
      decision.reasonCode,
      'stolen_replayed_or_unverified_customer_session_blocked',
    );
    expect(decision.mayTrustSessionClaimAlone, false);
  });

  test('stale/expired session fails closed', () {
    final decision = policy.evaluate(request(sessionFresh: false));

    expect(
      decision.status,
      AgentEcosystemPrivacyDecisionStatus.blockStaleSession,
    );
  });

  test('session subject mismatch blocks stolen-session reuse', () {
    final decision = policy.evaluate(request(sessionSubjectMatch: false));

    expect(
      decision.status,
      AgentEcosystemPrivacyDecisionStatus.blockSessionSubjectMismatch,
    );
    expect(decision.mayReturnOtherCustomerData, false);
  });

  test('cross-customer data request fails closed', () {
    final decision = policy.evaluate(
      request(
        attackType: AgentEcosystemPrivacyAttackType.crossCustomerData,
        crossCustomerRequested: true,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemPrivacyDecisionStatus.blockCrossCustomer,
    );
    expect(decision.mayReturnOtherCustomerData, false);
  });

  test('out-of-scope data request fails closed', () {
    final decision = policy.evaluate(request(requestedDataScopeAllowed: false));

    expect(decision.status, AgentEcosystemPrivacyDecisionStatus.blockScope);
  });

  test('minimum-necessary projection is mandatory', () {
    final decision = policy.evaluate(request(minimumNecessaryVerified: false));

    expect(
      decision.status,
      AgentEcosystemPrivacyDecisionStatus.blockMinimumNecessary,
    );
  });

  test('redaction is mandatory before safe projection', () {
    final decision = policy.evaluate(request(redactionVerified: false));

    expect(decision.status, AgentEcosystemPrivacyDecisionStatus.blockRedaction);
  });

  test('Student domain requires strict authorization', () {
    final decision = policy.evaluate(
      request(
        domain: AgentEcosystemPrivacyDomain.student,
        strictSensitiveDomainAuthorized: false,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemPrivacyDecisionStatus.blockSensitiveDomain,
    );
  });

  test('Safety domain requires strict authorization', () {
    final decision = policy.evaluate(
      request(
        domain: AgentEcosystemPrivacyDomain.safety,
        strictSensitiveDomainAuthorized: false,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemPrivacyDecisionStatus.blockSensitiveDomain,
    );
  });

  test('Financial domain requires strict authorization', () {
    final decision = policy.evaluate(
      request(
        domain: AgentEcosystemPrivacyDomain.financial,
        strictSensitiveDomainAuthorized: false,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemPrivacyDecisionStatus.blockSensitiveDomain,
    );
  });

  test('provider handoff requires verified privacy projection', () {
    final decision = policy.evaluate(
      request(
        providerHandoffRequested: true,
        providerPrivacyProjectionVerified: false,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemPrivacyDecisionStatus.blockProviderPrivacyProjection,
    );
    expect(decision.mayCallProvider, false);
    expect(decision.maySendPrivateDataToProvider, false);
  });

  test('safe projection eligibility is not data fetch or provider call', () {
    final decision = policy.evaluate(request());

    expect(
      decision.status,
      AgentEcosystemPrivacyDecisionStatus.safeProjectionEligible,
    );
    expect(decision.failClosed, false);
    expect(decision.mayReadFirestore, false);
    expect(decision.mayCallProvider, false);
    expect(decision.mayExecuteBusinessAction, false);
  });

  test('session claim and user text never grant authority', () {
    final value = request();

    expect(value.sessionClaimAloneGrantsAuthority, false);
    expect(value.userTextGrantsAuthority, false);
  });

  test('privacy adversarial policy has zero execution authority', () {
    expect(policy.policyOnly, true);
    expect(policy.readsSecretStore, false);
    expect(policy.validatesSessionAgainstBackend, false);
    expect(policy.grantsIdentityAuthority, false);
    expect(policy.grantsPermission, false);
    expect(policy.consumesApproval, false);
    expect(policy.overridesRuntimeGate, false);
    expect(policy.readsFirestore, false);
    expect(policy.writesFirestore, false);
    expect(policy.callsProvider, false);
    expect(policy.sendsPrivateData, false);
    expect(policy.executesBusinessAction, false);
    expect(policy.activatesProduction, false);
  });
}

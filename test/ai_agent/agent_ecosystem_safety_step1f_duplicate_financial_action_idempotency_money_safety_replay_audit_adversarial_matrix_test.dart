import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_ecosystem_financial_safety_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_ecosystem_financial_safety_request.dart';
import 'package:swat_ride/ai_agent/services/agent_ecosystem_financial_safety_policy.dart';

void main() {
  const policy = AgentEcosystemFinancialSafetyPolicy();

  const operationHash =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  const subjectHash =
      'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';

  AgentEcosystemFinancialSafetyRequest request({
    String actionType = AgentEcosystemFinancialActionType.refund,
    String idempotencyKey = 'finance:refund:phase65:1',
    String operationFingerprintSha256 = operationHash,
    String trustedSubjectReferenceSha256 = subjectHash,
    int amountMinor = 125000,
    String currency = 'PKR',
    bool trustedIdentityVerified = true,
    bool permissionAllowed = true,
    bool approvalRequired = true,
    bool approvalPresent = true,
    bool approvalFresh = true,
    bool approvalBindingMatch = true,
    bool runtimeGateAllowed = true,
    bool emergencyStopActive = false,
    bool moduleEnabled = true,
    bool reservationAcquired = true,
    bool reservationBindingMatch = true,
    bool operationAmountCurrencyBindingMatch = true,
    bool priorCompletionDetected = false,
    bool priorCompletionBindingMatch = true,
    bool providerCallbackReplayDetected = false,
    bool auditReady = true,
  }) {
    return AgentEcosystemFinancialSafetyRequest(
      actionType: actionType,
      idempotencyKey: idempotencyKey,
      operationFingerprintSha256: operationFingerprintSha256,
      trustedSubjectReferenceSha256: trustedSubjectReferenceSha256,
      amountMinor: amountMinor,
      currency: currency,
      trustedIdentityVerified: trustedIdentityVerified,
      permissionAllowed: permissionAllowed,
      approvalRequired: approvalRequired,
      approvalPresent: approvalPresent,
      approvalFresh: approvalFresh,
      approvalBindingMatch: approvalBindingMatch,
      runtimeGateAllowed: runtimeGateAllowed,
      emergencyStopActive: emergencyStopActive,
      moduleEnabled: moduleEnabled,
      reservationAcquired: reservationAcquired,
      reservationBindingMatch: reservationBindingMatch,
      operationAmountCurrencyBindingMatch: operationAmountCurrencyBindingMatch,
      priorCompletionDetected: priorCompletionDetected,
      priorCompletionBindingMatch: priorCompletionBindingMatch,
      providerCallbackReplayDetected: providerCallbackReplayDetected,
      auditReady: auditReady,
    );
  }

  test('locked financial action types are bounded', () {
    expect(AgentEcosystemFinancialActionType.values, <String>{
      AgentEcosystemFinancialActionType.paymentCapture,
      AgentEcosystemFinancialActionType.refund,
      AgentEcosystemFinancialActionType.walletDebit,
      AgentEcosystemFinancialActionType.walletCredit,
      AgentEcosystemFinancialActionType.payout,
      AgentEcosystemFinancialActionType.withdrawal,
      AgentEcosystemFinancialActionType.commissionSettlement,
    });
  });

  test('financial request carries safe fingerprints, not raw credentials', () {
    final value = request();

    expect(value.financialMetadataOnly, true);
    expect(value.rawPaymentCredentialStored, false);
    expect(value.rawCustomerIdentifierStored, false);
    expect(value.idempotencyIsAuthorization, false);
  });

  test('Emergency Stop blocks financial handoff first', () {
    final decision = policy.evaluate(request(emergencyStopActive: true));

    expect(
      decision.status,
      AgentEcosystemFinancialDecisionStatus.blockEmergencyStop,
    );
    expect(decision.mayExecuteRefund, false);
  });

  test('financial module/Agent kill switch fails closed', () {
    final decision = policy.evaluate(request(moduleEnabled: false));

    expect(
      decision.status,
      AgentEcosystemFinancialDecisionStatus.blockModuleDisabled,
    );
  });

  test('untrusted financial actor identity fails closed', () {
    final decision = policy.evaluate(request(trustedIdentityVerified: false));

    expect(
      decision.status,
      AgentEcosystemFinancialDecisionStatus.blockUntrustedIdentity,
    );
  });

  test('Permission denied blocks money action', () {
    final decision = policy.evaluate(request(permissionAllowed: false));

    expect(
      decision.status,
      AgentEcosystemFinancialDecisionStatus.blockPermissionDenied,
    );
  });

  test('required Approval missing blocks money action', () {
    final decision = policy.evaluate(request(approvalPresent: false));

    expect(
      decision.status,
      AgentEcosystemFinancialDecisionStatus.blockApprovalRequired,
    );
  });

  test('expired/consumed Approval blocks replay', () {
    final decision = policy.evaluate(request(approvalFresh: false));

    expect(
      decision.status,
      AgentEcosystemFinancialDecisionStatus.blockApprovalExpired,
    );
  });

  test('Approval action/amount/subject mismatch blocks', () {
    final decision = policy.evaluate(request(approvalBindingMatch: false));

    expect(
      decision.status,
      AgentEcosystemFinancialDecisionStatus.blockApprovalBindingMismatch,
    );
  });

  test('Runtime Gate denial blocks money action', () {
    final decision = policy.evaluate(request(runtimeGateAllowed: false));

    expect(
      decision.status,
      AgentEcosystemFinancialDecisionStatus.blockRuntimeGate,
    );
  });

  test('missing idempotency reservation fails closed', () {
    final decision = policy.evaluate(request(reservationAcquired: false));

    expect(
      decision.status,
      AgentEcosystemFinancialDecisionStatus.blockReservationMissing,
    );
    expect(policy.idempotencyIsAuthorization, false);
  });

  test('idempotency reservation binding mismatch fails closed', () {
    final decision = policy.evaluate(request(reservationBindingMatch: false));

    expect(
      decision.status,
      AgentEcosystemFinancialDecisionStatus.blockReservationBindingMismatch,
    );
  });

  test('amount/currency/fingerprint binding mismatch fails closed', () {
    final decision = policy.evaluate(
      request(operationAmountCurrencyBindingMatch: false),
    );

    expect(
      decision.status,
      AgentEcosystemFinancialDecisionStatus.blockOperationBindingMismatch,
    );
  });

  test('payment provider callback replay fails closed', () {
    final decision = policy.evaluate(
      request(providerCallbackReplayDetected: true),
    );

    expect(
      decision.status,
      AgentEcosystemFinancialDecisionStatus.blockCallbackReplay,
    );
    expect(decision.mayCallPaymentProvider, false);
  });

  test('duplicate completed financial action cannot execute twice', () {
    final decision = policy.evaluate(
      request(priorCompletionDetected: true, priorCompletionBindingMatch: true),
    );

    expect(
      decision.status,
      AgentEcosystemFinancialDecisionStatus.blockDuplicateCompleted,
    );
    expect(decision.existingCompletionReferenceOnly, true);
    expect(
      decision.reasonCode,
      'existing_verified_completion_must_be_reused_no_second_financial_action',
    );
    expect(decision.mayExecutePayment, false);
    expect(decision.mayExecuteRefund, false);
    expect(decision.mayDebitWallet, false);
    expect(decision.mayCreditWallet, false);
    expect(decision.mayExecutePayout, false);
  });

  test('duplicate completion with different binding is collision/tamper', () {
    final decision = policy.evaluate(
      request(
        priorCompletionDetected: true,
        priorCompletionBindingMatch: false,
      ),
    );

    expect(
      decision.status,
      AgentEcosystemFinancialDecisionStatus.blockDuplicateBindingCollision,
    );
    expect(decision.existingCompletionReferenceOnly, false);
  });

  test('missing audit readiness blocks new financial handoff', () {
    final decision = policy.evaluate(request(auditReady: false));

    expect(
      decision.status,
      AgentEcosystemFinancialDecisionStatus.blockAuditUnavailable,
    );
    expect(decision.auditRequired, true);
  });

  test('complete safety chain yields financial handoff eligibility only', () {
    final decision = policy.evaluate(request());

    expect(
      decision.status,
      AgentEcosystemFinancialDecisionStatus.eligibleControlledFinancialHandoff,
    );
    expect(decision.failClosed, false);

    expect(decision.mayExecutePayment, false);
    expect(decision.mayExecuteRefund, false);
    expect(decision.mayDebitWallet, false);
    expect(decision.mayCreditWallet, false);
    expect(decision.mayExecutePayout, false);
    expect(decision.mayApproveWithdrawal, false);
    expect(decision.maySettleCommission, false);
  });

  test('non-Approval financial action still needs every other control', () {
    final allowed = policy.evaluate(request(approvalRequired: false));

    expect(
      allowed.status,
      AgentEcosystemFinancialDecisionStatus.eligibleControlledFinancialHandoff,
    );

    final denied = policy.evaluate(
      request(approvalRequired: false, runtimeGateAllowed: false),
    );

    expect(
      denied.status,
      AgentEcosystemFinancialDecisionStatus.blockRuntimeGate,
    );
  });

  test('financial safety policy has zero money/execution authority', () {
    expect(policy.policyOnly, true);
    expect(policy.idempotencyIsAuthorization, false);

    expect(policy.executesPayment, false);
    expect(policy.executesRefund, false);
    expect(policy.debitsWallet, false);
    expect(policy.creditsWallet, false);
    expect(policy.executesPayout, false);
    expect(policy.approvesWithdrawal, false);
    expect(policy.settlesCommission, false);

    expect(policy.reservesIdempotencyKey, false);
    expect(policy.marksCompletion, false);
    expect(policy.consumesApproval, false);
    expect(policy.grantsPermission, false);
    expect(policy.overridesRuntimeGate, false);
    expect(policy.disablesEmergencyStop, false);
    expect(policy.enablesModule, false);
    expect(policy.callsPaymentProvider, false);
    expect(policy.readsFirestore, false);
    expect(policy.writesFirestore, false);
    expect(policy.writesBusinessData, false);
    expect(policy.activatesProduction, false);
  });
}

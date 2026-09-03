import 'package:flutter_test/flutter_test.dart';
import 'package:swat_ride/ai_agent/constants/agent_provider_backend_handoff_accounting_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_provider_expansion_contract_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_trusted_backend_handoff.dart';
import 'package:swat_ride/ai_agent/models/agent_provider_usage_event.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_trusted_backend_handoff_policy.dart';
import 'package:swat_ride/ai_agent/services/agent_provider_usage_accounting_boundary_policy.dart';

void main() {
  const hp = AgentProviderTrustedBackendHandoffPolicy();
  const ap = AgentProviderUsageAccountingBoundaryPolicy();

  AgentProviderTrustedBackendHandoff handoff({
    String tier = AgentProviderExpansionTier.freeOnline,
    bool backend = true,
    bool enabled = true,
    bool secretResolved = true,
    bool paidEnabled = false,
    bool budgetAllowed = false,
    bool approval = false,
    double maxCost = 0,
    double estimate = 0,
  }) => AgentProviderTrustedBackendHandoff(
    handoffId: 'handoff:001',
    idempotencyKey: 'idem:001',
    requestId: 'request:001',
    providerId: tier == AgentProviderExpansionTier.paidLastEscalation
        ? 'provider:paid:a'
        : 'provider:free:a',
    modelReference: 'model_ref:a',
    taskType: 'GENERAL_REASONING',
    providerTier: tier,
    privacyProjectionRef: 'privacy_ref:001',
    taskRouteDecisionRef: 'task_ref:001',
    resilientRouteDecisionRef: 'route_ref:001',
    backendExecution: backend,
    providerEnabled: enabled,
    secretReferenceResolvedByBackend: secretResolved,
    paidAiEnabled: paidEnabled,
    askBeforePaid: true,
    paidApprovalGranted: approval,
    budgetAllowed: budgetAllowed,
    authorizedMaxCostRs: maxCost,
    estimatedCostRs: estimate,
  );

  AgentProviderUsageEvent usage({
    String tier = AgentProviderExpansionTier.freeOnline,
    String outcome = AgentProviderUsageOutcome.success,
    bool trusted = true,
    double actual = 0,
    double maxCost = 0,
  }) => AgentProviderUsageEvent(
    eventId: 'event:001',
    idempotencyKey: 'idem:event:001',
    handoffId: 'handoff:001',
    providerId: tier == AgentProviderExpansionTier.paidLastEscalation
        ? 'provider:paid:a'
        : 'provider:free:a',
    modelReference: 'model_ref:a',
    providerTier: tier,
    outcome: outcome,
    trustedBackendObserved: trusted,
    inputTokens: 1000,
    outputTokens: 300,
    actualCostRs: actual,
    authorizedMaxCostRs: maxCost,
  );

  group('Phase 58 Step 1F', () {
    test(
      'handoff statuses locked',
      () => expect(AgentProviderBackendHandoffStatus.values.length, 5),
    );
    test(
      'usage outcomes locked',
      () => expect(AgentProviderUsageOutcome.values.length, 6),
    );
    test(
      'accounting statuses locked',
      () => expect(AgentProviderUsageAccountingStatus.values.length, 6),
    );

    test('free handoff eligible at zero billable cost', () {
      expect(
        hp.evaluate(handoff()),
        AgentProviderBackendHandoffStatus.eligible,
      );
    });
    test('client handoff blocked', () {
      expect(
        hp.evaluate(handoff(backend: false)),
        AgentProviderBackendHandoffStatus.backend,
      );
    });
    test('unresolved secret ref blocked', () {
      expect(
        hp.evaluate(handoff(secretResolved: false)),
        AgentProviderBackendHandoffStatus.backend,
      );
    });
    test('free billable cost authorization blocked', () {
      expect(
        hp.evaluate(handoff(maxCost: 1, estimate: 1)),
        AgentProviderBackendHandoffStatus.cost,
      );
    });
    test('paid disabled blocked', () {
      expect(
        hp.evaluate(
          handoff(
            tier: AgentProviderExpansionTier.paidLastEscalation,
            paidEnabled: false,
            budgetAllowed: true,
            approval: true,
            maxCost: 10,
            estimate: 5,
          ),
        ),
        AgentProviderBackendHandoffStatus.paid,
      );
    });
    test('paid budget blocked', () {
      expect(
        hp.evaluate(
          handoff(
            tier: AgentProviderExpansionTier.paidLastEscalation,
            paidEnabled: true,
            budgetAllowed: false,
            approval: true,
            maxCost: 10,
            estimate: 5,
          ),
        ),
        AgentProviderBackendHandoffStatus.paid,
      );
    });
    test('ask before paid blocks without approval', () {
      expect(
        hp.evaluate(
          handoff(
            tier: AgentProviderExpansionTier.paidLastEscalation,
            paidEnabled: true,
            budgetAllowed: true,
            approval: false,
            maxCost: 10,
            estimate: 5,
          ),
        ),
        AgentProviderBackendHandoffStatus.paid,
      );
    });
    test('paid estimate above ceiling blocked', () {
      expect(
        hp.evaluate(
          handoff(
            tier: AgentProviderExpansionTier.paidLastEscalation,
            paidEnabled: true,
            budgetAllowed: true,
            approval: true,
            maxCost: 10,
            estimate: 11,
          ),
        ),
        AgentProviderBackendHandoffStatus.cost,
      );
    });
    test('paid eligible only after controls', () {
      expect(
        hp.evaluate(
          handoff(
            tier: AgentProviderExpansionTier.paidLastEscalation,
            paidEnabled: true,
            budgetAllowed: true,
            approval: true,
            maxCost: 10,
            estimate: 5,
          ),
        ),
        AgentProviderBackendHandoffStatus.eligible,
      );
    });

    test('handoff contains no raw/provider authority', () {
      final h = handoff();
      expect(h.containsRawPrompt, false);
      expect(h.containsRawConversation, false);
      expect(h.containsRawProviderResponse, false);
      expect(h.containsRawSecret, false);
      expect(h.invokesProvider, false);
      expect(h.chargesCost, false);
      expect(h.mutatesBudget, false);
      expect(h.persistsHandoff, false);
      expect(h.grantsPermission, false);
      expect(h.consumesApproval, false);
      expect(h.executesBusinessAction, false);
    });

    test('handoff policy locks paid/cost boundaries', () {
      expect(hp.trustedBackendExecutionRequired, true);
      expect(hp.idempotencyRequired, true);
      expect(hp.paidAiOnOffPreserved, true);
      expect(hp.askBeforePaidPreserved, true);
      expect(hp.budgetAuthorizationRequired, true);
      expect(hp.freeLocalBillableProviderCostAuthorizationForbidden, true);
      expect(hp.providerInvocationImplementedHere, false);
      expect(hp.costChargingImplementedHere, false);
      expect(hp.budgetMutationImplementedHere, false);
      expect(hp.persistenceImplementedHere, false);
    });

    test('trusted free usage produces safe cost log', () {
      final d = ap.evaluate(event: usage(), duplicateAccountingDetected: false);
      expect(d.eligible, true);
      expect(d.costLogProjection, isNotNull);
      expect(d.costOverrun, false);
    });
    test('untrusted usage blocked', () {
      final d = ap.evaluate(
        event: usage(trusted: false),
        duplicateAccountingDetected: false,
      );
      expect(d.status, AgentProviderUsageAccountingStatus.untrusted);
    });
    test('duplicate accounting blocked', () {
      final d = ap.evaluate(event: usage(), duplicateAccountingDetected: true);
      expect(d.status, AgentProviderUsageAccountingStatus.duplicate);
    });
    test('free nonzero provider cost blocked', () {
      final d = ap.evaluate(
        event: usage(actual: 1),
        duplicateAccountingDetected: false,
      );
      expect(d.status, AgentProviderUsageAccountingStatus.tierCost);
    });
    test('paid usage within ceiling eligible', () {
      final d = ap.evaluate(
        event: usage(
          tier: AgentProviderExpansionTier.paidLastEscalation,
          actual: 7,
          maxCost: 10,
        ),
        duplicateAccountingDetected: false,
      );
      expect(d.eligible, true);
      expect(d.costOverrun, false);
      expect(d.costLogProjection!.allowFurtherPaidUsage, true);
    });
    test('paid overrun logged and review required', () {
      final d = ap.evaluate(
        event: usage(
          tier: AgentProviderExpansionTier.paidLastEscalation,
          actual: 12,
          maxCost: 10,
        ),
        duplicateAccountingDetected: false,
      );
      expect(d.status, AgentProviderUsageAccountingStatus.overrun);
      expect(d.costOverrun, true);
      expect(d.requiresOwnerReview, true);
      expect(d.costLogProjection!.allowFurtherPaidUsage, false);
      expect(d.costLogProjection!.automaticBudgetIncreaseAllowed, false);
      expect(d.costLogProjection!.automaticPaidEnableAllowed, false);
      expect(d.costLogProjection!.automaticCostLimitOverrideAllowed, false);
    });
    test('failure/timeout/rate-limit outcomes remain accountable', () {
      for (final outcome in <String>[
        AgentProviderUsageOutcome.providerFailure,
        AgentProviderUsageOutcome.timeout,
        AgentProviderUsageOutcome.rateLimited,
      ]) {
        final d = ap.evaluate(
          event: usage(
            tier: AgentProviderExpansionTier.paidLastEscalation,
            outcome: outcome,
            actual: 1,
            maxCost: 10,
          ),
          duplicateAccountingDetected: false,
        );
        expect(d.eligible, true, reason: outcome);
      }
    });
    test('cost log excludes raw payload and cannot mutate budget', () {
      final p = ap
          .evaluate(event: usage(), duplicateAccountingDetected: false)
          .costLogProjection!;
      expect(p.metadataOnly, true);
      expect(p.containsRawPrompt, false);
      expect(p.containsRawConversation, false);
      expect(p.containsRawProviderResponse, false);
      expect(p.containsPrivatePayload, false);
      expect(p.automaticBudgetIncreaseAllowed, false);
      expect(p.automaticPaidEnableAllowed, false);
      expect(p.invokesProvider, false);
      expect(p.mutatesBudget, false);
      expect(p.persistsCostLog, false);
      expect(p.executesBusinessAction, false);
    });
    test(
      'accounting policy locks failure isolation and no auto budget changes',
      () {
        expect(ap.trustedBackendObservationRequired, true);
        expect(ap.idempotencyPreventsDoubleCounting, true);
        expect(ap.rawPromptExcluded, true);
        expect(ap.rawConversationExcluded, true);
        expect(ap.rawProviderResponseExcluded, true);
        expect(ap.failuresTimeoutsRateLimitsStillAccountable, true);
        expect(ap.costOverrunStillLogged, true);
        expect(ap.costOverrunRequiresOwnerReview, true);
        expect(ap.costOverrunStopsAutomaticFurtherPaidUsage, true);
        expect(ap.automaticBudgetIncreaseAllowed, false);
        expect(ap.automaticPaidEnableAllowed, false);
        expect(ap.automaticCostLimitOverrideAllowed, false);
        expect(ap.coreAppContinuesOnProviderAccountingFailure, true);
        expect(ap.persistenceImplementedHere, false);
        expect(ap.providerInvocationImplementedHere, false);
        expect(ap.budgetMutationImplementedHere, false);
        expect(ap.executesBusinessAction, false);
      },
    );
    test('Phase59 quality evaluator remains separate', () {
      expect(ap.providerQualityEvaluationOwnedHere, false);
      expect(ap.phase59OwnsProviderQualityEvaluator, true);
    });
  });
}

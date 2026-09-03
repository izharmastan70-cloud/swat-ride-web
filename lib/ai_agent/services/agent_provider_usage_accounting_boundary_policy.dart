import '../constants/agent_provider_backend_handoff_accounting_constants.dart';
import '../models/agent_provider_cost_log_projection.dart';
import '../models/agent_provider_usage_accounting_decision.dart';
import '../models/agent_provider_usage_event.dart';

class AgentProviderUsageAccountingBoundaryPolicy {
  const AgentProviderUsageAccountingBoundaryPolicy();

  AgentProviderUsageAccountingDecision evaluate({
    required AgentProviderUsageEvent event,
    required bool duplicateAccountingDetected,
  }) {
    try {
      event.validateStructure();
    } catch (_) {
      return _blocked(
        AgentProviderUsageAccountingStatus.invalid,
        event.eventId,
        const <String>['invalid_usage_metadata', 'fail_closed'],
      );
    }
    if (!event.trustedBackendObserved) {
      return _blocked(
        AgentProviderUsageAccountingStatus.untrusted,
        event.eventId,
        const <String>['trusted_backend_observation_required'],
      );
    }
    if (duplicateAccountingDetected) {
      return _blocked(
        AgentProviderUsageAccountingStatus.duplicate,
        event.eventId,
        const <String>['idempotency_prevents_double_counting'],
      );
    }
    if (!event.paidTier && event.actualCostRs != 0) {
      return _blocked(
        AgentProviderUsageAccountingStatus.tierCost,
        event.eventId,
        const <String>['free_local_billable_cost_must_be_zero'],
      );
    }

    final over =
        event.paidTier && event.actualCostRs > event.authorizedMaxCostRs;
    final projection = AgentProviderCostLogProjection(
      eventId: event.eventId,
      idempotencyKey: event.idempotencyKey,
      handoffId: event.handoffId,
      providerId: event.providerId,
      modelReference: event.modelReference,
      providerTier: event.providerTier,
      outcome: event.outcome,
      inputTokens: event.inputTokens,
      outputTokens: event.outputTokens,
      actualCostRs: event.actualCostRs,
      authorizedMaxCostRs: event.authorizedMaxCostRs,
      costOverrun: over,
      requiresOwnerReview: over,
      allowFurtherPaidUsage: !over,
    );

    final decision = AgentProviderUsageAccountingDecision(
      status: over
          ? AgentProviderUsageAccountingStatus.overrun
          : AgentProviderUsageAccountingStatus.eligible,
      eventId: event.eventId,
      costLogProjection: projection,
      reasonCodes: <String>[
        'trusted_backend_usage_observed',
        'metadata_only',
        if (event.outcome != AgentProviderUsageOutcome.success)
          'failure_outcome_still_accountable',
        if (over) 'cost_overrun_requires_owner_review',
        'no_budget_mutation_here',
      ],
    );
    decision.validateStructure();
    return decision;
  }

  AgentProviderUsageAccountingDecision _blocked(
    String status,
    String id,
    List<String> reasons,
  ) {
    final d = AgentProviderUsageAccountingDecision(
      status: status,
      eventId: id.trim().isEmpty ? 'invalid_provider_usage_event' : id,
      costLogProjection: null,
      reasonCodes: reasons,
    );
    d.validateStructure();
    return d;
  }

  bool get trustedBackendObservationRequired => true;
  bool get idempotencyPreventsDoubleCounting => true;
  bool get rawPromptExcluded => true;
  bool get rawConversationExcluded => true;
  bool get rawProviderResponseExcluded => true;
  bool get failuresTimeoutsRateLimitsStillAccountable => true;
  bool get costOverrunStillLogged => true;
  bool get costOverrunRequiresOwnerReview => true;
  bool get costOverrunStopsAutomaticFurtherPaidUsage => true;
  bool get automaticBudgetIncreaseAllowed => false;
  bool get automaticPaidEnableAllowed => false;
  bool get automaticCostLimitOverrideAllowed => false;
  bool get coreAppContinuesOnProviderAccountingFailure => true;
  bool get persistenceImplementedHere => false;
  bool get providerInvocationImplementedHere => false;
  bool get budgetMutationImplementedHere => false;
  bool get providerQualityEvaluationOwnedHere => false;
  bool get phase59OwnsProviderQualityEvaluator => true;
  bool get executesBusinessAction => false;
}

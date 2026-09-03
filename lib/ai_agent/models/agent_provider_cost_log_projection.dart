class AgentProviderCostLogProjection {
  const AgentProviderCostLogProjection({
    required this.eventId,
    required this.idempotencyKey,
    required this.handoffId,
    required this.providerId,
    required this.modelReference,
    required this.providerTier,
    required this.outcome,
    required this.inputTokens,
    required this.outputTokens,
    required this.actualCostRs,
    required this.authorizedMaxCostRs,
    required this.costOverrun,
    required this.requiresOwnerReview,
    required this.allowFurtherPaidUsage,
  });

  final String eventId,
      idempotencyKey,
      handoffId,
      providerId,
      modelReference,
      providerTier,
      outcome;
  final int inputTokens, outputTokens;
  final double actualCostRs, authorizedMaxCostRs;
  final bool costOverrun, requiresOwnerReview, allowFurtherPaidUsage;

  bool get metadataOnly => true;
  bool get containsRawPrompt => false;
  bool get containsRawConversation => false;
  bool get containsRawProviderResponse => false;
  bool get containsPrivatePayload => false;
  bool get automaticBudgetIncreaseAllowed => false;
  bool get automaticPaidEnableAllowed => false;
  bool get automaticCostLimitOverrideAllowed => false;
  bool get invokesProvider => false;
  bool get mutatesBudget => false;
  bool get persistsCostLog => false;
  bool get executesBusinessAction => false;
}

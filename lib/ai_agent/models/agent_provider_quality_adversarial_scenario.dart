class AgentProviderQualityAdversarialScenario {
  const AgentProviderQualityAdversarialScenario({
    required this.scenarioId,
    this.forgedProvenance = false,
    this.duplicateEvidenceReplay = false,
    this.poisoningAttempt = false,
    this.hardSafetySuppressionAttempt = false,
    this.crossTierRankingAttempt = false,
    this.paidControlBypassAttempt = false,
    this.privacyBypassAttempt = false,
    this.capabilityBypassAttempt = false,
    this.circuitBypassAttempt = false,
    this.backendBoundaryBypassAttempt = false,
    this.directProviderInvocationAttempt = false,
    this.automaticRoutingMutationAttempt = false,
    this.providerStateMutationAttempt = false,
    this.budgetMutationAttempt = false,
    this.secretMutationAttempt = false,
    this.modelDeploymentAttempt = false,
    this.permissionAuthorityAttempt = false,
    this.approvalAuthorityAttempt = false,
    this.businessActionAttempt = false,
  });

  final String scenarioId;

  final bool forgedProvenance;
  final bool duplicateEvidenceReplay;
  final bool poisoningAttempt;
  final bool hardSafetySuppressionAttempt;
  final bool crossTierRankingAttempt;
  final bool paidControlBypassAttempt;
  final bool privacyBypassAttempt;
  final bool capabilityBypassAttempt;
  final bool circuitBypassAttempt;
  final bool backendBoundaryBypassAttempt;

  final bool directProviderInvocationAttempt;
  final bool automaticRoutingMutationAttempt;
  final bool providerStateMutationAttempt;
  final bool budgetMutationAttempt;
  final bool secretMutationAttempt;
  final bool modelDeploymentAttempt;

  final bool permissionAuthorityAttempt;
  final bool approvalAuthorityAttempt;
  final bool businessActionAttempt;

  bool get hasAttackAttempt =>
      forgedProvenance ||
      duplicateEvidenceReplay ||
      poisoningAttempt ||
      hardSafetySuppressionAttempt ||
      crossTierRankingAttempt ||
      paidControlBypassAttempt ||
      privacyBypassAttempt ||
      capabilityBypassAttempt ||
      circuitBypassAttempt ||
      backendBoundaryBypassAttempt ||
      directProviderInvocationAttempt ||
      automaticRoutingMutationAttempt ||
      providerStateMutationAttempt ||
      budgetMutationAttempt ||
      secretMutationAttempt ||
      modelDeploymentAttempt ||
      permissionAuthorityAttempt ||
      approvalAuthorityAttempt ||
      businessActionAttempt;

  void validateStructure() {
    final String trimmed = scenarioId.trim();

    if (trimmed.isEmpty ||
        trimmed.length > 220 ||
        !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(trimmed)) {
      throw const FormatException(
        'Invalid provider quality adversarial scenario.',
      );
    }
  }
}

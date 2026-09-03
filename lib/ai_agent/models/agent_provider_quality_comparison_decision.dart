import '../constants/agent_provider_quality_comparison_constants.dart';

class AgentProviderQualityComparisonDecision {
  AgentProviderQualityComparisonDecision({
    required this.status,
    required this.taskType,
    required this.providerTier,
    required this.preferredProviderId,
    required this.preferredModelReference,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status;
  final String taskType;
  final String providerTier;
  final String? preferredProviderId;
  final String? preferredModelReference;
  final List<String> reasonCodes;

  bool get hasPreferredCandidate =>
      preferredProviderId != null && preferredModelReference != null;

  bool get recommendationMetadataOnly => true;
  bool get tierPreserving => true;

  bool get mayCompareAcrossTiers => false;
  bool get mayOverrideFreeLocalPaidOrder => false;
  bool get mayOverridePaidAiOnOff => false;
  bool get mayOverrideAskBeforePaid => false;
  bool get mayOverrideBudgetLimit => false;
  bool get mayOverridePrivacyGate => false;
  bool get mayOverrideCapabilityGate => false;
  bool get mayOverrideCircuitBreaker => false;
  bool get mayOverrideBackendBoundary => false;

  bool get invokesProvider => false;
  bool get mutatesRouting => false;
  bool get enablesProvider => false;
  bool get disablesProvider => false;
  bool get mutatesBudget => false;
  bool get changesSecret => false;
  bool get deploysModel => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;
  bool get persistsDecision => false;

  void validateStructure() {
    if (!AgentProviderQualityComparisonStatus.values.contains(status) ||
        taskType.trim().isEmpty ||
        providerTier.trim().isEmpty ||
        reasonCodes.isEmpty ||
        reasonCodes.length >
            AgentProviderQualityCostTradeoffLimits.maxReasonCodes) {
      throw const FormatException(
        'Invalid provider quality comparison decision.',
      );
    }

    final bool preferredStatus =
        status == AgentProviderQualityComparisonStatus.preferredWithinTier;

    if (preferredStatus != hasPreferredCandidate) {
      throw const FormatException('Preferred status/candidate mismatch.');
    }
  }
}

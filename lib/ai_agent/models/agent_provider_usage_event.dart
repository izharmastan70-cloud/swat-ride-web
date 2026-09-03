import '../constants/agent_provider_backend_handoff_accounting_constants.dart';
import '../constants/agent_provider_expansion_contract_constants.dart';

class AgentProviderUsageEvent {
  const AgentProviderUsageEvent({
    required this.eventId,
    required this.idempotencyKey,
    required this.handoffId,
    required this.providerId,
    required this.modelReference,
    required this.providerTier,
    required this.outcome,
    required this.trustedBackendObserved,
    required this.inputTokens,
    required this.outputTokens,
    required this.actualCostRs,
    required this.authorizedMaxCostRs,
  });

  final String eventId,
      idempotencyKey,
      handoffId,
      providerId,
      modelReference,
      providerTier,
      outcome;
  final bool trustedBackendObserved;
  final int inputTokens, outputTokens;
  final double actualCostRs, authorizedMaxCostRs;

  bool get paidTier =>
      providerTier == AgentProviderExpansionTier.paidLastEscalation;
  bool get containsRawPrompt => false;
  bool get containsRawConversation => false;
  bool get containsRawProviderResponse => false;
  bool get containsPrivatePayload => false;
  bool get invokesProvider => false;
  bool get chargesCostHere => false;
  bool get mutatesBudget => false;
  bool get persistsEvent => false;
  bool get grantsPermission => false;
  bool get executesBusinessAction => false;

  void validateStructure() {
    final ids = <String>[eventId, idempotencyKey, handoffId, providerId];
    final badId = ids.any(
      (v) =>
          v.trim().isEmpty ||
          v.length > AgentProviderBackendAccountingLimits.idMax ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(v),
    );
    if (badId ||
        modelReference.trim().isEmpty ||
        !AgentProviderExpansionTier.values.contains(providerTier) ||
        !AgentProviderUsageOutcome.values.contains(outcome) ||
        inputTokens < 0 ||
        outputTokens < 0 ||
        inputTokens > AgentProviderBackendAccountingLimits.absoluteMaxTokens ||
        outputTokens > AgentProviderBackendAccountingLimits.absoluteMaxTokens ||
        !actualCostRs.isFinite ||
        !authorizedMaxCostRs.isFinite ||
        actualCostRs < 0 ||
        authorizedMaxCostRs < 0) {
      throw const FormatException('Invalid provider usage event.');
    }
  }
}

import '../constants/agent_provider_backend_handoff_accounting_constants.dart';
import 'agent_provider_cost_log_projection.dart';

class AgentProviderUsageAccountingDecision {
  AgentProviderUsageAccountingDecision({
    required this.status,
    required this.eventId,
    required this.costLogProjection,
    required List<String> reasonCodes,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String status, eventId;
  final AgentProviderCostLogProjection? costLogProjection;
  final List<String> reasonCodes;

  bool get eligible =>
      status == AgentProviderUsageAccountingStatus.eligible ||
      status == AgentProviderUsageAccountingStatus.overrun;
  bool get costOverrun => costLogProjection?.costOverrun ?? false;
  bool get requiresOwnerReview =>
      costLogProjection?.requiresOwnerReview ?? false;
  bool get policyDecisionOnly => true;
  bool get writesCostLogHere => false;
  bool get invokesProvider => false;
  bool get mutatesBudget => false;
  bool get automaticBudgetIncreaseAllowed => false;
  bool get automaticPaidEnableAllowed => false;
  bool get executesBusinessAction => false;

  void validateStructure() {
    if (!AgentProviderUsageAccountingStatus.values.contains(status) ||
        eventId.trim().isEmpty ||
        reasonCodes.isEmpty ||
        reasonCodes.length >
            AgentProviderBackendAccountingLimits.maxReasonCodes ||
        (eligible && costLogProjection == null) ||
        (!eligible && costLogProjection != null)) {
      throw const FormatException('Invalid accounting decision.');
    }
  }
}

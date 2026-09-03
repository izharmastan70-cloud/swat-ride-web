import '../constants/agent_provider_backend_handoff_accounting_constants.dart';
import '../constants/agent_provider_expansion_contract_constants.dart';
import '../models/agent_provider_trusted_backend_handoff.dart';

class AgentProviderTrustedBackendHandoffPolicy {
  const AgentProviderTrustedBackendHandoffPolicy();

  String evaluate(AgentProviderTrustedBackendHandoff h) {
    try {
      h.validateStructure();
    } catch (_) {
      return AgentProviderBackendHandoffStatus.invalid;
    }
    if (!h.backendExecution ||
        !h.providerEnabled ||
        !h.secretReferenceResolvedByBackend) {
      return AgentProviderBackendHandoffStatus.backend;
    }
    if (h.paidTier) {
      if (!h.paidAiEnabled ||
          !h.budgetAllowed ||
          (h.askBeforePaid && !h.paidApprovalGranted)) {
        return AgentProviderBackendHandoffStatus.paid;
      }
      if (h.authorizedMaxCostRs <= 0 ||
          h.estimatedCostRs > h.authorizedMaxCostRs) {
        return AgentProviderBackendHandoffStatus.cost;
      }
    } else {
      if (h.providerTier != AgentProviderExpansionTier.freeOnline &&
          h.providerTier != AgentProviderExpansionTier.localOptional) {
        return AgentProviderBackendHandoffStatus.invalid;
      }
      if (h.authorizedMaxCostRs != 0 || h.estimatedCostRs != 0) {
        return AgentProviderBackendHandoffStatus.cost;
      }
    }
    return AgentProviderBackendHandoffStatus.eligible;
  }

  bool get trustedBackendExecutionRequired => true;
  bool get idempotencyRequired => true;
  bool get paidAiOnOffPreserved => true;
  bool get askBeforePaidPreserved => true;
  bool get budgetAuthorizationRequired => true;
  bool get freeLocalBillableProviderCostAuthorizationForbidden => true;
  bool get providerInvocationImplementedHere => false;
  bool get costChargingImplementedHere => false;
  bool get budgetMutationImplementedHere => false;
  bool get persistenceImplementedHere => false;
  bool get executesBusinessAction => false;
}

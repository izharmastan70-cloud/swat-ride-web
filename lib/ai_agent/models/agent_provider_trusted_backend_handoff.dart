import '../constants/agent_provider_backend_handoff_accounting_constants.dart';
import '../constants/agent_provider_expansion_contract_constants.dart';

class AgentProviderTrustedBackendHandoff {
  const AgentProviderTrustedBackendHandoff({
    required this.handoffId,
    required this.idempotencyKey,
    required this.requestId,
    required this.providerId,
    required this.modelReference,
    required this.taskType,
    required this.providerTier,
    required this.privacyProjectionRef,
    required this.taskRouteDecisionRef,
    required this.resilientRouteDecisionRef,
    required this.backendExecution,
    required this.providerEnabled,
    required this.secretReferenceResolvedByBackend,
    required this.paidAiEnabled,
    required this.askBeforePaid,
    required this.paidApprovalGranted,
    required this.budgetAllowed,
    required this.authorizedMaxCostRs,
    required this.estimatedCostRs,
  });

  final String handoffId,
      idempotencyKey,
      requestId,
      providerId,
      modelReference,
      taskType;
  final String providerTier,
      privacyProjectionRef,
      taskRouteDecisionRef,
      resilientRouteDecisionRef;
  final bool backendExecution,
      providerEnabled,
      secretReferenceResolvedByBackend;
  final bool paidAiEnabled, askBeforePaid, paidApprovalGranted, budgetAllowed;
  final double authorizedMaxCostRs, estimatedCostRs;

  bool get paidTier =>
      providerTier == AgentProviderExpansionTier.paidLastEscalation;
  bool get containsRawPrompt => false;
  bool get containsRawConversation => false;
  bool get containsRawProviderResponse => false;
  bool get containsRawSecret => false;
  bool get invokesProvider => false;
  bool get chargesCost => false;
  bool get mutatesBudget => false;
  bool get persistsHandoff => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get executesBusinessAction => false;

  void validateStructure() {
    final ids = <String>[
      handoffId,
      idempotencyKey,
      requestId,
      providerId,
      privacyProjectionRef,
      taskRouteDecisionRef,
      resilientRouteDecisionRef,
    ];
    final badId = ids.any(
      (v) =>
          v.trim().isEmpty ||
          v.length > AgentProviderBackendAccountingLimits.idMax ||
          !RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(v),
    );
    if (badId ||
        modelReference.trim().isEmpty ||
        modelReference.length >
            AgentProviderBackendAccountingLimits.modelRefMax ||
        taskType.trim().isEmpty ||
        !AgentProviderExpansionTier.values.contains(providerTier) ||
        !authorizedMaxCostRs.isFinite ||
        !estimatedCostRs.isFinite ||
        authorizedMaxCostRs < 0 ||
        estimatedCostRs < 0 ||
        authorizedMaxCostRs >
            AgentProviderBackendAccountingLimits.absoluteMaxProviderCostRs ||
        estimatedCostRs >
            AgentProviderBackendAccountingLimits.absoluteMaxProviderCostRs) {
      throw const FormatException('Invalid trusted backend handoff.');
    }
  }
}

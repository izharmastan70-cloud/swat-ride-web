import '../constants/agent_ecosystem_financial_safety_constants.dart';

class AgentEcosystemFinancialSafetyDecision {
  AgentEcosystemFinancialSafetyDecision({
    required this.status,
    required this.routeTo,
    required this.reasonCode,
    required this.auditRequired,
    required this.existingCompletionReferenceOnly,
  }) {
    validate();
  }

  final String status;
  final String routeTo;
  final String reasonCode;

  final bool auditRequired;

  /// True only when a verified duplicate completion exists. The authoritative
  /// backend may reference its prior receipt/result; no second money action is
  /// permitted by this contract.
  final bool existingCompletionReferenceOnly;

  bool get failClosed =>
      status !=
      AgentEcosystemFinancialDecisionStatus.eligibleControlledFinancialHandoff;

  bool get mayExecutePayment => false;
  bool get mayExecuteRefund => false;
  bool get mayDebitWallet => false;
  bool get mayCreditWallet => false;
  bool get mayExecutePayout => false;
  bool get mayApproveWithdrawal => false;
  bool get maySettleCommission => false;

  bool get mayReserveIdempotencyKey => false;
  bool get mayMarkCompletion => false;
  bool get mayConsumeApproval => false;
  bool get mayGrantPermission => false;
  bool get mayOverrideRuntimeGate => false;
  bool get mayDisableEmergencyStop => false;
  bool get mayEnableModule => false;
  bool get mayCallPaymentProvider => false;
  bool get mayReadFirestore => false;
  bool get mayWriteFirestore => false;
  bool get mayWriteBusinessData => false;
  bool get mayActivateProduction => false;

  void validate() {
    if (!AgentEcosystemFinancialDecisionStatus.values.contains(status) ||
        routeTo.trim().isEmpty ||
        reasonCode.trim().isEmpty ||
        (existingCompletionReferenceOnly &&
            status !=
                AgentEcosystemFinancialDecisionStatus
                    .blockDuplicateCompleted)) {
      throw const FormatException(
        'Invalid ecosystem financial safety decision.',
      );
    }
  }
}

class AgentEcosystemFinancialActionType {
  AgentEcosystemFinancialActionType._();

  static const String paymentCapture = 'PAYMENT_CAPTURE';
  static const String refund = 'REFUND';
  static const String walletDebit = 'WALLET_DEBIT';
  static const String walletCredit = 'WALLET_CREDIT';
  static const String payout = 'PAYOUT';
  static const String withdrawal = 'WITHDRAWAL';
  static const String commissionSettlement = 'COMMISSION_SETTLEMENT';

  static const Set<String> values = <String>{
    paymentCapture,
    refund,
    walletDebit,
    walletCredit,
    payout,
    withdrawal,
    commissionSettlement,
  };
}

class AgentEcosystemFinancialDecisionStatus {
  AgentEcosystemFinancialDecisionStatus._();

  static const String blockEmergencyStop = 'BLOCK_EMERGENCY_STOP';
  static const String blockModuleDisabled = 'BLOCK_MODULE_DISABLED';
  static const String blockUntrustedIdentity = 'BLOCK_UNTRUSTED_IDENTITY';
  static const String blockPermissionDenied = 'BLOCK_PERMISSION_DENIED';
  static const String blockApprovalRequired = 'BLOCK_APPROVAL_REQUIRED';
  static const String blockApprovalExpired = 'BLOCK_APPROVAL_EXPIRED';
  static const String blockApprovalBindingMismatch =
      'BLOCK_APPROVAL_BINDING_MISMATCH';
  static const String blockRuntimeGate = 'BLOCK_RUNTIME_GATE';
  static const String blockIdempotencyMissing = 'BLOCK_IDEMPOTENCY_MISSING';
  static const String blockReservationMissing = 'BLOCK_RESERVATION_MISSING';
  static const String blockReservationBindingMismatch =
      'BLOCK_RESERVATION_BINDING_MISMATCH';
  static const String blockOperationBindingMismatch =
      'BLOCK_OPERATION_BINDING_MISMATCH';
  static const String blockCallbackReplay = 'BLOCK_CALLBACK_REPLAY';
  static const String blockDuplicateCompleted = 'BLOCK_DUPLICATE_COMPLETED';
  static const String blockDuplicateBindingCollision =
      'BLOCK_DUPLICATE_BINDING_COLLISION';
  static const String blockAuditUnavailable = 'BLOCK_AUDIT_UNAVAILABLE';
  static const String eligibleControlledFinancialHandoff =
      'ELIGIBLE_CONTROLLED_FINANCIAL_HANDOFF';

  static const Set<String> values = <String>{
    blockEmergencyStop,
    blockModuleDisabled,
    blockUntrustedIdentity,
    blockPermissionDenied,
    blockApprovalRequired,
    blockApprovalExpired,
    blockApprovalBindingMismatch,
    blockRuntimeGate,
    blockIdempotencyMissing,
    blockReservationMissing,
    blockReservationBindingMismatch,
    blockOperationBindingMismatch,
    blockCallbackReplay,
    blockDuplicateCompleted,
    blockDuplicateBindingCollision,
    blockAuditUnavailable,
    eligibleControlledFinancialHandoff,
  };
}

class AgentEcosystemFinancialRoute {
  AgentEcosystemFinancialRoute._();

  static const String blocked = 'BLOCKED';
  static const String trustedIdentityGate = 'TRUSTED_IDENTITY_GATE';
  static const String permissionGate = 'PERMISSION_GATE';
  static const String approvalGate = 'APPROVAL_GATE';
  static const String runtimeGate = 'RUNTIME_GATE';
  static const String idempotencyGate = 'IDEMPOTENCY_GATE';
  static const String duplicateReview = 'DUPLICATE_REVIEW';
  static const String auditGate = 'AUDIT_GATE';
  static const String controlledFinancialHandoff =
      'CONTROLLED_FINANCIAL_HANDOFF';
}

class AgentEcosystemFinancialLimits {
  AgentEcosystemFinancialLimits._();

  static const int idempotencyKeyMaxLength = 200;
  static const int sha256HexLength = 64;
  static const int currencyLength = 3;
}

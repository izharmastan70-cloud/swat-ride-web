class AgentFutureProposalStatus {
  AgentFutureProposalStatus._();

  static const String draft = 'DRAFT';
  static const String awaitingReview = 'AWAITING_REVIEW';
  static const String needsEdit = 'NEEDS_EDIT';
  static const String approved = 'APPROVED';
  static const String rejected = 'REJECTED';

  static const String handedToCodeAgent = 'HANDED_TO_CODE_AGENT';
  static const String codeChangePrepared = 'CODE_CHANGE_PREPARED';

  static const String qaPending = 'QA_PENDING';
  static const String qaPassed = 'QA_PASSED';
  static const String qaFailed = 'QA_FAILED';

  static const String securityPending = 'SECURITY_PENDING';
  static const String securityPassed = 'SECURITY_PASSED';
  static const String securityRejected = 'SECURITY_REJECTED';

  static const String ownerDecisionPending = 'OWNER_DECISION_PENDING';
  static const String kept = 'KEPT';
  static const String rollbackRequested = 'ROLLBACK_REQUESTED';
  static const String rolledBack = 'ROLLED_BACK';

  static const Set<String> values = <String>{
    draft,
    awaitingReview,
    needsEdit,
    approved,
    rejected,
    handedToCodeAgent,
    codeChangePrepared,
    qaPending,
    qaPassed,
    qaFailed,
    securityPending,
    securityPassed,
    securityRejected,
    ownerDecisionPending,
    kept,
    rollbackRequested,
    rolledBack,
  };

  static bool isValid(String value) => values.contains(value);

  static bool isTerminal(String value) =>
      value == rejected || value == kept || value == rolledBack;
}

class AgentFutureProposalRisk {
  AgentFutureProposalRisk._();

  static const String low = 'LOW';
  static const String medium = 'MEDIUM';
  static const String high = 'HIGH';
  static const String critical = 'CRITICAL';

  static const Set<String> values = <String>{low, medium, high, critical};

  static bool isValid(String value) => values.contains(value);
}

class AgentFutureProposalComplexity {
  AgentFutureProposalComplexity._();

  static const String small = 'SMALL';
  static const String medium = 'MEDIUM';
  static const String large = 'LARGE';
  static const String veryLarge = 'VERY_LARGE';

  static const Set<String> values = <String>{small, medium, large, veryLarge};

  static bool isValid(String value) => values.contains(value);
}

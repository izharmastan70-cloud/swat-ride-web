class AgentOwnerAttentionSourceKind {
  AgentOwnerAttentionSourceKind._();

  static const String seriousComplaint = 'SERIOUS_COMPLAINT';
  static const String highValuePaymentDispute = 'HIGH_VALUE_PAYMENT_DISPUTE';
  static const String unresolvedCall = 'UNRESOLVED_CALL';
  static const String securityAlert = 'SECURITY_ALERT';
  static const String agentConflict = 'AGENT_CONFLICT';
  static const String pendingSensitiveApproval = 'PENDING_SENSITIVE_APPROVAL';
  static const String criticalCrash = 'CRITICAL_CRASH';
  static const String fraudFinding = 'FRAUD_FINDING';
  static const String emergencyCase = 'EMERGENCY_CASE';

  static const String emailUnusualReview = 'EMAIL_UNUSUAL_REVIEW';

  static const Set<String> values = <String>{
    seriousComplaint,
    highValuePaymentDispute,
    unresolvedCall,
    securityAlert,
    agentConflict,
    pendingSensitiveApproval,
    criticalCrash,
    fraudFinding,
    emergencyCase,
    emailUnusualReview,
  };
}

class AgentOwnerAttentionIngestionStatus {
  AgentOwnerAttentionIngestionStatus._();

  static const String accepted = 'ACCEPTED';
  static const String blockedDuplicate = 'BLOCKED_DUPLICATE';
  static const String blockedInvalid = 'BLOCKED_INVALID';
  static const String blockedMapping = 'BLOCKED_MAPPING';

  static const Set<String> values = <String>{
    accepted,
    blockedDuplicate,
    blockedInvalid,
    blockedMapping,
  };
}

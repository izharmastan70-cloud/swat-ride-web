class AgentOwnerAttentionCategory {
  AgentOwnerAttentionCategory._();

  static const String seriousComplaint = 'SERIOUS_COMPLAINT';
  static const String highValuePaymentDispute = 'HIGH_VALUE_PAYMENT_DISPUTE';
  static const String unresolvedCall = 'UNRESOLVED_CALL';
  static const String securityAlert = 'SECURITY_ALERT';
  static const String agentConflict = 'AGENT_CONFLICT';
  static const String pendingSensitiveApproval = 'PENDING_SENSITIVE_APPROVAL';
  static const String criticalCrash = 'CRITICAL_CRASH';
  static const String fraudFinding = 'FRAUD_FINDING';
  static const String emergencyCase = 'EMERGENCY_CASE';

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
  };
}

class AgentOwnerAttentionPriority {
  AgentOwnerAttentionPriority._();

  static const String normal = 'NORMAL';
  static const String high = 'HIGH';
  static const String critical = 'CRITICAL';
  static const String emergency = 'EMERGENCY';

  static const Set<String> values = <String>{normal, high, critical, emergency};

  static int rank(String value) {
    switch (value) {
      case normal:
        return 0;
      case high:
        return 1;
      case critical:
        return 2;
      case emergency:
        return 3;
      default:
        return -1;
    }
  }
}

class AgentOwnerAttentionStatus {
  AgentOwnerAttentionStatus._();

  static const String pendingReview = 'PENDING_REVIEW';
  static const String acknowledged = 'ACKNOWLEDGED';
  static const String inReview = 'IN_REVIEW';
  static const String resolved = 'RESOLVED';
  static const String dismissed = 'DISMISSED';

  static const Set<String> values = <String>{
    pendingReview,
    acknowledged,
    inReview,
    resolved,
    dismissed,
  };
}

class AgentOwnerAttentionSourceType {
  AgentOwnerAttentionSourceType._();

  static const String feedback = 'FEEDBACK';
  static const String payment = 'PAYMENT';
  static const String call = 'CALL';
  static const String security = 'SECURITY';
  static const String crossAgentSupervisor = 'CROSS_AGENT_SUPERVISOR';
  static const String approval = 'APPROVAL';
  static const String crash = 'CRASH';
  static const String fraud = 'FRAUD';
  static const String emergency = 'EMERGENCY';
  static const String emailAttention = 'EMAIL_ATTENTION';

  static const Set<String> values = <String>{
    feedback,
    payment,
    call,
    security,
    crossAgentSupervisor,
    approval,
    crash,
    fraud,
    emergency,
    emailAttention,
  };
}

class AgentOwnerAttentionLimits {
  AgentOwnerAttentionLimits._();

  static const int opaqueIdMaxLength = 220;
  static const int safeTitleMaxLength = 140;
  static const int safeSummaryMaxLength = 800;
  static const int reasonCodeMaxLength = 120;
  static const int maxReasonCodes = 20;
  static const int referenceHashLength = 64;
  static const Duration maximumFutureClockSkew = Duration(minutes: 5);
}

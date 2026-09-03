class AgentEvaluationCategory {
  AgentEvaluationCategory._();

  static const String safeAnswer = 'SAFE_ANSWER';
  static const String refusal = 'REFUSAL';
  static const String escalation = 'ESCALATION';
  static const String permission = 'PERMISSION';
  static const String approval = 'APPROVAL';
  static const String privacy = 'PRIVACY';
  static const String security = 'SECURITY';
  static const String providerFallback = 'PROVIDER_FALLBACK';
  static const String toolBoundary = 'TOOL_BOUNDARY';
  static const String hallucinationControl = 'HALLUCINATION_CONTROL';

  static const Set<String> values = <String>{
    safeAnswer,
    refusal,
    escalation,
    permission,
    approval,
    privacy,
    security,
    providerFallback,
    toolBoundary,
    hallucinationControl,
  };
}

class AgentEvaluationRisk {
  AgentEvaluationRisk._();

  static const String low = 'LOW';
  static const String medium = 'MEDIUM';
  static const String high = 'HIGH';
  static const String critical = 'CRITICAL';

  static const Set<String> values = <String>{low, medium, high, critical};
}

class AgentEvaluationExpectedDecision {
  AgentEvaluationExpectedDecision._();

  static const String answerReadOnly = 'ANSWER_READ_ONLY';
  static const String allow = 'ALLOW';
  static const String deny = 'DENY';
  static const String refuse = 'REFUSE';
  static const String escalate = 'ESCALATE';
  static const String askApproval = 'ASK_APPROVAL';
  static const String safeFallback = 'SAFE_FALLBACK';

  static const Set<String> values = <String>{
    answerReadOnly,
    allow,
    deny,
    refuse,
    escalate,
    askApproval,
    safeFallback,
  };
}

class AgentEvaluationResultStatus {
  AgentEvaluationResultStatus._();

  static const String notRun = 'NOT_RUN';
  static const String passed = 'PASSED';
  static const String failed = 'FAILED';
  static const String blocked = 'BLOCKED';

  static const Set<String> values = <String>{notRun, passed, failed, blocked};
}

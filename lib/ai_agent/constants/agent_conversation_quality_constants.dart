class AgentConversationQualityAction {
  AgentConversationQualityAction._();

  static const String answer = 'ANSWER';
  static const String verify = 'VERIFY';
  static const String clarify = 'CLARIFY';
  static const String safeFallback = 'SAFE_FALLBACK';
  static const String escalate = 'ESCALATE';
  static const String refuse = 'REFUSE';

  static const Set<String> values = <String>{
    answer,
    verify,
    clarify,
    safeFallback,
    escalate,
    refuse,
  };
}

class AgentConversationKnowledgeState {
  AgentConversationKnowledgeState._();

  static const String sufficient = 'SUFFICIENT';
  static const String partial = 'PARTIAL';
  static const String missing = 'MISSING';
  static const String conflicting = 'CONFLICTING';
  static const String unverified = 'UNVERIFIED';

  static const Set<String> values = <String>{
    sufficient,
    partial,
    missing,
    conflicting,
    unverified,
  };
}

class AgentConversationRisk {
  AgentConversationRisk._();

  static const String low = 'LOW';
  static const String medium = 'MEDIUM';
  static const String high = 'HIGH';
  static const String critical = 'CRITICAL';

  static const Set<String> values = <String>{low, medium, high, critical};
}

// =========================================================
// AI AGENT — FEEDBACK CONSTANTS
// =========================================================

class AgentFeedbackType {
  AgentFeedbackType._();

  static const String rating = 'RATING';
  static const String review = 'REVIEW';
  static const String complaint = 'COMPLAINT';
  static const String suggestion = 'SUGGESTION';
  static const String bugReport = 'BUG_REPORT';
  static const String featureRequest = 'FEATURE_REQUEST';

  static const Set<String> values = <String>{
    rating,
    review,
    complaint,
    suggestion,
    bugReport,
    featureRequest,
  };

  static bool isValid(String value) => values.contains(value);
}

class AgentFeedbackStatus {
  AgentFeedbackStatus._();

  static const String open = 'OPEN';
  static const String underReview = 'UNDER_REVIEW';
  static const String replied = 'REPLIED';
  static const String escalated = 'ESCALATED';
  static const String resolved = 'RESOLVED';
  static const String rejected = 'REJECTED';

  static const Set<String> values = <String>{
    open,
    underReview,
    replied,
    escalated,
    resolved,
    rejected,
  };

  static bool isValid(String value) => values.contains(value);
}

class AgentFeedbackSentiment {
  AgentFeedbackSentiment._();

  static const String positive = 'POSITIVE';
  static const String neutral = 'NEUTRAL';
  static const String negative = 'NEGATIVE';
  static const String critical = 'CRITICAL';
  static const String unknown = 'UNKNOWN';
}

class AgentFeedbackEscalation {
  AgentFeedbackEscalation._();

  static const String none = 'NONE';
  static const String support = 'SUPPORT';
  static const String manager = 'MANAGER';
  static const String owner = 'OWNER';
  static const String safetyHuman = 'SAFETY_HUMAN';
}

class AgentContentCommentCategory {
  AgentContentCommentCategory._();

  static const String greeting = 'greeting';
  static const String faq = 'faq';
  static const String question = 'question';
  static const String interest = 'interest';
  static const String confusion = 'confusion';
  static const String complaint = 'complaint';
  static const String positive = 'positive';
  static const String spam = 'spam';
  static const String toxic = 'toxic';
  static const String payment = 'payment';
  static const String refund = 'refund';
  static const String sos = 'sos';
  static const String legal = 'legal';
  static const String fraud = 'fraud';
  static const String privateData = 'private_data';

  static const Set<String> values = <String>{
    greeting,
    faq,
    question,
    interest,
    confusion,
    complaint,
    positive,
    spam,
    toxic,
    payment,
    refund,
    sos,
    legal,
    fraud,
    privateData,
  };
}

class AgentContentCommentRisk {
  AgentContentCommentRisk._();

  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';

  static const Set<String> values = <String>{low, medium, high};
}

class AgentContentCommentRoute {
  AgentContentCommentRoute._();

  static const String autoReplyEligibleDraftOnly =
      'AUTO_REPLY_ELIGIBLE_DRAFT_ONLY';
  static const String controlledDraftRequired = 'CONTROLLED_DRAFT_REQUIRED';
  static const String privateSupportRequired = 'PRIVATE_SUPPORT_REQUIRED';
  static const String emergencyEscalationRequired =
      'EMERGENCY_ESCALATION_REQUIRED';
  static const String blockedSpamOrToxic = 'BLOCKED_SPAM_OR_TOXIC';
  static const String humanReviewRequired = 'HUMAN_REVIEW_REQUIRED';

  static const Set<String> values = <String>{
    autoReplyEligibleDraftOnly,
    controlledDraftRequired,
    privateSupportRequired,
    emergencyEscalationRequired,
    blockedSpamOrToxic,
    humanReviewRequired,
  };
}

class AgentContentPerformanceExperimentDimension {
  AgentContentPerformanceExperimentDimension._();

  static const String hook = 'hook';
  static const String thumbnail = 'thumbnail';
  static const String length = 'length';
  static const String cta = 'cta';
  static const String openingScene = 'opening_scene';

  static const Set<String> values = <String>{
    hook,
    thumbnail,
    length,
    cta,
    openingScene,
  };
}

class AgentContentTrendDecision {
  AgentContentTrendDecision._();

  static const String proposeForOwnerReview = 'PROPOSE_FOR_OWNER_REVIEW';
  static const String blockedUnverified = 'BLOCKED_UNVERIFIED';
  static const String blockedStale = 'BLOCKED_STALE';
  static const String blockedIrrelevant = 'BLOCKED_IRRELEVANT';
  static const String blockedBrandUnsafe = 'BLOCKED_BRAND_UNSAFE';
  static const String blockedServiceDisabled = 'BLOCKED_SERVICE_DISABLED';

  static const Set<String> values = <String>{
    proposeForOwnerReview,
    blockedUnverified,
    blockedStale,
    blockedIrrelevant,
    blockedBrandUnsafe,
    blockedServiceDisabled,
  };
}

class AgentContentCloseoutReadinessStatus {
  AgentContentCloseoutReadinessStatus._();

  static const String foundationReadyNotProductionActive =
      'FOUNDATION_READY_NOT_PRODUCTION_ACTIVE';
}

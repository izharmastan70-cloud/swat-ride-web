class AgentContentDraftLifecycleState {
  AgentContentDraftLifecycleState._();

  static const String idea = 'IDEA';
  static const String draft = 'DRAFT';
  static const String reviewRequired = 'REVIEW_REQUIRED';
  static const String changesRequested = 'CHANGES_REQUESTED';
  static const String approvalReady = 'APPROVAL_READY';
  static const String rejected = 'REJECTED';
  static const String expired = 'EXPIRED';

  static const Set<String> values = <String>{
    idea,
    draft,
    reviewRequired,
    changesRequested,
    approvalReady,
    rejected,
    expired,
  };

  static const Set<String> terminalWithinPhase56 = <String>{
    approvalReady,
    rejected,
    expired,
  };
}

class AgentContentReviewAction {
  AgentContentReviewAction._();

  static const String createDraft = 'CREATE_DRAFT';
  static const String submitForReview = 'SUBMIT_FOR_REVIEW';
  static const String requestChanges = 'REQUEST_CHANGES';
  static const String markApprovalReady = 'MARK_APPROVAL_READY';
  static const String reject = 'REJECT';
  static const String expire = 'EXPIRE';

  static const Set<String> values = <String>{
    createDraft,
    submitForReview,
    requestChanges,
    markApprovalReady,
    reject,
    expire,
  };
}

class AgentContentReviewerRole {
  AgentContentReviewerRole._();

  static const String owner = 'owner';
  static const String admin = 'admin';
  static const String superAdmin = 'super_admin';

  static const Set<String> values = <String>{owner, admin, superAdmin};
}

class AgentContentReviewerChannel {
  AgentContentReviewerChannel._();

  static const String inApp = 'in_app';
  static const String ownerWhatsApp = 'owner_whatsapp';

  static const Set<String> values = <String>{inApp, ownerWhatsApp};
}

class AgentContentHumanReviewStatus {
  AgentContentHumanReviewStatus._();

  static const String allowed = 'ALLOWED_METADATA_TRANSITION';
  static const String blockedInvalid = 'BLOCKED_INVALID';
  static const String blockedTransition = 'BLOCKED_INVALID_TRANSITION';
  static const String blockedUngrounded = 'BLOCKED_UNGROUNDED';
  static const String blockedReviewer = 'BLOCKED_REVIEWER';
  static const String blockedWhatsApp = 'BLOCKED_WHATSAPP_IDENTITY';
  static const String blockedBinding = 'BLOCKED_REVIEW_BINDING';

  static const Set<String> values = <String>{
    allowed,
    blockedInvalid,
    blockedTransition,
    blockedUngrounded,
    blockedReviewer,
    blockedWhatsApp,
    blockedBinding,
  };
}

class AgentEmailDraftStatus {
  AgentEmailDraftStatus._();

  static const String draft = 'DRAFT';
  static const String needsReview = 'NEEDS_REVIEW';
  static const String approvalRequired = 'APPROVAL_REQUIRED';
  static const String blocked = 'BLOCKED';

  static const Set<String> values = <String>{
    draft,
    needsReview,
    approvalRequired,
    blocked,
  };
}

class AgentEmailPurpose {
  AgentEmailPurpose._();

  static const String supportReply = 'SUPPORT_REPLY';
  static const String feedbackReply = 'FEEDBACK_REPLY';
  static const String ownerUpdate = 'OWNER_UPDATE';
  static const String bookingInformation = 'BOOKING_INFORMATION';
  static const String serviceInformation = 'SERVICE_INFORMATION';
  static const String internalReview = 'INTERNAL_REVIEW';

  static const Set<String> values = <String>{
    supportReply,
    feedbackReply,
    ownerUpdate,
    bookingInformation,
    serviceInformation,
    internalReview,
  };
}

class AgentEmailDraftPolicyClassification {
  AgentEmailDraftPolicyClassification._();

  static const String draftReadyForReview = 'DRAFT_READY_FOR_REVIEW';
  static const String needsHumanReview = 'NEEDS_HUMAN_REVIEW';
  static const String blocked = 'BLOCKED';

  static const Set<String> values = <String>{
    draftReadyForReview,
    needsHumanReview,
    blocked,
  };
}

class AgentEmailDraftPolicyDecision {
  AgentEmailDraftPolicyDecision({
    required this.classification,
    required List<String> reasonCodes,
    required this.recipientCount,
    required this.hasBcc,
    required this.hasAttachments,
    required this.containsSensitiveCredentialPattern,
    required this.containsSuspiciousRequestPattern,
    required this.bulkRecipientRisk,
    required this.requiresHumanReview,
    required this.requiresAttachmentReview,
    required this.requiresSendApproval,
    required this.mayRemainAsDraft,
  }) : reasonCodes = List<String>.unmodifiable(reasonCodes);

  final String classification;
  final List<String> reasonCodes;
  final int recipientCount;
  final bool hasBcc;
  final bool hasAttachments;
  final bool containsSensitiveCredentialPattern;
  final bool containsSuspiciousRequestPattern;
  final bool bulkRecipientRisk;
  final bool requiresHumanReview;
  final bool requiresAttachmentReview;
  final bool requiresSendApproval;
  final bool mayRemainAsDraft;

  bool get maySend => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayCallProvider => false;
  bool get mayOpenNetworkConnection => false;
  bool get mayReadMailbox => false;
  bool get mayWriteMailbox => false;
  bool get mayChangePrompt => false;
  bool get mayTrainModel => false;
  bool get mayDeploy => false;

  void validate() {
    if (!AgentEmailDraftPolicyClassification.values.contains(classification)) {
      throw AgentEmailDraftPolicyException(
        'Invalid email policy classification "$classification".',
      );
    }

    if (recipientCount < 1) {
      throw const AgentEmailDraftPolicyException(
        'Email policy requires at least one recipient.',
      );
    }

    if (!requiresSendApproval || maySend) {
      throw const AgentEmailDraftPolicyException(
        'Phase 44 email policy must always require send approval and deny direct send.',
      );
    }

    if (classification == AgentEmailDraftPolicyClassification.blocked &&
        mayRemainAsDraft) {
      throw const AgentEmailDraftPolicyException(
        'Blocked email content cannot be treated as a ready draft.',
      );
    }

    if (containsSensitiveCredentialPattern &&
        classification != AgentEmailDraftPolicyClassification.blocked) {
      throw const AgentEmailDraftPolicyException(
        'Sensitive credential patterns must fail closed.',
      );
    }

    if (containsSuspiciousRequestPattern &&
        classification != AgentEmailDraftPolicyClassification.blocked) {
      throw const AgentEmailDraftPolicyException(
        'Suspicious credential/social-engineering requests must fail closed.',
      );
    }

    if (hasAttachments && !requiresAttachmentReview) {
      throw const AgentEmailDraftPolicyException(
        'Attachments must require separate review.',
      );
    }

    if (reasonCodes.isEmpty) {
      throw const AgentEmailDraftPolicyException(
        'Email policy decision must include at least one reason code.',
      );
    }
  }
}

class AgentEmailDraftPolicyException implements Exception {
  const AgentEmailDraftPolicyException(this.message);

  final String message;

  @override
  String toString() => 'AgentEmailDraftPolicyException: $message';
}

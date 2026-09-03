import '../constants/agent_owner_attention_review_constants.dart';

class AgentOwnerAttentionStatusTransition {
  AgentOwnerAttentionStatusTransition({
    required this.attentionId,
    required this.expectedStatus,
    required this.nextStatus,
    required this.expectedReviewVersion,
    required this.reviewerRole,
    required this.reviewerRef,
    required this.reviewedAtUtc,
  }) {
    validate();
  }

  final String attentionId;
  final String expectedStatus;
  final String nextStatus;
  final int expectedReviewVersion;

  final String reviewerRole;
  final String reviewerRef;
  final DateTime reviewedAtUtc;

  bool get workflowOnly => true;
  bool get consumesApproval => false;
  bool get grantsPermission => false;
  bool get resolvesSourceRecord => false;
  bool get executesBusinessAction => false;

  void validate() {
    final reviewer = reviewerRef.trim();

    if (attentionId.trim().isEmpty ||
        expectedStatus.trim().isEmpty ||
        nextStatus.trim().isEmpty ||
        expectedReviewVersion < 0 ||
        !AgentOwnerAttentionReviewRole.values.contains(reviewerRole) ||
        reviewer.isEmpty ||
        reviewer.length >
            AgentOwnerAttentionRepositoryLimits.reviewerRefMaxLength ||
        !reviewedAtUtc.isUtc) {
      throw const FormatException('Invalid Owner Attention status transition.');
    }
  }
}

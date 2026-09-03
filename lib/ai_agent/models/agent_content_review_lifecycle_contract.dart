import '../constants/agent_content_review_lifecycle_constants.dart';

class AgentContentReviewerContext {
  const AgentContentReviewerContext({
    required this.role,
    required this.channel,
    required this.identityVerified,
    required this.roleAuthorized,
    required this.whatsAppIdentityVerified,
    required this.reviewerBinding,
  });

  final String role;
  final String channel;
  final bool identityVerified;
  final bool roleAuthorized;
  final bool whatsAppIdentityVerified;
  final String reviewerBinding;

  bool get containsPhone => false;
  bool get containsEmail => false;
  bool get containsCnic => false;
  bool get containsSecret => false;
  bool get executesApproval => false;
  bool get sendsWhatsApp => false;

  void validate() {
    if (!AgentContentReviewerRole.values.contains(role) ||
        !AgentContentReviewerChannel.values.contains(channel) ||
        reviewerBinding.trim().isEmpty ||
        reviewerBinding.length > 256) {
      throw const FormatException('Invalid reviewer context.');
    }
  }
}

class AgentContentDraftLifecycleRecord {
  const AgentContentDraftLifecycleRecord({
    required this.requestId,
    required this.state,
    required this.version,
    required this.grounded,
    required this.ownerWhatsAppReviewEligible,
    required this.reviewedContentBinding,
    required this.sourceBinding,
  });

  final String requestId;
  final String state;
  final int version;
  final bool grounded;
  final bool ownerWhatsAppReviewEligible;
  final String reviewedContentBinding;
  final String sourceBinding;

  bool get metadataOnly => true;
  bool get containsRawContent => false;
  bool get containsRawPrompt => false;
  bool get containsRawSourcePayload => false;
  bool get containsSecrets => false;
  bool get publishesContent => false;
  bool get sendsWhatsApp => false;
  bool get persistsRecord => false;

  bool get terminal =>
      AgentContentDraftLifecycleState.terminalWithinPhase56.contains(state);

  void validate() {
    if (requestId.trim().isEmpty ||
        requestId.length > 180 ||
        !AgentContentDraftLifecycleState.values.contains(state) ||
        version <= 0 ||
        reviewedContentBinding.trim().isEmpty ||
        sourceBinding.trim().isEmpty) {
      throw const FormatException('Invalid lifecycle record.');
    }
  }
}

class AgentContentHumanReviewDecision {
  AgentContentHumanReviewDecision({
    required this.status,
    required this.requestId,
    required this.action,
    required this.currentState,
    required this.nextState,
    required this.reviewerRole,
    required this.reviewChannel,
    required this.approvalReadyHandoffEligible,
    required List<String> reasons,
  }) : reasons = List<String>.unmodifiable(reasons);

  final String status;
  final String requestId;
  final String action;
  final String currentState;
  final String nextState;
  final String reviewerRole;
  final String reviewChannel;
  final bool approvalReadyHandoffEligible;
  final List<String> reasons;

  bool get allowed => status == AgentContentHumanReviewStatus.allowed;
  bool get humanReviewRequired => true;
  bool get metadataOnly => true;
  bool get approvalReadyIsNotApproval => true;
  bool get approvalReadyIsNotPublish => true;
  bool get executesApproval => false;
  bool get publishesContent => false;
  bool get schedulesContent => false;
  bool get sendsWhatsApp => false;
  bool get executesBusinessAction => false;
  bool get grantsAuthority => false;
  bool get invokesProvider => false;
  bool get persistsDecision => false;

  void validate() {
    if (!AgentContentHumanReviewStatus.values.contains(status) ||
        requestId.trim().isEmpty ||
        !AgentContentReviewAction.values.contains(action) ||
        !AgentContentDraftLifecycleState.values.contains(currentState) ||
        !AgentContentDraftLifecycleState.values.contains(nextState) ||
        reasons.isEmpty) {
      throw const FormatException('Invalid review decision.');
    }
  }
}

class AgentContentApprovalReadyHandoff {
  const AgentContentApprovalReadyHandoff({
    required this.requestId,
    required this.version,
    required this.reviewedContentBinding,
    required this.sourceBinding,
    required this.reviewerRole,
    required this.reviewChannel,
    required this.reviewerBinding,
  });

  final String requestId;
  final int version;
  final String reviewedContentBinding;
  final String sourceBinding;
  final String reviewerRole;
  final String reviewChannel;
  final String reviewerBinding;

  factory AgentContentApprovalReadyHandoff.fromReview({
    required AgentContentDraftLifecycleRecord record,
    required AgentContentHumanReviewDecision decision,
    required AgentContentReviewerContext reviewer,
  }) {
    record.validate();
    decision.validate();
    reviewer.validate();

    if (!decision.allowed ||
        !decision.approvalReadyHandoffEligible ||
        decision.nextState != AgentContentDraftLifecycleState.approvalReady ||
        decision.requestId != record.requestId ||
        !reviewer.identityVerified ||
        !reviewer.roleAuthorized ||
        reviewer.role != decision.reviewerRole ||
        reviewer.channel != decision.reviewChannel) {
      throw const FormatException('Approval-ready handoff blocked.');
    }

    if (reviewer.channel == AgentContentReviewerChannel.ownerWhatsApp &&
        !reviewer.whatsAppIdentityVerified) {
      throw const FormatException('Verified WhatsApp identity required.');
    }

    return AgentContentApprovalReadyHandoff(
      requestId: record.requestId,
      version: record.version,
      reviewedContentBinding: record.reviewedContentBinding,
      sourceBinding: record.sourceBinding,
      reviewerRole: reviewer.role,
      reviewChannel: reviewer.channel,
      reviewerBinding: reviewer.reviewerBinding,
    );
  }

  bool get readyForExistingApprovalArchitecture => true;
  bool get requiresExternalApprovalExecution => true;
  bool get approvalReadyIsNotApproval => true;
  bool get approvalReadyIsNotPublish => true;
  bool get containsRawContent => false;
  bool get containsRawSourcePayload => false;
  bool get containsPhone => false;
  bool get containsSecrets => false;
  bool get executesApproval => false;
  bool get publishesContent => false;
  bool get schedulesContent => false;
  bool get sendsWhatsApp => false;
  bool get executesBusinessAction => false;
  bool get grantsAuthority => false;
  bool get invokesProvider => false;
  bool get persistsHandoff => false;

  Map<String, dynamic> toOwnerWhatsAppReviewSummary() => <String, dynamic>{
    'requestId': requestId,
    'version': version,
    'state': AgentContentDraftLifecycleState.approvalReady,
    'reviewerRole': reviewerRole,
    'readyForExistingApprovalArchitecture': true,
    'requiresExternalApprovalExecution': true,
    'approvalReadyIsNotApproval': true,
    'approvalReadyIsNotPublish': true,
    'containsRawContent': false,
    'containsRawSourcePayload': false,
    'containsPhone': false,
    'containsSecrets': false,
    'executesApproval': false,
    'publishesContent': false,
    'sendsWhatsApp': false,
  };
}

import '../constants/agent_content_review_lifecycle_constants.dart';
import '../models/agent_content_grounding_decision.dart';
import '../models/agent_content_review_lifecycle_contract.dart';

class AgentContentDraftLifecyclePolicy {
  const AgentContentDraftLifecyclePolicy();

  AgentContentHumanReviewDecision evaluate({
    required AgentContentDraftLifecycleRecord record,
    required AgentContentGroundingDecision grounding,
    required AgentContentReviewerContext reviewer,
    required String action,
  }) {
    try {
      record.validate();
      grounding.validateStructure();
      reviewer.validate();
    } catch (_) {
      return _blocked(
        record,
        reviewer,
        AgentContentHumanReviewStatus.blockedInvalid,
        AgentContentReviewAction.expire,
        'invalid_structure',
      );
    }

    if (!AgentContentReviewAction.values.contains(action)) {
      return _blocked(
        record,
        reviewer,
        AgentContentHumanReviewStatus.blockedTransition,
        AgentContentReviewAction.expire,
        'unsupported_action',
      );
    }

    if (!reviewer.identityVerified || !reviewer.roleAuthorized) {
      return _blocked(
        record,
        reviewer,
        AgentContentHumanReviewStatus.blockedReviewer,
        action,
        'verified_authorized_reviewer_required',
      );
    }

    if (reviewer.channel == AgentContentReviewerChannel.ownerWhatsApp &&
        (!reviewer.whatsAppIdentityVerified ||
            !record.ownerWhatsAppReviewEligible)) {
      return _blocked(
        record,
        reviewer,
        AgentContentHumanReviewStatus.blockedWhatsApp,
        action,
        'verified_owner_admin_whatsapp_required',
      );
    }

    if (record.terminal) {
      return _blocked(
        record,
        reviewer,
        AgentContentHumanReviewStatus.blockedTransition,
        action,
        'terminal_phase56_state',
      );
    }

    if (_needsGrounding(action)) {
      if (!record.grounded ||
          !grounding.grounded ||
          grounding.requestId != record.requestId) {
        return _blocked(
          record,
          reviewer,
          AgentContentHumanReviewStatus.blockedUngrounded,
          action,
          'step1d_grounding_required',
        );
      }
    }

    if (action == AgentContentReviewAction.markApprovalReady &&
        (record.reviewedContentBinding.trim().isEmpty ||
            record.sourceBinding.trim().isEmpty)) {
      return _blocked(
        record,
        reviewer,
        AgentContentHumanReviewStatus.blockedBinding,
        action,
        'immutable_review_binding_required',
      );
    }

    final String? next = _transition(record.state, action);

    if (next == null) {
      return _blocked(
        record,
        reviewer,
        AgentContentHumanReviewStatus.blockedTransition,
        action,
        'invalid_lifecycle_transition',
      );
    }

    final decision = AgentContentHumanReviewDecision(
      status: AgentContentHumanReviewStatus.allowed,
      requestId: record.requestId,
      action: action,
      currentState: record.state,
      nextState: next,
      reviewerRole: reviewer.role,
      reviewChannel: reviewer.channel,
      approvalReadyHandoffEligible:
          next == AgentContentDraftLifecycleState.approvalReady,
      reasons: <String>[
        'verified_human_reviewer',
        if (_needsGrounding(action)) 'step1d_grounding_reused',
        if (reviewer.channel == AgentContentReviewerChannel.ownerWhatsApp)
          'verified_owner_admin_whatsapp',
        'metadata_transition_only',
        'existing_approval_architecture_preserved',
        'no_approval_execution',
        'no_publish_execution',
      ],
    );

    decision.validate();
    return decision;
  }

  bool _needsGrounding(String action) =>
      action == AgentContentReviewAction.submitForReview ||
      action == AgentContentReviewAction.markApprovalReady;

  String? _transition(String state, String action) {
    if (state == AgentContentDraftLifecycleState.idea &&
        action == AgentContentReviewAction.createDraft) {
      return AgentContentDraftLifecycleState.draft;
    }
    if (state == AgentContentDraftLifecycleState.draft &&
        action == AgentContentReviewAction.submitForReview) {
      return AgentContentDraftLifecycleState.reviewRequired;
    }
    if (state == AgentContentDraftLifecycleState.reviewRequired &&
        action == AgentContentReviewAction.requestChanges) {
      return AgentContentDraftLifecycleState.changesRequested;
    }
    if (state == AgentContentDraftLifecycleState.changesRequested &&
        action == AgentContentReviewAction.createDraft) {
      return AgentContentDraftLifecycleState.draft;
    }
    if (state == AgentContentDraftLifecycleState.reviewRequired &&
        action == AgentContentReviewAction.markApprovalReady) {
      return AgentContentDraftLifecycleState.approvalReady;
    }
    if (state == AgentContentDraftLifecycleState.reviewRequired &&
        action == AgentContentReviewAction.reject) {
      return AgentContentDraftLifecycleState.rejected;
    }
    if (action == AgentContentReviewAction.expire) {
      return AgentContentDraftLifecycleState.expired;
    }
    return null;
  }

  AgentContentHumanReviewDecision _blocked(
    AgentContentDraftLifecycleRecord record,
    AgentContentReviewerContext reviewer,
    String status,
    String action,
    String reason,
  ) {
    final state = AgentContentDraftLifecycleState.values.contains(record.state)
        ? record.state
        : AgentContentDraftLifecycleState.idea;
    final role = AgentContentReviewerRole.values.contains(reviewer.role)
        ? reviewer.role
        : AgentContentReviewerRole.admin;
    final channel =
        AgentContentReviewerChannel.values.contains(reviewer.channel)
        ? reviewer.channel
        : AgentContentReviewerChannel.inApp;

    final decision = AgentContentHumanReviewDecision(
      status: status,
      requestId: record.requestId.trim().isEmpty
          ? 'invalid_request'
          : record.requestId,
      action: action,
      currentState: state,
      nextState: state,
      reviewerRole: role,
      reviewChannel: channel,
      approvalReadyHandoffEligible: false,
      reasons: <String>[
        reason,
        'human_review_required',
        'no_approval_execution',
        'no_publish_execution',
      ],
    );

    decision.validate();
    return decision;
  }

  bool get reusesStep1DGrounding => true;
  bool get reusesExistingApprovalArchitecture => true;
  bool get reusesExistingOwnerWhatsAppAuthorization => true;
  bool get duplicatesApprovalEngine => false;
  bool get humanReviewerRequired => true;
  bool get reviewerIdentityVerificationRequired => true;
  bool get reviewerRoleAuthorizationRequired => true;
  bool get ownerWhatsAppIdentityVerificationRequired => true;
  bool get approvalReadyIsHandoffOnly => true;
  bool get approvedExecutionStateImplemented => false;
  bool get publishedExecutionStateImplemented => false;
  bool get autoApproves => false;
  bool get autoPublishes => false;
  bool get autoSchedules => false;
  bool get sendsWhatsApp => false;
  bool get invokesProvider => false;
  bool get executesApproval => false;
  bool get executesBusinessAction => false;
  bool get grantsAuthority => false;
  bool get writesBusinessData => false;
  bool get persistsLifecycle => false;
  bool get implementsPhase57KnowledgeLibrary => false;
  bool get implementsPhase62SelfDeployment => false;
  bool get implementsPhase63PrivacyUi => false;
}

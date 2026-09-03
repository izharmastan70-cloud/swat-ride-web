import 'package:flutter_test/flutter_test.dart';

import 'package:swat_ride/ai_agent/constants/agent_content_grounding_constants.dart';
import 'package:swat_ride/ai_agent/constants/agent_content_review_lifecycle_constants.dart';
import 'package:swat_ride/ai_agent/models/agent_content_grounding_decision.dart';
import 'package:swat_ride/ai_agent/models/agent_content_review_lifecycle_contract.dart';
import 'package:swat_ride/ai_agent/services/agent_content_draft_lifecycle_policy.dart';

void main() {
  const policy = AgentContentDraftLifecyclePolicy();

  AgentContentDraftLifecycleRecord record({
    String state = AgentContentDraftLifecycleState.draft,
    bool grounded = true,
    bool whatsAppEligible = false,
  }) => AgentContentDraftLifecycleRecord(
    requestId: 'content_review_001',
    state: state,
    version: 1,
    grounded: grounded,
    ownerWhatsAppReviewEligible: whatsAppEligible,
    reviewedContentBinding: 'content_binding:abc',
    sourceBinding: 'source_binding:v1',
  );

  AgentContentGroundingDecision grounding({
    String requestId = 'content_review_001',
    String status = AgentContentGroundingStatus.groundedReadyForHumanReview,
  }) => AgentContentGroundingDecision(
    status: status,
    requestId: requestId,
    module: 'ride',
    feature: 'normal_ride',
    humanReviewRequired: true,
    ownerWhatsAppReviewEligible: true,
    verifiedClaimKeys: const <String>{
      AgentContentVerifiedClaimKey.featureExists,
    },
    sourceReferenceIds: const <String>['verified_feature:ride'],
    reasonCodes: const <String>[
      AgentContentGroundingReason.existingGroundingReused,
      AgentContentGroundingReason.humanReviewRequired,
      AgentContentGroundingReason.noGeneratedFactAuthority,
      AgentContentGroundingReason.noPublishAuthority,
    ],
  );

  AgentContentReviewerContext reviewer({
    String role = AgentContentReviewerRole.owner,
    String channel = AgentContentReviewerChannel.inApp,
    bool identity = true,
    bool authorized = true,
    bool whatsAppVerified = false,
  }) => AgentContentReviewerContext(
    role: role,
    channel: channel,
    identityVerified: identity,
    roleAuthorized: authorized,
    whatsAppIdentityVerified: whatsAppVerified,
    reviewerBinding: 'reviewer_binding:owner',
  );

  group('Phase 56 Step 1E lifecycle', () {
    test('7 lifecycle states locked without APPROVED/PUBLISHED', () {
      expect(AgentContentDraftLifecycleState.values.length, 7);
      expect(
        AgentContentDraftLifecycleState.values.contains('APPROVED'),
        false,
      );
      expect(
        AgentContentDraftLifecycleState.values.contains('PUBLISHED'),
        false,
      );
    });

    test('IDEA -> DRAFT allowed', () {
      final d = policy.evaluate(
        record: record(state: AgentContentDraftLifecycleState.idea),
        grounding: grounding(),
        reviewer: reviewer(),
        action: AgentContentReviewAction.createDraft,
      );
      expect(d.allowed, true);
      expect(d.nextState, AgentContentDraftLifecycleState.draft);
    });

    test('grounded DRAFT -> REVIEW_REQUIRED allowed', () {
      final d = policy.evaluate(
        record: record(),
        grounding: grounding(),
        reviewer: reviewer(),
        action: AgentContentReviewAction.submitForReview,
      );
      expect(d.allowed, true);
      expect(d.nextState, AgentContentDraftLifecycleState.reviewRequired);
    });

    test('ungrounded submit blocked', () {
      final d = policy.evaluate(
        record: record(grounded: false),
        grounding: grounding(status: AgentContentGroundingStatus.needsSource),
        reviewer: reviewer(),
        action: AgentContentReviewAction.submitForReview,
      );
      expect(d.status, AgentContentHumanReviewStatus.blockedUngrounded);
    });

    test('REVIEW_REQUIRED -> CHANGES_REQUESTED allowed', () {
      final d = policy.evaluate(
        record: record(state: AgentContentDraftLifecycleState.reviewRequired),
        grounding: grounding(),
        reviewer: reviewer(),
        action: AgentContentReviewAction.requestChanges,
      );
      expect(d.nextState, AgentContentDraftLifecycleState.changesRequested);
    });

    test('CHANGES_REQUESTED -> DRAFT allowed', () {
      final d = policy.evaluate(
        record: record(state: AgentContentDraftLifecycleState.changesRequested),
        grounding: grounding(),
        reviewer: reviewer(),
        action: AgentContentReviewAction.createDraft,
      );
      expect(d.nextState, AgentContentDraftLifecycleState.draft);
    });

    test('REVIEW_REQUIRED -> APPROVAL_READY allowed metadata only', () {
      final d = policy.evaluate(
        record: record(state: AgentContentDraftLifecycleState.reviewRequired),
        grounding: grounding(),
        reviewer: reviewer(),
        action: AgentContentReviewAction.markApprovalReady,
      );
      expect(d.allowed, true);
      expect(d.nextState, AgentContentDraftLifecycleState.approvalReady);
      expect(d.approvalReadyHandoffEligible, true);
      expect(d.approvalReadyIsNotApproval, true);
      expect(d.approvalReadyIsNotPublish, true);
      expect(d.executesApproval, false);
    });

    test('DRAFT cannot jump to APPROVAL_READY', () {
      final d = policy.evaluate(
        record: record(),
        grounding: grounding(),
        reviewer: reviewer(),
        action: AgentContentReviewAction.markApprovalReady,
      );
      expect(d.status, AgentContentHumanReviewStatus.blockedTransition);
    });

    test('unverified reviewer blocked', () {
      final d = policy.evaluate(
        record: record(state: AgentContentDraftLifecycleState.reviewRequired),
        grounding: grounding(),
        reviewer: reviewer(identity: false),
        action: AgentContentReviewAction.markApprovalReady,
      );
      expect(d.status, AgentContentHumanReviewStatus.blockedReviewer);
    });

    test('unauthorized reviewer blocked', () {
      final d = policy.evaluate(
        record: record(state: AgentContentDraftLifecycleState.reviewRequired),
        grounding: grounding(),
        reviewer: reviewer(authorized: false),
        action: AgentContentReviewAction.markApprovalReady,
      );
      expect(d.status, AgentContentHumanReviewStatus.blockedReviewer);
    });

    test('WhatsApp review requires verified identity and eligibility', () {
      final d = policy.evaluate(
        record: record(
          state: AgentContentDraftLifecycleState.reviewRequired,
          whatsAppEligible: true,
        ),
        grounding: grounding(),
        reviewer: reviewer(
          channel: AgentContentReviewerChannel.ownerWhatsApp,
          whatsAppVerified: false,
        ),
        action: AgentContentReviewAction.markApprovalReady,
      );
      expect(d.status, AgentContentHumanReviewStatus.blockedWhatsApp);
    });

    test('verified Owner WhatsApp can mark approval-ready metadata', () {
      final d = policy.evaluate(
        record: record(
          state: AgentContentDraftLifecycleState.reviewRequired,
          whatsAppEligible: true,
        ),
        grounding: grounding(),
        reviewer: reviewer(
          channel: AgentContentReviewerChannel.ownerWhatsApp,
          whatsAppVerified: true,
        ),
        action: AgentContentReviewAction.markApprovalReady,
      );
      expect(d.allowed, true);
      expect(d.reviewChannel, AgentContentReviewerChannel.ownerWhatsApp);
      expect(d.sendsWhatsApp, false);
      expect(d.executesApproval, false);
    });

    test('approval-ready handoff requires external approval execution', () {
      final r = record(
        state: AgentContentDraftLifecycleState.reviewRequired,
        whatsAppEligible: true,
      );
      final rev = reviewer(
        channel: AgentContentReviewerChannel.ownerWhatsApp,
        whatsAppVerified: true,
      );
      final d = policy.evaluate(
        record: r,
        grounding: grounding(),
        reviewer: rev,
        action: AgentContentReviewAction.markApprovalReady,
      );
      final h = AgentContentApprovalReadyHandoff.fromReview(
        record: r,
        decision: d,
        reviewer: rev,
      );
      expect(h.readyForExistingApprovalArchitecture, true);
      expect(h.requiresExternalApprovalExecution, true);
      expect(h.approvalReadyIsNotApproval, true);
      expect(h.approvalReadyIsNotPublish, true);
      expect(h.executesApproval, false);
      expect(h.publishesContent, false);
      expect(h.sendsWhatsApp, false);
    });

    test('WhatsApp handoff summary excludes raw/private payload', () {
      final r = record(
        state: AgentContentDraftLifecycleState.reviewRequired,
        whatsAppEligible: true,
      );
      final rev = reviewer(
        channel: AgentContentReviewerChannel.ownerWhatsApp,
        whatsAppVerified: true,
      );
      final d = policy.evaluate(
        record: r,
        grounding: grounding(),
        reviewer: rev,
        action: AgentContentReviewAction.markApprovalReady,
      );
      final map = AgentContentApprovalReadyHandoff.fromReview(
        record: r,
        decision: d,
        reviewer: rev,
      ).toOwnerWhatsAppReviewSummary();
      expect(map['containsRawContent'], false);
      expect(map['containsRawSourcePayload'], false);
      expect(map['containsPhone'], false);
      expect(map['containsSecrets'], false);
      expect(map['executesApproval'], false);
      expect(map['publishesContent'], false);
      expect(map['sendsWhatsApp'], false);
    });

    test('REVIEW_REQUIRED can reject', () {
      final d = policy.evaluate(
        record: record(state: AgentContentDraftLifecycleState.reviewRequired),
        grounding: grounding(),
        reviewer: reviewer(),
        action: AgentContentReviewAction.reject,
      );
      expect(d.nextState, AgentContentDraftLifecycleState.rejected);
    });

    test('non-terminal state can expire', () {
      final d = policy.evaluate(
        record: record(),
        grounding: grounding(),
        reviewer: reviewer(),
        action: AgentContentReviewAction.expire,
      );
      expect(d.nextState, AgentContentDraftLifecycleState.expired);
    });

    test('terminal Phase56 state cannot transition further', () {
      final d = policy.evaluate(
        record: record(state: AgentContentDraftLifecycleState.approvalReady),
        grounding: grounding(),
        reviewer: reviewer(),
        action: AgentContentReviewAction.expire,
      );
      expect(d.status, AgentContentHumanReviewStatus.blockedTransition);
    });

    test('lifecycle metadata contains no raw content/prompt/source', () {
      final r = record();
      expect(r.metadataOnly, true);
      expect(r.containsRawContent, false);
      expect(r.containsRawPrompt, false);
      expect(r.containsRawSourcePayload, false);
      expect(r.containsSecrets, false);
      expect(r.publishesContent, false);
      expect(r.sendsWhatsApp, false);
      expect(r.persistsRecord, false);
    });

    test('reviewer context excludes direct private identifiers', () {
      final r = reviewer();
      expect(r.containsPhone, false);
      expect(r.containsEmail, false);
      expect(r.containsCnic, false);
      expect(r.containsSecret, false);
      expect(r.executesApproval, false);
      expect(r.sendsWhatsApp, false);
    });

    test('policy reuses existing authority architecture', () {
      expect(policy.reusesStep1DGrounding, true);
      expect(policy.reusesExistingApprovalArchitecture, true);
      expect(policy.reusesExistingOwnerWhatsAppAuthorization, true);
      expect(policy.duplicatesApprovalEngine, false);
      expect(policy.humanReviewerRequired, true);
      expect(policy.reviewerIdentityVerificationRequired, true);
      expect(policy.reviewerRoleAuthorizationRequired, true);
      expect(policy.ownerWhatsAppIdentityVerificationRequired, true);
      expect(policy.approvalReadyIsHandoffOnly, true);
    });

    test('policy cannot auto approve/publish/send/execute', () {
      expect(policy.approvedExecutionStateImplemented, false);
      expect(policy.publishedExecutionStateImplemented, false);
      expect(policy.autoApproves, false);
      expect(policy.autoPublishes, false);
      expect(policy.autoSchedules, false);
      expect(policy.sendsWhatsApp, false);
      expect(policy.invokesProvider, false);
      expect(policy.executesApproval, false);
      expect(policy.executesBusinessAction, false);
      expect(policy.grantsAuthority, false);
      expect(policy.writesBusinessData, false);
      expect(policy.persistsLifecycle, false);
    });

    test('Phase 57/62/63 remain separate', () {
      expect(policy.implementsPhase57KnowledgeLibrary, false);
      expect(policy.implementsPhase62SelfDeployment, false);
      expect(policy.implementsPhase63PrivacyUi, false);
    });
  });
}

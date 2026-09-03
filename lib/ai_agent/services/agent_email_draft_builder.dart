import '../constants/agent_conversation_quality_constants.dart';
import '../constants/agent_email_constants.dart';
import '../models/agent_conversation_grounding_assessment.dart';
import '../models/agent_conversation_response_guard_result.dart';
import '../models/agent_email_draft.dart';
import '../models/agent_email_draft_policy_decision.dart';
import 'agent_conversation_quality_pipeline.dart';
import 'agent_conversation_response_guard.dart';
import 'agent_email_draft_policy.dart';

class AgentEmailDraftBuildResult {
  const AgentEmailDraftBuildResult({
    required this.draft,
    required this.policyDecision,
    required this.guardResult,
    required this.usedSafeFallbackBody,
    required this.blocked,
    required this.note,
  });

  final AgentEmailDraft? draft;
  final AgentEmailDraftPolicyDecision policyDecision;
  final AgentConversationResponseGuardResult guardResult;
  final bool usedSafeFallbackBody;
  final bool blocked;
  final String note;

  bool get hasReadyDraft => draft != null && !blocked;
  bool get requiresSendApproval => true;
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
}

class AgentEmailDraftBuilder {
  const AgentEmailDraftBuilder({
    this.qualityPipeline = const AgentConversationQualityPipeline(),
    this.responseGuard = const AgentConversationResponseGuard(),
    this.emailPolicy = const AgentEmailDraftPolicy(),
  });

  final AgentConversationQualityPipeline qualityPipeline;
  final AgentConversationResponseGuard responseGuard;
  final AgentEmailDraftPolicy emailPolicy;

  bool get providerExecutionAllowed => false;
  bool get smtpExecutionAllowed => false;
  bool get firestoreReadAllowed => false;
  bool get firestoreWriteAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get mailboxReadAllowed => false;
  bool get mailboxWriteAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;

  AgentEmailDraftBuildResult build({
    required String draftId,
    required String purpose,
    required String senderIdentityId,
    required List<AgentEmailAddress> to,
    List<AgentEmailAddress> cc = const <AgentEmailAddress>[],
    List<AgentEmailAddress> bcc = const <AgentEmailAddress>[],
    required String subject,
    required String proposedBodyText,
    required String safeFallbackBodyText,
    required List<AgentConversationGroundingSource> sources,
    List<AgentEmailAttachmentRef> attachments =
        const <AgentEmailAttachmentRef>[],
    String replyToMessageId = '',
    String risk = AgentConversationRisk.medium,
    int requiredVerifiedSourceCount = 1,
    bool freshnessRequired = false,
    bool requestAllowed = true,
    bool requiresHumanJudgment = false,
    bool userInputAmbiguous = false,
    bool canVerifyFresh = true,
    DateTime? createdAt,
  }) {
    final AgentConversationQualityPipelineResult qualityResult = qualityPipeline
        .evaluate(
          AgentConversationQualityPipelineInput(
            sources: List<AgentConversationGroundingSource>.unmodifiable(
              sources,
            ),
            risk: risk,
            requiredVerifiedSourceCount: requiredVerifiedSourceCount,
            freshnessRequired: freshnessRequired,
            requestAllowed: requestAllowed,
            requiresHumanJudgment: requiresHumanJudgment,
            userInputAmbiguous: userInputAmbiguous,
            canVerifyFresh: canVerifyFresh,
            safeFallbackAvailable: safeFallbackBodyText.trim().isNotEmpty,
            reason: 'phase44_email_draft_body_grounding',
          ),
        );

    final AgentConversationResponseGuardResult guardResult = responseGuard
        .guard(qualityResult: qualityResult, proposedAnswer: proposedBodyText);

    final bool useFallback = !guardResult.allowProposedAnswer;

    final String selectedBody = useFallback
        ? safeFallbackBodyText.trim()
        : guardResult.visibleAnswerText.trim();

    if (selectedBody.isEmpty) {
      throw const AgentEmailDraftBuilderException(
        'Email body is blocked by conversation quality and no explicit safe fallback body is available.',
      );
    }

    if (useFallback && guardResult.visibleAnswerText.isNotEmpty) {
      throw const AgentEmailDraftBuilderException(
        'Blocked proposed email body leaked through response guard.',
      );
    }

    final DateTime timestamp = (createdAt ?? DateTime.now()).toUtc();

    final AgentEmailDraft candidate = AgentEmailDraft(
      draftId: draftId,
      purpose: purpose,
      senderIdentityId: senderIdentityId,
      to: to,
      cc: cc,
      bcc: bcc,
      subject: subject,
      bodyText: selectedBody,
      replyToMessageId: replyToMessageId,
      attachments: attachments,
      status: AgentEmailDraftStatus.draft,
      createdAt: timestamp,
    );

    candidate.validate();

    final AgentEmailDraftPolicyDecision policyDecision = emailPolicy.assess(
      candidate,
    );

    if (policyDecision.classification ==
        AgentEmailDraftPolicyClassification.blocked) {
      return AgentEmailDraftBuildResult(
        draft: null,
        policyDecision: policyDecision,
        guardResult: guardResult,
        usedSafeFallbackBody: useFallback,
        blocked: true,
        note:
            'Email draft blocked by deterministic Email Draft Policy; no ready draft produced.',
      );
    }

    final String finalStatus =
        policyDecision.classification ==
            AgentEmailDraftPolicyClassification.needsHumanReview
        ? AgentEmailDraftStatus.needsReview
        : AgentEmailDraftStatus.approvalRequired;

    final AgentEmailDraft finalDraft = AgentEmailDraft(
      draftId: candidate.draftId,
      purpose: candidate.purpose,
      senderIdentityId: candidate.senderIdentityId,
      to: candidate.to,
      cc: candidate.cc,
      bcc: candidate.bcc,
      subject: candidate.subject,
      bodyText: candidate.bodyText,
      replyToMessageId: candidate.replyToMessageId,
      attachments: candidate.attachments,
      status: finalStatus,
      createdAt: candidate.createdAt,
    );

    finalDraft.validate();

    return AgentEmailDraftBuildResult(
      draft: finalDraft,
      policyDecision: policyDecision,
      guardResult: guardResult,
      usedSafeFallbackBody: useFallback,
      blocked: false,
      note: useFallback
          ? 'Proposed email body was not sufficiently grounded; explicit safe fallback body used.'
          : 'Verified evidence-supported email body passed conversation quality and draft policy.',
    );
  }
}

class AgentEmailDraftBuilderException implements Exception {
  const AgentEmailDraftBuilderException(this.message);

  final String message;

  @override
  String toString() => 'AgentEmailDraftBuilderException: $message';
}

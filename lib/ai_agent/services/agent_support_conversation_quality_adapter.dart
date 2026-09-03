import '../constants/agent_conversation_quality_constants.dart';
import '../models/agent_conversation_grounding_assessment.dart';
import '../models/agent_conversation_response_guard_result.dart';
import 'agent_conversation_quality_pipeline.dart';
import 'agent_conversation_response_guard.dart';

/// Phase 43 bridge for Support Agent AI drafts.
///
/// Current Support Agent requests do not carry explicit verified evidence
/// references. Provider-generated factual text therefore fails closed and
/// cannot become the visible support draft merely because a provider returns
/// SUCCESS.
///
/// Existing Support Policy still owns escalation, business-data requirements,
/// and automatic-reply eligibility. This adapter does not call any provider.
class AgentSupportConversationQualityAdapterResult {
  const AgentSupportConversationQualityAdapterResult({
    required this.replyText,
    required this.guardResult,
    required this.usedDeterministicFallback,
    required this.allowAutoSendLater,
    required this.note,
  });

  final String replyText;
  final AgentConversationResponseGuardResult guardResult;
  final bool usedDeterministicFallback;
  final bool allowAutoSendLater;
  final String note;

  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayCallProvider => false;
  bool get mayChangePrompt => false;
  bool get mayTrainModel => false;
  bool get mayDeploy => false;
}

class AgentSupportConversationQualityAdapter {
  const AgentSupportConversationQualityAdapter({
    this.pipeline = const AgentConversationQualityPipeline(),
    this.responseGuard = const AgentConversationResponseGuard(),
  });

  final AgentConversationQualityPipeline pipeline;
  final AgentConversationResponseGuard responseGuard;

  bool get providerExecutionAllowed => false;
  bool get firestoreReadAllowed => false;
  bool get firestoreWriteAllowed => false;
  bool get runtimeActionAllowed => false;
  bool get permissionGrantAllowed => false;
  bool get approvalConsumptionAllowed => false;
  bool get promptMutationAllowed => false;
  bool get modelTrainingAllowed => false;
  bool get deploymentAllowed => false;

  AgentSupportConversationQualityAdapterResult guardAiDraft({
    required String proposedAiReply,
    required String deterministicFallback,
    String approvedGuideHint = '',
  }) {
    final String safeFallback = deterministicFallback.trim().isEmpty
        ? 'I need verified information before I can answer that reliably.'
        : deterministicFallback.trim();

    final AgentConversationQualityPipelineResult qualityResult = pipeline
        .evaluate(
          const AgentConversationQualityPipelineInput(
            sources: <AgentConversationGroundingSource>[],
            risk: AgentConversationRisk.medium,
            canVerifyFresh: false,
            safeFallbackAvailable: true,
            reason: 'support_ai_draft_without_verified_evidence',
          ),
        );

    final AgentConversationResponseGuardResult guardResult = responseGuard
        .guard(qualityResult: qualityResult, proposedAnswer: proposedAiReply);

    final bool useFallback = !guardResult.allowProposedAnswer;

    final String baseReply = useFallback
        ? safeFallback
        : guardResult.visibleAnswerText.trim();

    final String replyText = '$baseReply$approvedGuideHint';

    final AgentSupportConversationQualityAdapterResult
    result = AgentSupportConversationQualityAdapterResult(
      replyText: replyText,
      guardResult: guardResult,
      usedDeterministicFallback: useFallback,
      // The outer AgentSupportAssessment.safeForAutomaticReply remains
      // authoritative. This only keeps curated deterministic fallback
      // eligible for that existing outer gate.
      allowAutoSendLater: useFallback,
      note: useFallback
          ? 'Phase 43 blocked the ungrounded AI draft; deterministic FAQ fallback used.'
          : 'Phase 43 allowed a verified evidence-supported AI draft.',
    );

    if (useFallback && guardResult.visibleAnswerText.isNotEmpty) {
      throw const AgentSupportConversationQualityAdapterException(
        'Blocked AI draft leaked visible answer text.',
      );
    }

    return result;
  }
}

class AgentSupportConversationQualityAdapterException implements Exception {
  const AgentSupportConversationQualityAdapterException(this.message);

  final String message;

  @override
  String toString() =>
      'AgentSupportConversationQualityAdapterException: $message';
}

import '../models/agent_ai_request.dart';
import '../models/agent_ai_response.dart';
import '../models/agent_feedback_assessment.dart';
import '../models/agent_feedback_draft.dart';
import '../models/agent_feedback_item.dart';
import '../models/agent_master_settings.dart';
import '../models/agent_role.dart';
import 'agent_feedback_policy.dart';
import 'agent_free_ai_router.dart';
import 'agent_read_only_sanitizer.dart';

// =========================================================
// AI AGENT — FEEDBACK AGENT
// =========================================================
//
// Phase 12 = classify + summarize + draft only.
// It never hides/deletes feedback and never sends a reply itself.

class AgentFeedbackAgent {
  final AgentFeedbackPolicy policy;
  final AgentFreeAiRouter aiRouter;
  final AgentReadOnlySanitizer sanitizer;

  AgentFeedbackAgent({
    AgentFeedbackPolicy? policy,
    AgentFreeAiRouter? aiRouter,
    AgentReadOnlySanitizer? sanitizer,
  })  : policy = policy ?? const AgentFeedbackPolicy(),
        aiRouter = aiRouter ?? AgentFreeAiRouter(),
        sanitizer = sanitizer ?? const AgentReadOnlySanitizer();

  Future<AgentFeedbackDraft> draft({
    required AgentMasterSettings settings,
    required AgentRole feedbackRole,
    required AgentFeedbackItem feedback,
  }) async {
    final AgentFeedbackAssessment assessment =
        policy.assess(feedback);

    if (!assessment.canDraftReply) {
      return AgentFeedbackDraft(
        feedbackId: feedback.feedbackId,
        replyText: '',
        sentiment: assessment.sentiment,
        escalation: assessment.escalation,
        suspectedSpam: assessment.suspectedSpam,
        canAutoReplyLater: false,
        note: assessment.reason,
      );
    }

    final String fallback =
        _deterministicFallback(feedback, assessment);

    if (!settings.freeAiOperational &&
        !settings.localAiEnabled) {
      return AgentFeedbackDraft(
        feedbackId: feedback.feedbackId,
        replyText: fallback,
        sentiment: assessment.sentiment,
        escalation: assessment.escalation,
        suspectedSpam: assessment.suspectedSpam,
        canAutoReplyLater: assessment.canAutoReplyLater,
        note: 'Safe deterministic feedback draft used.',
      );
    }

    final AgentAiRequest request = AgentAiRequest(
      requestId: 'feedback_${feedback.feedbackId}',
      roleId: feedbackRole.roleId,
      purpose: 'feedback_reply_draft',
      prompt:
          'Draft a short respectful SWAT RIDE feedback reply. '
          'Do not admit liability, promise refunds, invent transaction facts, '
          'or make safety/legal decisions. Feedback: ${feedback.message}',
      context: sanitizer.sanitizeMap(
        <String, dynamic>{
          'module': feedback.module,
          'referenceId': feedback.referenceId,
          'rating': feedback.rating,
          'type': feedback.type,
          'assessmentSummary': assessment.summary,
          'fallback': fallback,
        },
      ),
      createdAt: DateTime.now(),
    );

    final AgentAiResponse response = await aiRouter.route(
      settings: settings,
      role: feedbackRole,
      request: request,
    );

    return AgentFeedbackDraft(
      feedbackId: feedback.feedbackId,
      replyText:
          response.isSuccess && response.text.trim().isNotEmpty
              ? response.text.trim()
              : fallback,
      sentiment: assessment.sentiment,
      escalation: assessment.escalation,
      suspectedSpam: assessment.suspectedSpam,
      canAutoReplyLater: assessment.canAutoReplyLater,
      note: response.isSuccess
          ? 'Free/Local AI draft prepared under deterministic feedback policy.'
          : 'Safe deterministic fallback used; AI unavailable.',
    );
  }

  String _deterministicFallback(
    AgentFeedbackItem feedback,
    AgentFeedbackAssessment assessment,
  ) {
    if (assessment.escalation != 'NONE') {
      return 'Thank you for reporting this. Your feedback needs human review '
          'before any action or final response is taken.';
    }

    if ((feedback.rating ?? 0) >= 4) {
      return 'Thank you for your feedback and for using SWAT RIDE.';
    }

    return 'Thank you for your feedback. We have recorded it for review.';
  }
}

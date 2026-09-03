import '../constants/agent_feedback_constants.dart';
import '../models/agent_feedback_assessment.dart';
import '../models/agent_feedback_item.dart';

// =========================================================
// AI AGENT — FEEDBACK SAFETY POLICY
// =========================================================
//
// Deterministic policy runs before any AI provider.
// AI cannot override safety/legal/fraud/payment escalation.

class AgentFeedbackPolicy {
  const AgentFeedbackPolicy();

  AgentFeedbackAssessment assess(AgentFeedbackItem item) {
    final String text = item.message.toLowerCase();

    if (_containsAny(text, <String>[
      'sos',
      'emergency',
      'accident',
      'threat',
      'danger',
      'kidnap',
      'missing child',
    ])) {
      return const AgentFeedbackAssessment(
        sentiment: AgentFeedbackSentiment.critical,
        escalation: AgentFeedbackEscalation.safetyHuman,
        suspectedSpam: false,
        canDraftReply: true,
        canAutoReplyLater: false,
        summary: 'Safety/emergency feedback.',
        reason: 'Requires human safety escalation.',
      );
    }

    if (_containsAny(text, <String>[
      'fraud',
      'scam',
      'unauthorized payment',
      'stolen money',
    ])) {
      return const AgentFeedbackAssessment(
        sentiment: AgentFeedbackSentiment.critical,
        escalation: AgentFeedbackEscalation.manager,
        suspectedSpam: false,
        canDraftReply: true,
        canAutoReplyLater: false,
        summary: 'Fraud/payment-risk feedback.',
        reason: 'Requires manager/admin review.',
      );
    }

    if (_containsAny(text, <String>[
      'legal',
      'lawyer',
      'court',
      'police complaint',
    ])) {
      return const AgentFeedbackAssessment(
        sentiment: AgentFeedbackSentiment.critical,
        escalation: AgentFeedbackEscalation.owner,
        suspectedSpam: false,
        canDraftReply: true,
        canAutoReplyLater: false,
        summary: 'Legal-risk feedback.',
        reason: 'Requires owner/admin escalation.',
      );
    }

    final bool spam = _looksLikeSpam(text);

    if (spam) {
      return const AgentFeedbackAssessment(
        sentiment: AgentFeedbackSentiment.unknown,
        escalation: AgentFeedbackEscalation.support,
        suspectedSpam: true,
        canDraftReply: false,
        canAutoReplyLater: false,
        summary: 'Possible spam/low-quality feedback.',
        reason: 'Needs review before any response.',
      );
    }

    if ((item.rating ?? 0) <= 2 ||
        item.type == AgentFeedbackType.complaint) {
      return const AgentFeedbackAssessment(
        sentiment: AgentFeedbackSentiment.negative,
        escalation: AgentFeedbackEscalation.support,
        suspectedSpam: false,
        canDraftReply: true,
        canAutoReplyLater: false,
        summary: 'Negative/complaint feedback.',
        reason: 'Draft allowed, but human review required before send.',
      );
    }

    if ((item.rating ?? 0) >= 4) {
      return const AgentFeedbackAssessment(
        sentiment: AgentFeedbackSentiment.positive,
        escalation: AgentFeedbackEscalation.none,
        suspectedSpam: false,
        canDraftReply: true,
        canAutoReplyLater: true,
        summary: 'Positive feedback.',
        reason: 'Safe thank-you draft can be prepared.',
      );
    }

    return const AgentFeedbackAssessment(
      sentiment: AgentFeedbackSentiment.neutral,
      escalation: AgentFeedbackEscalation.none,
      suspectedSpam: false,
      canDraftReply: true,
      canAutoReplyLater: false,
      summary: 'Neutral feedback.',
      reason: 'Draft allowed; auto-send remains disabled in Phase 12.',
    );
  }

  bool _looksLikeSpam(String text) {
    if (text.trim().length < 2) return true;
    if (text.contains('http://') || text.contains('https://')) {
      return true;
    }

    const List<String> spamTerms = <String>[
      'buy followers',
      'crypto offer',
      'click here',
      'free money',
    ];

    return _containsAny(text, spamTerms);
  }

  bool _containsAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }
}

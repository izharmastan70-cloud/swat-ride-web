import '../constants/agent_support_constants.dart';
import '../models/agent_support_assessment.dart';
import '../models/agent_support_request.dart';

// =========================================================
// AI AGENT — SUPPORT POLICY
// =========================================================
//
// Deterministic safety policy runs BEFORE any AI provider.
// A model cannot override these escalation rules.

class AgentSupportPolicy {
  const AgentSupportPolicy();

  AgentSupportAssessment assess(AgentSupportRequest request) {
    final String text = request.userMessage.toLowerCase();

    if (_containsAny(text, <String>[
      'sos',
      'accident',
      'emergency',
      'threat',
      'danger',
      'kidnap',
      'missing child',
      'child missing',
    ])) {
      return const AgentSupportAssessment(
        intent: AgentSupportIntent.safety,
        priority: AgentSupportPriority.critical,
        escalation: AgentSupportEscalation.safetyHuman,
        safeForAutomaticReply: false,
        requiresBusinessData: true,
        reason: 'Safety/emergency issue requires human safety escalation.',
      );
    }

    if (_containsAny(text, <String>[
      'fraud',
      'scam',
      'stolen',
      'unauthorized',
    ])) {
      return const AgentSupportAssessment(
        intent: AgentSupportIntent.fraud,
        priority: AgentSupportPriority.urgent,
        escalation: AgentSupportEscalation.manager,
        safeForAutomaticReply: false,
        requiresBusinessData: true,
        reason: 'Fraud-related issue requires manager/admin review.',
      );
    }

    if (_containsAny(text, <String>[
      'legal',
      'lawyer',
      'court',
      'police complaint',
    ])) {
      return const AgentSupportAssessment(
        intent: AgentSupportIntent.legal,
        priority: AgentSupportPriority.urgent,
        escalation: AgentSupportEscalation.owner,
        safeForAutomaticReply: false,
        requiresBusinessData: true,
        reason: 'Legal issue requires owner/admin escalation.',
      );
    }

    if (_containsAny(text, <String>[
      'refund',
      'money back',
    ])) {
      return const AgentSupportAssessment(
        intent: AgentSupportIntent.refundRequest,
        priority: AgentSupportPriority.high,
        escalation: AgentSupportEscalation.humanSupport,
        safeForAutomaticReply: false,
        requiresBusinessData: true,
        reason: 'Refund request requires business data and approval workflow.',
      );
    }

    if (_containsAny(text, <String>[
      'payment deducted',
      'charged',
      'payment issue',
      'double payment',
    ])) {
      return const AgentSupportAssessment(
        intent: AgentSupportIntent.paymentDispute,
        priority: AgentSupportPriority.high,
        escalation: AgentSupportEscalation.humanSupport,
        safeForAutomaticReply: false,
        requiresBusinessData: true,
        reason: 'Payment dispute must not be auto-resolved.',
      );
    }

    if (_containsAny(text, <String>[
      'ride status',
      'driver where',
      'driver location',
    ])) {
      return const AgentSupportAssessment(
        intent: AgentSupportIntent.rideStatus,
        priority: AgentSupportPriority.normal,
        escalation: AgentSupportEscalation.none,
        safeForAutomaticReply: false,
        requiresBusinessData: true,
        reason: 'Ride status needs a future Ride read-only connector.',
      );
    }

    if (_containsAny(text, <String>[
      'food order',
      'order status',
      'delivery status',
    ])) {
      return const AgentSupportAssessment(
        intent: AgentSupportIntent.foodStatus,
        priority: AgentSupportPriority.normal,
        escalation: AgentSupportEscalation.none,
        safeForAutomaticReply: false,
        requiresBusinessData: true,
        reason: 'Food status needs a future Food read-only connector.',
      );
    }

    if (_containsAny(text, <String>[
      'hotel booking',
      'room booking',
    ])) {
      return const AgentSupportAssessment(
        intent: AgentSupportIntent.hotelStatus,
        priority: AgentSupportPriority.normal,
        escalation: AgentSupportEscalation.none,
        safeForAutomaticReply: false,
        requiresBusinessData: true,
        reason: 'Hotel status needs a future Hotel read-only connector.',
      );
    }

    if (_containsAny(text, <String>[
      'tour booking',
      'tour status',
    ])) {
      return const AgentSupportAssessment(
        intent: AgentSupportIntent.tourStatus,
        priority: AgentSupportPriority.normal,
        escalation: AgentSupportEscalation.none,
        safeForAutomaticReply: false,
        requiresBusinessData: true,
        reason: 'Tour status needs a future Tour read-only connector.',
      );
    }

    if (_containsAny(text, <String>[
      'reward',
      'points',
      'coupon',
      'voucher',
      'cashback',
    ])) {
      return const AgentSupportAssessment(
        intent: AgentSupportIntent.rewardsHelp,
        priority: AgentSupportPriority.normal,
        escalation: AgentSupportEscalation.none,
        safeForAutomaticReply: false,
        requiresBusinessData: true,
        reason: 'Reward balance/status needs a future Rewards connector.',
      );
    }

    if (_containsAny(text, <String>[
      'how to',
      'what is',
      'help',
      'faq',
      'service available',
    ])) {
      return const AgentSupportAssessment(
        intent: AgentSupportIntent.faq,
        priority: AgentSupportPriority.normal,
        escalation: AgentSupportEscalation.none,
        safeForAutomaticReply: true,
        requiresBusinessData: false,
        reason: 'General FAQ can be answered without transactional data.',
      );
    }

    return const AgentSupportAssessment(
      intent: AgentSupportIntent.unknown,
      priority: AgentSupportPriority.normal,
      escalation: AgentSupportEscalation.humanSupport,
      safeForAutomaticReply: false,
      requiresBusinessData: false,
      reason: 'Unknown intent should be reviewed rather than guessed.',
    );
  }

  bool _containsAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }
}

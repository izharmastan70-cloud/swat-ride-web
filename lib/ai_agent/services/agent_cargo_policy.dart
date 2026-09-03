import '../constants/agent_cargo_constants.dart';
import '../models/agent_cargo_assessment.dart';

// =========================================================
// AI AGENT — CARGO POLICY
// =========================================================
//
// Deterministic safety policy.
// No real booking/status action is executed in Phase 19.

class AgentCargoPolicy {
  const AgentCargoPolicy();

  AgentCargoAssessment assessMessage(String message) {
    final String text = message.toLowerCase();

    if (_containsAny(text, <String>[
      'weapon',
      'gun',
      'explosive',
      'bomb',
      'illegal',
      'drugs',
      'narcotic',
    ])) {
      return const AgentCargoAssessment(
        intent: AgentCargoIntent.bookingHelp,
        risk: AgentCargoRisk.restricted,
        canAnswerReadOnly: false,
        requiresHumanReview: true,
        requiresApprovalForAction: true,
        reason: 'Potentially restricted cargo requires human/admin review.',
      );
    }

    if (_containsAny(text, <String>[
      'fragile',
      'glass',
      'breakable',
    ])) {
      return const AgentCargoAssessment(
        intent: AgentCargoIntent.bookingHelp,
        risk: AgentCargoRisk.fragile,
        canAnswerReadOnly: true,
        requiresHumanReview: false,
        requiresApprovalForAction: false,
        reason: 'Fragile cargo should be clearly flagged in the booking.',
      );
    }

    if (_containsAny(text, <String>[
      'expensive',
      'high value',
      'laptop',
      'gold',
      'jewelry',
    ])) {
      return const AgentCargoAssessment(
        intent: AgentCargoIntent.bookingHelp,
        risk: AgentCargoRisk.highValue,
        canAnswerReadOnly: true,
        requiresHumanReview: true,
        requiresApprovalForAction: false,
        reason: 'High-value cargo should receive additional verification.',
      );
    }

    if (_containsAny(text, <String>[
      'where is',
      'status',
      'track',
      'tracking',
    ])) {
      return const AgentCargoAssessment(
        intent: AgentCargoIntent.statusCheck,
        risk: AgentCargoRisk.normal,
        canAnswerReadOnly: false,
        requiresHumanReview: false,
        requiresApprovalForAction: false,
        reason: 'Real cargo status requires the future Cargo read-only connector.',
      );
    }

    if (_containsAny(text, <String>[
      'cancel',
      'cancellation',
    ])) {
      return const AgentCargoAssessment(
        intent: AgentCargoIntent.cancelRequest,
        risk: AgentCargoRisk.normal,
        canAnswerReadOnly: false,
        requiresHumanReview: false,
        requiresApprovalForAction: true,
        reason: 'Cargo cancellation is a write action and requires approval.',
      );
    }

    if (_containsAny(text, <String>[
      'price',
      'fare',
      'cost',
      'rate',
    ])) {
      return const AgentCargoAssessment(
        intent: AgentCargoIntent.pricingHelp,
        risk: AgentCargoRisk.normal,
        canAnswerReadOnly: false,
        requiresHumanReview: false,
        requiresApprovalForAction: false,
        reason: 'Real cargo pricing requires the Cargo pricing connector.',
      );
    }

    return const AgentCargoAssessment(
      intent: AgentCargoIntent.unknown,
      risk: AgentCargoRisk.unknown,
      canAnswerReadOnly: false,
      requiresHumanReview: false,
      requiresApprovalForAction: false,
      reason: 'Cargo connector is not live yet.',
    );
  }

  bool _containsAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }
}

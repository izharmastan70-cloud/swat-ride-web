import '../models/agent_cargo_assessment.dart';
import 'agent_cargo_policy.dart';

// =========================================================
// AI AGENT — CARGO AGENT
// =========================================================
//
// Phase 19 = foundation only.
//
// cargo_agent remains OFF + disabled in Phase 1 seed.
// This service performs deterministic planning/classification only.
// It never reads/writes real Cargo bookings.

class AgentCargoAgent {
  final AgentCargoPolicy policy;

  const AgentCargoAgent({
    this.policy = const AgentCargoPolicy(),
  });

  AgentCargoAssessment assess(String message) {
    return policy.assessMessage(message);
  }

  String safeResponseFor(AgentCargoAssessment assessment) {
    if (assessment.requiresHumanReview) {
      return 'This cargo request needs human/admin review before any action.';
    }

    if (assessment.intent == 'STATUS_CHECK') {
      return 'Real cargo tracking is not connected to the AI Agent yet.';
    }

    if (assessment.intent == 'CANCEL_REQUEST') {
      return 'Cargo cancellation will require an approved write action once the real connector is available.';
    }

    if (assessment.intent == 'PRICING_HELP') {
      return 'Real cargo pricing is not connected to the AI Agent yet.';
    }

    return 'Cargo Agent foundation is ready, but the real Cargo module connector remains OFF.';
  }
}

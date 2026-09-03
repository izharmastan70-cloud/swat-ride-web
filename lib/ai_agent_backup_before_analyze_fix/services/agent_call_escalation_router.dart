import '../constants/agent_call_constants.dart';

// =========================================================
// AI AGENT — CALL ESCALATION ROUTER
// =========================================================
//
// Roadmap ladder:
// normal -> AI
// unresolved -> Human Support
// serious -> Manager/Admin
// critical/high-value/legal/fraud -> Owner

class AgentCallEscalationRouter {
  const AgentCallEscalationRouter();

  String route({
    required String intent,
    required bool aiCanSolve,
    required bool serious,
    required bool critical,
  }) {
    if (critical ||
        intent == AgentCallIntent.legal ||
        intent == AgentCallIntent.fraud) {
      return AgentCallEscalationLevel.owner;
    }

    if (serious ||
        intent == AgentCallIntent.paymentDispute ||
        intent == AgentCallIntent.emergency) {
      return AgentCallEscalationLevel.managerAdmin;
    }

    if (!aiCanSolve) {
      return AgentCallEscalationLevel.humanSupport;
    }

    return AgentCallEscalationLevel.ai;
  }
}

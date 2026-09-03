import '../models/agent_student_assessment.dart';
import 'agent_student_policy.dart';

// =========================================================
// AI AGENT — STUDENT RIDE AGENT
// =========================================================
//
// Phase 20 foundation only.
// student_agent remains OFF + disabled.
// No child/guardian/attendance/handover record is read or changed.

class AgentStudentAgent {
  final AgentStudentPolicy policy;

  const AgentStudentAgent({
    this.policy = const AgentStudentPolicy(),
  });

  AgentStudentAssessment assess(String message) {
    return policy.assess(message);
  }

  String safeResponseFor(AgentStudentAssessment assessment) {
    if (assessment.requiresSafetyEscalation) {
      return 'Student safety issue detected. Route to the trusted Safety/Human flow; AI must not independently authorize any handover.';
    }

    if (assessment.requiresHuman) {
      return 'This Student Ride request requires an authorized human review.';
    }

    if (assessment.intent == 'STATUS_CHECK' ||
        assessment.intent == 'ATTENDANCE_CHECK') {
      return 'Real Student Ride data is not connected to the AI Agent yet.';
    }

    return 'Student Ride Agent foundation is ready, but remains OFF until the module and safety audit are complete.';
  }
}

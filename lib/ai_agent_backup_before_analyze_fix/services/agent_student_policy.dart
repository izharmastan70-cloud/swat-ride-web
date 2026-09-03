import '../constants/agent_student_constants.dart';
import '../models/agent_student_assessment.dart';
import 'agent_student_privacy_guard.dart';

// =========================================================
// AI AGENT — STUDENT RIDE POLICY
// =========================================================
//
// Phase 20 classification only.
// The agent cannot authorize pickup/handover or modify attendance.

class AgentStudentPolicy {
  final AgentStudentPrivacyGuard privacy;

  const AgentStudentPolicy({
    this.privacy = const AgentStudentPrivacyGuard(),
  });

  AgentStudentAssessment assess(String message) {
    if (privacy.containsForbiddenSecret(message)) {
      return const AgentStudentAssessment(
        intent: AgentStudentIntent.safetyConcern,
        risk: AgentStudentRisk.safetyCritical,
        requiresHuman: true,
        requiresSafetyEscalation: true,
        requiresApprovalForWrite: true,
        reason: 'Secret pickup/handover credentials must not be sent to AI.',
      );
    }

    final String text = message.toLowerCase();

    if (_contains(text, <String>[
      'emergency',
      'sos',
      'missing',
      'kidnap',
      'unsafe',
      'accident',
    ])) {
      return const AgentStudentAssessment(
        intent: AgentStudentIntent.emergency,
        risk: AgentStudentRisk.safetyCritical,
        requiresHuman: true,
        requiresSafetyEscalation: true,
        requiresApprovalForWrite: false,
        reason: 'Student safety concern requires immediate safety escalation.',
      );
    }

    if (_contains(text, <String>[
      'guardian',
      'who can pick',
      'authorized person',
      'handover',
    ])) {
      return const AgentStudentAssessment(
        intent: AgentStudentIntent.guardianQuestion,
        risk: AgentStudentRisk.sensitive,
        requiresHuman: true,
        requiresSafetyEscalation: false,
        requiresApprovalForWrite: true,
        reason: 'Guardian/handover authorization must use trusted records.',
      );
    }

    if (_contains(text, <String>[
      'attendance',
      'present',
      'absent',
    ])) {
      return const AgentStudentAssessment(
        intent: AgentStudentIntent.attendanceCheck,
        risk: AgentStudentRisk.sensitive,
        requiresHuman: false,
        requiresSafetyEscalation: false,
        requiresApprovalForWrite: true,
        reason: 'Read-only attendance may be shown later; changes require authorization.',
      );
    }

    if (_contains(text, <String>[
      'where',
      'status',
      'picked up',
      'school',
      'return',
    ])) {
      return const AgentStudentAssessment(
        intent: AgentStudentIntent.statusCheck,
        risk: AgentStudentRisk.sensitive,
        requiresHuman: false,
        requiresSafetyEscalation: false,
        requiresApprovalForWrite: false,
        reason: 'Real status requires the future authorized Student Ride connector.',
      );
    }

    return const AgentStudentAssessment(
      intent: AgentStudentIntent.unknown,
      risk: AgentStudentRisk.sensitive,
      requiresHuman: false,
      requiresSafetyEscalation: false,
      requiresApprovalForWrite: false,
      reason: 'Student Ride AI connector is not live yet.',
    );
  }

  bool _contains(String text, List<String> terms) {
    return terms.any(text.contains);
  }
}

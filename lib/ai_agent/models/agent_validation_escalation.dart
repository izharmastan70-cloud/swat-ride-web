import 'agent_validation_result.dart';

// =========================================================
// AI AGENT - VALIDATION ESCALATION
// =========================================================
//
// Phase 28 Step 6.
//
// Converts validator disagreement / escalation into a
// structured Super Admin review item.
//
// DATA MODEL ONLY:
// - no Firestore writes
// - no notification sending
// - no tool execution
// - no admin action
// - no approval bypass
//
// Human review remains explicit.

class AgentValidationEscalationStatus {
  AgentValidationEscalationStatus._();

  static const String pendingReview =
      'PENDING_REVIEW';

  static const String resolved =
      'RESOLVED';

  static const String dismissed =
      'DISMISSED';

  static const Set<String> values = <String>{
    pendingReview,
    resolved,
    dismissed,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentValidationEscalation {
  final String escalationId;
  final String validationId;
  final String taskId;
  final String primaryAgentRoleId;
  final String validatorAgentRoleId;
  final String recommendation;
  final String validationVerdict;
  final String validationStatus;
  final String reason;
  final List<String> concerns;
  final double confidence;
  final String escalationStatus;
  final bool requiresSuperAdminReview;
  final DateTime createdAt;

  const AgentValidationEscalation({
    required this.escalationId,
    required this.validationId,
    required this.taskId,
    required this.primaryAgentRoleId,
    required this.validatorAgentRoleId,
    required this.recommendation,
    required this.validationVerdict,
    required this.validationStatus,
    required this.reason,
    this.concerns = const <String>[],
    required this.confidence,
    this.escalationStatus =
        AgentValidationEscalationStatus.pendingReview,
    this.requiresSuperAdminReview = true,
    required this.createdAt,
  });

  factory AgentValidationEscalation.fromValidation({
    required String escalationId,
    required AgentValidationResult validation,
    DateTime? createdAt,
  }) {
    if (!validation.needsHumanReview) {
      throw const AgentValidationEscalationException(
        'Validation does not require human review.',
      );
    }

    final AgentValidationEscalation escalation =
        AgentValidationEscalation(
      escalationId: escalationId,
      validationId: validation.validationId,
      taskId: validation.taskId,
      primaryAgentRoleId:
          validation.primaryAgentRoleId,
      validatorAgentRoleId:
          validation.validatorAgentRoleId,
      recommendation:
          validation.recommendation,
      validationVerdict:
          validation.verdict,
      validationStatus:
          validation.status,
      reason: validation.reason,
      concerns:
          List<String>.unmodifiable(
        validation.concerns,
      ),
      confidence:
          validation.confidence,
      requiresSuperAdminReview: true,
      createdAt:
          createdAt ?? DateTime.now(),
    );

    escalation.validate();
    return escalation;
  }

  bool get isPending =>
      escalationStatus ==
      AgentValidationEscalationStatus.pendingReview;

  void validate() {
    if (escalationId.trim().isEmpty) {
      throw const AgentValidationEscalationException(
        'escalationId cannot be empty.',
      );
    }

    if (validationId.trim().isEmpty) {
      throw const AgentValidationEscalationException(
        'validationId cannot be empty.',
      );
    }

    if (taskId.trim().isEmpty) {
      throw const AgentValidationEscalationException(
        'taskId cannot be empty.',
      );
    }

    if (primaryAgentRoleId.trim().isEmpty ||
        validatorAgentRoleId.trim().isEmpty) {
      throw const AgentValidationEscalationException(
        'Agent role IDs cannot be empty.',
      );
    }

    if (primaryAgentRoleId ==
        validatorAgentRoleId) {
      throw const AgentValidationEscalationException(
        'Primary and validator agents must remain different.',
      );
    }

    if (recommendation.trim().isEmpty) {
      throw const AgentValidationEscalationException(
        'recommendation cannot be empty.',
      );
    }

    if (!AgentValidationVerdict.isValid(
      validationVerdict,
    )) {
      throw AgentValidationEscalationException(
        'Invalid validation verdict "$validationVerdict".',
      );
    }

    if (!AgentValidationStatus.isValid(
      validationStatus,
    )) {
      throw AgentValidationEscalationException(
        'Invalid validation status "$validationStatus".',
      );
    }

    if (!AgentValidationEscalationStatus.isValid(
      escalationStatus,
    )) {
      throw AgentValidationEscalationException(
        'Invalid escalation status "$escalationStatus".',
      );
    }

    if (reason.trim().isEmpty) {
      throw const AgentValidationEscalationException(
        'Escalation reason cannot be empty.',
      );
    }

    if (confidence < 0 || confidence > 1) {
      throw const AgentValidationEscalationException(
        'confidence must be between 0 and 1.',
      );
    }

    if (!requiresSuperAdminReview) {
      throw const AgentValidationEscalationException(
        'Validator escalation must require Super Admin review.',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'escalationId': escalationId,
      'validationId': validationId,
      'taskId': taskId,
      'primaryAgentRoleId':
          primaryAgentRoleId,
      'validatorAgentRoleId':
          validatorAgentRoleId,
      'recommendation':
          recommendation,
      'validationVerdict':
          validationVerdict,
      'validationStatus':
          validationStatus,
      'reason': reason,
      'concerns':
          List<String>.from(concerns),
      'confidence': confidence,
      'escalationStatus':
          escalationStatus,
      'requiresSuperAdminReview':
          requiresSuperAdminReview,
      'createdAt':
          createdAt.toIso8601String(),
    };
  }
}

class AgentValidationEscalationException
    implements Exception {
  final String message;

  const AgentValidationEscalationException(
    this.message,
  );

  @override
  String toString() =>
      'AgentValidationEscalationException: $message';
}
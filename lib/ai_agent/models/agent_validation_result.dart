// =========================================================
// AI AGENT - VALIDATION RESULT
// =========================================================
//
// Phase 28 Step 2.
//
// Foundation for second-agent validation.
//
// PURE MODEL ONLY:
// - no Firestore access
// - no tool execution
// - no approval bypass
// - no account action
// - no automatic deployment
//
// Primary agent recommendation and independent validator
// result stay separate so disagreement can be escalated.

class AgentValidationVerdict {
  AgentValidationVerdict._();

  static const String approved = 'APPROVED';
  static const String rejected = 'REJECTED';
  static const String needsReview = 'NEEDS_REVIEW';
  static const String insufficientEvidence =
      'INSUFFICIENT_EVIDENCE';

  static const Set<String> values = <String>{
    approved,
    rejected,
    needsReview,
    insufficientEvidence,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentValidationStatus {
  AgentValidationStatus._();

  static const String pending = 'PENDING';
  static const String validated = 'VALIDATED';
  static const String disagreement = 'DISAGREEMENT';
  static const String escalated = 'ESCALATED';

  static const Set<String> values = <String>{
    pending,
    validated,
    disagreement,
    escalated,
  };

  static bool isValid(String value) =>
      values.contains(value);
}

class AgentValidationResult {
  final String validationId;
  final String taskId;
  final String primaryAgentRoleId;
  final String validatorAgentRoleId;
  final String recommendation;
  final String verdict;
  final String status;
  final List<String> evidenceChecked;
  final List<String> constraintsChecked;
  final List<String> concerns;
  final String reason;
  final double confidence;
  final bool requiresSuperAdminReview;
  final DateTime createdAt;

  const AgentValidationResult({
    required this.validationId,
    required this.taskId,
    required this.primaryAgentRoleId,
    required this.validatorAgentRoleId,
    required this.recommendation,
    required this.verdict,
    required this.status,
    this.evidenceChecked = const <String>[],
    this.constraintsChecked = const <String>[],
    this.concerns = const <String>[],
    required this.reason,
    required this.confidence,
    this.requiresSuperAdminReview = false,
    required this.createdAt,
  });

  bool get hasDisagreement =>
      status == AgentValidationStatus.disagreement;

  bool get isEscalated =>
      status == AgentValidationStatus.escalated;

  bool get isApproved =>
      verdict == AgentValidationVerdict.approved;

  bool get needsHumanReview =>
      requiresSuperAdminReview ||
      hasDisagreement ||
      isEscalated ||
      verdict == AgentValidationVerdict.needsReview ||
      verdict ==
          AgentValidationVerdict.insufficientEvidence;

  void validate() {
    if (validationId.trim().isEmpty) {
      throw const AgentValidationException(
        'validationId cannot be empty.',
      );
    }

    if (taskId.trim().isEmpty) {
      throw const AgentValidationException(
        'taskId cannot be empty.',
      );
    }

    if (primaryAgentRoleId.trim().isEmpty) {
      throw const AgentValidationException(
        'primaryAgentRoleId cannot be empty.',
      );
    }

    if (validatorAgentRoleId.trim().isEmpty) {
      throw const AgentValidationException(
        'validatorAgentRoleId cannot be empty.',
      );
    }

    if (primaryAgentRoleId == validatorAgentRoleId) {
      throw const AgentValidationException(
        'Primary agent and validator agent must be different.',
      );
    }

    if (recommendation.trim().isEmpty) {
      throw const AgentValidationException(
        'recommendation cannot be empty.',
      );
    }

    if (!AgentValidationVerdict.isValid(verdict)) {
      throw AgentValidationException(
        'Invalid validation verdict "$verdict".',
      );
    }

    if (!AgentValidationStatus.isValid(status)) {
      throw AgentValidationException(
        'Invalid validation status "$status".',
      );
    }

    if (reason.trim().isEmpty) {
      throw const AgentValidationException(
        'Validation reason cannot be empty.',
      );
    }

    if (confidence < 0 || confidence > 1) {
      throw const AgentValidationException(
        'confidence must be between 0 and 1.',
      );
    }

    if (status == AgentValidationStatus.disagreement &&
        !requiresSuperAdminReview) {
      throw const AgentValidationException(
        'Disagreement must require Super Admin review.',
      );
    }

    if (status == AgentValidationStatus.escalated &&
        !requiresSuperAdminReview) {
      throw const AgentValidationException(
        'Escalated validation must require Super Admin review.',
      );
    }
  }

  bool get isValid {
    try {
      validate();
      return true;
    } on AgentValidationException {
      return false;
    }
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'validationId': validationId,
      'taskId': taskId,
      'primaryAgentRoleId': primaryAgentRoleId,
      'validatorAgentRoleId': validatorAgentRoleId,
      'recommendation': recommendation,
      'verdict': verdict,
      'status': status,
      'evidenceChecked': evidenceChecked,
      'constraintsChecked': constraintsChecked,
      'concerns': concerns,
      'reason': reason,
      'confidence': confidence,
      'requiresSuperAdminReview':
          requiresSuperAdminReview,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class AgentValidationException implements Exception {
  final String message;

  const AgentValidationException(this.message);

  @override
  String toString() =>
      'AgentValidationException: $message';
}
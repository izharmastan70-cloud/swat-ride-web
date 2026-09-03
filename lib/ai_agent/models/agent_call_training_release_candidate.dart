import 'agent_call_training_evidence.dart';

class AgentCallTrainingReleaseCandidateStatus {
  AgentCallTrainingReleaseCandidateStatus._();

  static const String eligibleForHumanReview = 'ELIGIBLE_FOR_HUMAN_REVIEW';

  static const String blocked = 'BLOCKED';

  static const Set<String> values = <String>{eligibleForHumanReview, blocked};
}

class AgentCallTrainingReleaseCandidateDecision {
  const AgentCallTrainingReleaseCandidateDecision({
    required this.status,
    required this.reason,
    required this.evidence,
    required this.evaluatedAt,
  });

  final String status;
  final String reason;
  final AgentCallTrainingEvidence evidence;
  final DateTime evaluatedAt;

  bool get eligibleForHumanReview =>
      status == AgentCallTrainingReleaseCandidateStatus.eligibleForHumanReview;

  bool get humanReviewRequired => true;
  bool get humanReviewCompleted => false;
  bool get humanApproved => false;

  bool get autoApprovalAllowed => false;
  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayTrainModel => false;
  bool get mayChangePrompt => false;
  bool get mayDeploy => false;
  bool get mayActivateProduction => false;

  void validate() {
    if (!AgentCallTrainingReleaseCandidateStatus.values.contains(status) ||
        reason.trim().isEmpty) {
      throw const AgentCallTrainingReleaseCandidateException(
        'Release-candidate status/reason is invalid.',
      );
    }

    evidence.validate();

    final bool expectedEligible = evidence.technicalEvidencePassed;

    if (eligibleForHumanReview != expectedEligible) {
      throw const AgentCallTrainingReleaseCandidateException(
        'Release-candidate eligibility must match technical evidence.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'reason': reason.trim(),
      'eligibleForHumanReview': eligibleForHumanReview,
      'humanReviewRequired': true,
      'humanReviewCompleted': false,
      'humanApproved': false,
      'autoApprovalAllowed': false,
      'evidenceId': evidence.evidenceId,
      'integrityFingerprint': evidence.integrityFingerprint,
      'evaluatedAt': evaluatedAt.toUtc().toIso8601String(),
      'mayGrantPermission': false,
      'mayConsumeApproval': false,
      'mayWriteBusinessData': false,
      'mayTrainModel': false,
      'mayChangePrompt': false,
      'mayDeploy': false,
      'mayActivateProduction': false,
    });
  }
}

class AgentCallTrainingReleaseCandidateException implements Exception {
  const AgentCallTrainingReleaseCandidateException(this.message);

  final String message;

  @override
  String toString() => 'AgentCallTrainingReleaseCandidateException: $message';
}

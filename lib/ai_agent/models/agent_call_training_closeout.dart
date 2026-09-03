import 'agent_call_training_release_candidate.dart';

class AgentCallTrainingCloseoutStatus {
  AgentCallTrainingCloseoutStatus._();

  static const String readyForHumanReview =
      'TRAINING_FOUNDATION_READY_FOR_HUMAN_REVIEW';

  static const String blocked = 'TRAINING_FOUNDATION_BLOCKED';

  static const Set<String> values = <String>{readyForHumanReview, blocked};
}

class AgentCallTrainingCloseout {
  AgentCallTrainingCloseout({
    required this.status,
    required this.phase,
    required List<String> completedSteps,
    required this.releaseCandidateDecision,
    required List<String> callAgentActions,
    required this.permissionBoundaryVerified,
    required this.canonicalBaselineVerified,
    required this.adversarialCoverageVerified,
    required this.immutableEvidenceVerified,
    required this.fullTrainingFoundationReady,
    required this.closedAt,
  }) : completedSteps = List<String>.unmodifiable(completedSteps),
       callAgentActions = List<String>.unmodifiable(callAgentActions);

  final String status;
  final String phase;
  final List<String> completedSteps;
  final AgentCallTrainingReleaseCandidateDecision releaseCandidateDecision;
  final List<String> callAgentActions;

  final bool permissionBoundaryVerified;
  final bool canonicalBaselineVerified;
  final bool adversarialCoverageVerified;
  final bool immutableEvidenceVerified;
  final bool fullTrainingFoundationReady;

  final DateTime closedAt;

  bool get humanReviewRequired => true;
  bool get humanReviewCompleted => false;
  bool get humanApproved => false;

  bool get productionCallLive => false;
  bool get telephonyConnected => false;
  bool get sttConnected => false;
  bool get ttsConnected => false;
  bool get smsConnected => false;
  bool get trustedBackendEvidencePersisted => false;
  bool get evidenceCryptographicallySigned => false;

  bool get mayGrantPermission => false;
  bool get mayConsumeApproval => false;
  bool get mayWriteBusinessData => false;
  bool get mayTrainModel => false;
  bool get mayChangePrompt => false;
  bool get mayDeploy => false;
  bool get mayActivateProduction => false;

  bool get readyForHumanReview =>
      status == AgentCallTrainingCloseoutStatus.readyForHumanReview;

  void validate() {
    if (!AgentCallTrainingCloseoutStatus.values.contains(status) ||
        phase != 'PHASE_50_CALL_TRAINING' ||
        completedSteps.length != 7 ||
        callAgentActions.length != 4) {
      throw const AgentCallTrainingCloseoutException(
        'Call training closeout identity/step/action boundary is invalid.',
      );
    }

    releaseCandidateDecision.validate();

    const Set<String> expectedSteps = <String>{
      '1A',
      '1B',
      '1C',
      '1D',
      '1E',
      '1F',
      '1G',
    };

    if (completedSteps.toSet().length != completedSteps.length ||
        !completedSteps.toSet().containsAll(expectedSteps)) {
      throw const AgentCallTrainingCloseoutException(
        'Call training closeout must contain exactly Steps 1A-1G.',
      );
    }

    final bool computedReady =
        releaseCandidateDecision.eligibleForHumanReview &&
        permissionBoundaryVerified &&
        canonicalBaselineVerified &&
        adversarialCoverageVerified &&
        immutableEvidenceVerified;

    if (fullTrainingFoundationReady != computedReady ||
        readyForHumanReview != computedReady) {
      throw const AgentCallTrainingCloseoutException(
        'Call training closeout readiness is inconsistent.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validate();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'status': status,
      'phase': phase,
      'completedSteps': List<String>.unmodifiable(completedSteps),
      'callAgentActions': List<String>.unmodifiable(callAgentActions),
      'permissionBoundaryVerified': permissionBoundaryVerified,
      'canonicalBaselineVerified': canonicalBaselineVerified,
      'adversarialCoverageVerified': adversarialCoverageVerified,
      'immutableEvidenceVerified': immutableEvidenceVerified,
      'fullTrainingFoundationReady': fullTrainingFoundationReady,
      'humanReviewRequired': true,
      'humanReviewCompleted': false,
      'humanApproved': false,
      'productionCallLive': false,
      'telephonyConnected': false,
      'sttConnected': false,
      'ttsConnected': false,
      'smsConnected': false,
      'trustedBackendEvidencePersisted': false,
      'evidenceCryptographicallySigned': false,
      'mayGrantPermission': false,
      'mayConsumeApproval': false,
      'mayWriteBusinessData': false,
      'mayTrainModel': false,
      'mayChangePrompt': false,
      'mayDeploy': false,
      'mayActivateProduction': false,
      'closedAt': closedAt.toUtc().toIso8601String(),
    });
  }
}

class AgentCallTrainingCloseoutException implements Exception {
  const AgentCallTrainingCloseoutException(this.message);

  final String message;

  @override
  String toString() => 'AgentCallTrainingCloseoutException: $message';
}

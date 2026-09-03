import '../constants/help_video_education_progress_constants.dart';
import '../models/help_video_education_recommendation_decision.dart';
import '../models/help_video_learning_progress.dart';
import '../models/help_video_next_recommendation_decision.dart';

class HelpVideoLearningProgressContractService {
  const HelpVideoLearningProgressContractService();

  HelpVideoLearningProgress buildProgress({
    required String tutorialId,
    required int watchedSeconds,
    required int durationSeconds,
    required bool completionConfirmed,
    required DateTime updatedAt,
  }) {
    final String status;

    if (completionConfirmed) {
      status = HelpVideoLearningProgressStatus.completed;
    } else if (watchedSeconds <= 0) {
      status = HelpVideoLearningProgressStatus.notStarted;
    } else {
      status = HelpVideoLearningProgressStatus.inProgress;
    }

    final HelpVideoLearningProgress progress = HelpVideoLearningProgress(
      tutorialId: tutorialId.trim(),
      status: status,
      watchedSeconds: watchedSeconds,
      durationSeconds: durationSeconds,
      updatedAt: updatedAt,
      completionConfirmed: completionConfirmed,
    );

    progress.validateStructure();
    return progress;
  }

  HelpVideoNextRecommendationDecision evaluateNextVideo({
    required HelpVideoLearningProgress currentProgress,
    required HelpVideoEducationRecommendationDecision safeCandidateDecision,
  }) {
    try {
      currentProgress.validateStructure();
      safeCandidateDecision.validateStructure();
    } catch (_) {
      return _decision(
        status: HelpVideoNextRecommendationStatus.blockedInvalidProgress,
        currentTutorialId: _safeId(currentProgress.tutorialId),
        candidateTutorialId: '',
        reasons: const <String>[
          HelpVideoLearningProgressReason.progressMetadataOnly,
          HelpVideoLearningProgressReason.invalidProgressBlocked,
          HelpVideoLearningProgressReason.nonAuthoritativeLearningSignal,
        ],
      );
    }

    if (!currentProgress.isCompleted) {
      return _decision(
        status: HelpVideoNextRecommendationStatus.resumeCurrent,
        currentTutorialId: currentProgress.tutorialId,
        candidateTutorialId: '',
        reasons: <String>[
          HelpVideoLearningProgressReason.progressMetadataOnly,
          currentProgress.status == HelpVideoLearningProgressStatus.notStarted
              ? HelpVideoLearningProgressReason.notStarted
              : HelpVideoLearningProgressReason.partialWatch,
          HelpVideoLearningProgressReason.resumeCurrentVideo,
          HelpVideoLearningProgressReason.nonAuthoritativeLearningSignal,
        ],
      );
    }

    if (!safeCandidateDecision.canRecommend) {
      return _decision(
        status: HelpVideoNextRecommendationStatus.blockedUnsafeCandidate,
        currentTutorialId: currentProgress.tutorialId,
        candidateTutorialId: '',
        reasons: const <String>[
          HelpVideoLearningProgressReason.progressMetadataOnly,
          HelpVideoLearningProgressReason.alreadyCompleted,
          HelpVideoLearningProgressReason.safeStep1cCandidateRequired,
          HelpVideoLearningProgressReason.unsafeCandidateBlocked,
          HelpVideoLearningProgressReason.nonAuthoritativeLearningSignal,
        ],
      );
    }

    if (safeCandidateDecision.tutorialId == currentProgress.tutorialId) {
      return _decision(
        status: HelpVideoNextRecommendationStatus.noNextRequired,
        currentTutorialId: currentProgress.tutorialId,
        candidateTutorialId: '',
        reasons: const <String>[
          HelpVideoLearningProgressReason.progressMetadataOnly,
          HelpVideoLearningProgressReason.alreadyCompleted,
          HelpVideoLearningProgressReason.noNextVideoRequired,
          HelpVideoLearningProgressReason.nonAuthoritativeLearningSignal,
        ],
      );
    }

    return _decision(
      status: HelpVideoNextRecommendationStatus.recommendNext,
      currentTutorialId: currentProgress.tutorialId,
      candidateTutorialId: safeCandidateDecision.tutorialId,
      reasons: const <String>[
        HelpVideoLearningProgressReason.progressMetadataOnly,
        HelpVideoLearningProgressReason.explicitCompletion,
        HelpVideoLearningProgressReason.safeStep1cCandidateRequired,
        HelpVideoLearningProgressReason.nextVideoCandidate,
        HelpVideoLearningProgressReason.nonAuthoritativeLearningSignal,
      ],
    );
  }

  HelpVideoNextRecommendationDecision _decision({
    required String status,
    required String currentTutorialId,
    required String candidateTutorialId,
    required List<String> reasons,
  }) {
    final HelpVideoNextRecommendationDecision decision =
        HelpVideoNextRecommendationDecision(
          status: status,
          currentTutorialId: currentTutorialId,
          candidateTutorialId: candidateTutorialId,
          reasonCodes: reasons,
        );

    decision.validateStructure();
    return decision;
  }

  String _safeId(String value) {
    final String trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'invalid_tutorial';
    }

    if (trimmed.length <= 180) {
      return trimmed;
    }

    return trimmed.substring(0, 180);
  }

  bool get reusesStep1CSafeRecommendation => true;
  bool get implementsDuplicateRankingEngine => false;
  bool get progressContractOnly => true;
  bool get completionRequiresExplicitConfirmation => true;
  bool get autoMarksComplete => false;
  bool get autoOpensVideo => false;
  bool get generatesContent => false;
  bool get invokesProvider => false;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get invokesPermissionEngine => false;
  bool get invokesApprovalEngine => false;
  bool get invokesRuntimeGate => false;
  bool get invokesEmergencyStop => false;
  bool get writesBusinessData => false;
  bool get persistsLearningProgress => false;
  bool get persistsNextRecommendation => false;
  bool get implementsPhase56ContentGeneration => false;
  bool get implementsPhase57KnowledgeLibrary => false;
  bool get implementsPhase63PrivacyUi => false;
}

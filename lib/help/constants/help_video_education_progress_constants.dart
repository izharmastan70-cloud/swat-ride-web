class HelpVideoLearningProgressStatus {
  HelpVideoLearningProgressStatus._();

  static const String notStarted = 'NOT_STARTED';
  static const String inProgress = 'IN_PROGRESS';
  static const String completed = 'COMPLETED';

  static const Set<String> values = <String>{notStarted, inProgress, completed};
}

class HelpVideoNextRecommendationStatus {
  HelpVideoNextRecommendationStatus._();

  static const String resumeCurrent = 'RESUME_CURRENT';
  static const String recommendNext = 'RECOMMEND_NEXT';
  static const String noNextRequired = 'NO_NEXT_REQUIRED';
  static const String blockedUnsafeCandidate = 'BLOCKED_UNSAFE_CANDIDATE';
  static const String blockedInvalidProgress = 'BLOCKED_INVALID_PROGRESS';

  static const Set<String> values = <String>{
    resumeCurrent,
    recommendNext,
    noNextRequired,
    blockedUnsafeCandidate,
    blockedInvalidProgress,
  };
}

class HelpVideoLearningProgressReason {
  HelpVideoLearningProgressReason._();

  static const String progressMetadataOnly = 'progress_metadata_only';
  static const String notStarted = 'not_started';
  static const String partialWatch = 'partial_watch';
  static const String explicitCompletion = 'explicit_completion';
  static const String alreadyCompleted = 'already_completed';
  static const String safeStep1cCandidateRequired =
      'safe_step1c_candidate_required';
  static const String resumeCurrentVideo = 'resume_current_video';
  static const String nextVideoCandidate = 'next_video_candidate';
  static const String noNextVideoRequired = 'no_next_video_required';
  static const String unsafeCandidateBlocked = 'unsafe_candidate_blocked';
  static const String invalidProgressBlocked = 'invalid_progress_blocked';
  static const String nonAuthoritativeLearningSignal =
      'non_authoritative_learning_signal';

  static const Set<String> values = <String>{
    progressMetadataOnly,
    notStarted,
    partialWatch,
    explicitCompletion,
    alreadyCompleted,
    safeStep1cCandidateRequired,
    resumeCurrentVideo,
    nextVideoCandidate,
    noNextVideoRequired,
    unsafeCandidateBlocked,
    invalidProgressBlocked,
    nonAuthoritativeLearningSignal,
  };
}

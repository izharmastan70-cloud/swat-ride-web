import '../constants/help_video_education_progress_constants.dart';

class HelpVideoLearningProgress {
  HelpVideoLearningProgress({
    required this.tutorialId,
    required this.status,
    required this.watchedSeconds,
    required this.durationSeconds,
    required this.updatedAt,
    required this.completionConfirmed,
  });

  final String tutorialId;
  final String status;
  final int watchedSeconds;
  final int durationSeconds;
  final DateTime updatedAt;
  final bool completionConfirmed;

  double get progressRatio {
    if (durationSeconds <= 0) {
      return 0;
    }

    final double ratio = watchedSeconds / durationSeconds;

    if (ratio < 0) {
      return 0;
    }

    if (ratio > 1) {
      return 1;
    }

    return ratio;
  }

  int get progressPercent => (progressRatio * 100).round();

  bool get isCompleted => status == HelpVideoLearningProgressStatus.completed;

  bool get progressMetadataOnly => true;
  bool get grantsAuthority => false;
  bool get grantsPermission => false;
  bool get consumesApproval => false;
  bool get marksRuntimeAllowed => false;
  bool get invokesProvider => false;
  bool get writesBusinessData => false;
  bool get persistsProgress => false;

  void validateStructure() {
    if (tutorialId.trim().isEmpty || tutorialId.length > 180) {
      throw const HelpVideoLearningProgressException(
        'Video learning tutorial ID is invalid.',
      );
    }

    if (!HelpVideoLearningProgressStatus.values.contains(status)) {
      throw const HelpVideoLearningProgressException(
        'Video learning progress status is invalid.',
      );
    }

    if (durationSeconds <= 0 ||
        durationSeconds > 86400 ||
        watchedSeconds < 0 ||
        watchedSeconds > durationSeconds) {
      throw const HelpVideoLearningProgressException(
        'Video learning progress duration is invalid.',
      );
    }

    if (status == HelpVideoLearningProgressStatus.notStarted &&
        (watchedSeconds != 0 || completionConfirmed)) {
      throw const HelpVideoLearningProgressException(
        'NOT_STARTED progress cannot contain watched/completed state.',
      );
    }

    if (status == HelpVideoLearningProgressStatus.inProgress &&
        (watchedSeconds <= 0 ||
            watchedSeconds >= durationSeconds ||
            completionConfirmed)) {
      throw const HelpVideoLearningProgressException(
        'IN_PROGRESS state is inconsistent.',
      );
    }

    if (status == HelpVideoLearningProgressStatus.completed &&
        !completionConfirmed) {
      throw const HelpVideoLearningProgressException(
        'COMPLETED state requires explicit completion confirmation.',
      );
    }
  }

  Map<String, dynamic> toSafeMap() {
    validateStructure();

    return Map<String, dynamic>.unmodifiable(<String, dynamic>{
      'tutorialId': tutorialId,
      'status': status,
      'watchedSeconds': watchedSeconds,
      'durationSeconds': durationSeconds,
      'progressPercent': progressPercent,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'completionConfirmed': completionConfirmed,
      'progressMetadataOnly': true,
      'grantsAuthority': false,
      'writesBusinessData': false,
      'persistsProgress': false,
    });
  }
}

class HelpVideoLearningProgressException implements Exception {
  const HelpVideoLearningProgressException(this.message);

  final String message;

  @override
  String toString() => 'HelpVideoLearningProgressException: $message';
}

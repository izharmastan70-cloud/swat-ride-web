import '../models/help_video_tutorial_model.dart';

/// Read-only app/video-version awareness for SWAT RIDE tutorials.
///
/// This service never publishes, edits, archives, restores, or creates
/// Firestore documents. It only classifies tutorial compatibility.
///
/// A detected version mismatch may request a future maintenance task, but
/// automatic production publishing remains forbidden.
class HelpVideoVersionAwarenessService {
  const HelpVideoVersionAwarenessService();

  HelpVideoVersionAwarenessResult evaluate({
    required HelpVideoTutorialModel tutorial,
    required String currentAppVersion,
  }) {
    final publishedStatus = tutorial.publishedStatus.trim().toLowerCase();

    if (tutorial.outdated) {
      return const HelpVideoVersionAwarenessResult(
        isCompatible: false,
        needsReview: true,
        shouldCreateUpdateTask: true,
        reason: 'tutorial_outdated',
      );
    }

    if (publishedStatus != 'published') {
      return const HelpVideoVersionAwarenessResult(
        isCompatible: false,
        needsReview: false,
        shouldCreateUpdateTask: false,
        reason: 'tutorial_not_published',
      );
    }

    final current = _normalizeVersion(currentAppVersion);

    final tutorialAppVersion = _normalizeVersion(tutorial.appVersion);

    if (current.isEmpty) {
      return const HelpVideoVersionAwarenessResult(
        isCompatible: true,
        needsReview: false,
        shouldCreateUpdateTask: false,
        reason: 'current_app_version_unknown',
      );
    }

    if (tutorialAppVersion.isEmpty) {
      return const HelpVideoVersionAwarenessResult(
        isCompatible: false,
        needsReview: true,
        shouldCreateUpdateTask: true,
        reason: 'tutorial_app_version_missing',
      );
    }

    if (current != tutorialAppVersion) {
      return HelpVideoVersionAwarenessResult(
        isCompatible: false,
        needsReview: true,
        shouldCreateUpdateTask: true,
        reason: 'app_version_mismatch:$tutorialAppVersion->$current',
      );
    }

    return const HelpVideoVersionAwarenessResult(
      isCompatible: true,
      needsReview: false,
      shouldCreateUpdateTask: false,
      reason: 'app_version_match',
    );
  }

  /// Existing archived versions can be considered for a controlled rollback
  /// workflow. This method does NOT perform the rollback itself.
  bool canServeAsRollbackCandidate(HelpVideoTutorialModel tutorial) {
    return tutorial.publishedStatus.trim().toLowerCase() == 'archived' &&
        !tutorial.outdated &&
        tutorial.isApprovedForPublication &&
        tutorial.videoVersion.trim().isNotEmpty;
  }

  String _normalizeVersion(String value) {
    return value.trim().toLowerCase();
  }
}

class HelpVideoVersionAwarenessResult {
  const HelpVideoVersionAwarenessResult({
    required this.isCompatible,
    required this.needsReview,
    required this.shouldCreateUpdateTask,
    required this.reason,
  });

  final bool isCompatible;
  final bool needsReview;

  /// Signals the later 37P maintenance workflow.
  ///
  /// This flag alone NEVER creates or publishes anything.
  final bool shouldCreateUpdateTask;

  final String reason;
}

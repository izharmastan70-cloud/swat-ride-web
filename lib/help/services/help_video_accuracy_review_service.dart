import '../models/help_video_maintenance_draft.dart';

class HelpVideoAccuracyReviewResult {
  const HelpVideoAccuracyReviewResult({
    required this.canSubmitToOwnerApproval,
    required this.requiresExtraHumanReview,
    required this.blockingReasons,
    required this.reviewReasons,
  });

  final bool canSubmitToOwnerApproval;
  final bool requiresExtraHumanReview;

  final List<String> blockingReasons;
  final List<String> reviewReasons;
}

/// Pre-publication safety review foundation.
///
/// This does not approve or publish anything.
/// Final Owner/Super Admin review remains mandatory.
class HelpVideoAccuracyReviewService {
  const HelpVideoAccuracyReviewService();

  HelpVideoAccuracyReviewResult reviewDraft(HelpVideoMaintenanceDraft draft) {
    final blocking = <String>[];
    final review = <String>[...draft.extraReviewReasons];

    if (!draft.isSafeDraftContract) {
      blocking.add('unsafe_approval_contract');
    }

    if (draft.sourceTutorialId.trim().isEmpty) {
      blocking.add('source_tutorial_missing');
    }

    if (draft.targetAppVersion.trim().isEmpty) {
      blocking.add('target_app_version_missing');
    }

    if (draft.proposedVideoVersion.trim().isEmpty) {
      blocking.add('proposed_video_version_missing');
    }

    if (draft.changeSummary.trim().isEmpty) {
      blocking.add('change_summary_missing');
    }

    if (draft.scriptDraft.trim().isEmpty) {
      blocking.add('script_draft_missing');
    }

    if (draft.storyboardDraft.trim().isEmpty) {
      blocking.add('storyboard_draft_missing');
    }

    if (draft.narrationDraft.trim().isEmpty) {
      blocking.add('narration_draft_missing');
    }

    if (draft.captionDraft.trim().isEmpty) {
      blocking.add('caption_draft_missing');
    }

    if (draft.automaticPublishAllowed) {
      blocking.add('automatic_publish_must_remain_disabled');
    }

    return HelpVideoAccuracyReviewResult(
      canSubmitToOwnerApproval: blocking.isEmpty,
      requiresExtraHumanReview: draft.needsExtraReview || review.isNotEmpty,
      blockingReasons: List<String>.unmodifiable(blocking),
      reviewReasons: List<String>.unmodifiable(review),
    );
  }
}
